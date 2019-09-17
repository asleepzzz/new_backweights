#include <iostream>
#include <stdio.h>
#include <vector>
#include <hip/hip_runtime.h>
#include <hip/hip_runtime_api.h>
#include "mkldnn_conv.h"
#include "verify.hpp"
//#define DEBUG 1
//#ifdef DEBUG
//    #define DEBUG_PRINT printf
//#else
    #define DEBUG_PRINT(...)
//#endif

constexpr unsigned x = 16;
#define HIP_ASSERT(x) (assert((x)==hipSuccess))


#define CHECK(cmd)                                                                                 \
    {                                                                                              \
        hipError_t error = cmd;                                                                    \
        if (error != hipSuccess) {                                                                 \
            fprintf(stderr, "error: '%s'(%d) at %s:%d\n", hipGetErrorString(error), error,         \
                    __FILE__, __LINE__);                                                           \
            exit(EXIT_FAILURE);                                                                    \
        }                                                                                          \
}

typedef struct{
    unsigned int pnx;
    unsigned int pny;
    unsigned int pnz;
    unsigned int qnx;
    unsigned int qny;
    unsigned int qnz;
    unsigned int fnx;
    unsigned int fny;
    unsigned int fnz;
    unsigned int pnc;
    unsigned int qnc;
    unsigned int bat;
} group_prop_t;



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

void calculateCRSOffsetIndex(unsigned int* inIndex ,int block,int N,int OutH,int OutW,int C,int H,int W ,int K,int R,int S,int strideH,int strideW)
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
                int matrix_a_offset = (unsigned int)(wg_c_global_fetch * H *W + wg_r_global_fetch*strideH * W + wg_s_global_fetch*strideW);


                //IF C *R*S is out of boundary
                if(wg_c_global_fetch >=C) {
                    matrix_a_offset = (unsigned int)(C*H*W-1);
                }
 
                inIndex[i*128+j] = matrix_a_offset;
            }
        }
}

int computeWeiIndex(int g,int i, int j, int k,int l,int weiN,int weiC,int weiH,int weiW,int group_count )
{
    return (g*(weiN/group_count)+i)*(weiC/group_count)*weiH*weiW+j*weiH*weiW+k*weiW+l;
}


void compare(float* cpu,float* hip,int weiN,int weiC,int weiH,int  weiW,int num_matrixK,int combine)
{

    //std::vector<float> cpu_vector(cpu, cpu + weiN*weiC*weiH*weiW);
    //std::vector<float> gpu_vector(hip, hip + weiN*weiC*weiH*weiW);
    //double tt= rms_range(cpu_vector,gpu_vector);


    double error_weights = verify( cpu,hip,weiN*weiC*weiH*weiW* sizeof(float));
printf("shit %.9f\n",error_weights);

    double square_tmp =0.0;
    double max_tmp =0.0;
        for (int i =0;i<(weiN);i++)
        {
            for (int j =0;j<(weiC);j++)
            {
                for (int k =0;k<weiH;k++)
                {
                    for (int l =0;l<weiW;l++)
                    {
                        int index = computeWeiIndex( 0,i,  j,  k, l, weiN, weiC, weiH, weiW,1); 
                        float tmp=0;
                        if (combine ==1)
                        {
                            for (int u =0;u<16;u++)
                            {
                                tmp+=hip[index+u*weiN*weiC*weiH*weiW];
                                if (index==0)
                                {
                                    DEBUG_PRINT("16 combine %d  index %d is %f\n",u,index+u*weiN*weiC*weiH*weiW,hip[index+u*weiN*weiC*weiH*weiW]);
                                }
                            
                            }
                        } else {
                            tmp = hip[index];
                        }    

                        square_tmp += (double)((cpu[index]-tmp)*(cpu[index]-tmp));
                        if (cpu[index]>max_tmp)
                            max_tmp = cpu[index];

                        if (tmp>max_tmp)
                            max_tmp = tmp;

                        if ((abs(cpu[index]-tmp)/cpu[index])>=((1e-6)) )
                        //if (cpu[index]!=tmp)
                        {

                            //printf("error %f %f\n",cpu[index],tmp);

                            //return ;
                            DEBUG_PRINT("not queal %.15f %15f kcrs  %d %d %d %d\n",cpu[index],tmp,i,j,k,l);
                        } else {

                            DEBUG_PRINT("the same %.15f %.15f kcrs  %d %d %d %d\n",cpu[index],tmp,i,j,k,l);
                        }
                    }
                }
            }
        }

    //miopen
    double tolrence = (std::sqrt((double)square_tmp) / ((double)std::sqrt(weiN*weiC*weiH*weiW) * (double)max_tmp));
    if(!(error_weights < 1e-6))
    {

        printf("verify failed %f max is %f\n",tolrence,max_tmp);
    } else {

        printf("verify ok\n");

    }

}

void cpu_backward_weights(float *in,float* out,float* weight
                          ,int N,int C,int H,int W,
                          int K,int R,int S,
                          int outH,int outW,
                          int strideH, int strideW,
                          int dilation_h,int dilation_w)
{

    struct timespec tstart={0,0}, tend={0,0};


    clock_gettime(CLOCK_MONOTONIC, &tstart);

       for(int k = 0; k < K; k++)
        {
            for(int c = 0; c < C; c++)
            {
                for(int y = 0; y < R; y++)
                {
                    for(int x = 0; x < S; x++)
                    {

                        double acc =0;//if you dont use double to add here, precision will miss

//    #pragma omp parallel for
    for(int n = 0; n < N; n++)
    {
 
                        for(int h = 0; h < outH; h++)
                        {
                           for(int w = 0; w < outW; w++)
                           {
                                int in_h = h*strideH  + y*dilation_h ;
                                int in_w = w*strideW  + x*dilation_w ;
                                if((in_h >= 0) && (in_h < H) && (in_w >= 0) && (in_w < W))
                                {
//                                    #pragma omp atomic
                                    acc+=  
                                    static_cast<double>((in[n *C*H*W+  c*H*W+in_h *W + in_w])*
                                    static_cast<double>(out[n*K*outH*outW +k*outH*outW+h*outW+w]));
                                }
                           }
                        }
                            
    }
                        weight[k*C*R*S + c*R*S+ y * S + x] = acc;
                    }
                }
            }
        }
    clock_gettime(CLOCK_MONOTONIC, &tend);
    DEBUG_PRINT("cpu computation took about %.5f seconds\n",
           ((double)tend.tv_sec + 1.0e-9*tend.tv_nsec) - 
           ((double)tstart.tv_sec + 1.0e-9*tstart.tv_nsec));


}





void fconv_generate_auxbuf( unsigned int* indices, const group_prop_t* p_prop, const unsigned int* strides, unsigned int ntidx )
{
    unsigned int snx, sny, snz, onx, ony, onz,onc, inc, bat, su, sv, sd, nvalid, npix, pix, uv, i, tid,isafe;
    snx=p_prop->pnx;
    sny=p_prop->pny;
    snz=p_prop->pnz;
    onx=p_prop->qnx;
    ony=p_prop->qny;
    onz=p_prop->qnz;
    onc=p_prop->qnc;
    inc=p_prop->pnc;
    bat=p_prop->bat;
    su=sv=sd=1;
    if(strides!=0){
        su=strides[0];
        sv=strides[1];
        if(snz>1){ sd=strides[2]; }
    }



    npix=onx*ony;
    nvalid=bat*npix;
//DEBUG_PRINT("nvalid %u \n",nvalid);
    unsigned int istr  = inc*sny ; //inc*sny
    unsigned int ostr  = onc*onx*ony*onz ; //onc*npx

    for(int i=0; i<ntidx; ++i ){
        isafe=i<nvalid?i:0;
        unsigned int ibt=isafe/npix;//small n
        pix=isafe%npix;
        unsigned int y=pix/onx;
        unsigned int x=pix%onx;
        indices[i*2]=  (((ibt*istr+sv*y)*snx+su*x)<<2);
        //indices[i*2]=  (((ibt*istr+sv*y)*snx+su*x)<<2);
        indices[i*2+1]=(ibt*ostr+pix)<<2;
//DEBUG_PRINT("fconv_generate_auxbuf1 %d %u  %u \n",i,ibt,indices[i*2]);
//DEBUG_PRINT("fconv_generate_auxbuf2 %d %u  %u \n",i,ibt,indices[i*2+1]);
    }
}

void fconv_generate_span( unsigned int* p_span, const group_prop_t* p_prop, const unsigned int* strides, unsigned int izero )
{
    unsigned int dnx, dny, dnz, fnx, fny, fnz, inc, du, dv, dd, x, y, z, c, i, n;
    dnx=p_prop->pnx;
    dny=p_prop->pny;
    dnz=p_prop->pnz;
    fnx=p_prop->fnx;
    fny=p_prop->fny;
    fnz=p_prop->fnz;
    inc=p_prop->pnc;
    du=dv=dd=1;


    if(strides!=0){
//        du=strides[0];
//        dv=strides[1];
//        if(fnz>1){ dd=strides[2]; }
    }

     for( c=0; c<inc; ++c ){ 
        for( z=0; z<fnz; ++z ){
            for( y=0; y<fny; ++y ){
                for( x=0; x<fnx; ++x ){

                    *p_span=(((c*dny+y*dv)*dnx)+x*du)<<2;
                    ++p_span;

                }
            }
        }
    }



//    n=fnx*fny*fnz*inc;
//    if((n&7)!=0){
//        const unsigned int pn=PSIZE(n,8);
//        for( i=n; i<pn; ++i ){ *p_span=izero; ++p_span; }
//    }
//    for( i=0; i<32; ++i ){ *p_span=0; ++p_span; }
}


void Parse(int argc, char* argv[],unsigned int* n, unsigned int* c,unsigned int* k,unsigned int* h,unsigned int* w
,unsigned int* r,unsigned int* s,unsigned int* strideH,unsigned int* strideW)
{
    std::vector<std::string> args;
    for(int i = 1; i < argc; i++) {
        
        args.push_back(argv[i]);
    }

    for(int i = 0; i < args.size(); i++)
    {
        std::string temp = args[i];
        if(temp[0] != '-')
        {
            printf("Illegal input flag\n");
        } else {
            if(i + 1 >= args.size()) {
                printf("parameter not enough\n");
            } else {

                char short_name = temp[1];
                std::string para_value = args[i + 1];
                if (short_name == 'n') {
                    int value = atoi(para_value.c_str());
                    *n= value;
                } else if (short_name == 'c') {
                    int value = atoi(para_value.c_str());
                    *c= value;
                }
                else if (short_name == 'k') {
                    int value = atoi(para_value.c_str());
                    *k= value;
                }

                else if (short_name == 'h') {
                    int value = atoi(para_value.c_str());
                    *h= value;
                }

                else if (short_name == 'w') {
                    int value = atoi(para_value.c_str());
                    *w= value;
                }


                else if (short_name == 'r') {
                    int value = atoi(para_value.c_str());
                    *r= value;
                }


                else if (short_name == 's') {
                    int value = atoi(para_value.c_str());
                    *s= value;
                }



                else if (short_name == 'x') {
                    int value = atoi(para_value.c_str());
                    *strideW= value;
                }

                else if (short_name == 'y') {
                    int value = atoi(para_value.c_str());
                    *strideH= value;
                }
                //printf("para %c\n",short_name);
                i++;
            }
        }
    }
}




//#define test_open 1
//#define kernel_test_open 1
int main(int argc, char* argv[]) {

//dilation kernel =r*(k-1)+1
unsigned int nn=128;
unsigned int kk=384;
unsigned int cc=384;
unsigned int hh=64;
unsigned int ww=66;
unsigned int rr=1;
unsigned int ss=3;
unsigned int yy=1;
unsigned int xx=1;

#if defined (test_open) 
for (int nn=8192;nn>=1;nn-=2500)
{
for (int cc=4096;cc>=16;cc-=16)
{
for (int kk=4096;kk>=8;kk-=8)
{
for (int ww=100;ww>=3;ww-=15)
{

unsigned int rr=7;
unsigned int ss=1;
unsigned int yy=1;
unsigned int xx=1;
unsigned int hh=ww+6;

if (((unsigned long long)nn*(unsigned long long)cc*(unsigned long long)hh*(unsigned long long)ww)>= (unsigned long long)(1<<28))
    continue;
if (((unsigned long long)kk*(unsigned long long)cc*(unsigned long long)rr*(unsigned long long)ss)>= (unsigned long long)(1<<28))
    continue;
if (((unsigned long long)kk*(unsigned long long)nn*(unsigned long long)hh*(unsigned long long)ww)>= (unsigned long long)(1<<28))
    continue;
#else


    Parse(argc,  argv,&nn,&cc,&kk,&hh,&ww,&rr,&ss,&yy,&xx);
    HIP_ASSERT(hipSetDevice(0));

#endif
    int N=nn; int C=cc;int H=hh;int W=ww;//in
    int K=kk;///out,carefully,you need to place correct size when stride and dilation
    int padh=0; int padw=0;//S for padw
    int R =rr;int S=ss;//wei
    int strideH = yy; int strideW =xx;
    int dilation_h =1;int dilation_w =1;
    int group_count =1;
    int outH=(2*padh+H-R)/strideH+1;
    int outW=(2*padw+W-S)/strideW+1;

    printf("N is %d C is %d K is %d H is %d W is %d R is %d S is %d strideH is %d strideW is %d outH is %d outW is %d\n",
    N,C, K ,H,W,R,S,strideH,strideW,outH,outW);


    //DEBUG_PRINT("outH is %d outW is %d \n",outH,outW);
    int CRS_64 = (C * R * S+63)/64;
    int CRS_32 = (C * R * S+31)/32;
    int K_64 =  (K+63)/64;
    int K_8 = (K+7)/8;


//                19  
//N*outW*outH <= 2     FOR precision
    if (((N*outH*outW)%64!=0) || ((C*R*S)%32!=0)  || (K%8!=0) || (group_count!=1))//k,crs is block of 4 ,if out of bound ,drop all block
    //NOO need 16 to split ,but after split,should factor of 4
    {
        printf("please follow rules,can not use\n");
#if defined (test_open)
        continue;
#else
        return 0;
#endif
    }    

float Data_scale = static_cast<float>(0.01);

    int Global_Size = ((K+127)/128)* ((C * R * S+127)/128);
//    DEBUG_PRINT("Global_Size is %d\n",Global_Size);

    int inSize = N*C*H*W* sizeof(float);
    int outSize = N*K*outH*outW* sizeof(float);
    int weiGroupSize = 16*K*C*R*S* sizeof(float);
    int wei_cpu_size = K*C*R*S* sizeof(float);

    float *in = (float *)malloc(inSize);
    float *out = (float *)malloc(outSize);
    float *wei = (float *)malloc(wei_cpu_size);
    float *dwei_gpu = (float *)malloc(weiGroupSize);

#if defined (kernel_test_open)
    float *host_test = (float *)malloc(256*sizeof(float));
    unsigned int *second_test =(unsigned int*)malloc(256*Global_Size*sizeof(unsigned int));
#endif

    for (int i=0;i<inSize/sizeof(float);i++) {
         float r = (float)(static_cast <float> (rand()) / static_cast <float> (RAND_MAX));

         int j = (int)(r*10);
         if (j<1) j=(int)(i%10);
         in[i] = static_cast <float>(Data_scale * RAN_GEN<float>(static_cast<float>(0.0), static_cast<float>(1.0)));
         //in[i] = miopen_scale*r;
//         DEBUG_PRINT("input %d is %f \n",i,in[i]);
    }

    for (int i=0;i<outSize/sizeof(float);i++) {
         float r = (float)(static_cast <float> (rand()) / static_cast <float> (RAND_MAX));
         int j = (int)(r*10);
         if (j<1) j=(int)(i%10);
         //out[i] = miopen_scale*r;
         out[i] =  static_cast <float>(Data_scale * RAN_GEN<float>(static_cast<float>(0.0), static_cast<float>(1.0)));
//         DEBUG_PRINT("output %d is %f \n",i,out[i]);
    }

    for (int i=0;i<wei_cpu_size/sizeof(float);i++) {
         wei[i] =static_cast<float>(0);
         
    }



    for (int i=0;i<weiGroupSize/sizeof(float);i++) {
         dwei_gpu[i] = static_cast<float>(0);
    }



struct timespec tstart={0,0}, tend={0,0}; 
clock_gettime(CLOCK_MONOTONIC, &tstart);

//mkldnn_conv_bwd_f_nchw (in, wei, out, N,C, H, W, K,R ,S, 0, 0, strideH, strideW, 1, 1);

    clock_gettime(CLOCK_MONOTONIC, &tend);
    DEBUG_PRINT("mkl computation took about %.5f seconds\n",
           ((double)tend.tv_sec + 1.0e-9*tend.tv_nsec) - 
           ((double)tstart.tv_sec + 1.0e-9*tstart.tv_nsec));


    cpu_backward_weights(in,out,wei
        ,N,C,H,W,
        K,R,S,
        outH,outW,strideH,strideW,
        dilation_h,dilation_w);



    


group_prop_t *gprop = new group_prop_t();
gprop->pnx=W;
gprop->pny=H;
gprop->pnz=1;
gprop->qnx=outW;
gprop->qny=outH;
gprop->qnz=1;

gprop->fnx=S;
gprop->fny=R;
gprop->fnz=1;
gprop->pnc=C;
gprop->qnc=K;
gprop->bat=N;


unsigned int* strides = (unsigned int*)malloc(3*sizeof(unsigned int));
strides[0]=strideW;
strides[1]=strideH;
strides[2]=1;

unsigned int* dilations = (unsigned int*)malloc(3*sizeof(unsigned int));
dilations = NULL;

unsigned char*       temp;
temp=(unsigned char *)malloc(1u<<28);


int NOO_64 = ((N*outH*outW+63)/64);
int NOO_256 = ((N*outH*outW+255)/256);
int CRS_8 =(C*R*S+7)/8;
int ntidx = NOO_256*256;//you need to read next 16 NOO,and you have 16 split ,it's 16*16=256
int nb_amap = ntidx*4;
int nb_span = (CRS_8*8+32)*4;
fconv_generate_auxbuf(  (unsigned int*)(&temp[0]), gprop, strides, ntidx  );
//*4 is address *2 is 2 auxbuf
fconv_generate_span( (unsigned int*)&temp[nb_amap*2], gprop, strides, 0 );
    
unsigned int* temp2 =(unsigned int*)temp;
for (int i =0;i<N*outH*outW*2;i++)
{
    DEBUG_PRINT(" aux %d %u\n",i,temp2[i]);
}

//unsigned int* temp3 =(unsigned int*)(temp2[ntidx*2]);
for (int i =0;i<C*R*S;i++)
{
    DEBUG_PRINT(" crs %d %u\n",i,temp2[ntidx*2+i]);
}

    unsigned int* d_auxbuf;
    hipMalloc( (void**)&d_auxbuf, 1<<28 );
    hipMemcpyHtoD( d_auxbuf, temp, (nb_amap*2)+nb_span );




    int BLOCKS_PER_K = (K+127)/128;
    int block_size = ((Global_Size+BLOCKS_PER_K-1)/BLOCKS_PER_K);

    hipInit(0);
    hipDevice_t device;
    hipCtx_t context;
    hipDeviceGet(&device, 0);
    hipCtxCreate(&context, 0, device);
    hipModule_t Module;
    hipModule_t Module_add;
    hipFunction_t Function;
    hipFunction_t Function_add; 




#if defined (kernel_test_open)
    
    float* device_test;
    unsigned int *device_second_test;


    HIP_ASSERT(hipMalloc(&device_test, 256*sizeof(float)));
    HIP_ASSERT(hipMalloc(&device_second_test, 256*Global_Size*sizeof(unsigned int)));
    
#endif

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



    hipModuleLoad(&Module, "for.co");
    hipModuleLoad(&Module_add, "add.co");
    hipModuleGetFunction(&Function, Module, "back_weights");

    hipModuleGetFunction(&Function_add, Module_add, "split_add");



    struct {
       void *auxbuf;//0x00
       void *span;//0x08
       unsigned int CRS_group;//0x10
       unsigned int K;//0x14
       unsigned int CRS;//0x18
       unsigned int sgs;//0x1c
       void* matrixA;//0x20
       void* matrixB;//0x28
       void* matrixC;//0X30
       float alpha ;//0x38

       unsigned int NOO;//0x3c
       unsigned int OO;//0x40
       unsigned int NCHW_1;//0x44
#if defined (kernel_test_open)
       void* test;//0x48
       void* second_test;//0x50
#endif
    } args;



    args.auxbuf= (void*)((unsigned char*)d_auxbuf);
    args.span =  (void*)(((unsigned char*)d_auxbuf)+(nb_amap*2));

    args.CRS_group = C*R*S;
    args.K = K;
    args.CRS = C*R*S;
    args.sgs = W*H*C;

    args.matrixA = (void*)devicein;

    args.matrixB = (void*)deviceout;

    args.matrixC = (void*)devicedwei;

    args.alpha=1.0f;

    args.NOO=N*outW*outH;

    args.OO=outW*outH;
    args.NCHW_1 = (N*W*H*C)*4;
#if defined (kernel_test_open)
    args.test = (void*)device_test;
    args.second_test= (void*)device_second_test;
#endif



    size_t size = sizeof(args);

    void *config[] = {
        HIP_LAUNCH_PARAM_BUFFER_POINTER, &args,
        HIP_LAUNCH_PARAM_BUFFER_SIZE, &size,
        HIP_LAUNCH_PARAM_END
    };
    DEBUG_PRINT("  kernel global size is %d\n",Global_Size);


//for test performance
//hipModuleLaunchKernel(Function,Global_Size,1,1,Threads_Size,1,1,0,0,NULL,(void**)&config);
    float eventMs = 0.0f;
    hipEvent_t start, stop;
    hipEventCreate(&start);
    hipEventCreate(&stop);
    hipEventRecord(start, NULL);


    hipModuleLaunchKernel(Function,K_64,CRS_64,16,Threads_Size,1,1,0,0,NULL,(void**)&config);






    hipEventRecord(stop, NULL);
    hipEventSynchronize(stop);
    hipEventElapsedTime(&eventMs, start, stop);
    printf("kernel profiler computation time taken  = %6.3fms\n", eventMs);

#if defined (kernel_test_open)
    CHECK(hipMemcpy(host_test,device_test, 256*sizeof(float), hipMemcpyDeviceToHost));
    CHECK(hipMemcpy(second_test,device_second_test, 256*Global_Size*sizeof(unsigned int), hipMemcpyDeviceToHost));
#endif
    CHECK(hipMemcpy(dwei_gpu,devicedwei, weiGroupSize, hipMemcpyDeviceToHost));

    //for debug
#if defined (kernel_test_open)
    for (int i=0;i<256;i++)
    {
        DEBUG_PRINT("==========test %d  %f ======\n",i,host_test[i]);
    }
    for (int i=0;i<2*256*Global_Size;i++)
    {
        DEBUG_PRINT("==========test second %d %u ======\n",i,second_test[i]);
    }
    for (int i =0;i<weiGroupSize/sizeof(float);i++)
    {
      DEBUG_PRINT("dwei %d is %f\n",i,dwei_gpu[i]);
    }
#endif

    //compare
//    compare(wei,dwei_gpu,K, C, R, S,N*outH*outW,1);

//    std::cout<<std::endl;



//------------------add---------------------------

#if defined (kernel_test_open)
    float *host_test_add = (float *)malloc(256*sizeof(float));
    unsigned int *second_test_add =(unsigned int*)malloc(256*sizeof(unsigned int));

    float* device_test_add;
    unsigned int *device_second_test_add;


    HIP_ASSERT(hipMalloc(&device_test_add, 256*sizeof(float)));
    HIP_ASSERT(hipMalloc(&device_second_test_add, 256*sizeof(unsigned int)));
#endif


    struct {
       void* matrixC;//0x00 
       void* final_matrixC;//0x08
       unsigned int KCRS;//0x10
       unsigned int CRS;//0x14
#if defined (kernel_test_open)
       void* test;//0x18
       void* second_test;//0x20
#endif
      
    } args_add;


    int kcrs_16_size = 16*K*C*R*S* sizeof(float); 
    int kcrs_size = K*C*R*S* sizeof(float);
    float* host_final_KCRS = (float*)malloc(kcrs_size);

    float* device_final_KCRS;
    HIP_ASSERT(hipMalloc((void**)&device_final_KCRS, kcrs_size));
    hipMemcpyHtoD( device_final_KCRS, host_final_KCRS, kcrs_size );


    args_add.matrixC = (void*)devicedwei;
    args_add.final_matrixC = (void*)device_final_KCRS;
    args_add.KCRS = K*C*R*S;
    args_add.CRS = C*R*S;
#if defined (kernel_test_open)
    args_add.test = (void*)device_test_add;
    args_add.second_test= (void*)device_second_test_add;
#endif



    int Threads_Size_add = 64;

    size_t size_add = sizeof(args_add);

    void *config_add[] = {
        HIP_LAUNCH_PARAM_BUFFER_POINTER, &args_add,
        HIP_LAUNCH_PARAM_BUFFER_SIZE, &size_add,
        HIP_LAUNCH_PARAM_END
    };


    float eventMs_add = 0.0f;
    hipEvent_t start_add, stop_add;
    hipEventCreate(&start_add);
    hipEventCreate(&stop_add);
    hipEventRecord(start_add, NULL);



    hipModuleLaunchKernel(Function_add,K_8,CRS_32,1,Threads_Size_add,1,1,0,0,NULL,(void**)&config_add);

    hipEventRecord(stop_add, NULL);
    hipEventSynchronize(stop_add);
    hipEventElapsedTime(&eventMs_add, start_add, stop_add);
    printf("ADD kernel profiler computation time taken  = %6.3fms\n", eventMs_add);


    CHECK(hipMemcpy(host_final_KCRS,device_final_KCRS, kcrs_size, hipMemcpyDeviceToHost));
    
    for (int i =0 ;i<64;i++)
    {
        DEBUG_PRINT("==========after add %d  %f ======\n",i,host_final_KCRS[i]);
    }

#if defined (kernel_test_open)
    CHECK(hipMemcpy(host_test_add,device_test_add, 64*sizeof(float), hipMemcpyDeviceToHost));
    CHECK(hipMemcpy(second_test_add,device_second_test_add, 64*sizeof(unsigned int), hipMemcpyDeviceToHost));
  


    for debug
    for (int i=0;i<64;i++)
    {
        DEBUG_PRINT("==========add test %d  %f ======\n",i,host_test_add[i]);
    }
    for (int i=0;i<64;i++)
    {
        DEBUG_PRINT("==========add test second %d %u ======\n",i,second_test_add[i]);
    }


#endif

    compare(wei,host_final_KCRS,K, C, R, S,N*outH*outW,0);

//    std::cout<<std::endl;



#if defined (kernel_test_open)
    HIP_ASSERT(hipFree(device_test_add));
    HIP_ASSERT(hipFree(device_second_test_add));
#endif
    HIP_ASSERT(hipFree(device_final_KCRS));    


    HIP_ASSERT(hipFree(d_auxbuf));

    HIP_ASSERT(hipFree(deviceout));
    HIP_ASSERT(hipFree(devicein));
    HIP_ASSERT(hipFree(devicedwei));

#if defined (kernel_test_open)
    HIP_ASSERT(hipFree(device_test));
    HIP_ASSERT(hipFree(device_second_test));


    free(host_test_add);
    free(second_test_add);
#endif

    free(host_final_KCRS);

    free(temp);

    free(in);
    free(out);
    free(wei);
    free(dwei_gpu);

#if defined (kernel_test_open)
    free(host_test);
    free(second_test);
#endif




#if defined (test_open)
}
}
}
}
#endif











    return 0;
}
