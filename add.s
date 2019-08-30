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
                granulated_wavefront_sgpr_count = 11;(s+3)+8-1/8-1
                granulated_workitem_vgpr_count = 15;(v+4-1)/4-1
                wavefront_sgpr_count = 96;sgpr+3
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
.set sgpr_kcrs_tmp,10
.set sgpr_block_start_offset,16


;//9 not use
.set sgpr_block_start_address,10;//10 11
.set sgpr_load_address,12 ;//12 13 14 15
.set Srd127_96, 0x0020000


.set vgpr_k_local_idx,1
.set vgpr_crs_local_idx,2
.set vgpr_start_addrerss,3
.set vgpr_k_local_offset,4


.set vgpr_1_last,8;//8 9 10 11
;.set vgpr_1_tmp2,8
;.set vgpr_1_tmp3,12
;.set vgpr_1_tmp4,16

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

    s_lshl_b32  s[sgpr_block_start_offset], s[sgpr_K_8], 5;//8*4
    s_mul_i32 s[sgpr_block_start_offset], s[sgpr_block_start_offset], s[sgpr_CRS];//8*4*CRS
    s_lshl_b32 s[sgpr_kcrs_tmp], s[sgpr_CRS_32],7;//32*4
    s_add_u32 s[sgpr_block_start_offset], s[sgpr_block_start_offset],s[sgpr_kcrs_tmp];//crs_32*32*4+k_8*8*CRS*4

    v_lshrrev_b32  v[vgpr_k_local_idx], 3,v0;// v0/8
    v_and_b32 v[vgpr_crs_local_idx],v0,7;//x=v0%8
    v_lshlrev_b32 v[vgpr_crs_local_idx],2,v[vgpr_crs_local_idx]

    v_lshlrev_b32 v[vgpr_k_local_offset],2,v[vgpr_k_local_idx]   ;//k*CRS*4
    ;v_mul_lo_u32 v[vgpr_k_local_offset], s[sgpr_CRS], v[vgpr_k_local_offset]

    v_lshl_add_u32 v[vgpr_start_addrerss],v[vgpr_crs_local_idx],2,v[vgpr_k_local_offset];//

    s_waitcnt     lgkmcnt(0)

;//block 0 -15 this is block 0
    s_add_u32     s[sgpr_block_start_address], s[sgpr_Matrix_address], s[sgpr_block_start_offset]
    s_addc_u32    s[sgpr_block_start_address+1], s[sgpr_Matrix_address+1], 0

    s_mov_b32 s[sgpr_load_address+0],s[sgpr_block_start_address]
    s_mov_b32 s[sgpr_load_address+1],s[sgpr_block_start_address+1]
    s_mov_b32 s[sgpr_load_address+2],8*32*4
    s_mov_b32 s[sgpr_load_address+3], Srd127_96
    buffer_load_dwordx4 v[vgpr_1_last:vgpr_1_last+3], v[vgpr_start_addrerss], s[sgpr_load_address:sgpr_load_address+3], 0, offen offset:0

    s_waitcnt vmcnt(0);



s_cmp_eq_u32  s[sgpr_CRS_32], 0
s_cbranch_scc0 xxxx


       s_load_dwordx2 s[36:37], s[0:1], 0x20
       s_waitcnt     lgkmcnt(0) vmcnt(0)
       v_lshlrev_b32 v60, 2, v0
       v_mov_b32 v63,s[sgpr_CRS]
       ;v_mov_b32 v63,11
       global_store_dword  v[60:61], v[vgpr_k_local_offset], s[36:37]
;//v[vgpr_lds_A_offset]
;global_store_dword  v[124:125], v[vgpr_FMA_value], s[36:37]
;global_store_dword  v[124:125], v[vgpr_lds_A_offset], s[36:37]
;global_store_dword  v[124:125], v[vgpr_thread_A_4], s[36:37]
       s_waitcnt     vmcnt(0)
        ;//kevin end
xxxx:




    s_endpgm
.Lfunc_end0:
        .size   split_add, .Lfunc_end0-split_add

