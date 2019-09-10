        .hsa_code_object_version 2,1
        .hsa_code_object_isa 9,0,6,"AMD","AMDGPU"
        .p2align        8
        .type   split_add,@function
        .amdgpu_hsa_kernel split_add
split_add:
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
                granulated_wavefront_sgpr_count = 2;(s+3)+8-1/8-1
                granulated_workitem_vgpr_count = 15;(v+4-1)/4-1
                wavefront_sgpr_count = 24;sgpr+3
                workitem_vgpr_count = 64
                workgroup_group_segment_byte_size = 32768;//LDS size
                enable_sgpr_workgroup_id_x = 1;s2
                enable_sgpr_workgroup_id_y = 1;s3
                enable_sgpr_workgroup_id_z = 1;s4
        .end_amd_kernel_code_t

;//hipModuleLaunchKernel(Function_add,K_8,CRS_32,1,Threads_Size_add,1,1,0,0,NULL,(void**)&config_add);
;    struct {
;       void* matrixC;//0x00 
;       void* final_matrixC;//0x08
;       unsigned int KCRS;//0x10
;       unsigned int CRS;//0X14
;       void* test;//0x18
;       void* second_test;//0x20

;    } args_add;


.set sgpr_K_8, 2
.set sgpr_CRS_32,3
.set sgpr_Matrix_address,4;//4 5
.set sgpr_final_Matrix_address,6;//6 7

.set sgpr_KCRS,8
.set sgpr_CRS,9
.set sgpr_block_start_address,10;//10 11
.set sgpr_load_address,12 ;//12 13 14 15

.set sgpr_block_start_offset,16
.set Srd127_96, 0x0020000

.set sgpr_kcrs_tmp,17
.set sgpr_kcrs_x4,18
;.set sgpr_write_limit,19
.set sgpr_write_address,20;//20 21 22 23

.set vgpr_k_local_idx,1
.set vgpr_crs_local_idx,2
.set vgpr_total_local_offset,3
.set vgpr_k_local_offset,4
.set vgpr_write_local_offset,5

.set vgpr_1_last,8;//8 9 10 11
.set vgpr_1_tmp1,12;//12 13 14 15
.set vgpr_1_tmp2,16
.set vgpr_1_tmp3,20

.set vgpr_2_last,24;
.set vgpr_2_tmp1,28;
.set vgpr_2_tmp2,32
.set vgpr_2_tmp3,36

.set vgpr_3_last,40;
.set vgpr_3_tmp1,44;
.set vgpr_3_tmp2,48
.set vgpr_3_tmp3,52


.set vgpr_4_last,56;
.set vgpr_4_tmp1,60;
.set vgpr_4_tmp2,12
.set vgpr_4_tmp3,16



;.set vgpr_2_last,8
;        8 K
;    |------- |
;    |t0       |  down load        
;    |t1       |  every thread load 4     
;32  |         |        
;CRS |         |  
;    |t7       |
;    |--------|
;    first second
;


; for 16 block
;every 4 block add first to save vgpr
;           last
;
;   last           tmp2
;
; last  tmp1   tmp2   tmp3
;
;you need (1+1+1+4)*4 vgpr
;read 1 2 3 4
;add 1 2 3 4 read 5 6 7 8
;add 5 6 7 8 read 9 10 11 12
;push 5 to 2
;add 9 10 11 12  read 5 6 7 8
;push 9 to 3
;add 5 6 7 8
;add 1 2 3 5 
;above need *4 due to every thread handle 4



    s_load_dwordx4 s[sgpr_Matrix_address:sgpr_Matrix_address+3],s[0:1],0x00;//
    s_load_dwordx2   s[sgpr_KCRS:sgpr_CRS],s[0:1],0x10



    v_lshrrev_b32  v[vgpr_k_local_idx], 3,v0;// v0/8
    v_and_b32 v[vgpr_crs_local_idx],v0,7;//x=v0%8
    v_lshlrev_b32 v[vgpr_crs_local_idx],2,v[vgpr_crs_local_idx]

    s_waitcnt     lgkmcnt(0)

    s_lshl_b32 s[sgpr_kcrs_x4],s[sgpr_KCRS],2
    s_lshl_b32  s[sgpr_block_start_offset], s[sgpr_K_8], 5;//8*CRS*4
    s_mul_i32 s[sgpr_block_start_offset], s[sgpr_block_start_offset], s[sgpr_CRS]

    s_lshl_b32 s[sgpr_kcrs_tmp], s[sgpr_CRS_32],7;//32*4
    s_add_u32 s[sgpr_block_start_offset], s[sgpr_block_start_offset],s[sgpr_kcrs_tmp];//k_8*8*CRS*4+crs_32*32*4    


    v_lshlrev_b32 v[vgpr_k_local_offset],2,v[vgpr_k_local_idx]   ;//k*CRS*4
    v_mul_lo_u32 v[vgpr_k_local_offset],v[vgpr_k_local_offset],s[sgpr_CRS]
    v_lshl_add_u32 v[vgpr_total_local_offset],v[vgpr_crs_local_idx],2,v[vgpr_k_local_offset];//




;//block 0 -15 this is block 0
    s_add_u32     s[sgpr_block_start_address], s[sgpr_Matrix_address], s[sgpr_block_start_offset]
    s_addc_u32    s[sgpr_block_start_address+1], s[sgpr_Matrix_address+1], 0

    s_mov_b32 s[sgpr_load_address+0],s[sgpr_block_start_address]
    s_mov_b32 s[sgpr_load_address+1],s[sgpr_block_start_address+1]


    s_add_u32 s[sgpr_write_address], s[sgpr_final_Matrix_address], s[sgpr_block_start_offset]
    s_addc_u32 s[sgpr_write_address+1], s[sgpr_final_Matrix_address+1],0


    ;//CRS*7*4+32*4
    s_mul_i32 s[sgpr_load_address+2],s[sgpr_CRS],28
    s_add_u32 s[sgpr_load_address+2],s[sgpr_load_address+2],128
    ;s_mov_b32 s[sgpr_load_address+2],0x800000
    s_mov_b32 s[sgpr_load_address+3], Srd127_96
    buffer_load_dwordx4 v[vgpr_1_last:vgpr_1_last+3], v[vgpr_total_local_offset], s[sgpr_load_address:sgpr_load_address+3], 0, offen offset:0

    v_mov_b32 v[vgpr_write_local_offset],v[vgpr_total_local_offset];//save offset ,use when write
    s_mov_b32 s[sgpr_write_address+2],s[sgpr_load_address+2];//save limit ,use when write
    s_mov_b32 s[sgpr_write_address+3], Srd127_96

    v_add_u32 v[vgpr_total_local_offset],v[vgpr_total_local_offset],s[sgpr_kcrs_x4]
    s_add_u32 s[sgpr_load_address+2],s[sgpr_load_address+2],s[sgpr_kcrs_x4]
    buffer_load_dwordx4 v[vgpr_1_tmp1:vgpr_1_tmp1+3], v[vgpr_total_local_offset], s[sgpr_load_address:sgpr_load_address+3], 0, offen offset:0

    v_add_u32 v[vgpr_total_local_offset],v[vgpr_total_local_offset],s[sgpr_kcrs_x4]
    s_add_u32 s[sgpr_load_address+2],s[sgpr_load_address+2],s[sgpr_kcrs_x4]
    buffer_load_dwordx4 v[vgpr_1_tmp2:vgpr_1_tmp2+3], v[vgpr_total_local_offset], s[sgpr_load_address:sgpr_load_address+3], 0, offen offset:0
 
    v_add_u32 v[vgpr_total_local_offset],v[vgpr_total_local_offset],s[sgpr_kcrs_x4]
    s_add_u32 s[sgpr_load_address+2],s[sgpr_load_address+2],s[sgpr_kcrs_x4]
    buffer_load_dwordx4 v[vgpr_1_tmp3:vgpr_1_tmp3+3], v[vgpr_total_local_offset], s[sgpr_load_address:sgpr_load_address+3], 0, offen offset:0
 

    s_waitcnt vmcnt(0);

    v_add_u32 v[vgpr_total_local_offset],v[vgpr_total_local_offset],s[sgpr_kcrs_x4]
    s_add_u32 s[sgpr_load_address+2],s[sgpr_load_address+2],s[sgpr_kcrs_x4]
    buffer_load_dwordx4 v[vgpr_2_last:vgpr_2_last+3], v[vgpr_total_local_offset], s[sgpr_load_address:sgpr_load_address+3], 0, offen offset:0

    v_add_u32 v[vgpr_total_local_offset],v[vgpr_total_local_offset],s[sgpr_kcrs_x4]
    s_add_u32 s[sgpr_load_address+2],s[sgpr_load_address+2],s[sgpr_kcrs_x4]
    buffer_load_dwordx4 v[vgpr_2_tmp1:vgpr_2_tmp1+3], v[vgpr_total_local_offset], s[sgpr_load_address:sgpr_load_address+3], 0, offen offset:0

    v_add_u32 v[vgpr_total_local_offset],v[vgpr_total_local_offset],s[sgpr_kcrs_x4]
    s_add_u32 s[sgpr_load_address+2],s[sgpr_load_address+2],s[sgpr_kcrs_x4]
    buffer_load_dwordx4 v[vgpr_2_tmp2:vgpr_2_tmp2+3], v[vgpr_total_local_offset], s[sgpr_load_address:sgpr_load_address+3], 0, offen offset:0

    v_add_u32 v[vgpr_total_local_offset],v[vgpr_total_local_offset],s[sgpr_kcrs_x4]
    s_add_u32 s[sgpr_load_address+2],s[sgpr_load_address+2],s[sgpr_kcrs_x4]
    buffer_load_dwordx4 v[vgpr_2_tmp3:vgpr_2_tmp3+3], v[vgpr_total_local_offset], s[sgpr_load_address:sgpr_load_address+3], 0, offen offset:0


    ;s_waitcnt vmcnt(0);

    v_add_f32 v[vgpr_1_last],v[vgpr_1_last],v[vgpr_1_tmp1]
    v_add_f32 v[vgpr_1_last+1],v[vgpr_1_last+1],v[vgpr_1_tmp1+1]
    v_add_f32 v[vgpr_1_last+2],v[vgpr_1_last+2],v[vgpr_1_tmp1+2]
    v_add_f32 v[vgpr_1_last+3],v[vgpr_1_last+3],v[vgpr_1_tmp1+3]


    v_add_f32 v[vgpr_1_last],v[vgpr_1_last],v[vgpr_1_tmp2]
    v_add_f32 v[vgpr_1_last+1],v[vgpr_1_last+1],v[vgpr_1_tmp2+1]
    v_add_f32 v[vgpr_1_last+2],v[vgpr_1_last+2],v[vgpr_1_tmp2+2]
    v_add_f32 v[vgpr_1_last+3],v[vgpr_1_last+3],v[vgpr_1_tmp2+3]


    v_add_f32 v[vgpr_1_last],v[vgpr_1_last],v[vgpr_1_tmp3]
    v_add_f32 v[vgpr_1_last+1],v[vgpr_1_last+1],v[vgpr_1_tmp3+1]
    v_add_f32 v[vgpr_1_last+2],v[vgpr_1_last+2],v[vgpr_1_tmp3+2]
    v_add_f32 v[vgpr_1_last+3],v[vgpr_1_last+3],v[vgpr_1_tmp3+3]

    s_waitcnt vmcnt(0);

    v_add_u32 v[vgpr_total_local_offset],v[vgpr_total_local_offset],s[sgpr_kcrs_x4]
    s_add_u32 s[sgpr_load_address+2],s[sgpr_load_address+2],s[sgpr_kcrs_x4]
    buffer_load_dwordx4 v[vgpr_3_last:vgpr_3_last+3], v[vgpr_total_local_offset], s[sgpr_load_address:sgpr_load_address+3], 0, offen offset:0

    v_add_u32 v[vgpr_total_local_offset],v[vgpr_total_local_offset],s[sgpr_kcrs_x4]
    s_add_u32 s[sgpr_load_address+2],s[sgpr_load_address+2],s[sgpr_kcrs_x4]
    buffer_load_dwordx4 v[vgpr_3_tmp1:vgpr_3_tmp1+3], v[vgpr_total_local_offset], s[sgpr_load_address:sgpr_load_address+3], 0, offen offset:0

    v_add_u32 v[vgpr_total_local_offset],v[vgpr_total_local_offset],s[sgpr_kcrs_x4]
    s_add_u32 s[sgpr_load_address+2],s[sgpr_load_address+2],s[sgpr_kcrs_x4]
    buffer_load_dwordx4 v[vgpr_3_tmp2:vgpr_3_tmp2+3], v[vgpr_total_local_offset], s[sgpr_load_address:sgpr_load_address+3], 0, offen offset:0

    v_add_u32 v[vgpr_total_local_offset],v[vgpr_total_local_offset],s[sgpr_kcrs_x4]
    s_add_u32 s[sgpr_load_address+2],s[sgpr_load_address+2],s[sgpr_kcrs_x4]
    buffer_load_dwordx4 v[vgpr_3_tmp3:vgpr_3_tmp3+3], v[vgpr_total_local_offset], s[sgpr_load_address:sgpr_load_address+3], 0, offen offset:0



    v_add_f32 v[vgpr_2_last],v[vgpr_2_last],v[vgpr_2_tmp1]
    v_add_f32 v[vgpr_2_last+1],v[vgpr_2_last+1],v[vgpr_2_tmp1+1]
    v_add_f32 v[vgpr_2_last+2],v[vgpr_2_last+2],v[vgpr_2_tmp1+2]
    v_add_f32 v[vgpr_2_last+3],v[vgpr_2_last+3],v[vgpr_2_tmp1+3]


    v_add_f32 v[vgpr_2_last],v[vgpr_2_last],v[vgpr_2_tmp2]
    v_add_f32 v[vgpr_2_last+1],v[vgpr_2_last+1],v[vgpr_2_tmp2+1]
    v_add_f32 v[vgpr_2_last+2],v[vgpr_2_last+2],v[vgpr_2_tmp2+2]
    v_add_f32 v[vgpr_2_last+3],v[vgpr_2_last+3],v[vgpr_2_tmp2+3]


    v_add_f32 v[vgpr_2_last],v[vgpr_2_last],v[vgpr_2_tmp3]
    v_add_f32 v[vgpr_2_last+1],v[vgpr_2_last+1],v[vgpr_2_tmp3+1]
    v_add_f32 v[vgpr_2_last+2],v[vgpr_2_last+2],v[vgpr_2_tmp3+2]
    v_add_f32 v[vgpr_2_last+3],v[vgpr_2_last+3],v[vgpr_2_tmp3+3]

    s_waitcnt vmcnt(0);

    v_add_u32 v[vgpr_total_local_offset],v[vgpr_total_local_offset],s[sgpr_kcrs_x4]
    s_add_u32 s[sgpr_load_address+2],s[sgpr_load_address+2],s[sgpr_kcrs_x4]
    buffer_load_dwordx4 v[vgpr_4_last:vgpr_4_last+3], v[vgpr_total_local_offset], s[sgpr_load_address:sgpr_load_address+3], 0, offen offset:0

    v_add_u32 v[vgpr_total_local_offset],v[vgpr_total_local_offset],s[sgpr_kcrs_x4]
    s_add_u32 s[sgpr_load_address+2],s[sgpr_load_address+2],s[sgpr_kcrs_x4]
    buffer_load_dwordx4 v[vgpr_4_tmp1:vgpr_4_tmp1+3], v[vgpr_total_local_offset], s[sgpr_load_address:sgpr_load_address+3], 0, offen offset:0

    v_add_u32 v[vgpr_total_local_offset],v[vgpr_total_local_offset],s[sgpr_kcrs_x4]
    s_add_u32 s[sgpr_load_address+2],s[sgpr_load_address+2],s[sgpr_kcrs_x4]
    buffer_load_dwordx4 v[vgpr_4_tmp2:vgpr_4_tmp2+3], v[vgpr_total_local_offset], s[sgpr_load_address:sgpr_load_address+3], 0, offen offset:0

    v_add_u32 v[vgpr_total_local_offset],v[vgpr_total_local_offset],s[sgpr_kcrs_x4]
    s_add_u32 s[sgpr_load_address+2],s[sgpr_load_address+2],s[sgpr_kcrs_x4]
    buffer_load_dwordx4 v[vgpr_4_tmp3:vgpr_4_tmp3+3], v[vgpr_total_local_offset], s[sgpr_load_address:sgpr_load_address+3], 0, offen offset:0





    v_add_f32 v[vgpr_3_last],v[vgpr_3_last],v[vgpr_3_tmp1]
    v_add_f32 v[vgpr_3_last+1],v[vgpr_3_last+1],v[vgpr_3_tmp1+1]
    v_add_f32 v[vgpr_3_last+2],v[vgpr_3_last+2],v[vgpr_3_tmp1+2]
    v_add_f32 v[vgpr_3_last+3],v[vgpr_3_last+3],v[vgpr_3_tmp1+3]


    v_add_f32 v[vgpr_3_last],v[vgpr_3_last],v[vgpr_3_tmp2]
    v_add_f32 v[vgpr_3_last+1],v[vgpr_3_last+1],v[vgpr_3_tmp2+1]
    v_add_f32 v[vgpr_3_last+2],v[vgpr_3_last+2],v[vgpr_3_tmp2+2]
    v_add_f32 v[vgpr_3_last+3],v[vgpr_3_last+3],v[vgpr_3_tmp2+3]


    v_add_f32 v[vgpr_3_last],v[vgpr_3_last],v[vgpr_3_tmp3]
    v_add_f32 v[vgpr_3_last+1],v[vgpr_3_last+1],v[vgpr_3_tmp3+1]
    v_add_f32 v[vgpr_3_last+2],v[vgpr_3_last+2],v[vgpr_3_tmp3+2]
    v_add_f32 v[vgpr_3_last+3],v[vgpr_3_last+3],v[vgpr_3_tmp3+3]


    s_waitcnt vmcnt(0);


    v_add_f32 v[vgpr_4_last],v[vgpr_4_last],v[vgpr_4_tmp1]
    v_add_f32 v[vgpr_4_last+1],v[vgpr_4_last+1],v[vgpr_4_tmp1+1]
    v_add_f32 v[vgpr_4_last+2],v[vgpr_4_last+2],v[vgpr_4_tmp1+2]
    v_add_f32 v[vgpr_4_last+3],v[vgpr_4_last+3],v[vgpr_4_tmp1+3]


    v_add_f32 v[vgpr_4_last],v[vgpr_4_last],v[vgpr_4_tmp2]
    v_add_f32 v[vgpr_4_last+1],v[vgpr_4_last+1],v[vgpr_4_tmp2+1]
    v_add_f32 v[vgpr_4_last+2],v[vgpr_4_last+2],v[vgpr_4_tmp2+2]
    v_add_f32 v[vgpr_4_last+3],v[vgpr_4_last+3],v[vgpr_4_tmp2+3]


    v_add_f32 v[vgpr_4_last],v[vgpr_4_last],v[vgpr_4_tmp3]
    v_add_f32 v[vgpr_4_last+1],v[vgpr_4_last+1],v[vgpr_4_tmp3+1]
    v_add_f32 v[vgpr_4_last+2],v[vgpr_4_last+2],v[vgpr_4_tmp3+2]
    v_add_f32 v[vgpr_4_last+3],v[vgpr_4_last+3],v[vgpr_4_tmp3+3]




    v_add_f32 v[vgpr_1_last],v[vgpr_1_last],v[vgpr_2_last]
    v_add_f32 v[vgpr_1_last+1],v[vgpr_1_last+1],v[vgpr_2_last+1]
    v_add_f32 v[vgpr_1_last+2],v[vgpr_1_last+2],v[vgpr_2_last+2]
    v_add_f32 v[vgpr_1_last+3],v[vgpr_1_last+3],v[vgpr_2_last+3]


    v_add_f32 v[vgpr_3_last],v[vgpr_3_last],v[vgpr_4_last]
    v_add_f32 v[vgpr_3_last+1],v[vgpr_3_last+1],v[vgpr_4_last+1]
    v_add_f32 v[vgpr_3_last+2],v[vgpr_3_last+2],v[vgpr_4_last+2]
    v_add_f32 v[vgpr_3_last+3],v[vgpr_3_last+3],v[vgpr_4_last+3]


    v_add_f32 v[vgpr_1_last],v[vgpr_1_last],v[vgpr_3_last]
    v_add_f32 v[vgpr_1_last+1],v[vgpr_1_last+1],v[vgpr_3_last+1]
    v_add_f32 v[vgpr_1_last+2],v[vgpr_1_last+2],v[vgpr_3_last+2]
    v_add_f32 v[vgpr_1_last+3],v[vgpr_1_last+3],v[vgpr_3_last+3]




    buffer_store_dwordx4 v[vgpr_1_last:vgpr_1_last+3], v[vgpr_write_local_offset], s[sgpr_write_address:sgpr_write_address+3], 0, offen offset:0
    s_waitcnt     vmcnt(0)

;s_cmp_eq_u32  s[sgpr_CRS_32], 0
;s_cbranch_scc0 xxxx


;       s_load_dwordx2 s[36:37], s[0:1], 0x08
;       s_waitcnt     lgkmcnt(0) vmcnt(0)
;       v_lshlrev_b32 v4, 2, v0
;       v_mov_b32 v63,s[sgpr_kcrs_x4]
;       v_mov_b32 v63,11
;       global_store_dword  v[4:5], v[vgpr_1_last], s[36:37]
;       s_waitcnt     vmcnt(0)
        ;//kevin end
;xxxx:




    s_endpgm
.Lfunc_end0:
        .size   split_add, .Lfunc_end0-split_add

