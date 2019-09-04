        .hsa_code_object_version 2,1
        .hsa_code_object_isa 9,0,6,"AMD","AMDGPU"
        .p2align        8
        .type   back_weights,@function
        .amdgpu_hsa_kernel back_weights
back_weights:
.Lfunc_begin0:
        .amd_kernel_code_t
                enable_sgpr_kernarg_segment_ptr = 1;so,s1:kernel argi,vo:workitem
                float_mode = 192
                enable_ieee_mode = 1
                enable_trap_handler = 1
                is_ptr64 = 1
                user_sgpr_count = 2
                kernarg_segment_byte_size = 100
                kernel_code_entry_byte_offset = 256
                granulated_wavefront_sgpr_count = 11;(s+3)+8-1/8-1
                granulated_workitem_vgpr_count = 63;(v+4-1)/4-1
                wavefront_sgpr_count = 96;sgpr+3
                workitem_vgpr_count = 256
                workgroup_group_segment_byte_size = 32768;//LDS size
                enable_sgpr_workgroup_id_x = 1;s2
                enable_sgpr_workgroup_id_y = 1;s3
                enable_sgpr_workgroup_id_z = 1;s4
        .end_amd_kernel_code_t

;//NOO need %16=0 due to load B I LOAD 16 noo in once,if not %16=0,you need to add protection,max is NKOO-1
;    struct {
;       void *auxbuf;//0x00
;       void *span;//0x08
;       unsigned int CRS_group;//0x10
;       unsigned int K;//0x14
;       unsigned int CRS;//0x18
;       unsigned int sgs;//0x1c;//CHW
;       void* matrixA;//0x20
;       void* matrixB;//0x28
;       void* matrixC;//0X30
;       float alpha ;//0x38

;       unsigned int NOO;//0x3c
;       unsigned int OO;//0x40
;       unsigned int NCHW_1;//0X44
;//48 for float test 50 for int test
;    } args;

.set sgpr_K_64, 2
.set sgpr_CRS_64, 3
.set sgpr_splitK_idx,4
.set sgpr_NCHW_1_address,5
.set sgpr_NOO,6
.set sgpr_OO,7
;.set sgpr_CRS_1_address,6
;.set sgpr_NKOO_1_address,7
.set sgpr_matrixK_NOO_address ,8;/8 9
.set sgpr_span_address, 10;//10 11


.set sgpr_CRS_group,12
.set sgpr_K,13
.set sgpr_CRS,14
.set sgpr_CHW,15
.set sgpr_matrixAB_address ,16;//16 17 18 19
.set sgpr_matrixB_start_address ,18
.set sgpr_matrixC_start_address,20
.set sgpr_wave_NOO_offset,22

.set sgpr_NOO_16,23
.set sgpr_auxbuf_8, 24;//24 25 26 27 28 29 30 31
;.set sgpr_OO,23
.set sgpr_NOO_start_address_split,32

.set sgpr_CRS_1_address,33;//

.set sgpr_NKOO_1_address,34;//
.set sgpr_NOO_loop_idx_in_split,35;//start in loop every time+32
.set sgpr_buf_crs_address,36;//36 37 38 39
.set sgpr_buf_A_address,40;//40 41 42 43
.set sgpr_NOO_wave_idx_in_split,44;//each wave's start in loop idx+6 6....6 |14 14...14|22 22...22 |30 30..30

.set sgpr_NOO_wave_idx_offset,45;//it's num offset of last 6 6....6 |14 14...14|22 22...22 |30 30..30
.set sgpr_NOO_wave_start_idx_offset,46;//0 0...0|8 8 ...8|16 16..16|24 24...24
.set sgpr_NOO_wave_start_idx_in_split,47;//each wave's start in loop idx+ 0 0...0|8 8 ...8|16 16..16|24 24...24

.set sgpr_NOO_out_of_bound_tmp,48
.set sgpr_NOO_out_of_bound_wave_start_address_tmp,49
.set sgpr_NOO_out_of_bound_status,50;//0:ok 1:all 0 2:first ok 3: 1&2ok 4:1&2&3 ok
.set sgpr_NOO_real_idx,51;//not auxbuf, it's real idx


;.set sgpr_NOO,28
;.set sgpr_OO,29
;.set sgpr_NCHW_1_address,30

.set sgpr_cmp_tmp_address,52;//52 53
.set sgpr_before_cmp_address,54;//54 55
.set sgpr_buf_B_address,56;//56 57 58 59
.set sgpr_buf_crs_address,60;//60 61 62 63

.set sgpr_B_load_judge,64
.set sgpr_lds_NOO_offset,65
;//just use once
.set sgpr_tmp_final,66
.set sgpr_tmp2_final,67
;//use once end
.set sgpr_buf_C_address,68;//68 69 70 71
.set sgpr_crs_id,72
.set sgpr_KCRS_ok,73
;//sgpr

.set vgpr_CRS_value,1
.set vgpr_wave_tid,2
;//v3:global crs
.set vgpr_A_value_4,4;//4 5 6 7
.set vgpr_waveid,8
;//9 already use
.set vgpr_lds_offset,10;//wave tid*4+waveid*16*64
.set vgpr_kOO,11;//kOO or KOO-1
;//9 for some instru
.set vgpr_global_k,12
.set vgpr_block_thread_tile_x,13
.set vgpr_block_thread_tile_y,14
.set vgpr_lds_A_offset,15
.set vgpr_lds_B_offset,16
.set vgpr_final_offset,17
;//17 18 19


.set vgpr_thread_A_4,20;//20 21 22 23
.set vgpr_B_value_4,24;//24 25 26 27
.set vgpr_thread_B_4,28;//28 29 30 31
 
.set vgpr_FMA_value,32;//32-47
;.set vgpr_lds_B_offset,44

.set vgpr_reuse_tmp_write_dis,4


.set vgpr_crs_global_id,48

.set Srd127_96, 0x0020000
.set BufferLimit, 0x80000000;//2gb
.set smallLimit,16384;//64*CRS*4
;.set BufferOOB, 0x80000000;//
;.set vgpr_crsId ,3



;//hipModuleLaunchKernel(Function,K_64,CRS_64,16,Threads_Size,1,1,0,0,NULL,(void**)&config);


    s_load_dwordx4 s[sgpr_matrixK_NOO_address:sgpr_matrixK_NOO_address+3], s[0:1], 0x00;//auxbuf and span       
    s_load_dword s[sgpr_NCHW_1_address], s[0:1], 0x44
    s_load_dwordx2 s[sgpr_NOO:sgpr_OO],s[0:1],0x3c;//NOO& OO
    s_load_dwordx4 s[sgpr_CRS_group:sgpr_CHW], s[0:1], 0x10
    s_load_dwordx4 s[sgpr_matrixAB_address:sgpr_matrixAB_address+3], s[0:1], 0x20;//AB
    s_load_dwordx2 s[sgpr_matrixC_start_address:sgpr_matrixC_start_address+1], s[0:1], 0x30;//C

    v_lshrrev_b32  v[vgpr_waveid], 6, v0;// 0 0..0|1...1|2...2|3...3 wave id ,will use after
    v_lshlrev_b32 v2,5,v[vgpr_waveid];//0 0...0|32 32..32|64 64..64|96 96..96

    ;//this is for lds,but for final address, xy not the same,so don't confused
    v_lshrrev_b32 v[vgpr_block_thread_tile_y], 4, v0;//y=v0/16
    v_lshlrev_b32 v[vgpr_block_thread_tile_y],4,v[vgpr_block_thread_tile_y];//*4*4due to every thread have 4
    v_and_b32 v[vgpr_block_thread_tile_x],v0,15;//x=v0%16
    v_lshlrev_b32 v[vgpr_block_thread_tile_x],4,v[vgpr_block_thread_tile_x]


    s_lshl_b32 s[sgpr_crs_id],s[sgpr_CRS_64],6


    v_and_b32     v[vgpr_wave_tid], 63, v0;//wave tid,will use after

    v_add_u32 v[vgpr_crs_global_id],v[vgpr_wave_tid],s[sgpr_crs_id]


    v_mov_b32 v[vgpr_A_value_4],0
    v_mov_b32 v[vgpr_A_value_4+1],0
    v_mov_b32 v[vgpr_A_value_4+2],0
    v_mov_b32 v[vgpr_A_value_4+3],0


    s_mov_b32 s[sgpr_lds_NOO_offset],256

    s_waitcnt     lgkmcnt(0);//wait sload


    ;s_mov_b32 s[sgpr_lds_NOO_offset],256



    s_lshr_b32    s[sgpr_NOO_16], s[sgpr_NOO], 4
    s_lshl_b32    s[sgpr_NOO_start_address_split],s[sgpr_NOO_16],3;//you need to *4*2 due to auxbuf is mixed
    s_mul_i32 s[sgpr_NOO_start_address_split],s[sgpr_NOO_start_address_split],s[sgpr_splitK_idx]
    v_readfirstlane_b32 s[sgpr_wave_NOO_offset],v2;//0 0...0|32 32..32|64 64..64|96 96..96

    s_mov_b32 s[sgpr_NOO_loop_idx_in_split],0


;//C calculate
    s_mul_i32 s[sgpr_tmp_final],s[sgpr_K],s[sgpr_CRS];//s4*KCRS*4+K_64*64*CRS*4+CRS_64*64*4+    k*CRS*4+crs*4
    s_lshl_b32 s[sgpr_tmp_final],s[sgpr_tmp_final],2;//KCRS*4
    s_mul_i32 s[sgpr_tmp_final],s[sgpr_tmp_final],s[sgpr_splitK_idx]
    s_mul_i32 s[sgpr_tmp2_final],s[sgpr_K_64],s[sgpr_CRS]
    s_lshl_b32 s[sgpr_tmp2_final],s[sgpr_tmp2_final],8;//*64*4
    s_add_u32 s[sgpr_tmp_final],s[sgpr_tmp_final],s[sgpr_tmp2_final]
    s_lshl_b32 s[sgpr_tmp2_final],s[sgpr_CRS_64],8
    s_add_u32 s[sgpr_tmp_final],s[sgpr_tmp_final],s[sgpr_tmp2_final]

    v_mul_lo_u32 v[vgpr_final_offset],v[vgpr_block_thread_tile_x],s[sgpr_CRS];//it's x
    ;v_lshlrev_b32 v[vgpr_final_offset],2,s[sgpr_CRS];//*4
    v_add_u32  v[vgpr_final_offset],v[vgpr_final_offset],v[vgpr_block_thread_tile_y]
    ;v_lshl_add_u32 v[vgpr_final_offset],s[sgpr_CRS],2,v[vgpr_final_offset]

    s_add_u32     s[sgpr_buf_C_address], s[sgpr_matrixC_start_address], s[sgpr_tmp_final]
    s_addc_u32    s[sgpr_buf_C_address+1], s[sgpr_matrixC_start_address+1], 0

    s_lshl_b32 s[sgpr_buf_C_address+2] ,  s[sgpr_CRS],8;//64*crs*4
    
    


;    s_lshl_b32 s[sgpr_tmp_final],s[sgpr_K_64],6 ;//k*64
;    s_sub_i32 s[sgpr_tmp_final],s[sgpr_K],s[sgpr_tmp_final]
;    s_cmp_ge_i32 s[sgpr_tmp_final],64
;    s_cselect_b32 s[sgpr_tmp2_final],1,0

;    s_or_saveexec_b64 s[sgpr_before_cmp_address:sgpr_before_cmp_address+1],exec     
;//open
    s_lshl_b32 s[sgpr_tmp_final],s[sgpr_CRS_64],6
    s_sub_i32 s[sgpr_tmp_final],s[sgpr_CRS],s[sgpr_tmp_final]
    s_cmp_ge_i32 s[sgpr_tmp_final],64
    s_cselect_b32 s[sgpr_KCRS_ok],1,0


    s_lshl_b32 s[sgpr_tmp2_final],s[sgpr_K_64],6
    s_sub_i32 s[sgpr_tmp2_final],s[sgpr_K],s[sgpr_tmp2_final]
    s_cmp_ge_i32 s[sgpr_tmp2_final],64
    s_cselect_b32 s[sgpr_KCRS_ok],s[sgpr_KCRS_ok],0
;//open end
;    s_mov_b64 exec,s[sgpr_before_cmp_address:sgpr_before_cmp_address+1]

;    s_cselect_b32 s[sgpr_tmp_final],1,0
;    s_mul_i32 s[sgpr_KCRS_ok],s[sgpr_tmp2_final],s[sgpr_tmp_final]
;    s_mov_b64 exec,s[sgpr_before_cmp_address:sgpr_before_cmp_address+1]



;//set limit handle k over here, crs over need use cmpx 
;    s_add_u32  s[sgpr_tmp_final],s[sgpr_K_64],1
;    s_lshl_b32 s[sgpr_tmp_final],s[sgpr_tmp_final],6;//k*64
;    s_sub_i32 s[sgpr_tmp_final],s[sgpr_K],s[sgpr_tmp_final]
;    s_mul_i32 s[sgpr_tmp2_final],s[sgpr_tmp_final],s[sgpr_CRS]
;    s_lshl_b32 s[sgpr_tmp2_final],s[sgpr_tmp2_final],2

 
    ;s_cmp_ge_u32 s[sgpr_tmp_final], 64;//real limit too hard to calculate,just block it by k
    
    ;s_cselect_b32 s[sgpr_buf_C_address+2] ,BufferLimit,s[sgpr_tmp2_final]
    ;s_cselect_b32 s[sgpr_buf_C_address+2],s[sgpr_tmp3_final] ,s[sgpr_tmp2_final]

    ;s_lshl_b32 s[sgpr_buf_C_address+2],s[sgpr_CRS],4
    ;//64*CRS*4+64*4
    ;s_add_u32 s[sgpr_buf_C_address+2],s[sgpr_buf_C_address+2],16
    ;s_mov_b32 s[sgpr_buf_C_address+2],0x80000000
    s_mov_b32 s[sgpr_buf_C_address+3], Srd127_96
;//C calculate end 


    s_waitcnt     lgkmcnt(0);//wait s[sgpr_wave_NOO_offset]

    s_lshr_b32 s[sgpr_NOO_wave_start_idx_offset],s[sgpr_wave_NOO_offset],2;//0 0 ....0|8 8 ...8|16 16 ...16|24 24.....24
    s_add_u32 s[sgpr_NOO_wave_idx_offset],s[sgpr_NOO_wave_start_idx_offset],6;//6 6....6 |14 14...14|22 22...22 |30 30..30 last wave noo offset inaux
    s_add_u32 s[sgpr_NOO_wave_start_idx_offset],s[sgpr_NOO_wave_start_idx_offset],0;//0 0...0|8 8 ...8|16 16..16|24 24...24 first wave noo offset in aux
    s_add_u32 s[sgpr_NOO_wave_idx_in_split],s[sgpr_NOO_loop_idx_in_split],s[sgpr_NOO_wave_idx_offset];//everytime in loop + 6 6....6 |14 14...14|22 22...22 |30 30..30
    s_add_u32 s[sgpr_NOO_wave_start_idx_in_split],s[sgpr_NOO_loop_idx_in_split],s[sgpr_NOO_wave_start_idx_offset];//everytime in loop + 0 0...0|8 8 ...8|16 16..16|24 24...24

    s_lshr_b32 s[sgpr_NOO_real_idx],s[sgpr_NOO_wave_idx_in_split],1;//
    s_add_u32 s[sgpr_NOO_real_idx],s[sgpr_NOO_real_idx],1;//4 4...4|8 8 ...8|12  12|16 16
;//sgpr_NOO_start_address_split

;//use even out of bound
    s_mul_i32 s[sgpr_NKOO_1_address],s[sgpr_NOO],s[sgpr_K]
    s_lshl_b32  s[sgpr_NKOO_1_address], s[sgpr_NKOO_1_address],2


    v_lshlrev_b32 v3, 2, v[vgpr_wave_tid];//0 4 8...252|0 4 8...252|0 4 8...252|0 4 8...252
    v_mov_b32 v9,s[sgpr_CRS_64]
    v_lshl_add_u32 v3,v9,8,v3;//global crs id*4 = crs id*256+wave tid*4
;//




    s_cmp_gt_u32  s[sgpr_NOO_real_idx], s[sgpr_NOO_16];//not use ge due to start from 1 not 0
    s_cbranch_scc0 A_read_not_out_of_bound

A_wave_read_out_of_bound:
    ;//before already set 0 ,do not do here

 
;//FMA value reset
    v_mov_b32 v[vgpr_FMA_value],0
    v_mov_b32 v[vgpr_FMA_value+1],0
    v_mov_b32 v[vgpr_FMA_value+2],0
    v_mov_b32 v[vgpr_FMA_value+3],0
    v_mov_b32 v[vgpr_FMA_value+4],0
    v_mov_b32 v[vgpr_FMA_value+5],0
    v_mov_b32 v[vgpr_FMA_value+6],0
    v_mov_b32 v[vgpr_FMA_value+7],0
    v_mov_b32 v[vgpr_FMA_value+8],0
    v_mov_b32 v[vgpr_FMA_value+9],0
    v_mov_b32 v[vgpr_FMA_value+10],0
    v_mov_b32 v[vgpr_FMA_value+11],0
    v_mov_b32 v[vgpr_FMA_value+12],0
    v_mov_b32 v[vgpr_FMA_value+13],0
    v_mov_b32 v[vgpr_FMA_value+14],0
    v_mov_b32 v[vgpr_FMA_value+15],0

;//FMA value reset over


;    s_lshr_b32 s[sgpr_NOO_real_idx],s[sgpr_NOO_wave_start_idx_in_split],1
;    s_add_u32 s[sgpr_NOO_real_idx],s[sgpr_NOO_real_idx],1
    s_sub_u32 s[sgpr_NOO_out_of_bound_tmp],s[sgpr_NOO_real_idx],3

    s_cmp_gt_u32 s[sgpr_NOO_out_of_bound_tmp], s[sgpr_NOO_16]    
    s_cbranch_scc0 A_read_some_in_bonud_0
    s_mov_b32 s[sgpr_NOO_out_of_bound_status],1
    s_branch first_write_A_to_lds

A_read_some_in_bonud_0:;//read 1

    s_or_saveexec_b64 s[sgpr_before_cmp_address:sgpr_before_cmp_address+1],exec
    v_cmpx_lt_u32 vcc, v[vgpr_crs_global_id], s[sgpr_CRS]
 

    s_add_u32 s[sgpr_NOO_start_address_split],s[sgpr_NOO_start_address_split],s[sgpr_wave_NOO_offset]
    s_load_dwordx2 s[sgpr_auxbuf_8:sgpr_auxbuf_8+1], s[sgpr_matrixK_NOO_address:sgpr_matrixK_NOO_address+1], s[sgpr_NOO_start_address_split]    
    s_waitcnt     lgkmcnt(0)

;//s[sgpr_crs_id]
    ;v_cmpx_lt_u32 vcc, v64, s65
    s_mov_b32 s[sgpr_buf_crs_address],s[sgpr_span_address]
    s_mov_b32 s[sgpr_buf_crs_address+1],s[sgpr_span_address+1]
    s_lshl_b32    s[sgpr_CRS_1_address], s[sgpr_CRS], 2 
    s_mov_b32 s[sgpr_buf_crs_address+2],s[sgpr_CRS_1_address]
    s_mov_b32 s[sgpr_buf_crs_address+3], Srd127_96


    buffer_load_dword v[vgpr_CRS_value], v3, s[sgpr_buf_crs_address:sgpr_buf_crs_address+3], 0, offen offset:0

    s_waitcnt vmcnt(0);

    
    s_add_u32     s[sgpr_buf_A_address], s[sgpr_matrixAB_address], s[sgpr_auxbuf_8]
    s_addc_u32    s[sgpr_buf_A_address+1], s[sgpr_matrixAB_address+1], 0
    s_sub_u32 s[sgpr_buf_A_address+2],s[sgpr_NCHW_1_address],s[sgpr_auxbuf_8]
    s_mov_b32 s[sgpr_buf_A_address+3], Srd127_96
    buffer_load_dword v[vgpr_A_value_4], v[vgpr_CRS_value], s[sgpr_buf_A_address:sgpr_buf_A_address+3], 0, offen offset:0

    
    ;s_not_b64 vcc, vcc
    ;s_and_b64 exec, exec, vcc
    

    
    s_add_u32 s[sgpr_NOO_out_of_bound_tmp],s[sgpr_NOO_out_of_bound_tmp],1
    s_cmp_gt_u32 s[sgpr_NOO_out_of_bound_tmp], s[sgpr_NOO_16]
    s_cbranch_scc0 A_read_some_in_bonud_1
    s_mov_b32 s[sgpr_NOO_out_of_bound_status],2

    ;//only after leave judge ,reset excc
    s_mov_b64 exec,s[sgpr_before_cmp_address:sgpr_before_cmp_address+1]
    s_branch first_write_A_to_lds

A_read_some_in_bonud_1:;//read 2
;    s_or_saveexec_b64 s[sgpr_before_cmp_address:sgpr_before_cmp_address+1],exec
;    v_cmpx_lt_u32 vcc, v[vgpr_crs_global_id], s[sgpr_CRS]

    s_add_u32 s[sgpr_NOO_out_of_bound_wave_start_address_tmp],s[sgpr_NOO_start_address_split],8
    s_load_dwordx2 s[sgpr_auxbuf_8+2:sgpr_auxbuf_8+3], s[sgpr_matrixK_NOO_address:sgpr_matrixK_NOO_address+1], s[sgpr_NOO_out_of_bound_wave_start_address_tmp]    
    s_waitcnt     lgkmcnt(0)

;//crs already read before
    s_add_u32     s[sgpr_buf_A_address], s[sgpr_matrixAB_address], s[sgpr_auxbuf_8+2]
    s_addc_u32    s[sgpr_buf_A_address+1], s[sgpr_matrixAB_address+1], 0
    s_sub_u32 s[sgpr_buf_A_address+2],s[sgpr_NCHW_1_address],s[sgpr_auxbuf_8+2]
    buffer_load_dword v[vgpr_A_value_4+1], v[vgpr_CRS_value], s[sgpr_buf_A_address:sgpr_buf_A_address+3], 0, offen offset:0


    s_add_u32 s[sgpr_NOO_out_of_bound_tmp],s[sgpr_NOO_out_of_bound_tmp],1
    s_cmp_gt_u32 s[sgpr_NOO_out_of_bound_tmp], s[sgpr_NOO_16]
    s_cbranch_scc0 A_read_some_in_bonud_2
    s_mov_b32 s[sgpr_NOO_out_of_bound_status],3

    s_mov_b64 exec,s[sgpr_before_cmp_address:sgpr_before_cmp_address+1]
    s_branch first_write_A_to_lds



A_read_some_in_bonud_2:;//read 3
;    s_or_saveexec_b64 s[sgpr_before_cmp_address:sgpr_before_cmp_address+1],exec
;    v_cmpx_lt_u32 vcc, v[vgpr_crs_global_id], s[sgpr_CRS]

    s_add_u32 s[sgpr_NOO_out_of_bound_wave_start_address_tmp],s[sgpr_NOO_start_address_split],16
    s_load_dwordx2 s[sgpr_auxbuf_8+4:sgpr_auxbuf_8+5], s[sgpr_matrixK_NOO_address:sgpr_matrixK_NOO_address+1], s[sgpr_NOO_out_of_bound_wave_start_address_tmp]
    s_waitcnt     lgkmcnt(0)

;//crs already read before
    s_add_u32     s[sgpr_buf_A_address], s[sgpr_matrixAB_address], s[sgpr_auxbuf_8+4]
    s_addc_u32    s[sgpr_buf_A_address+1], s[sgpr_matrixAB_address+1], 0
    s_sub_u32 s[sgpr_buf_A_address+2],s[sgpr_NCHW_1_address],s[sgpr_auxbuf_8+4]
    buffer_load_dword v[vgpr_A_value_4+2], v[vgpr_CRS_value], s[sgpr_buf_A_address:sgpr_buf_A_address+3], 0, offen offset:0


    s_mov_b32 s[sgpr_NOO_out_of_bound_status],4

    s_mov_b64 exec,s[sgpr_before_cmp_address:sgpr_before_cmp_address+1]
    s_branch first_write_A_to_lds   


A_read_not_out_of_bound:

    s_add_u32 s[sgpr_NOO_start_address_split],s[sgpr_NOO_start_address_split],s[sgpr_wave_NOO_offset]
    s_load_dwordx8 s[sgpr_auxbuf_8:sgpr_auxbuf_8+7], s[sgpr_matrixK_NOO_address:sgpr_matrixK_NOO_address+1], s[sgpr_NOO_start_address_split]

;//use even out of bound
;    s_mul_i32 s[sgpr_NKOO_1_address],s[sgpr_NOO],s[sgpr_K]
;    s_lshl_b32  s[sgpr_NKOO_1_address], s[sgpr_NKOO_1_address],2

;    v_lshlrev_b32 v3, 2, v[vgpr_wave_tid];//0 4 8...252|0 4 8...252|0 4 8...252|0 4 8...252

;    v_mov_b32 v9,s[sgpr_CRS_64]
;    v_lshl_add_u32 v3,v9,8,v3;//global crs id = crs id*256+wave tid*4
;//

    s_mov_b32 s[sgpr_NOO_out_of_bound_status],0

    s_waitcnt     lgkmcnt(0)




    s_or_saveexec_b64 s[sgpr_before_cmp_address:sgpr_before_cmp_address+1],exec
    v_cmpx_lt_u32 vcc, v[vgpr_crs_global_id], s[sgpr_CRS]
    


    s_mov_b32 s[sgpr_buf_crs_address],s[sgpr_span_address]
    s_mov_b32 s[sgpr_buf_crs_address+1],s[sgpr_span_address+1]
    s_lshl_b32    s[sgpr_CRS_1_address], s[sgpr_CRS], 2 
    s_mov_b32 s[sgpr_buf_crs_address+2],s[sgpr_CRS_1_address]
    s_mov_b32 s[sgpr_buf_crs_address+3], Srd127_96
    buffer_load_dword v[vgpr_CRS_value], v3, s[sgpr_buf_crs_address:sgpr_buf_crs_address+3], 0, offen offset:0

    s_waitcnt vmcnt(0);


    s_add_u32     s[sgpr_buf_A_address], s[sgpr_matrixAB_address], s[sgpr_auxbuf_8]
    s_addc_u32    s[sgpr_buf_A_address+1], s[sgpr_matrixAB_address+1], 0
    s_sub_u32 s[sgpr_buf_A_address+2],s[sgpr_NCHW_1_address],s[sgpr_auxbuf_8]
    s_mov_b32 s[sgpr_buf_A_address+3], Srd127_96
    buffer_load_dword v[vgpr_A_value_4], v[vgpr_CRS_value], s[sgpr_buf_A_address:sgpr_buf_A_address+3], 0, offen offset:0

    s_add_u32     s[sgpr_buf_A_address], s[sgpr_matrixAB_address], s[sgpr_auxbuf_8+2]
    s_addc_u32    s[sgpr_buf_A_address+1], s[sgpr_matrixAB_address+1], 0
    s_sub_u32 s[sgpr_buf_A_address+2],s[sgpr_NCHW_1_address],s[sgpr_auxbuf_8+2]
    buffer_load_dword v[vgpr_A_value_4+1], v[vgpr_CRS_value], s[sgpr_buf_A_address:sgpr_buf_A_address+3], 0, offen offset:0


    s_add_u32     s[sgpr_buf_A_address], s[sgpr_matrixAB_address], s[sgpr_auxbuf_8+4]
    s_addc_u32    s[sgpr_buf_A_address+1], s[sgpr_matrixAB_address+1], 0
    s_sub_u32 s[sgpr_buf_A_address+2],s[sgpr_NCHW_1_address],s[sgpr_auxbuf_8+4]
    buffer_load_dword v[vgpr_A_value_4+2], v[vgpr_CRS_value], s[sgpr_buf_A_address:sgpr_buf_A_address+3], 0, offen offset:0

    s_add_u32     s[sgpr_buf_A_address], s[sgpr_matrixAB_address], s[sgpr_auxbuf_8+6]
    s_addc_u32    s[sgpr_buf_A_address+1], s[sgpr_matrixAB_address+1], 0
    s_sub_u32 s[sgpr_buf_A_address+2],s[sgpr_NCHW_1_address],s[sgpr_auxbuf_8+6]
    buffer_load_dword v[vgpr_A_value_4+3], v[vgpr_CRS_value], s[sgpr_buf_A_address:sgpr_buf_A_address+3], 0, offen offset:0



    s_mov_b64 exec,s[sgpr_before_cmp_address:sgpr_before_cmp_address+1]


//FMA value reset
    v_mov_b32 v[vgpr_FMA_value],0
    v_mov_b32 v[vgpr_FMA_value+1],0
    v_mov_b32 v[vgpr_FMA_value+2],0
    v_mov_b32 v[vgpr_FMA_value+3],0
    v_mov_b32 v[vgpr_FMA_value+4],0
    v_mov_b32 v[vgpr_FMA_value+5],0
    v_mov_b32 v[vgpr_FMA_value+6],0
    v_mov_b32 v[vgpr_FMA_value+7],0
    v_mov_b32 v[vgpr_FMA_value+8],0
    v_mov_b32 v[vgpr_FMA_value+9],0
    v_mov_b32 v[vgpr_FMA_value+10],0
    v_mov_b32 v[vgpr_FMA_value+11],0
    v_mov_b32 v[vgpr_FMA_value+12],0
    v_mov_b32 v[vgpr_FMA_value+13],0
    v_mov_b32 v[vgpr_FMA_value+14],0
    v_mov_b32 v[vgpr_FMA_value+15],0

;//FMA value reset over


first_write_A_to_lds:

    s_waitcnt vmcnt(0);//load A ok
    v_lshlrev_b32 v9,10,v[vgpr_waveid];//waveid*16*64
;read
;A          aux1
;  tid wave0   wave1  2   3   next noo
;      ____________________|____
;   16 |     |     |    |     |
;   32 |                      |
;   48 |                      |
;   64 |______________________|
;next  |
;crs
;   16
;//[NOO][64] store to lds,down sore
    ;//wave id *16*64+wave tid*4
    


    v_lshl_add_u32 v10,v[vgpr_wave_tid],2,v9;//wave tid*4+waveid*16*64
    ds_write_b32  v10, v[vgpr_A_value_4]
    ds_write_b32  v10, v[vgpr_A_value_4+1] offset:256
    ds_write_b32  v10, v[vgpr_A_value_4+2] offset:512
    ds_write_b32  v10, v[vgpr_A_value_4+3] offset:768
    s_waitcnt     lgkmcnt(0)




;//but store to lds,down sore to help load conti after
;//[64][N00]
;   ________________ 
;   |0 256    |64*16  
;   |4 260
;   |8
;   |12_____________
;

;B 
;                 64     
;          _______________________next k
;wave0    |______________________|
;wave1    |______________________|
;wave2    |______________________|
;wave3    |______________________|
;16       |      
;        next noo
;        aux2 


    ;//v11 ----------------------------->K*o*o
    v_lshl_add_u32 v[vgpr_global_k],s[sgpr_K_64],6,v2;//k_64*64+wave tid global k
    ;//find 0-63 koo
    v_mul_lo_u32 v11,v[vgpr_global_k],s[sgpr_OO]

    ;//MatrixN  max is KOO-1
    s_or_saveexec_b64 s[sgpr_before_cmp_address:sgpr_before_cmp_address+1],exec
    v_cmpx_ge_u32  s[sgpr_cmp_tmp_address:sgpr_cmp_tmp_address+1], v12, s[sgpr_K]
    v_mov_b32 v12,s[sgpr_K]
    v_mul_lo_u32 v11,v12,s[sgpr_OO]
    v_sub_u32 v11,v11,1
    s_mov_b64 exec,s[sgpr_before_cmp_address:sgpr_before_cmp_address+1]
    

    v_lshlrev_b32 v11,2,v11;//koo*4




;//due to splitk noo already get in A,so B do not need to handle split address

    s_cmp_eq_u32  s[sgpr_NOO_out_of_bound_status], 0;
    s_cbranch_scc1 B_read_not_out_of_bound
        
    v_mov_b32 v[vgpr_B_value_4],0
    v_mov_b32 v[vgpr_B_value_4+1],0
    v_mov_b32 v[vgpr_B_value_4+2],0
    v_mov_b32 v[vgpr_B_value_4+3],0

    s_add_u32     s[sgpr_buf_B_address], s[sgpr_matrixB_start_address], s[sgpr_auxbuf_8+1]
    s_addc_u32    s[sgpr_buf_B_address+1], s[sgpr_matrixB_start_address+1], 0
    s_sub_u32 s[sgpr_buf_B_address+2],s[sgpr_NKOO_1_address],s[sgpr_auxbuf_8+1]
    s_mov_b32 s[sgpr_buf_B_address+3], Srd127_96


    s_cmp_eq_u32 s[sgpr_NOO_out_of_bound_status], 2
    s_cbranch_scc1 B_read_some_in_bonud_status_2

    s_cmp_eq_u32 s[sgpr_NOO_out_of_bound_status], 3
    s_cbranch_scc1 B_read_some_in_bonud_status_3

    s_cmp_eq_u32 s[sgpr_NOO_out_of_bound_status], 4
    s_cbranch_scc1 B_read_some_in_bonud_status_4
    ;//status 1, do not read
    s_branch first_write_B_to_lds

;//status 4 only need read 3 data
B_read_some_in_bonud_status_4:
    
    buffer_load_dwordx2 v[vgpr_B_value_4:vgpr_B_value_4+1], v[11], s[sgpr_buf_B_address:sgpr_buf_B_address+3], 0, offen offset:0
    buffer_load_dword v[vgpr_B_value_4+2], v[11], s[sgpr_buf_B_address:sgpr_buf_B_address+3], 0, offen offset:8
    s_waitcnt vmcnt(0)
    ;v_mov_b32 v[vgpr_B_value_4+3],0
    s_branch first_write_B_to_lds

B_read_some_in_bonud_status_2:
    buffer_load_dword v[vgpr_B_value_4], v[11], s[sgpr_buf_B_address:sgpr_buf_B_address+3], 0, offen offset:0
    s_branch first_write_B_to_lds

B_read_some_in_bonud_status_3:
    buffer_load_dwordx2 v[vgpr_B_value_4:vgpr_B_value_4+1], v[11], s[sgpr_buf_B_address:sgpr_buf_B_address+3], 0, offen offset:0
    s_branch first_write_B_to_lds


B_read_not_out_of_bound:
    s_add_u32     s[sgpr_buf_B_address], s[sgpr_matrixB_start_address], s[sgpr_auxbuf_8+1]
    s_addc_u32    s[sgpr_buf_B_address+1], s[sgpr_matrixB_start_address+1], 0
    s_sub_u32 s[sgpr_buf_B_address+2],s[sgpr_NKOO_1_address],s[sgpr_auxbuf_8+1]
    s_mov_b32 s[sgpr_buf_B_address+3], Srd127_96

    s_sub_u32 s[sgpr_B_load_judge],s[sgpr_auxbuf_8+7],s[sgpr_auxbuf_8+1]
;//need add
    s_cmp_eq_u32  s[sgpr_B_load_judge], 12
    s_cbranch_scc1  B_conti_read


    buffer_load_dword v[vgpr_B_value_4], v[11], s[sgpr_buf_B_address:sgpr_buf_B_address+3], 0, offen offset:0



s_add_u32     s[sgpr_buf_B_address], s[sgpr_matrixB_start_address], s[sgpr_auxbuf_8+3]
s_addc_u32    s[sgpr_buf_B_address+1], s[sgpr_matrixB_start_address+1], 0
s_sub_u32 s[sgpr_buf_B_address+2],s[sgpr_NKOO_1_address],s[sgpr_auxbuf_8+3]
buffer_load_dword v[vgpr_B_value_4+1], v[11], s[sgpr_buf_B_address:sgpr_buf_B_address+3], 0, offen offset:0




s_add_u32     s[sgpr_buf_B_address], s[sgpr_matrixB_start_address], s[sgpr_auxbuf_8+5]
s_addc_u32    s[sgpr_buf_B_address+1], s[sgpr_matrixB_start_address+1], 0
s_sub_u32 s[sgpr_buf_B_address+2],s[sgpr_NKOO_1_address],s[sgpr_auxbuf_8+5]
buffer_load_dword v[vgpr_B_value_4+2], v[11], s[sgpr_buf_B_address:sgpr_buf_B_address+3], 0, offen offset:0





s_add_u32     s[sgpr_buf_B_address], s[sgpr_matrixB_start_address], s[sgpr_auxbuf_8+7]
s_addc_u32    s[sgpr_buf_B_address+1], s[sgpr_matrixB_start_address+1], 0
s_sub_u32 s[sgpr_buf_B_address+2],s[sgpr_NKOO_1_address],s[sgpr_auxbuf_8+7]
buffer_load_dword v[vgpr_B_value_4+3], v[11], s[sgpr_buf_B_address:sgpr_buf_B_address+3], 0, offen offset:0

    s_branch first_write_B_to_lds 
;//BELOW IS TEST


B_conti_read:
;//NOO must %4=0 or global_load_dwordx4 may read 0
    buffer_load_dwordx4 v[vgpr_B_value_4:vgpr_B_value_4+3], v[11], s[sgpr_buf_B_address:sgpr_buf_B_address+3], 0, offen offset:0




first_write_B_to_lds:
    s_waitcnt     vmcnt(0)
;//[NOO][64] store to lds,store right
;_________________________________
;   |0 4 ...                 252 |
;   |256                         |
;   |..         wave0            |
;   |__________________________
;   |64*16 ......
;
;LDS SIZE:        8192
;A1       A2       |B1        B2
;64*16*4  64*16*4  |64*16*4   64*16*4
;

    ds_write_b32  v10, v[vgpr_B_value_4] offset:8192
    ds_write_b32  v10, v[vgpr_B_value_4+1] offset:8192+256
    ds_write_b32  v10, v[vgpr_B_value_4+2] offset:8192+512
    ds_write_b32  v10, v[vgpr_B_value_4+3] offset:8192+768

    s_waitcnt     lgkmcnt(0)
;   ---->x
;|   _1.2,____
;|   |1 2|   56 1.            load 13    load 24
;|   |3 4|   78 2.    load56 
;y                    load78
;
;loop1:13&56 
;   1*5   1*6      x0y0:A[y]B[x]   x1y0
;   3*5   3*6      x0y1            x1y1
;      +
;loop2:24&78   
;   2*7   2*8
;   4*7   4*8
;
;   for (loop)<=matrik
;        for(x)      
;           for(y)
;             sum[x][y]+=A[y]B[x] col-base due to CRS is col K is row


;thread0 A0B0 thread1 A0B1 thread16 A1B0 thread17 A1B1
;NOO 0:loop0
;


FMA_do:
s_barrier;

    v_mov_b32 v[vgpr_lds_A_offset],v[vgpr_block_thread_tile_y]
    v_mov_b32 v[vgpr_lds_B_offset],v[vgpr_block_thread_tile_x]
    ds_read_b128  v[vgpr_thread_A_4:vgpr_thread_A_4+3], v[vgpr_lds_A_offset] offset:0
    ds_read_b128  v[vgpr_thread_B_4:vgpr_thread_B_4+3],v[vgpr_lds_B_offset] offset:8192

    s_waitcnt     lgkmcnt(0)

v_fmac_f32    v[vgpr_FMA_value], v[vgpr_thread_A_4], v[vgpr_thread_B_4]
v_fmac_f32    v[vgpr_FMA_value+1],v[vgpr_thread_A_4+1], v[vgpr_thread_B_4]
v_fmac_f32    v[vgpr_FMA_value+2],v[vgpr_thread_A_4+2], v[vgpr_thread_B_4]
v_fmac_f32    v[vgpr_FMA_value+3],v[vgpr_thread_A_4+3], v[vgpr_thread_B_4]
v_fmac_f32    v[vgpr_FMA_value+4], v[vgpr_thread_A_4], v[vgpr_thread_B_4+1]
v_fmac_f32    v[vgpr_FMA_value+5],v[vgpr_thread_A_4+1], v[vgpr_thread_B_4+1]
v_fmac_f32    v[vgpr_FMA_value+6],v[vgpr_thread_A_4+2], v[vgpr_thread_B_4+1]
v_fmac_f32    v[vgpr_FMA_value+7],v[vgpr_thread_A_4+3], v[vgpr_thread_B_4+1]
v_fmac_f32    v[vgpr_FMA_value+8], v[vgpr_thread_A_4], v[vgpr_thread_B_4+2]
v_fmac_f32    v[vgpr_FMA_value+9],v[vgpr_thread_A_4+1], v[vgpr_thread_B_4+2]
v_fmac_f32    v[vgpr_FMA_value+10],v[vgpr_thread_A_4+2], v[vgpr_thread_B_4+2]
v_fmac_f32    v[vgpr_FMA_value+11],v[vgpr_thread_A_4+3], v[vgpr_thread_B_4+2]
v_fmac_f32    v[vgpr_FMA_value+12], v[vgpr_thread_A_4], v[vgpr_thread_B_4+3]
v_fmac_f32    v[vgpr_FMA_value+13],v[vgpr_thread_A_4+1], v[vgpr_thread_B_4+3]
v_fmac_f32    v[vgpr_FMA_value+14],v[vgpr_thread_A_4+2], v[vgpr_thread_B_4+3]
v_fmac_f32    v[vgpr_FMA_value+15],v[vgpr_thread_A_4+3], v[vgpr_thread_B_4+3]



;both LDS A and B [NOO][64],so you just +64*4,you can jump to next NOO
;//NOO LOOP 1

;s_lshl_b32 s[sgpr_lds_NOO_offset] ,  s[sgpr_CRS],2;//crs*4

v_add_u32 v[vgpr_lds_A_offset],v[vgpr_lds_A_offset],s[sgpr_lds_NOO_offset];//64*4 
v_add_u32 v[vgpr_lds_B_offset],v[vgpr_lds_B_offset],s[sgpr_lds_NOO_offset]

ds_read_b128  v[vgpr_thread_A_4:vgpr_thread_A_4+3], v[vgpr_lds_A_offset] offset:0
ds_read_b128  v[vgpr_thread_B_4:vgpr_thread_B_4+3],v[vgpr_lds_B_offset] offset:8192
s_waitcnt     lgkmcnt(0)

v_fmac_f32    v[vgpr_FMA_value], v[vgpr_thread_A_4], v[vgpr_thread_B_4]
v_fmac_f32    v[vgpr_FMA_value+1],v[vgpr_thread_A_4+1], v[vgpr_thread_B_4]
v_fmac_f32    v[vgpr_FMA_value+2],v[vgpr_thread_A_4+2], v[vgpr_thread_B_4]
v_fmac_f32    v[vgpr_FMA_value+3],v[vgpr_thread_A_4+3], v[vgpr_thread_B_4]
v_fmac_f32    v[vgpr_FMA_value+4], v[vgpr_thread_A_4], v[vgpr_thread_B_4+1]
v_fmac_f32    v[vgpr_FMA_value+5],v[vgpr_thread_A_4+1], v[vgpr_thread_B_4+1]
v_fmac_f32    v[vgpr_FMA_value+6],v[vgpr_thread_A_4+2], v[vgpr_thread_B_4+1]
v_fmac_f32    v[vgpr_FMA_value+7],v[vgpr_thread_A_4+3], v[vgpr_thread_B_4+1]
v_fmac_f32    v[vgpr_FMA_value+8], v[vgpr_thread_A_4], v[vgpr_thread_B_4+2]
v_fmac_f32    v[vgpr_FMA_value+9],v[vgpr_thread_A_4+1], v[vgpr_thread_B_4+2]
v_fmac_f32    v[vgpr_FMA_value+10],v[vgpr_thread_A_4+2], v[vgpr_thread_B_4+2]
v_fmac_f32    v[vgpr_FMA_value+11],v[vgpr_thread_A_4+3], v[vgpr_thread_B_4+2]
v_fmac_f32    v[vgpr_FMA_value+12], v[vgpr_thread_A_4], v[vgpr_thread_B_4+3]
v_fmac_f32    v[vgpr_FMA_value+13],v[vgpr_thread_A_4+1], v[vgpr_thread_B_4+3]
v_fmac_f32    v[vgpr_FMA_value+14],v[vgpr_thread_A_4+2], v[vgpr_thread_B_4+3]
v_fmac_f32    v[vgpr_FMA_value+15],v[vgpr_thread_A_4+3], v[vgpr_thread_B_4+3]

;//NOO LOOP 2
v_add_u32 v[vgpr_lds_A_offset],v[vgpr_lds_A_offset],s[sgpr_lds_NOO_offset];//64*4 
v_add_u32 v[vgpr_lds_B_offset],v[vgpr_lds_B_offset],s[sgpr_lds_NOO_offset]

ds_read_b128  v[vgpr_thread_A_4:vgpr_thread_A_4+3], v[vgpr_lds_A_offset] offset:0
ds_read_b128  v[vgpr_thread_B_4:vgpr_thread_B_4+3],v[vgpr_lds_B_offset] offset:8192
s_waitcnt     lgkmcnt(0)

v_fmac_f32    v[vgpr_FMA_value], v[vgpr_thread_A_4], v[vgpr_thread_B_4]
v_fmac_f32    v[vgpr_FMA_value+1],v[vgpr_thread_A_4+1], v[vgpr_thread_B_4]
v_fmac_f32    v[vgpr_FMA_value+2],v[vgpr_thread_A_4+2], v[vgpr_thread_B_4]
v_fmac_f32    v[vgpr_FMA_value+3],v[vgpr_thread_A_4+3], v[vgpr_thread_B_4]
v_fmac_f32    v[vgpr_FMA_value+4], v[vgpr_thread_A_4], v[vgpr_thread_B_4+1]
v_fmac_f32    v[vgpr_FMA_value+5],v[vgpr_thread_A_4+1], v[vgpr_thread_B_4+1]
v_fmac_f32    v[vgpr_FMA_value+6],v[vgpr_thread_A_4+2], v[vgpr_thread_B_4+1]
v_fmac_f32    v[vgpr_FMA_value+7],v[vgpr_thread_A_4+3], v[vgpr_thread_B_4+1]
v_fmac_f32    v[vgpr_FMA_value+8], v[vgpr_thread_A_4], v[vgpr_thread_B_4+2]
v_fmac_f32    v[vgpr_FMA_value+9],v[vgpr_thread_A_4+1], v[vgpr_thread_B_4+2]
v_fmac_f32    v[vgpr_FMA_value+10],v[vgpr_thread_A_4+2], v[vgpr_thread_B_4+2]
v_fmac_f32    v[vgpr_FMA_value+11],v[vgpr_thread_A_4+3], v[vgpr_thread_B_4+2]
v_fmac_f32    v[vgpr_FMA_value+12], v[vgpr_thread_A_4], v[vgpr_thread_B_4+3]
v_fmac_f32    v[vgpr_FMA_value+13],v[vgpr_thread_A_4+1], v[vgpr_thread_B_4+3]
v_fmac_f32    v[vgpr_FMA_value+14],v[vgpr_thread_A_4+2], v[vgpr_thread_B_4+3]
v_fmac_f32    v[vgpr_FMA_value+15],v[vgpr_thread_A_4+3], v[vgpr_thread_B_4+3]



;//NOO LOOP 3
v_add_u32 v[vgpr_lds_A_offset],v[vgpr_lds_A_offset],s[sgpr_lds_NOO_offset];//64*4 
v_add_u32 v[vgpr_lds_B_offset],v[vgpr_lds_B_offset],s[sgpr_lds_NOO_offset]

ds_read_b128  v[vgpr_thread_A_4:vgpr_thread_A_4+3], v[vgpr_lds_A_offset] offset:0
ds_read_b128  v[vgpr_thread_B_4:vgpr_thread_B_4+3],v[vgpr_lds_B_offset] offset:8192
s_waitcnt     lgkmcnt(0)

v_fmac_f32    v[vgpr_FMA_value], v[vgpr_thread_A_4], v[vgpr_thread_B_4]
v_fmac_f32    v[vgpr_FMA_value+1],v[vgpr_thread_A_4+1], v[vgpr_thread_B_4]
v_fmac_f32    v[vgpr_FMA_value+2],v[vgpr_thread_A_4+2], v[vgpr_thread_B_4]
v_fmac_f32    v[vgpr_FMA_value+3],v[vgpr_thread_A_4+3], v[vgpr_thread_B_4]
v_fmac_f32    v[vgpr_FMA_value+4], v[vgpr_thread_A_4], v[vgpr_thread_B_4+1]
v_fmac_f32    v[vgpr_FMA_value+5],v[vgpr_thread_A_4+1], v[vgpr_thread_B_4+1]
v_fmac_f32    v[vgpr_FMA_value+6],v[vgpr_thread_A_4+2], v[vgpr_thread_B_4+1]
v_fmac_f32    v[vgpr_FMA_value+7],v[vgpr_thread_A_4+3], v[vgpr_thread_B_4+1]
v_fmac_f32    v[vgpr_FMA_value+8], v[vgpr_thread_A_4], v[vgpr_thread_B_4+2]
v_fmac_f32    v[vgpr_FMA_value+9],v[vgpr_thread_A_4+1], v[vgpr_thread_B_4+2]
v_fmac_f32    v[vgpr_FMA_value+10],v[vgpr_thread_A_4+2], v[vgpr_thread_B_4+2]
v_fmac_f32    v[vgpr_FMA_value+11],v[vgpr_thread_A_4+3], v[vgpr_thread_B_4+2]
v_fmac_f32    v[vgpr_FMA_value+12], v[vgpr_thread_A_4], v[vgpr_thread_B_4+3]
v_fmac_f32    v[vgpr_FMA_value+13],v[vgpr_thread_A_4+1], v[vgpr_thread_B_4+3]
v_fmac_f32    v[vgpr_FMA_value+14],v[vgpr_thread_A_4+2], v[vgpr_thread_B_4+3]
v_fmac_f32    v[vgpr_FMA_value+15],v[vgpr_thread_A_4+3], v[vgpr_thread_B_4+3]





;       K
;     v0  v1......v15
;CRS  v16
;
;WRITE OUT
;
;


;    s_sub_u32 s[sgpr_tmp2_final],s[sgpr_CRS],s[sgpr_crs_id]

;    s_or_saveexec_b64 s[sgpr_before_cmp_address:sgpr_before_cmp_address+1],exec
;    s_cmp_eq_u32 s[sgpr_KCRS_ok], 1
;    s_cbranch_scc0 write_not_all_group


;v_mov_b32 v65,3.0
;v_mov_b32 v62,s[sgpr_matrixC_start_address]

;v_mov_b32 v63,s[sgpr_matrixC_start_address+1]

;global_store_dword v[62:63], v65 off offset:64

;s_or_saveexec_b64 s[sgpr_before_cmp_address:sgpr_before_cmp_address+1],exec
;v_cmpx_eq_u32  vcc, v0,0
;buffer_store_dword v[vgpr_FMA_value],v[vgpr_final_offset], s[sgpr_buf_C_address:sgpr_buf_C_address+3], 0, offen offset:0
;s_mov_b64 exec,s[sgpr_before_cmp_address:sgpr_before_cmp_address+1]

;s_or_saveexec_b64 s[sgpr_before_cmp_address:sgpr_before_cmp_address+1],exec
;v_cmpx_lt_u32 vcc, v0, 16


;buffer_store_dword v[vgpr_FMA_value],v[vgpr_final_offset], s[sgpr_buf_C_address:sgpr_buf_C_address+3], 0, offen offset:0

    s_barrier;
s_cmp_eq_u32  s[sgpr_KCRS_ok], 1
s_cbranch_scc0 write_not_all_group


write_out:
    buffer_store_dwordx4 v[vgpr_FMA_value:vgpr_FMA_value+3],v[vgpr_final_offset], s[sgpr_buf_C_address:sgpr_buf_C_address+3], 0, offen offset:0 
    v_lshl_add_u32 v[vgpr_reuse_tmp_write_dis],s[sgpr_CRS],2,v[vgpr_final_offset]
    buffer_store_dwordx4 v[vgpr_FMA_value+4:vgpr_FMA_value+7],v[vgpr_reuse_tmp_write_dis], s[sgpr_buf_C_address:sgpr_buf_C_address+3], 0, offen offset:0
    v_lshl_add_u32 v[vgpr_reuse_tmp_write_dis],s[sgpr_CRS],2,v[vgpr_reuse_tmp_write_dis]
    buffer_store_dwordx4 v[vgpr_FMA_value+8:vgpr_FMA_value+11],v[vgpr_reuse_tmp_write_dis], s[sgpr_buf_C_address:sgpr_buf_C_address+3], 0, offen offset:0
    v_lshl_add_u32 v[vgpr_reuse_tmp_write_dis],s[sgpr_CRS],2,v[vgpr_reuse_tmp_write_dis]
    buffer_store_dwordx4 v[vgpr_FMA_value+12:vgpr_FMA_value+15],v[vgpr_reuse_tmp_write_dis], s[sgpr_buf_C_address:sgpr_buf_C_address+3], 0, offen offset:0
    s_waitcnt vmcnt(0)
    s_branch write_over

write_not_all_group:
      ;//vgpr_block_thread_tile_y vgpr_block_thread_tile_x not address again,it's idx
      
      v_lshrrev_b32 v[vgpr_block_thread_tile_y],2,v[vgpr_block_thread_tile_y];//0...0|4....4|....
      v_lshrrev_b32 v[vgpr_block_thread_tile_x],2,v[vgpr_block_thread_tile_x];//0 4 8...64|0 4 8...64....
      s_lshl_b32 s[sgpr_tmp_final],s[sgpr_K_64],6;//64
      s_lshl_b32 s[sgpr_tmp2_final],s[sgpr_CRS_64],6;//64
      v_add_u32 v[vgpr_block_thread_tile_x],v[vgpr_block_thread_tile_x],s[sgpr_tmp_final]
      v_add_u32 v[vgpr_block_thread_tile_y],v[vgpr_block_thread_tile_y],s[sgpr_tmp2_final]
      v_cmpx_gt_u32 vcc,  s[sgpr_K],v[vgpr_block_thread_tile_x]
      v_cmpx_gt_u32 vcc,  s[sgpr_CRS],v[vgpr_block_thread_tile_y]

;    v_cmpx_gt_u32 vcc,  1,v0

    buffer_store_dwordx4 v[vgpr_FMA_value:vgpr_FMA_value+3],v[vgpr_final_offset], s[sgpr_buf_C_address:sgpr_buf_C_address+3], 0, offen offset:0 
    v_lshl_add_u32 v[vgpr_reuse_tmp_write_dis],s[sgpr_CRS],2,v[vgpr_final_offset]
    buffer_store_dwordx4 v[vgpr_FMA_value+4:vgpr_FMA_value+7],v[vgpr_reuse_tmp_write_dis], s[sgpr_buf_C_address:sgpr_buf_C_address+3], 0, offen offset:0
    v_lshl_add_u32 v[vgpr_reuse_tmp_write_dis],s[sgpr_CRS],2,v[vgpr_reuse_tmp_write_dis]
    buffer_store_dwordx4 v[vgpr_FMA_value+8:vgpr_FMA_value+11],v[vgpr_reuse_tmp_write_dis], s[sgpr_buf_C_address:sgpr_buf_C_address+3], 0, offen offset:0
    v_lshl_add_u32 v[vgpr_reuse_tmp_write_dis],s[sgpr_CRS],2,v[vgpr_reuse_tmp_write_dis]
    buffer_store_dwordx4 v[vgpr_FMA_value+12:vgpr_FMA_value+15],v[vgpr_reuse_tmp_write_dis], s[sgpr_buf_C_address:sgpr_buf_C_address+3], 0, offen offset:0
 

;//here vgpr_block_thread_tile_y change to idx ,not offset again
;    v_lshrrev_b32 v[vgpr_reuse_tmp_write_dis+1], 4, v0

;    v_lshlrev_b32 v[vgpr_reuse_tmp_write_dis+1], 2,v[vgpr_reuse_tmp_write_dis+1]
;    v_add_u32 v[vgpr_reuse_tmp_write_dis+1],v[vgpr_reuse_tmp_write_dis+1],s[sgpr_crs_id]    

;    v_sub_i32 v[vgpr_reuse_tmp_write_dis+1],s[sgpr_CRS],v[vgpr_reuse_tmp_write_dis+1]
;    s_or_saveexec_b64 s[sgpr_before_cmp_address:sgpr_before_cmp_address+1],exec
;    v_cmpx_ge_i32  vcc, v[vgpr_reuse_tmp_write_dis+1], 4


;     buffer_store_dwordx4 v[vgpr_FMA_value:vgpr_FMA_value+3],v[vgpr_final_offset], s[sgpr_buf_C_address:sgpr_buf_C_address+3], 0, offen offset:0 
;    v_lshl_add_u32 v[vgpr_reuse_tmp_write_dis],s[sgpr_CRS],2,v[vgpr_final_offset]
;    buffer_store_dwordx4 v[vgpr_FMA_value+4:vgpr_FMA_value+7],v[vgpr_reuse_tmp_write_dis], s[sgpr_buf_C_address:sgpr_buf_C_address+3], 0, offen offset:0
;    v_lshl_add_u32 v[vgpr_reuse_tmp_write_dis],s[sgpr_CRS],2,v[vgpr_reuse_tmp_write_dis]
;    buffer_store_dwordx4 v[vgpr_FMA_value+8:vgpr_FMA_value+11],v[vgpr_reuse_tmp_write_dis], s[sgpr_buf_C_address:sgpr_buf_C_address+3], 0, offen offset:0
;    v_lshl_add_u32 v[vgpr_reuse_tmp_write_dis],s[sgpr_CRS],2,v[vgpr_reuse_tmp_write_dis]
;    buffer_store_dwordx4 v[vgpr_FMA_value+12:vgpr_FMA_value+15],v[vgpr_reuse_tmp_write_dis], s[sgpr_buf_C_address:sgpr_buf_C_address+3], 0, offen offset:0
  
    s_waitcnt vmcnt(0)
;    s_mov_b64 exec,s[sgpr_before_cmp_address:sgpr_before_cmp_address+1]



;v[vgpr_crs_global_id]
    ;s_lshl_b32 s[sgpr_tmp_final],s[sgpr_CRS],2;//CRS*4
    ;v_sub_u32 
    ;s_sub_u32 s[sgpr_tmp2_final],s[sgpr_tmp_final],s[sgpr_tmp_final]
    

write_over:
;    s_mov_b64 exec,s[sgpr_before_cmp_address:sgpr_before_cmp_address+1]
    s_waitcnt vmcnt(0);
;//-------------------------------------------------------------------




;    s_load_dwordx4 s[sgpr_matrixK_NOO_address:sgpr_matrixK_NOO_address+3], s[0:1], 0x00;//auxbuf and span
;    s_load_dwordx4 s[sgpr_CRS_group:sgpr_CHW] s[0:1], 0x10
;    s_load_dwordx4 s[sgpr_matrixAB_address:sgpr_matrixAB_address+3], s[0:1], 0x20;//AB
    
;    s_load_dwordx2 s[sgpr_NOO:sgpr_OO], s[0:1], 0x3c;//NOO& OO
;    s_load_dword s[sgpr_NCHW_1_address], s[0:1], 0x44

    

;    v_lshrrev_b32  v8, 6, v0;// 0 0..0|1...1|2...2|3...3 wave id ,will use after
;    v_lshlrev_b32 v2,5,v8;//0 0...0|32 32..32|64 64..64|96 96..96

;    v_readfirstlane_b32 s16,v2;//s14 is noo for every wave

;    v_lshrrev_b32 v[vgpr_block_thread_tile_y], 4, v0;//y=v0/16
;    v_lshlrev_b32 v[vgpr_block_thread_tile_y],4,v[vgpr_block_thread_tile_y];//*4*4due to every thread have 4
;    v_and_b32 v[vgpr_block_thread_tile_x],v0,15;//x=v0%16
;    v_lshlrev_b32 v[vgpr_block_thread_tile_x],4,v[vgpr_block_thread_tile_x]

;    s_mov_b32 s[sgpr_lds_NOO_offset],256
;    s_waitcnt     lgkmcnt(0)


;    s_load_dwordx8 s[sgpr_auxbuf_8:sgpr_auxbuf_8+7], s[sgpr_matrixK_NOO_address:sgpr_matrixK_NOO_address+1], s16
;    v_and_b32     v2, 63, v0;//wave tid,will use after
;    v_lshlrev_b32 v3, 2, v2;//0 4 8...252|0 4 8...252|0 4 8...252|0 4 8...252
;    v_mov_b32 v9,s[sgpr_CRS_64]
;    v_lshl_add_u32 v3,v9,8,v3;//crs id*256+wave tid*4
;    s_waitcnt     lgkmcnt(0)



;    s_mov_b32 s[sgpr_buf_crs_address],s[sgpr_span_address]
;    s_mov_b32 s[sgpr_buf_crs_address+1],s[sgpr_span_address+1]
;    s_lshl_b32    s[sgpr_CRS_1_address], s[sgpr_CRS], 2 
;    s_mov_b32 s[sgpr_buf_crs_address+2],s[sgpr_CRS_1_address]
;    s_mov_b32 s[sgpr_buf_crs_address+3], Srd127_96
;    buffer_load_dword v[vgpr_CRS_value], v3, s[sgpr_buf_crs_address:sgpr_buf_crs_address+3], 0, offen offset:0



;    s_mul_i32 s[sgpr_NKOO_1_address],s[sgpr_NOO],s[sgpr_K]
;    s_lshl_b32  s[sgpr_NKOO_1_address], s[sgpr_NKOO_1_address],2



    






;    s_waitcnt vmcnt(0);
     

;//test buf
;s_add_u32     s[sgpr_buf_A_address], s[sgpr_matrixAB_address], s[sgpr_auxbuf_8]
;s_addc_u32    s[sgpr_buf_A_address+1], s[sgpr_matrixAB_address+1], 0
;s_sub_u32 s[sgpr_buf_A_address+2],s[sgpr_NCHW_1_address],s[sgpr_auxbuf_8]
;s_mov_b32 s[sgpr_buf_A_address+3], Srd127_96
;buffer_load_dword v[vgpr_A_value_4], v[vgpr_CRS_value], s[sgpr_buf_A_address:sgpr_buf_A_address+3], 0, offen offset:0

;s_add_u32     s[sgpr_buf_A_address], s[sgpr_matrixAB_address], s[sgpr_auxbuf_8+2]
;s_addc_u32    s[sgpr_buf_A_address+1], s[sgpr_matrixAB_address+1], 0
;s_sub_u32 s[sgpr_buf_A_address+2],s[sgpr_NCHW_1_address],s[sgpr_auxbuf_8+2]
;buffer_load_dword v[vgpr_A_value_4+1], v[vgpr_CRS_value], s[sgpr_buf_A_address:sgpr_buf_A_address+3], 0, offen offset:0


;s_add_u32     s[sgpr_buf_A_address], s[sgpr_matrixAB_address], s[sgpr_auxbuf_8+4]
;s_addc_u32    s[sgpr_buf_A_address+1], s[sgpr_matrixAB_address+1], 0
;s_sub_u32 s[sgpr_buf_A_address+2],s[sgpr_NCHW_1_address],s[sgpr_auxbuf_8+4]
;buffer_load_dword v[vgpr_A_value_4+2], v[vgpr_CRS_value], s[sgpr_buf_A_address:sgpr_buf_A_address+3], 0, offen offset:0

;s_add_u32     s[sgpr_buf_A_address], s[sgpr_matrixAB_address], s[sgpr_auxbuf_8+6]
;s_addc_u32    s[sgpr_buf_A_address+1], s[sgpr_matrixAB_address+1], 0
;s_sub_u32 s[sgpr_buf_A_address+2],s[sgpr_NCHW_1_address],s[sgpr_auxbuf_8+6]
;buffer_load_dword v[vgpr_A_value_4+3], v[vgpr_CRS_value], s[sgpr_buf_A_address:sgpr_buf_A_address+3], 0, offen offset:0




;//FMA value reset
;    v_mov_b32 v[vgpr_FMA_value],0
;    v_mov_b32 v[vgpr_FMA_value+1],0
;    v_mov_b32 v[vgpr_FMA_value+2],0
;    v_mov_b32 v[vgpr_FMA_value+3],0
;    v_mov_b32 v[vgpr_FMA_value+4],0
;    v_mov_b32 v[vgpr_FMA_value+5],0
;    v_mov_b32 v[vgpr_FMA_value+6],0
;    v_mov_b32 v[vgpr_FMA_value+7],0
;    v_mov_b32 v[vgpr_FMA_value+8],0
;    v_mov_b32 v[vgpr_FMA_value+9],0
;    v_mov_b32 v[vgpr_FMA_value+10],0
;    v_mov_b32 v[vgpr_FMA_value+11],0
;    v_mov_b32 v[vgpr_FMA_value+12],0
;    v_mov_b32 v[vgpr_FMA_value+13],0
;    v_mov_b32 v[vgpr_FMA_value+14],0
;    v_mov_b32 v[vgpr_FMA_value+15],0

;//FMA value reset over
;    s_waitcnt vmcnt(0);//load A ok



;test buf end




;    v_lshlrev_b32 v9,10,v8;//waveid*16*64
;read
;A          aux1
;  tid wave0   wave1  2   3   next noo
;      ____________________|____
;   16 |     |     |    |     |
;   32 |                      |
;   48 |                      |
;   64 |______________________|
;next  |
;crs
;   16
;//[NOO][64] store to lds,down sore
    ;//wave id *16*64+wave tid*4
    

;    v_lshl_add_u32 v10,v2,2,v9;//wave tid*4+waveid*16*64
;    ds_write_b32  v10, v[vgpr_A_value_4]

;    ds_write_b32  v10, v[vgpr_A_value_4+1] offset:256

;    ds_write_b32  v10, v[vgpr_A_value_4+2] offset:512

;    ds_write_b32  v10, v[vgpr_A_value_4+3] offset:768

;    s_waitcnt     lgkmcnt(0)




;//but store to lds,down sore to help load conti after
;   ________________ 
;   |0 256    |64*16  
;   |4 260
;   |8
;   |12_____________
;

;B 
;                 64     
;          _______________________next k
;wave0    |______________________|
;wave1    |______________________|
;wave2    |______________________|
;wave3    |______________________|
;16       |      
;        next noo
;        aux2 

    ;//v11 ----------------------------->K*o*o
;    v_lshl_add_u32 v12,s[sgpr_K_64],6,v2;//k_64*64+wave tid global k
    ;//find 0-63 koo
;    v_mul_lo_u32 v11,v12,s[sgpr_OO]

    ;//MatrixN  max is KOO-1
;    s_or_saveexec_b64 s[sgpr_before_cmp_address:sgpr_before_cmp_address+1],exec
;    v_cmpx_ge_u32  s[sgpr_cmp_tmp_address:sgpr_cmp_tmp_address+1], v12, s[sgpr_K]
;    v_mov_b32 v12,s[sgpr_K]
;    v_mul_lo_u32 v11,v12,s[sgpr_OO]
;    v_sub_u32 v11,v11,1
;    s_mov_b64 exec,s[sgpr_before_cmp_address:sgpr_before_cmp_address+1]
    

;    v_lshlrev_b32 v11,2,v11;//koo*4



    ;YOU NEED TO TRY LOAD 4 AFTER
;//HERE
;s_add_u32     s[sgpr_buf_B_address], s[sgpr_matrixB_start_address], s[sgpr_auxbuf_8+1]
;s_addc_u32    s[sgpr_buf_B_address+1], s[sgpr_matrixB_start_address+1], 0
;s_sub_u32 s[sgpr_buf_B_address+2],s[sgpr_NKOO_1_address],s[sgpr_auxbuf_8+1]
;s_mov_b32 s[sgpr_buf_B_address+3], Srd127_96

;//HERE END




;    s_sub_u32 s[sgpr_B_load_judge],s[sgpr_auxbuf_8+7],s[sgpr_auxbuf_8+1]
;//need add
;    s_cmp_eq_u32  s[sgpr_B_load_judge], 12
;    s_cbranch_scc1  B_conti_read


;    buffer_load_dword v[vgpr_B_value_4], v[11], s[sgpr_buf_B_address:sgpr_buf_B_address+3], 0, offen offset:0

 
;s_add_u32     s[sgpr_buf_B_address], s[sgpr_matrixB_start_address], s[sgpr_auxbuf_8+3]
;s_addc_u32    s[sgpr_buf_B_address+1], s[sgpr_matrixB_start_address+1], 0
;s_sub_u32 s[sgpr_buf_B_address+2],s[sgpr_NKOO_1_address],s[sgpr_auxbuf_8+3]
;buffer_load_dword v[vgpr_B_value_4+1], v[11], s[sgpr_buf_B_address:sgpr_buf_B_address+3], 0, offen offset:0




;s_add_u32     s[sgpr_buf_B_address], s[sgpr_matrixB_start_address], s[sgpr_auxbuf_8+5]
;s_addc_u32    s[sgpr_buf_B_address+1], s[sgpr_matrixB_start_address+1], 0
;s_sub_u32 s[sgpr_buf_B_address+2],s[sgpr_NKOO_1_address],s[sgpr_auxbuf_8+5]
;buffer_load_dword v[vgpr_B_value_4+2], v[11], s[sgpr_buf_B_address:sgpr_buf_B_address+3], 0, offen offset:0





;s_add_u32     s[sgpr_buf_B_address], s[sgpr_matrixB_start_address], s[sgpr_auxbuf_8+7]
;s_addc_u32    s[sgpr_buf_B_address+1], s[sgpr_matrixB_start_address+1], 0
;s_sub_u32 s[sgpr_buf_B_address+2],s[sgpr_NKOO_1_address],s[sgpr_auxbuf_8+7]
;buffer_load_dword v[vgpr_B_value_4+3], v[11], s[sgpr_buf_B_address:sgpr_buf_B_address+3], 0, offen offset:0




;    s_branch after_read_B
;//BELOW IS TEST


;B_conti_read:
;//NOO must %4=0 or global_load_dwordx4 may read 0
;    buffer_load_dwordx4 v[vgpr_B_value_4:vgpr_B_value_4+3], v[11], s[sgpr_buf_B_address:sgpr_buf_B_address+3], 0, offen offset:0




;after_read_B:

;    s_waitcnt     vmcnt(0)
;//[NOO][64] store to lds,store right
;_________________________________
;   |0 4 ...                 252 |
;   |256                         |
;   |..         wave0            |
;   |__________________________
;   |64*16 ......
;
;LDS SIZE:
;A1       A2       B1        B2
;64*16*4  64*16*4  64*16*4   64*16*4
;

;ds_write_b32  v10, v[vgpr_B_value_4] offset:8192
;ds_write_b32  v10, v[vgpr_B_value_4+1] offset:8192+256
;ds_write_b32  v10, v[vgpr_B_value_4+2] offset:8192+512
;ds_write_b32  v10, v[vgpr_B_value_4+3] offset:8192+768

;s_waitcnt     lgkmcnt(0)
;   ---->x
;|   _1.2,____
;|   |1 2|   56 1.            load 13    load 24
;|   |3 4|   78 2.    load56 
;y                    load78
;
;loop1:13&56 
;   1*5   1*6      x0y0:A[y]B[x]   x1y0
;   3*5   3*6      x0y1            x1y1
;      +
;loop2:24&78   
;   2*7   2*8
;   4*7   4*8
;
;   for (loop)<=matrik
;        for(x)      
;           for(y)
;             sum[x][y]+=A[y]B[x] col-base due to CRS is col K is row


;thread0 A0B0 thread1 A0B1 thread16 A1B0 thread17 A1B1
;NOO 0:loop0
;


;v_mov_b32 v[vgpr_lds_A_offset],v[vgpr_block_thread_tile_y]
;v_mov_b32 v[vgpr_lds_B_offset],v[vgpr_block_thread_tile_x]
;ds_read_b128  v[vgpr_thread_A_4:vgpr_thread_A_4+3], v[vgpr_lds_A_offset] offset:0
;ds_read_b128  v[vgpr_thread_B_4:vgpr_thread_B_4+3],v[vgpr_lds_B_offset] offset:8192

;s_waitcnt     lgkmcnt(0)
;//v_fmac_f32    
;v_fma_f32    v[vgpr_FMA_value], v[vgpr_thread_A_4], v[vgpr_thread_B_4],v[vgpr_FMA_value]
;v_fma_f32    v[vgpr_FMA_value+1], v[vgpr_thread_A_4], v[vgpr_thread_B_4+1],v[vgpr_FMA_value+1]
;v_fma_f32    v[vgpr_FMA_value+2], v[vgpr_thread_A_4], v[vgpr_thread_B_4+2],v[vgpr_FMA_value+2]
;v_fma_f32    v[vgpr_FMA_value+3], v[vgpr_thread_A_4], v[vgpr_thread_B_4+3],v[vgpr_FMA_value+3]
;v_fma_f32    v[vgpr_FMA_value+4], v[vgpr_thread_A_4+1], v[vgpr_thread_B_4],v[vgpr_FMA_value+4]
;v_fma_f32    v[vgpr_FMA_value+5], v[vgpr_thread_A_4+1], v[vgpr_thread_B_4+1],v[vgpr_FMA_value+5]
;v_fma_f32    v[vgpr_FMA_value+6], v[vgpr_thread_A_4+1], v[vgpr_thread_B_4+2],v[vgpr_FMA_value+6]
;v_fma_f32    v[vgpr_FMA_value+7], v[vgpr_thread_A_4+1], v[vgpr_thread_B_4+3],v[vgpr_FMA_value+7]
;v_fma_f32    v[vgpr_FMA_value+8], v[vgpr_thread_A_4+2], v[vgpr_thread_B_4],v[vgpr_FMA_value+8]
;v_fma_f32    v[vgpr_FMA_value+9], v[vgpr_thread_A_4+2], v[vgpr_thread_B_4+1],v[vgpr_FMA_value+9]
;v_fma_f32    v[vgpr_FMA_value+10], v[vgpr_thread_A_4+2], v[vgpr_thread_B_4+2],v[vgpr_FMA_value+10]
;v_fma_f32    v[vgpr_FMA_value+11], v[vgpr_thread_A_4+2], v[vgpr_thread_B_4+3],v[vgpr_FMA_value+11]
;v_fma_f32    v[vgpr_FMA_value+12], v[vgpr_thread_A_4+3], v[vgpr_thread_B_4],v[vgpr_FMA_value+12]
;v_fma_f32    v[vgpr_FMA_value+13], v[vgpr_thread_A_4+3], v[vgpr_thread_B_4+1],v[vgpr_FMA_value+13]
;v_fma_f32    v[vgpr_FMA_value+14], v[vgpr_thread_A_4+3], v[vgpr_thread_B_4+2],v[vgpr_FMA_value+14]
;v_fma_f32    v[vgpr_FMA_value+15], v[vgpr_thread_A_4+3], v[vgpr_thread_B_4+3],v[vgpr_FMA_value+15]
;//NOO LOOP 1
;v_add_u32 v[vgpr_lds_A_offset],v[vgpr_lds_A_offset],s[sgpr_lds_NOO_offset];//64*4 
;v_add_u32 v[vgpr_lds_B_offset],v[vgpr_lds_B_offset],s[sgpr_lds_NOO_offset]

;ds_read_b128  v[vgpr_thread_A_4:vgpr_thread_A_4+3], v[vgpr_lds_A_offset] offset:0
;ds_read_b128  v[vgpr_thread_B_4:vgpr_thread_B_4+3],v[vgpr_lds_B_offset] offset:8192
;s_waitcnt     lgkmcnt(0)
;v_fma_f32    v[vgpr_FMA_value], v[vgpr_thread_A_4], v[vgpr_thread_B_4],v[vgpr_FMA_value]
;v_fma_f32    v[vgpr_FMA_value+1], v[vgpr_thread_A_4], v[vgpr_thread_B_4+1],v[vgpr_FMA_value+1]
;v_fma_f32    v[vgpr_FMA_value+2], v[vgpr_thread_A_4], v[vgpr_thread_B_4+2],v[vgpr_FMA_value+2]
;v_fma_f32    v[vgpr_FMA_value+3], v[vgpr_thread_A_4], v[vgpr_thread_B_4+3],v[vgpr_FMA_value+3]
;v_fma_f32    v[vgpr_FMA_value+4], v[vgpr_thread_A_4+1], v[vgpr_thread_B_4],v[vgpr_FMA_value+4]
;v_fma_f32    v[vgpr_FMA_value+5], v[vgpr_thread_A_4+1], v[vgpr_thread_B_4+1],v[vgpr_FMA_value+5]
;v_fma_f32    v[vgpr_FMA_value+6], v[vgpr_thread_A_4+1], v[vgpr_thread_B_4+2],v[vgpr_FMA_value+6]
;v_fma_f32    v[vgpr_FMA_value+7], v[vgpr_thread_A_4+1], v[vgpr_thread_B_4+3],v[vgpr_FMA_value+7]
;v_fma_f32    v[vgpr_FMA_value+8], v[vgpr_thread_A_4+2], v[vgpr_thread_B_4],v[vgpr_FMA_value+8]
;v_fma_f32    v[vgpr_FMA_value+9], v[vgpr_thread_A_4+2], v[vgpr_thread_B_4+1],v[vgpr_FMA_value+9]
;v_fma_f32    v[vgpr_FMA_value+10], v[vgpr_thread_A_4+2], v[vgpr_thread_B_4+2],v[vgpr_FMA_value+10]
;v_fma_f32    v[vgpr_FMA_value+11], v[vgpr_thread_A_4+2], v[vgpr_thread_B_4+3],v[vgpr_FMA_value+11]
;v_fma_f32    v[vgpr_FMA_value+12], v[vgpr_thread_A_4+3], v[vgpr_thread_B_4],v[vgpr_FMA_value+12]
;v_fma_f32    v[vgpr_FMA_value+13], v[vgpr_thread_A_4+3], v[vgpr_thread_B_4+1],v[vgpr_FMA_value+13]
;v_fma_f32    v[vgpr_FMA_value+14], v[vgpr_thread_A_4+3], v[vgpr_thread_B_4+2],v[vgpr_FMA_value+14]
;v_fma_f32    v[vgpr_FMA_value+15], v[vgpr_thread_A_4+3], v[vgpr_thread_B_4+3],v[vgpr_FMA_value+15]







;    s_add_u32     s[sgpr_B_address_4], s[sgpr_matrixB_start_address], s[sgpr_auxbuf_8+6]
;sgpr_matrixB_start_address

    ;//auxbuf1 
    
    ;s_load_dwordx2  s[sgpr_matrixK_NOO_address:sgpr_matrixK_NOO_address+1], s[0:1], 0x00 ;//auxbuf 
    ;s_load_dwordx2  s[sgpr_span_address:sgpr_span_address+1], s[0:1], 0x08;//span
    ;s_load_dwordx4  s[8:11], s[0:1], 0x10
    ;s_load_dwordx4 s[sgpr_matrixAB_address:sgpr_matrixAB_address+3], s[0:1], 0x20
    





;//read crs 
;    v_and_b32     v1, 63, v0;//tid in wave 0 1 ...63| 0 1...63| 0 1...63| 0 1...63
;    v_lshl_or_b32  v3, s3, 6, v1;//s3:gdx v4=crs id
;    v_lshlrev_b32  v3, 2, v3
    ;v_mov_b32 v3,0
;    global_load_dword  v4, v[3:4], s[sgpr_span_address:sgpr_span_address+1]



;    v_lshrrev_b32  v2, 6, v0;// 0 0..0|1...1|2...2|3...3
;    v_lshlrev_b32 v2,5,v2;fisrt noo =0 32 64 96----->horizontal,next you need add 16
;    v_readfirstlane_b32 s14,v2;//s14 is noo for every wave

;    s_waitcnt     vmcnt(0)

;//read aux A0B0A1B1
;    s_load_dwordx8  s[sgpr_auxbuf_8:sgpr_auxbuf_8+7], s[sgpr_matrixK_NOO_address:sgpr_matrixK_NOO_address+1], s14
;    s_waitcnt     lgkmcnt(0)
 ;   s_lshl_b32    s[sgpr_auxbuf_8], s[sgpr_auxbuf_8], 2

;    s_add_u32     s[sgpr_noo_4], s[sgpr_matrixAB_address], s[sgpr_auxbuf_8]
;    s_addc_u32    s[sgpr_noo_4+1], s[sgpr_matrixAB_address+1], 0
;    global_load_dword v6,v[4:5],s[sgpr_noo_4:sgpr_noo_4+1]

    ;s_add_u32     s[sgpr_noo_4], s[sgpr_matrixAB_address], s[sgpr_auxbuf_8]
    ;s_addc_u32    s[sgpr_noo_4+1], s[sgpr_matrixAB_address+1], 0
    ;global_load_dword v7,v[4:5],s[sgpr_noo_4:sgpr_noo_4+1]



;    s_mov_b32 s[sgpr_noo_4],s[sgpr_auxbuf_8]
;    s_mov_b32 s[sgpr_noo_4+1],0
;    s_sub_u32 s15,s22,s16;//if ==12 conti,if not ,not cont



;    s_cmp_eq_u32 s15,12
;    s_cbranch_scc1 A_conti_read 

    


;A_not_cont_read:
    
;    s_branch after_A_read
;A_conti_read:
   
    ;s_mov_b32 s[sgpr_auxbuf_8],0 
    ;s_add_u32     s[sgpr_noo_4], s[sgpr_matrixAB_address], s[sgpr_auxbuf_8]
    ;s_addc_u32    s[sgpr_noo_4+1], s[sgpr_matrixAB_address+1], 0  

    ;global_load_dwordx4 v[8:11],v[4:5],s[sgpr_noo_4:sgpr_noo_4+1]
    
;after_A_read:


    ;v_and_b32     v1, 63, v0;//thread id in wave


;    s_load_dwordx8  s[14:21], s[4:5], s2

;v_lshlrev_b32  v4, 2, v0
;global_load_dword  v3, v[4:5], s[sgpr_matrixK_NOO_address:sgpr_matrixK_NOO_address+1]

;if NOO%N=>OO





;    s_mov_b32 s[sgpr_span_address+2], 0x80000000
    ;s_cselect_b32 s[sgpr_span_address+2], s[sgprShadowLimitA+0], BufferLimi
;    s_mov_b32 s[sgpr_span_address+3], Srd127_96 

;buffer_load_dword v[vgpr_crsId], v4, s[sgpr_span_address:sgpr_span_address+3], 0, offen offset:0

;global_load_dword  v3, v[4:5], s[12:13]

;v_mov_b32 


;    v_and_b32     v1, 15, v0;//distinguish to 0-15 ,4 groups 
                            ;//       16   32     48
;    v_lshrrev_b32  v2, 4, v0;// 0 0..0|1...1|2...2|3...3
;    v_and_b32     v3, 3, v0;//0 1 2 3|0 1 2 3|....0 1 2 3  
;    v_lshrrev_b32  v4, 2, v0;// 0 0 0 0| 1 1 1 1 |......15 15 15 15




;    v_lshl_or_b32  v51, s3, 6, v0;//s3:gdx v51=crs id  CRS_64 ,forward is NOO id
;    v_lshl_or_b32  v5, s2, 4, v4;//s2:gdy v5=K_64*16+V4 0 0 0 0| 1 1 1 1 |......15 15 15 15 ,if gdy=1 64 64 64 64| 65 65 65 65|....89 89 89 89






;    v_lshlrev_b32  v6, 3, v51;//crs*8,forward is noo*8
;    s_waitcnt     lgkmcnt(0)
;    global_load_dwordx2  v[42:43], v[6:7], s[4:5]







;    s_mov_b32 s[sgpr_buf_crs_address],s[sgpr_span_address]
;    s_mov_b32 s[sgpr_buf_crs_address+1],s[sgpr_span_address+1]
;    s_lshl_b32    s[sgpr_CRS_1_address], s[sgpr_CRS], 2 
;    s_mov_b32 s[sgpr_buf_crs_address+2],0x800000
;    s_mov_b32 s[sgpr_buf_crs_address+3], Srd127_96
;v_mov_b32 v3,4
;    buffer_load_dword v5, v3, s[sgpr_buf_crs_address:sgpr_buf_crs_address+3], 0, offen offset:0


s_cmp_eq_u32  s[sgpr_splitK_idx], 0


s_cbranch_scc0 xxxx
s_cmp_eq_u32  s[sgpr_CRS_64], 0
s_cbranch_scc0 xxxx


;v_mov_b32 v10,v[vgpr_lds_A_offset]
;ds_read_b128  v[vgpr_thread_A_4:vgpr_thread_A_4+3], v[vgpr_lds_A_offset] offset:0
;ds_read_b32 v60,v10 offset:0
;ds_read_b128  v[vgpr_thread_A_4:vgpr_thread_A_4+3], v10 offset:0


;//sgpr_matrixC_start_address

       s_load_dwordx2 s[36:37], s[0:1], 0x50
       s_waitcnt     lgkmcnt(0) vmcnt(0)
       v_lshlrev_b32 v124, 2, v0
       v_mov_b32 v126,s[sgpr_auxbuf_8+4]
       ;v_mov_b32 v122,20.0
       ;global_store_dword  v[124:125], v[vgpr_thread_A_4], s[36:37]
;//v[vgpr_lds_A_offset]

;global_store_dword  v[124:125], v[vgpr_block_thread_tile_y], s[36:37]
;global_store_dword  v[124:125], v[vgpr_thread_A_4], s[36:37]
;global_store_dword  v[124:125], v[vgpr_B_value_4+2], s[36:37]
global_store_dword  v[124:125], v126, s[36:37]

       s_waitcnt     vmcnt(0)
        ;//kevin end
xxxx:





    s_endpgm
.Lfunc_end0:
        .size   back_weights, .Lfunc_end0-back_weights
















