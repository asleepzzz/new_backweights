#ifndef __MKLDNN_CONV_H
#define __MKLDNN_CONV_H

#include <mkldnn.hpp>
static int out_size(int in_size, int pad, int dilation, int ksize, int stride)
{
     return (in_size + 2*pad- dilation*(ksize-1) -1)/stride + 1;
}
void nchw_2_cnhw(float *dst, const float * src, int n, int c, int h, int w){
    int in,ic,i;
    int off_src, off_dst;
    int unroll_len = (h*w)/8;
    int unroll_rem = (h*w)%8;
    for(ic=0;ic<c;ic++){
        for(in=0;in<n;in++){
            off_src = in*c*h*w+ic*h*w;
            off_dst = ic*n*h*w+in*h*w;
            for(i=0;i<unroll_len;i++){
                dst[off_dst+0] = src[off_src+0];
                dst[off_dst+1] = src[off_src+1];
                dst[off_dst+2] = src[off_src+2];
                dst[off_dst+3] = src[off_src+3];
                dst[off_dst+4] = src[off_src+4];
                dst[off_dst+5] = src[off_src+5];
                dst[off_dst+6] = src[off_src+6];
                dst[off_dst+7] = src[off_src+7];
                off_src += 8;
                off_dst += 8;
            }
            for(i=0;i<unroll_rem;i++){
                dst[off_dst] = src[off_src];
                off_src++;
                off_dst++;
            }
        }
    }
}
void cnhw_2_nchw(float *dst, const float * src, int n, int c, int h, int w){
    int in,ic,i;
    int off_src, off_dst;
    int unroll_len = (h*w)/8;
    int unroll_rem = (h*w)%8;
    for(in=0;in<n;in++){
        for(ic=0;ic<c;ic++){
            off_src = ic*n*h*w+in*h*w;
            off_dst = in*c*h*w+ic*h*w;
            for(i=0;i<unroll_len;i++){
                dst[off_dst+0] = src[off_src+0];
                dst[off_dst+1] = src[off_src+1];
                dst[off_dst+2] = src[off_src+2];
                dst[off_dst+3] = src[off_src+3];
                dst[off_dst+4] = src[off_src+4];
                dst[off_dst+5] = src[off_src+5];
                dst[off_dst+6] = src[off_src+6];
                dst[off_dst+7] = src[off_src+7];
                off_src += 8;
                off_dst += 8;
            }
            for(i=0;i<unroll_rem;i++){
                dst[off_dst] = src[off_src];
                off_src++;
                off_dst++;
            }
        }
    }
}
typedef struct {
    mkldnn::engine * eng;
}md_handle;
typedef struct{
    int n; // batch
    int c;
    int h;
    int w;
    int k;
    int r; // filter_h
    int s; // filter_w
    int p; // pad h
    int q; // pad w
    int u; // stride h
    int v; // stride w
    int dh; // dilation h
    int dw; // dilation w

    int oh;
    int ow;

    mkldnn::memory::desc *src_desc;
    mkldnn::memory::desc *filter_desc;
    mkldnn::memory::desc *dst_desc;

    mkldnn::convolution_forward::desc           *fwd_desc;
    mkldnn::convolution_backward_data::desc     *bwd_d_desc;
    mkldnn::convolution_backward_weights::desc  *bwd_f_desc;

    //mkldnn::convolution_forward *fwd;
}md_conv_handle;

void md_init(md_handle * mh){
    mh->eng = new mkldnn::engine(mkldnn::engine::kind::cpu,0);
}
void md_destroy(md_handle * mh){
    delete mh->eng;
}

void md_conv_init(md_conv_handle *conv,int n, int c, int h, int w, int k, int r, int s, int p, int q, int u, int v, int dh, int dw){
    conv->n = n;
    conv->c = c;
    conv->h = h;
    conv->w = w;
    conv->k = k;
    conv->r = r;
    conv->s = s;
    conv->p = p;
    conv->q = q;
    conv->u = u;
    conv->v = v;
    conv->dh = dh;
    conv->dw = dw;
    conv->oh = out_size(h, p, dh, r, u);
    conv->ow = out_size(w, q, dw, s, v);

    conv->src_desc = new mkldnn::memory::desc({n,c,h,w}, mkldnn::memory::data_type::f32, mkldnn::memory::format::nchw);
    conv->filter_desc = new mkldnn::memory::desc({k,c,r,s}, mkldnn::memory::data_type::f32, mkldnn::memory::format::oihw);
    conv->dst_desc = new mkldnn::memory::desc({n,k,conv->oh,conv->ow}, mkldnn::memory::data_type::f32, mkldnn::memory::format::nchw);


    conv->fwd_desc = new mkldnn::convolution_forward::desc(mkldnn::prop_kind::forward_inference,
                        mkldnn::algorithm::convolution_direct,
                        *conv->src_desc,*conv->filter_desc,*conv->dst_desc,
                        {u,v},{dh-1,dw-1},{p,q},{p,q},mkldnn::padding_kind::zero);
    // note in mkl-dnn, dilation is 0 when unit dilation.
    conv->bwd_d_desc = new mkldnn::convolution_backward_data::desc(mkldnn::algorithm::convolution_direct,
                        *conv->src_desc,*conv->filter_desc,*conv->dst_desc,
                        {u,v},{dh-1,dw-1},{p,q},{p,q},mkldnn::padding_kind::zero);
    
    conv->bwd_f_desc = new mkldnn::convolution_backward_weights::desc(mkldnn::algorithm::convolution_direct,
                        *conv->src_desc,*conv->filter_desc,*conv->dst_desc,
                        {u,v},{dh-1,dw-1},{p,q},{p,q},mkldnn::padding_kind::zero);
}
void md_conv_destroy(md_conv_handle * conv){
    delete conv->src_desc;
    delete conv->filter_desc;
    delete conv->dst_desc;
    delete conv->fwd_desc;
    delete conv->bwd_d_desc;
    delete conv->bwd_f_desc;
}
void md_conv_fwd_nchw(md_handle *mh, md_conv_handle *conv, float * src, float * filter, float * dst){
    auto src_memory = mkldnn::memory( {*conv->src_desc,*mh->eng}, src  );
    auto filter_memory = mkldnn::memory({*conv->filter_desc, *mh->eng}, filter  );
    auto dst_memory = mkldnn::memory({*conv->dst_desc, *mh->eng}, dst);
    mkldnn::convolution_forward conv_fwd({*conv->fwd_desc,*mh->eng},src_memory,filter_memory,dst_memory  );
    mkldnn::stream(mkldnn::stream::kind::eager).submit({conv_fwd}).wait();
}

void md_conv_fwd_cnhw(md_handle *mh, md_conv_handle *conv, float * src, float * filter, float * dst){
    int n = conv->src_desc->data.dims[0];
    int c = conv->src_desc->data.dims[1];
    int h = conv->src_desc->data.dims[2];
    int w = conv->src_desc->data.dims[3];
    int k = conv->dst_desc->data.dims[1];
    int oh = conv->dst_desc->data.dims[2];
    int ow = conv->dst_desc->data.dims[3];
    float * src_nchw = new float[n*c*h*w];
    float * dst_nchw = new float[n*k*oh*ow];
    cnhw_2_nchw(src_nchw, src, n, c, h, w);
    auto src_memory = mkldnn::memory( {*conv->src_desc,*mh->eng}, src_nchw  );
    auto filter_memory = mkldnn::memory({*conv->filter_desc, *mh->eng}, filter  );
    auto dst_memory = mkldnn::memory({*conv->dst_desc, *mh->eng}, dst_nchw);
    mkldnn::convolution_forward conv_fwd({*conv->fwd_desc,*mh->eng},src_memory,filter_memory,dst_memory  );
    mkldnn::stream(mkldnn::stream::kind::eager).submit({conv_fwd}).wait();
    nchw_2_cnhw(dst, dst_nchw, n, k, oh, ow);
    delete [] src_nchw;
    delete [] dst_nchw;
}
void md_conv_bwd_d_nchw(md_handle *mh, md_conv_handle *conv, float * src_grad, float * filter, float * dst_grad){
    auto src_grad_memory = mkldnn::memory( {*conv->src_desc,*mh->eng}, src_grad  );
    auto filter_memory = mkldnn::memory({*conv->filter_desc, *mh->eng}, filter  );
    auto dst_grad_memory = mkldnn::memory({*conv->dst_desc, *mh->eng}, dst_grad);
    mkldnn::convolution_backward_data conv_bwd_d({*conv->bwd_d_desc,*mh->eng, {*conv->fwd_desc,*mh->eng}},dst_grad_memory,filter_memory,src_grad_memory );
    mkldnn::stream(mkldnn::stream::kind::eager).submit({conv_bwd_d}).wait();
}
void md_conv_bwd_d_cnhw(md_handle *mh, md_conv_handle *conv, float * src_grad, float * filter, float * dst_grad){
    int n = conv->src_desc->data.dims[0];
    int c = conv->src_desc->data.dims[1];
    int h = conv->src_desc->data.dims[2];
    int w = conv->src_desc->data.dims[3];
    int k = conv->dst_desc->data.dims[1];
    int oh = conv->dst_desc->data.dims[2];
    int ow = conv->dst_desc->data.dims[3];
    float * src_grad_nchw = new float[n*c*h*w];
    float * dst_grad_nchw = new float[n*k*oh*ow];
    cnhw_2_nchw(dst_grad_nchw, dst_grad, n, k, oh, ow);
    auto src_grad_memory = mkldnn::memory( {*conv->src_desc,*mh->eng}, src_grad_nchw  );
    auto filter_memory = mkldnn::memory({*conv->filter_desc, *mh->eng}, filter  );
    auto dst_grad_memory = mkldnn::memory({*conv->dst_desc, *mh->eng}, dst_grad_nchw);
    mkldnn::convolution_backward_data conv_bwd_d({*conv->bwd_d_desc,*mh->eng, {*conv->fwd_desc,*mh->eng}},dst_grad_memory,filter_memory,src_grad_memory );
    mkldnn::stream(mkldnn::stream::kind::eager).submit({conv_bwd_d}).wait();
    nchw_2_cnhw(src_grad, src_grad_nchw, n, c, h, w);
    delete [] src_grad_nchw;
    delete [] dst_grad_nchw;
}
void md_conv_bwd_f_nchw(md_handle *mh, md_conv_handle *conv, float * src, float * filter_grad, float * dst_grad){
    auto src_memory = mkldnn::memory( {*conv->src_desc,*mh->eng}, src  );
    auto filter_grad_memory = mkldnn::memory({*conv->filter_desc, *mh->eng}, filter_grad  );
    auto dst_grad_memory = mkldnn::memory({*conv->dst_desc, *mh->eng}, dst_grad);
    mkldnn::convolution_backward_weights conv_bwd_f({*conv->bwd_f_desc,*mh->eng, {*conv->fwd_desc,*mh->eng}},src_memory,dst_grad_memory,filter_grad_memory);
    mkldnn::stream(mkldnn::stream::kind::eager).submit({conv_bwd_f}).wait();
}
void md_conv_bwd_f_cnhw(md_handle *mh, md_conv_handle *conv, float * src, float * filter_grad, float * dst_grad){
    int n = conv->src_desc->data.dims[0];
    int c = conv->src_desc->data.dims[1];
    int h = conv->src_desc->data.dims[2];
    int w = conv->src_desc->data.dims[3];
    int k = conv->dst_desc->data.dims[1];
    int oh = conv->dst_desc->data.dims[2];
    int ow = conv->dst_desc->data.dims[3];
    float * src_nchw = new float[n*c*h*w];
    float * dst_grad_nchw = new float[n*k*oh*ow];
    cnhw_2_nchw(dst_grad_nchw, dst_grad, n, k, oh, ow);
    cnhw_2_nchw(src_nchw, src, n, c, h, w);
    auto src_memory = mkldnn::memory( {*conv->src_desc,*mh->eng}, src_nchw  );
    auto filter_grad_memory = mkldnn::memory({*conv->filter_desc, *mh->eng}, filter_grad  );
    auto dst_grad_memory = mkldnn::memory({*conv->dst_desc, *mh->eng}, dst_grad_nchw);
    mkldnn::convolution_backward_weights conv_bwd_f({*conv->bwd_f_desc,*mh->eng, {*conv->fwd_desc,*mh->eng}},src_memory,dst_grad_memory,filter_grad_memory);
    mkldnn::stream(mkldnn::stream::kind::eager).submit({conv_bwd_f}).wait();
    delete [] src_nchw;
    delete [] dst_grad_nchw;
}

#define MKLDNN_CONV_WARP(dir, layout)                                               \
    void mkldnn_conv_ ## dir ## _ ## layout (float *ts, float *tf, float *td,       \
    int n, int c, int h, int w, int k, int r, int s, int p, int q, int u, int v, int dh, int dw) \
    {                                                                               \
        md_handle md_h;                                                             \
        md_conv_handle md_conv_h;                                                   \
        md_init(&md_h);                                                             \
        md_conv_init(&md_conv_h,n,c,h,w,k,r,s,p,q,u,v,dh,dw);                       \
        md_conv_## dir ## _ ## layout (&md_h, &md_conv_h, ts, tf, td);              \
        md_conv_destroy(&md_conv_h);                                                \
        md_destroy(&md_h);                                                          \
    }

MKLDNN_CONV_WARP(fwd, nchw)
MKLDNN_CONV_WARP(fwd, cnhw)
MKLDNN_CONV_WARP(bwd_d, nchw)
MKLDNN_CONV_WARP(bwd_d, cnhw)
MKLDNN_CONV_WARP(bwd_f, nchw)
MKLDNN_CONV_WARP(bwd_f, cnhw)

#endif