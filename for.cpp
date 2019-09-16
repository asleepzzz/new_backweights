#include <iostream>
#include <stdio.h>
#include <vector>
#include <hip/hip_runtime.h>
#include <hip/hip_runtime_api.h>


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


void compare(float* cpu,float* hip,int weiN,int weiC,int weiH,int  weiW,int combine)
{
    //for (int g=0;g<group_count;g++)
    //{
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

                        if (cpu[index]!=tmp)
                        {
                            DEBUG_PRINT("not queal %f %f kcrs  %d %d %d %d\n",cpu[index],tmp,i,j,k,l);
                        } else {
                            DEBUG_PRINT("the same %f %f kcrs  %d %d %d %d\n",cpu[index],tmp,i,j,k,l);
                        }
                    }
                }
            }
        }
    //}
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

    for(int n = 0; n < N; n++)
    {
        for(int k = 0; k < K; k++)
        {
            for(int c = 0; c < C; c++)
            {
                for(int y = 0; y < R; y++)
                {
                    for(int x = 0; x < S; x++)
                    {
                        for(int h = 0; h < outH; h++)
                        {
                           for(int w = 0; w < outW; w++)
                           {
                                int in_h = h*dilation_h  + y*strideH ;
                                int in_w = w*dilation_w  + x*strideW ;
                                if((in_h >= 0) && (in_h < H) && (in_w >= 0) && (in_w < W))
                                {
                                    weight[k*C*R*S + c*R*S+ y * S + x] +=
                                    in[n *C*H*W+  c*H*W+in_h *W + in_w]*
                                    out[n*K*outH*outW +k*outH*outW+h*outW+w];
                                }
                           }
                        }
                    }
                }
            }
        }
    }
    clock_gettime(CLOCK_MONOTONIC, &tend);
    DEBUG_PRINT("cpu computation took about %.5f seconds\n",
           ((double)tend.tv_sec + 1.0e-9*tend.tv_nsec) - 
           ((double)tstart.tv_sec + 1.0e-9*tstart.tv_nsec));


}



void cpu_backward_weights_group(float *in,float* out,float* weight
                          ,int N,int C,int H,int W,
                          int K,int R,int S,
                          int outH,int outW,
                          int strideH, int strideW,
                          int dilation_h,int dilation_w,int group_count)
{

    struct timespec tstart={0,0}, tend={0,0};

    clock_gettime(CLOCK_MONOTONIC, &tstart);
int cnt=0;
    for(int o = 0; o < N; o++)
    {
        for(int g = 0; g < group_count; g++)
        {
            for(int w = 0; w < K/ group_count; w++)
            {//name is w ,but it's k
                for(int k = 0; k < C/ group_count; k++)
                {//name is k ,but it's c
                    for(int x = 0; x < R; x++)
                    {//name is x ,but it's y
                        for(int y = 0; y < S; y++)
                        {//name is y ,but it's x
                            for(int i = 0; i < outH; i++)
                            {
                                for(int j = 0; j < outW; j++)
                                {

                                    
                                    int in_i = i*dilation_h  + x*strideH ;
                                    int in_j = j*dilation_w  + y*strideW ;
                                   printf("in_i %d in_j %d H %d, W %d x %d ,strideH %d  R %d \n",in_i,in_j,H,W,x,strideH,R); 
                                    if((in_i >= 0) && (in_i < H) && (in_j >= 0) &&
                                        (in_j < W))
                                    {


                                       //printf("kevin %d %d %d  %f add %f mul %f in %d out %d\n",cnt,x,y,weight[(k*R*S)+ (x * S) + y],in[o *C*H*W+in_i *W + in_j],out[(o*K*outH*outW) +(i*outW)+j]
                                        //,o *C*H*W+in_i *W + in_j,(o*K*outH*outW) +(i*outW)+j);
/*
if (g==0&& x==0&&y==0&&w==0) {
                                         printf("kevin %d   %f add %f mul %f in %d out %d\n",cnt,
                                         weight[((g * (K / group_count)+w)*((C*R*S)/group_count)) + (k*R*S)+ (x * S) + y],
                                         in[o *C*H*W+ ((g * (C / group_count)+k)*H*W)+in_i *W + in_j],
                                         out[(o*K*outH*outW) +((g * (K / group_count)+w)*outH*outW)+(i*outW)+j],
                                         o *C*H*W+ ((g * (C / group_count)+k)*H*W)+in_i *W + in_j,
                                         (o*K*outH*outW) +((g * (K / group_count)+w)*outH*outW)+(i*outW)+j);
}
*/



                                      weight[((g * (K / group_count)+w)*((C*R*S)/group_count)) + (k*R*S)+ (x * S) + y]
                                        += in[o *C*H*W+ ((g * (C / group_count)+k)*H*W)+in_i *W + in_j]
*out[(o*K*outH*outW) +((g * (K / group_count)+w)*outH*outW)+(i*outW)+j];







                                        //weight[C*R*S+(k*R*S)+ (x * S) + y]
                                        //+= in[o *C*H*W+in_i *W + in_j]
                                        //*out[(o*K*outH*outW)+outH*outW +(i*outW)+j];

//ckrs
//if (k==0 && w==0&&x==0&&y==0)
//{
//    printf("every time after add %f %f %f\n",weight[((g * (K / group_count)+w)*((C*R*S)/group_count)) + (k*R*S)+ (x * S) + y],
//in[o *C*H*W+ ((g * (C / group_count)+k)*H*W)+in_i *W + in_j],out[(o*K*outH*outW) +((g * (K / group_count)+w)*outH*outW)+(i*outW)+j]);
//}
 
cnt++;
                                    

                                        }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    clock_gettime(CLOCK_MONOTONIC, &tend);
    printf("cpu computation took about %.5f seconds\n",
           ((double)tend.tv_sec + 1.0e-9*tend.tv_nsec) - 
           ((double)tstart.tv_sec + 1.0e-9*tstart.tv_nsec));

}

void calculateUniIndex(int* unifiedIndex ,int N,int OutH,int OutW,int C,int H,int W ,int K,int strideH,int strideW,int dilationH,int dilationW,int group_count)
{//index*2 for matrix A & B,size is N*Oh*Ow*2
///Index[group][2][N*Oh*Ow]

    int matrixK = N*OutH*OutW;
    for (int g=0;g<group_count;g++) {
        for (int matrix_kk_index =0;matrix_kk_index< matrixK;matrix_kk_index++) {
            int n = matrix_kk_index /(OutH*OutW);
            int h = matrix_kk_index%(OutH*OutW)/OutW;
            int w = matrix_kk_index%(OutH*OutW)%OutW;

            int num = (C/group_count)*H*W;
            unifiedIndex[matrix_kk_index+g*2*matrixK]=  n*C*H*W+h*dilationH*W+dilationW*w;//for MatrixA
            unifiedIndex[matrix_kk_index+g*2*matrixK]+= g*num;//when you split your data,you need this offset to get real position for group conv

            num = (K/group_count)*OutH*OutW;   
            unifiedIndex[matrixK+matrix_kk_index+g*2*matrixK]= n*K*OutH*OutW+h*OutW+w;//+128*OutH*OutW;//for MatrixB
            unifiedIndex[matrixK+matrix_kk_index+g*2*matrixK] += g*num;//when you split your data,you need this offset to get real position for group conv
        }
    }
}

void calculateMNOffsetIndex(int* mnOffset,int BLOCKS_PER_K, int Global_Size)
{
    int nStart = Global_Size;
    for (int i = 0 ;i< Global_Size;i++)
    {
        unsigned tmp = (unsigned int)i;
        unsigned tmp2 = (unsigned int)BLOCKS_PER_K;
        unsigned tmp3 = (unsigned int)Global_Size;

        mnOffset[i]=((i/BLOCKS_PER_K) * 128);//moffset

        mnOffset[nStart+i] = ((i%BLOCKS_PER_K) * 128);//noffset 
    }

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
DEBUG_PRINT("nvalid %u \n",nvalid);
    unsigned int istr  = inc*sny ; //inc*sny
    unsigned int ostr  = onc*onx*ony*onz ; //onc*npx

    for(int i=0; i<ntidx; ++i ){
        isafe=i<nvalid?i:0;
        unsigned int ibt=isafe/npix;//small n
        pix=isafe%npix;
        unsigned int y=pix/onx;
        unsigned int x=pix%onx;
        ///back weights need to add su sv to crs
        indices[i*2]=  (((ibt*istr+y)*snx+x)<<2);
        //indices[i*2]=  (((ibt*istr+sv*y)*snx+su*x)<<2);
        indices[i*2+1]=(ibt*ostr+pix)<<2;
DEBUG_PRINT("fconv_generate_auxbuf1 %d %u  %u \n",i,ibt,indices[i*2]);
DEBUG_PRINT("fconv_generate_auxbuf2 %d %u  %u \n",i,ibt,indices[i*2+1]);
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
        du=strides[0];
        dv=strides[1];
        if(fnz>1){ dd=strides[2]; }
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

    Parse(argc,  argv,&nn,&cc,&kk,&hh,&ww,&rr,&ss,&yy,&xx);
    HIP_ASSERT(hipSetDevice(0));


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


    if (((N*outH*outW)%64!=0) || ((C*R*S)%4!=0)  || (K%64!=0) || (group_count!=1))//k,crs is block of 4 ,if out of bound ,drop all block
    //NOO need 16 to split ,but after split,should factor of 4
    {
        printf("please follow rules,can not use\n");
        return 0;
    }    


    int Global_Size = ((K+127)/128)* ((C * R * S+127)/128);
    DEBUG_PRINT("Global_Size is %d\n",Global_Size);

    int inSize = N*C*H*W* sizeof(float);
    int outSize = N*K*outH*outW* sizeof(float);
    int weiGroupSize = 16*K*C*R*S* sizeof(float);

    float *in = (float *)malloc(inSize);
    float *out = (float *)malloc(outSize);
    float *wei = (float *)malloc(weiGroupSize);
    float *dwei_gpu = (float *)malloc(weiGroupSize);

    float *host_test = (float *)malloc(256*sizeof(float));
    unsigned int *second_test =(unsigned int*)malloc(256*Global_Size*sizeof(unsigned int));

    for (int i=0;i<inSize/sizeof(float);i++) {
         float r = (float)(static_cast <float> (rand()) / static_cast <float> (RAND_MAX));

         int j = (int)(r*10);
         if (j<1) j=(int)(i%10);
         in[i] = 1.0f*j;//r;
         DEBUG_PRINT("input %d is %f \n",i,in[i]);
    }

    for (int i=0;i<outSize/sizeof(float);i++) {
         float r = (float)(static_cast <float> (rand()) / static_cast <float> (RAND_MAX));
         int j = (int)(r*10);
         if (j<1) j=(int)(i%10);
         out[i] = 1.0f*j;//r;
         DEBUG_PRINT("output %d is %f \n",i,out[i]);
    }

    for (int i=0;i<weiGroupSize/sizeof(float);i++) {
         wei[i] =0.0;
         dwei_gpu[i] = 0.0;
    }


//    cpu_backward_weights(in,out,wei
//        ,N,C,H,W,
//        K,R,S,
//        outH,outW,strideH,strideW,
//        dilation_h,dilation_w);



    
//    cpu_backward_weights_group(in,out,wei
//        ,N,C,H,W,
//        K,R,S,
//        outH,outW,strideH,strideW,
//        dilation_h,dilation_w,group_count);

//for (int i =0;i<weiGroupSize/sizeof(float);i++)
//{
//      printf("cpu %d: %f\n ",i,wei[i]);
//}

//    printf("cpu %d: %f\n ",1,wei[1]);



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
    DEBUG_PRINT("kevin aux %d %u\n",i,temp2[i]);
}

//unsigned int* temp3 =(unsigned int*)(temp2[ntidx*2]);
for (int i =0;i<C*R*S;i++)
{
    DEBUG_PRINT("kevin crs %d %u\n",i,temp2[ntidx*2+i]);
}

    unsigned int* d_auxbuf;
    hipMalloc( (void**)&d_auxbuf, 1<<28 );
    hipMemcpyHtoD( d_auxbuf, temp, (nb_amap*2)+nb_span );




    int uniIndexSize = 2*N*outH*outW*sizeof(int)*group_count;
    int* uniFiedIndex = (int*)malloc(uniIndexSize);
    calculateUniIndex(uniFiedIndex,N, outH, outW,C,H,W , K,strideH,strideW,dilation_h,dilation_w,group_count);
    //printf("kevin shit %d\n",uniFiedIndex[14399]);

    int BLOCKS_PER_K = (K+127)/128;
    int block_size = ((Global_Size+BLOCKS_PER_K-1)/BLOCKS_PER_K);

    int *mnOffset = (int*)malloc(2*Global_Size*sizeof(int));
    calculateMNOffsetIndex(mnOffset,BLOCKS_PER_K,Global_Size);
    //printf("kevin n 22 is %d \n",mnOffset[22+Global_Size]);

    int crsOffsetSize = block_size*128*sizeof(unsigned int);//thread
    unsigned int* inIndex = (unsigned int*)malloc(crsOffsetSize);
    calculateCRSOffsetIndex(inIndex ,block_size, N, outH, outW, C, H, W , K, R, S, strideH, strideW);
    //printf("kevin crs is %u %u %u %u\n",inIndex[128],inIndex[1],inIndex[2],inIndex[3]);

    int outOffsetSize = block_size*16*8*sizeof(int);
    int* outIndex = (int*)malloc(outOffsetSize);
    calculateOutIndex(outIndex ,block_size,BLOCKS_PER_K, K, C, R, S);
    //printf("out 1504 is %d\n",outIndex[1504]);

    hipInit(0);
    hipDevice_t device;
    hipCtx_t context;
    hipDeviceGet(&device, 0);
    hipCtxCreate(&context, 0, device);
    hipModule_t Module;
    hipModule_t Module_add;
    hipFunction_t Function;
    hipFunction_t Function_add; 





    
    int* device_uniIndex;
    unsigned int* device_inIndex;
    int* device_outIndex;
    int* device_mnOffset;
    float* device_test;
    unsigned int *device_second_test;


    HIP_ASSERT(hipMalloc(&device_mnOffset, 2*Global_Size*sizeof(int)));
    HIP_ASSERT(hipMalloc(&device_uniIndex, uniIndexSize));
    HIP_ASSERT(hipMalloc(&device_inIndex, crsOffsetSize));
    HIP_ASSERT(hipMalloc(&device_outIndex, outOffsetSize));
    HIP_ASSERT(hipMalloc(&device_test, 256*sizeof(float)));
    HIP_ASSERT(hipMalloc(&device_second_test, 256*Global_Size*sizeof(unsigned int)));
    

    HIP_ASSERT(hipMemcpy(device_mnOffset,mnOffset, 2*Global_Size*sizeof(int), hipMemcpyHostToDevice));
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

//    hipMemcpy(hResult,Rd, sizeof(float) * x, hipMemcpyDeviceToHost);




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
//       void *crsoffset;//0x44
//       unsigned int extra;
       void* test;//0x48
       void* second_test;//0x50
    } args;


/*
    struct {
        void *device_uniIndex;//0x00
        void *device_inIndex;//0x08
        void *device_outIndex;//0x10
        void *device_mnOffset;//0x18
        void* devicein;//0x20
        void* deviceout;//0x28
        void* devicedwei;//0x30
        void* device_test;//0x38
        void* device_second_test;//0x40

        int N;//0x48
        int CINGroup;//0x4c
        int H;//0x50
        int W;//0x54
        unsigned int KINGroup;//0x58
        int R;//0x5c
        int S;//0x60
        int outH;//0x64
        int outW;//0x68
        int strideH;//0x6c
        int strideW;//0x70
        int dilation_h;//0x74
        int dilation_w;//0x78
        int group_count;//0x7c
        int global_size;//0x80

    } args;

    
    args.device_uniIndex = device_uniIndex;
    args.device_inIndex = device_inIndex;
    args.device_outIndex = device_outIndex;
    args.device_mnOffset = device_mnOffset;
    args.devicein = devicein;
    args.deviceout = deviceout;
    args.devicedwei = devicedwei;
    args.device_test = device_test;
    args.device_second_test = device_second_test;

    args.N = N;
    args.CINGroup = (C/group_count);
    args.H = H;
    args.W = W;
    args.KINGroup = (K/group_count); 
    args.R = R;
    args.S = S;
    args.outH = outH;
    args.outW = outW;
    args.strideH = strideH;
    args.strideW = strideW;
    args.dilation_h = dilation_h;
    args.dilation_w = dilation_w;
    args.group_count = group_count;
    args.global_size = Global_Size;
*/


    args.auxbuf= (void*)((unsigned char*)d_auxbuf);//(void*)((unsigned char*)device_uniIndex);//    ( (unsigned char*)device_uniIndex);
    args.span =  (void*)(((unsigned char*)d_auxbuf)+(nb_amap*2));//(void*)((unsigned char*)device_inIndex);//(((unsigned char*)device_uniIndex)+4*ntidx);

    args.CRS_group = C*R*S;
    args.K = K;
    args.CRS = C*R*S;
    args.sgs = W*H*C;

    args.matrixA = (void*)devicein;

    args.matrixB = (void*)deviceout;

    args.matrixC = (void*)devicedwei;
    //args.onpx = onpx;

    args.alpha=1.0f;

    args.NOO=N*outW*outH;

    args.OO=outW*outH;
    args.NCHW_1 = (N*W*H*C)*4;
//    args.crsoffset = (void*)(((unsigned char*)d_auxbuf)+(nb_amap<<1)) ;//(((unsigned char*)device_uniIndex)+8*ntidx);
//    args.extra=2;
    args.test = (void*)device_test;
    args.second_test= (void*)device_second_test;




    size_t size = sizeof(args);

    void *config[] = {
        HIP_LAUNCH_PARAM_BUFFER_POINTER, &args,
        HIP_LAUNCH_PARAM_BUFFER_SIZE, &size,
        HIP_LAUNCH_PARAM_END
    };
    DEBUG_PRINT("kevin  kernel global size is %d\n",Global_Size);



//hipModuleLaunchKernel(Function,Global_Size,1,1,Threads_Size,1,1,0,0,NULL,(void**)&config);
    float eventMs = 0.0f;
    hipEvent_t start, stop;
    hipEventCreate(&start);
    hipEventCreate(&stop);
    hipEventRecord(start, NULL);


    hipModuleLaunchKernel(Function,K_64,CRS_64,16,Threads_Size,1,1,0,0,NULL,(void**)&config);





    //hipModuleLaunchKernel(Function,1,1,1,1,1,1,0,0,NULL,(void**)&config);

    //hipModuleLaunchKernel(Function,4,1,1,4,1,1,0,0,NULL,(void**)&config);
    //hipDeviceSynchronize();

    hipEventRecord(stop, NULL);
    hipEventSynchronize(stop);
    hipEventElapsedTime(&eventMs, start, stop);
    printf("kernel profiler computation time taken  = %6.3fms\n", eventMs);

    CHECK(hipMemcpy(host_test,device_test, 256*sizeof(float), hipMemcpyDeviceToHost));
    CHECK(hipMemcpy(second_test,device_second_test, 256*Global_Size*sizeof(unsigned int), hipMemcpyDeviceToHost));
    CHECK(hipMemcpy(dwei_gpu,devicedwei, weiGroupSize, hipMemcpyDeviceToHost));

    //for debug
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

    //compare
//    compare(wei,dwei_gpu,K, C, R, S,1);

//    std::cout<<std::endl;



//------------------add---------------------------


    float *host_test_add = (float *)malloc(256*sizeof(float));
    unsigned int *second_test_add =(unsigned int*)malloc(256*sizeof(unsigned int));

    float* device_test_add;
    unsigned int *device_second_test_add;


    HIP_ASSERT(hipMalloc(&device_test_add, 256*sizeof(float)));
    HIP_ASSERT(hipMalloc(&device_second_test_add, 256*sizeof(unsigned int)));
 


    struct {
       void* matrixC;//0x00 
       void* final_matrixC;//0x08
       unsigned int KCRS;//0x10
       unsigned int CRS;//0x14
       //unsigned int K;//0x20
       void* test;//0x18
       void* second_test;//0x20
      
    } args_add;


    int kcrs_16_size = 16*K*C*R*S* sizeof(float); 
    int kcrs_size = K*C*R*S* sizeof(float);
    //float* host_16_KCRS = (float*)malloc(kcrs_16_size);
    float* host_final_KCRS = (float*)malloc(kcrs_size);

    //for (int i=0;i< 16*K*C*R*S;i++)
    //{
    //    host_16_KCRS[i] = i*1.0f;
    //}

    //float* device_16_KCRS;
    float* device_final_KCRS;
    //HIP_ASSERT(hipMalloc((void**)&device_16_KCRS, kcrs_16_size));
    HIP_ASSERT(hipMalloc((void**)&device_final_KCRS, kcrs_size));
    //hipMemcpyHtoD( device_16_KCRS, host_16_KCRS, kcrs_16_size );
    hipMemcpyHtoD( device_final_KCRS, host_final_KCRS, kcrs_size );


    args_add.matrixC = (void*)devicedwei;//(void*)device_16_KCRS;
    args_add.final_matrixC = (void*)device_final_KCRS;
    args_add.KCRS = K*C*R*S;
    args_add.CRS = C*R*S;
    //args_add.K = K;
    args_add.test = (void*)device_test_add;
    args_add.second_test= (void*)device_second_test_add;




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


    CHECK(hipMemcpy(host_test_add,device_test_add, 64*sizeof(float), hipMemcpyDeviceToHost));
    CHECK(hipMemcpy(second_test_add,device_second_test_add, 64*sizeof(unsigned int), hipMemcpyDeviceToHost));
  


    //for debug
    //for (int i=0;i<64;i++)
    //{
    //    DEBUG_PRINT("==========add test %d  %f ======\n",i,host_test_add[i]);
    //}
    //for (int i=0;i<64;i++)
    ///{
    //    DEBUG_PRINT("==========add test second %d %u ======\n",i,second_test_add[i]);
    //}



//    compare(wei,host_final_KCRS,K, C, R, S,0);

//    std::cout<<std::endl;




//    HIP_ASSERT(hipFree(device_16_KCRS));
    HIP_ASSERT(hipFree(device_test_add));
    HIP_ASSERT(hipFree(device_second_test_add));
    HIP_ASSERT(hipFree(device_final_KCRS));    




    HIP_ASSERT(hipFree(device_uniIndex));
    HIP_ASSERT(hipFree(device_inIndex));
    HIP_ASSERT(hipFree(device_outIndex));
    HIP_ASSERT(hipFree(deviceout));
    HIP_ASSERT(hipFree(devicein));
    HIP_ASSERT(hipFree(devicedwei));
    HIP_ASSERT(hipFree(device_test));
    HIP_ASSERT(hipFree(device_second_test));


//    free(host_16_KCRS);
    free(host_test_add);
    free(second_test_add);
    free(host_final_KCRS);


    free(in);
    free(out);
    free(wei);
    free(dwei_gpu);
    free(uniFiedIndex);
    free(inIndex);
    free(mnOffset);
    free(outIndex);
    free(host_test);
    free(second_test);

















    return 0;
}
