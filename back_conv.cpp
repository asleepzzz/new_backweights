#include "hip/hip_runtime.h"
#include <stdlib.h>



#define HIP_ASSERT(x) (assert((x)==hipSuccess))
//#define THREADS_PER_BLOCK_X  1
//#define THREADS_PER_BLOCK_Y  1
//#define THREADS_PER_BLOCK_Z  1


#define CHECK(cmd)                                                                                 \
    {                                                                                              \
        hipError_t error = cmd;                                                                    \
        if (error != hipSuccess) {                                                                 \
            fprintf(stderr, "error: '%s'(%d) at %s:%d\n", hipGetErrorString(error), error,         \
                    __FILE__, __LINE__);                                                           \
            exit(EXIT_FAILURE);                                                                    \
        }                                                                                          \
}


void calculateUniIndex(int* unifiedIndex ,int N,int OutH,int OutW,int C,int H,int W ,int K,int strideH,int strideW)
{//index*2 for matrix A & B,size is N*Oh*Ow*2
///Index[group][2][N*Oh*Ow]

    int matrixK = N*OutH*OutW;
    //for (int g=0;g<group_count;g++) {
        for (int matrix_kk_index =0;matrix_kk_index< matrixK;matrix_kk_index++) {
            int n = matrix_kk_index /(OutH*OutW);
            int h = matrix_kk_index%(OutH*OutW)/OutW;
            int w = matrix_kk_index%(OutH*OutW)%OutW;

            int num = C*H*W;
            unifiedIndex[matrix_kk_index]=  n*C*H*W+h*W+w;//for MatrixA
            //unifiedIndex[matrix_kk_index+g*2*matrixK]+= g*num;//when you split your data,you need this offset to get real position for group conv

            num = K*OutH*OutW;
            unifiedIndex[matrixK+matrix_kk_index]= n*K*OutH*OutW+h*OutW+w;//+128*OutH*OutW;//for MatrixB
            //unifiedIndex[matrixK+matrix_kk_index+g*2*matrixK] += g*num;//when you split your data,you need this offset to get real position for group conv
        }
    //}
}



void cpu_backward_weights_group(float *in,float* out,float* weight
                          ,int N,int C,int H,int W,
                          int K,int R,int S,
                          int outH,int outW,
                          int strideH, int strideW)
{

    struct timespec tstart={0,0}, tend={0,0};
    clock_gettime(CLOCK_MONOTONIC, &tstart);

    for(int o = 0; o < N; o++)
    {
        //for(int g = 0; g < group_count; g++)
        //{
            for(int w = 0; w < K; w++)
            {
                for(int k = 0; k < C; k++)
                {
                    for(int x = 0; x < R; x++)
                    {
                        for(int y = 0; y < S; y++)
                        {
                            for(int i = 0; i < outH; i++)
                            {
                                for(int j = 0; j < outW; j++)
                                {
                                    int in_i = i  + x*strideH ;
                                    int in_j = j  + y*strideW ;
                                    if((in_i >= 0) && (in_i < H) && (in_j >= 0) &&
                                        (in_j < W))
                                    {
                                        weight[w*C*R*S+k*R*S+x*S+y]+=in[o*C*H*W+k*H*W+in_i *W + in_j]*out[o*K*outH*outW+w*outH*outW+(i*outW)+j];
                                        //weight[w*C*R*S+k*R*S+x*S+y]+=in[o*C*H*W+k*H*W+i *W+x*strideH*W + in_j]*out[o*K*outH*outW+w*outH*outW+(i*outW)+j];


                                        //weight[((g * (K / group_count)+w)*((C*R*S)/group_count)) + (k*R*S)+ (x * S) + y]
                                        //+= in[o *C*H*W+ ((g * (C / group_count)+k)*H*W)+in_i *W + in_j]
                                        //*out[(o*K*outH*outW) +((g * (K / group_count)+w)*outH*outW)+(i*outW)+j];
                                    }
                                }
                            }
                        }
                    }
                }
            }
        //}
    }

    clock_gettime(CLOCK_MONOTONIC, &tend);
    printf("cpu computation took about %.5f seconds\n",
           ((double)tend.tv_sec + 1.0e-9*tend.tv_nsec) -
           ((double)tstart.tv_sec + 1.0e-9*tstart.tv_nsec));

}

void calculateCRSOffsetIndex(int* inIndex ,int block,int N,int OutH,int OutW,int C,int H,int W ,int K,int R,int S,int strideH,int strideW)
{
        int BLOCKS_PER_K = (K+127)/128;

        for (int i =0;i<block;i++)
        {
            for (int j =0;j<128;j++)//ThreadID
            {
                int m_offset_global_fetch = i  *128 + j;
                int wg_c_global_fetch = m_offset_global_fetch / (R*S);
                int wg_r_global_fetch = (m_offset_global_fetch % (R*S) ) / S;
                int wg_s_global_fetch = (m_offset_global_fetch % (R*S) ) % S;
                int matrix_a_offset = wg_c_global_fetch * H *W + wg_r_global_fetch*strideH * W + wg_s_global_fetch*strideW;//stride need add only in A


                //IF C *R*S is out of boundary
                if(wg_c_global_fetch >=C) {
                    matrix_a_offset = C*H*W-1;
                }

                inIndex[i*128+j] = matrix_a_offset;
            }
        }
}

void calculateOutIndex(int* outIndex ,int blocks,int BLOCKS_PER_K,int K,int C,int R, int S)
{
    for (int b=0;b<blocks;b++)
    {
        for(int t =0; t < 16; t++)
        {
            for(int i =0; i < 8; i++)
            {
                    int m = i + ((t%16)*8)+(b *128);//if block id not equal to 0 ,CRS need to add

                    int c = m / (R*S);
                    int r = (m % (R*S)) / S;
                    int s = (m % (R*S)) % S;

                    outIndex[b*16*8+t*8+i]= c*R*S + r *S + s;
            }
        }
    }
}


int main()
{
    int N=1; int C=1;int H=4;int W=4;//in
    int K=1;int outH=2;int outW=2;///out,carefully,you need to place correct size when stride and dilation
    int R =2;int S=2;//wei
    int strideH = 2; int strideW =2;
//    int dilation_h =1;int dilation_w =1;
//    int group_count =1;


    int inSize = N*C*H*W* sizeof(float);
    int outSize = N*K*outH*outW* sizeof(float);
    int weiGroupSize =  K*C*R*S* sizeof(float);

    float *in = (float *)malloc(inSize);
    float *out = (float *)malloc(outSize);
    float *wei = (float *)malloc(weiGroupSize);
    float *dwei_gpu = (float *)malloc(weiGroupSize);

    for (int i=0;i<inSize/sizeof(float);i++) { 
         float r = (float)(static_cast <float> (rand()) / static_cast <float> (RAND_MAX));

         in[i] =1.0f*i;//r;
    }

    for (int i=0;i<outSize/sizeof(float);i++) {
         float r = (float)(static_cast <float> (rand()) / static_cast <float> (RAND_MAX));
         out[i] =1.0f;//r;
    }

    for (int i=0;i<weiGroupSize/sizeof(float);i++) {
         wei[i] =0;
         dwei_gpu[i] = 0;
    }



    cpu_backward_weights_group(in,out,wei
        ,N,C,H,W,
        K,R,S,
        outH,outW,strideH,strideW);

    for(int i =0 ;i<weiGroupSize/sizeof(float);i++)
    {
        printf("wei %d is %f\n",i,wei[i]);
    }

    int uniIndexSize = 2*N*outH*outW*sizeof(int);
    int* uniFiedIndex = (int*)malloc(uniIndexSize);
    calculateUniIndex(uniFiedIndex,N, outH, outW,C,H,W , K,strideH,strideW);


    int Global_Size = ((K+127)/128)* ((C * R * S+127)/128);
    int BLOCKS_PER_K = (K+127)/128;
    int block_size = ((Global_Size+BLOCKS_PER_K-1)/BLOCKS_PER_K);

    int crsOffsetSize = block_size*128*sizeof(int);//thread
    int* inIndex = (int*)malloc(crsOffsetSize);
    calculateCRSOffsetIndex(inIndex ,block_size, N, outH, outW, C, H, W , K, R, S, strideH, strideW);


    int outOffsetSize = block_size*16*8*sizeof(int);
    int* outIndex = (int*)malloc(outOffsetSize);
    calculateOutIndex(outIndex ,block_size,BLOCKS_PER_K, K, C, R,  S);


    int* device_uniIndex;
    int* device_inIndex;
    int* device_outIndex;
    float* device_test;

    HIP_ASSERT(hipMalloc(&device_uniIndex, uniIndexSize));
    HIP_ASSERT(hipMalloc(&device_inIndex, crsOffsetSize));
    HIP_ASSERT(hipMalloc(&device_outIndex, outOffsetSize));
    HIP_ASSERT(hipMalloc(&device_test, 64*sizeof(float)));


    HIP_ASSERT(hipMemcpy(device_uniIndex,uniFiedIndex, uniIndexSize, hipMemcpyHostToDevice));
    HIP_ASSERT(hipMemcpy(device_inIndex,inIndex, crsOffsetSize, hipMemcpyHostToDevice));
    HIP_ASSERT(hipMemcpy(device_outIndex,outIndex, outOffsetSize, hipMemcpyHostToDevice));

    float* devicein;
    float* deviceout;
    float* devicedwei;

    HIP_ASSERT(hipMalloc((void**)&devicein, inSize));
    HIP_ASSERT(hipMalloc((void**)&deviceout, outSize));
    HIP_ASSERT(hipMalloc((void**)&devicedwei, weiGroupSize));





    HIP_ASSERT(hipMemcpy(devicein,in, inSize, hipMemcpyHostToDevice));
    HIP_ASSERT(hipMemcpy(deviceout,out, outSize, hipMemcpyHostToDevice));
    HIP_ASSERT(hipMemcpy(devicedwei,dwei_gpu, weiGroupSize, hipMemcpyHostToDevice));


    int Threads_Size = 256;
int dilation_h =1;int dilation_w =1;
int group_count =1;
//    hipLaunchKernelGGL(back_weights,dim3(Global_Size), dim3(Threads_Size), 0, 0,
//                       devicein,deviceout,devicedwei,device_uniIndex,device_inIndex,device_outIndex,
//                       N,C,H,W,K,R,S,outH,outW,strideH,strideW,dilation_h,dilation_w,group_count,device_test);


//CHECK(hipMemcpy(dwei_gpu,devicedwei, weiGroupSize, hipMemcpyDeviceToHost));



    HIP_ASSERT(hipFree(deviceout));
    HIP_ASSERT(hipFree(devicein));
    HIP_ASSERT(hipFree(devicedwei));


    free(in);
    free(out);
    free(wei);
    free(dwei_gpu);
    free(uniFiedIndex);
    free(inIndex);


    return 0;
}


