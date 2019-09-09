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
                granulated_workitem_vgpr_count = 15;(v+4-1)/4-1
                wavefront_sgpr_count = 96;sgpr+3
                workitem_vgpr_count = 64
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
.set sgpr_NOO_real_idx,51;//not auxbuf, it's real idx in split


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
.set sgpr_LDS_switch_offset,74
.set sgpr_Loop_NOO_start,75;//don't use sgpr_NOO_real_idx to judge due to you need all wave when FMA(maybe can try sgpr_NOO_real_idx after....) 

.set sgpr_auxbuf_A_buf2, 76;//76 77 78 79
.set sgpr_auxbuf_B_buf2, 80;//80 81 82 83


;//sgpr

.set vgpr_CRS_value,1
.set vgpr_global_CRS_id_address,3
;//v2 for 0 0...0|32 32..32|64 64..64|96 96..96
.set vgpr_wave_tid,49;//don't use v2 ,it has another purpose

;//v3:global crs address
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
.set vgpr_xor_control,18;//for switch lds 1& 2,you need a offset and b offset
.set vgpr_xor_control_offset,19 ;//+0 or +4096

.set vgpr_thread_A_4,20;//20 21 22 23
.set vgpr_B_value_4,24;//24 25 26 27
.set vgpr_thread_B_4,28;//28 29 30 31
 
.set vgpr_FMA_value,32;//32-47
.set vgpr_crs_global_id,48
.set vgpr_reuse_tmp_write_dis,49;//after test ,you should use 4





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

    v_and_b32 v[vgpr_block_thread_tile_x],v0,15;//x=v0%16

    v_lshrrev_b32 v[vgpr_block_thread_tile_y], 4, v0;//y=v0/16
    v_lshlrev_b32 v[vgpr_block_thread_tile_y],4,v[vgpr_block_thread_tile_y];//*4*4due to every thread have 4




    v_lshlrev_b32 v[vgpr_block_thread_tile_x],4,v[vgpr_block_thread_tile_x]


    s_lshl_b32 s[sgpr_crs_id],s[sgpr_CRS_64],6


    v_and_b32     v[vgpr_wave_tid], 63, v0;//wave tid,will use after

    v_add_u32 v[vgpr_crs_global_id],v[vgpr_wave_tid],s[sgpr_crs_id]



    s_mov_b32 s[sgpr_lds_NOO_offset],256
    s_mov_b32 s[sgpr_LDS_switch_offset],4096

    v_mov_b32 v[vgpr_xor_control],0x0;//switch 0 and 1

    s_waitcnt     lgkmcnt(0);//wait sload





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
    v_add_u32  v[vgpr_final_offset],v[vgpr_final_offset],v[vgpr_block_thread_tile_y]

    s_add_u32     s[sgpr_buf_C_address], s[sgpr_matrixC_start_address], s[sgpr_tmp_final]
    s_addc_u32    s[sgpr_buf_C_address+1], s[sgpr_matrixC_start_address+1], 0

    s_lshl_b32 s[sgpr_buf_C_address+2] ,  s[sgpr_CRS],8;//64*crs*4
    

    s_lshl_b32 s[sgpr_tmp_final],s[sgpr_CRS_64],6
    s_sub_i32 s[sgpr_tmp_final],s[sgpr_CRS],s[sgpr_tmp_final]
    s_cmp_ge_i32 s[sgpr_tmp_final],64
    s_cselect_b32 s[sgpr_KCRS_ok],1,0


    s_lshl_b32 s[sgpr_tmp2_final],s[sgpr_K_64],6
    s_sub_i32 s[sgpr_tmp2_final],s[sgpr_K],s[sgpr_tmp2_final]
    s_cmp_ge_i32 s[sgpr_tmp2_final],64
    s_cselect_b32 s[sgpr_KCRS_ok],s[sgpr_KCRS_ok],0
    s_mov_b32 s[sgpr_buf_C_address+3], Srd127_96
;//C calculate end 

    s_waitcnt     lgkmcnt(0);//wait s[sgpr_wave_NOO_offset]



    s_lshr_b32 s[sgpr_NOO_wave_start_idx_offset],s[sgpr_wave_NOO_offset],2;//0 0 ....0|8 8 ...8|16 16 ...16|24 24.....24
    s_add_u32 s[sgpr_NOO_wave_idx_offset],s[sgpr_NOO_wave_start_idx_offset],6;//6 6....6 |14 14...14|22 22...22 |30 30..30 last wave noo offset inaux
    ;s_add_u32 s[sgpr_NOO_wave_start_idx_offset],s[sgpr_NOO_wave_start_idx_offset],0;//0 0...0|8 8 ...8|16 16..16|24 24...24 first wave noo offset in aux
    s_add_u32 s[sgpr_NOO_wave_idx_in_split],s[sgpr_NOO_loop_idx_in_split],s[sgpr_NOO_wave_idx_offset];//everytime in loop + 6 6....6 |14 14...14|22 22...22 |30 30..30
;    s_add_u32 s[sgpr_NOO_wave_start_idx_in_split],s[sgpr_NOO_loop_idx_in_split],s[sgpr_NOO_wave_start_idx_offset];//everytime in loop + 0 0...0|8 8 ...8|16 16..16|24 24...24

    s_lshr_b32 s[sgpr_NOO_real_idx],s[sgpr_NOO_wave_idx_in_split],1;//
    s_add_u32 s[sgpr_NOO_real_idx],s[sgpr_NOO_real_idx],1;//4 4...4|8 8 ...8|12  12|16 16
;//sgpr_NOO_start_address_split




    s_mul_i32 s[sgpr_NKOO_1_address],s[sgpr_NOO],s[sgpr_K]
    s_lshl_b32  s[sgpr_NKOO_1_address], s[sgpr_NKOO_1_address],2
    v_lshlrev_b32 v[vgpr_global_CRS_id_address], 2, v[vgpr_wave_tid];//0 4 8...252|0 4 8...252|0 4 8...252|0 4 8...252
    v_mov_b32 v9,s[sgpr_CRS_64]
    v_lshl_add_u32 v[vgpr_global_CRS_id_address],v9,8,v[vgpr_global_CRS_id_address];//global crs id*4 = crs id*256+wave tid*4



;//noo 0-3 wave0|noo 4-7 wave1....
;//sgpr_NOO_real_idx 4 4...4|8 8 ...8|12  12|16 16
    s_cmp_gt_u32  s[sgpr_NOO_real_idx], s[sgpr_NOO_16];//not use ge due to start from 1 not 0
    s_cbranch_scc0 A_read_not_out_of_bound

A_wave_read_out_of_bound:;//we assume NOO is factor of 4,I don't want to handle so many conditions...
;//but you still can't loadx4 due to non contiue
;//NOO out of bound set 0
    v_mov_b32 v[vgpr_A_value_4],0.0
    v_mov_b32 v[vgpr_A_value_4+1],0.0
    v_mov_b32 v[vgpr_A_value_4+2],0.0
    v_mov_b32 v[vgpr_A_value_4+3],0.0
;//prevent out of bound,but you should not use these auxbuf
    s_mov_b32 s[sgpr_auxbuf_8],0
    s_mov_b32 s[sgpr_auxbuf_8+1],0
    s_mov_b32 s[sgpr_auxbuf_8+2],0
    s_mov_b32 s[sgpr_auxbuf_8+3],0
    s_mov_b32 s[sgpr_auxbuf_8+4],0
    s_mov_b32 s[sgpr_auxbuf_8+5],0
    s_mov_b32 s[sgpr_auxbuf_8+6],0
    s_mov_b32 s[sgpr_auxbuf_8+7],0

    s_mov_b32 s[sgpr_NOO_out_of_bound_status],1
    s_branch first_write_A_to_lds

A_read_not_out_of_bound:

    s_add_u32 s[sgpr_NOO_start_address_split],s[sgpr_NOO_start_address_split],s[sgpr_wave_NOO_offset];//0 0...0|32 32..32|64 64..64|96 96..96
    s_load_dwordx8 s[sgpr_auxbuf_8:sgpr_auxbuf_8+7], s[sgpr_matrixK_NOO_address:sgpr_matrixK_NOO_address+1], s[sgpr_NOO_start_address_split]

    s_mov_b32 s[sgpr_NOO_out_of_bound_status],0

    s_waitcnt     lgkmcnt(0)


    s_or_saveexec_b64 s[sgpr_before_cmp_address:sgpr_before_cmp_address+1],exec
    ;//if CRS out of bound ,do nothing
    v_cmpx_lt_u32 vcc, v[vgpr_crs_global_id], s[sgpr_CRS]
    


    s_mov_b32 s[sgpr_buf_crs_address],s[sgpr_span_address]
    s_mov_b32 s[sgpr_buf_crs_address+1],s[sgpr_span_address+1]
    s_lshl_b32    s[sgpr_CRS_1_address], s[sgpr_CRS], 2 
    s_mov_b32 s[sgpr_buf_crs_address+2],s[sgpr_CRS_1_address]
    s_mov_b32 s[sgpr_buf_crs_address+3], Srd127_96
    buffer_load_dword v[vgpr_CRS_value], v[vgpr_global_CRS_id_address], s[sgpr_buf_crs_address:sgpr_buf_crs_address+3], 0, offen offset:0

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



first_write_A_to_lds:

//FMA value reset
    v_mov_b32 v[vgpr_FMA_value],0.0
    v_mov_b32 v[vgpr_FMA_value+1],0.0
    v_mov_b32 v[vgpr_FMA_value+2],0.0
    v_mov_b32 v[vgpr_FMA_value+3],0.0
    v_mov_b32 v[vgpr_FMA_value+4],0.0
    v_mov_b32 v[vgpr_FMA_value+5],0.0
    v_mov_b32 v[vgpr_FMA_value+6],0.0
    v_mov_b32 v[vgpr_FMA_value+7],0.0
    v_mov_b32 v[vgpr_FMA_value+8],0.0
    v_mov_b32 v[vgpr_FMA_value+9],0.0
    v_mov_b32 v[vgpr_FMA_value+10],0.0
    v_mov_b32 v[vgpr_FMA_value+11],0.0
    v_mov_b32 v[vgpr_FMA_value+12],0.0
    v_mov_b32 v[vgpr_FMA_value+13],0.0
    v_mov_b32 v[vgpr_FMA_value+14],0.0
    v_mov_b32 v[vgpr_FMA_value+15],0.0

;//FMA value reset over
;//calculate offset for ld set 0 or 1
    v_mul_lo_u32 v[vgpr_xor_control_offset],v[vgpr_xor_control],s[sgpr_LDS_switch_offset]


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
;read to right,save to bottom    
;//but store to lds,down sore to help load conti after
;//[64][N00]
;   ________________ 
;   |0 256    |64*16  
;   |4 260
;   |8
;   |12_____________
;



    v_lshl_add_u32 v10,v[vgpr_wave_tid],2,v9;//wave tid*4+waveid*16*64
    v_add_u32 v10,v10,v[vgpr_xor_control_offset];//add 0 or 4096 for diff round
    ds_write_b32  v10, v[vgpr_A_value_4]
    ds_write_b32  v10, v[vgpr_A_value_4+1] offset:256
    ds_write_b32  v10, v[vgpr_A_value_4+2] offset:512
    ds_write_b32  v10, v[vgpr_A_value_4+3] offset:768
    s_waitcnt     lgkmcnt(0)


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
    v_lshl_add_u32 v[vgpr_global_k],s[sgpr_K_64],6,v[vgpr_wave_tid];//k_64*64+wave tid global k
    ;//find 0-63 koo
    v_mul_lo_u32 v[vgpr_kOO],v[vgpr_global_k],s[sgpr_OO]

    ;//MatrixN  max is KOO-1
    s_or_saveexec_b64 s[sgpr_before_cmp_address:sgpr_before_cmp_address+1],exec
    v_cmpx_ge_u32  s[sgpr_cmp_tmp_address:sgpr_cmp_tmp_address+1], v[vgpr_global_k], s[sgpr_K]
    v_mov_b32 v[vgpr_global_k],s[sgpr_K]
    v_mul_lo_u32 v[vgpr_kOO],v[vgpr_global_k],s[sgpr_OO]
    v_sub_u32 v[vgpr_kOO],v[vgpr_kOO],1
    s_mov_b64 exec,s[sgpr_before_cmp_address:sgpr_before_cmp_address+1]
    

    v_lshlrev_b32 v[vgpr_kOO],2,v[vgpr_kOO];//koo*4

;//due to splitk noo already get in A,so B do not need to handle split address

    s_cmp_eq_u32  s[sgpr_NOO_out_of_bound_status], 0;
    s_cbranch_scc1 B_read_not_out_of_bound
 
B_read_out_of_bound:
    v_mov_b32 v[vgpr_B_value_4],0.0
    v_mov_b32 v[vgpr_B_value_4+1],0.0
    v_mov_b32 v[vgpr_B_value_4+2],0.0
    v_mov_b32 v[vgpr_B_value_4+3],0.0
    s_branch first_write_B_to_lds


B_read_not_out_of_bound:
    s_or_saveexec_b64 s[sgpr_before_cmp_address:sgpr_before_cmp_address+1],exec
    v_cmpx_lt_u32 vcc, v[vgpr_global_k], s[sgpr_K]


    s_add_u32     s[sgpr_buf_B_address], s[sgpr_matrixB_start_address], s[sgpr_auxbuf_8+1]
    s_addc_u32    s[sgpr_buf_B_address+1], s[sgpr_matrixB_start_address+1], 0
    s_sub_u32 s[sgpr_buf_B_address+2],s[sgpr_NKOO_1_address],s[sgpr_auxbuf_8+1]
    s_mov_b32 s[sgpr_buf_B_address+3], Srd127_96

    s_sub_u32 s[sgpr_B_load_judge],s[sgpr_auxbuf_8+7],s[sgpr_auxbuf_8+1]

    ;s_mov_b64 exec,s[sgpr_before_cmp_address:sgpr_before_cmp_address+1]

;//need add
    s_cmp_eq_u32  s[sgpr_B_load_judge], 12
    s_cbranch_scc1  B_conti_read




    buffer_load_dword v[vgpr_B_value_4], v[vgpr_kOO], s[sgpr_buf_B_address:sgpr_buf_B_address+3], 0, offen offset:0



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



B_conti_read:



;//split_NOO must %4=0 ,if not, global_load_dwordx4 may read 0
    buffer_load_dwordx4 v[vgpr_B_value_4:vgpr_B_value_4+3], v[11], s[sgpr_buf_B_address:sgpr_buf_B_address+3], 0, offen offset:0



first_write_B_to_lds:

    s_mov_b64 exec,s[sgpr_before_cmp_address:sgpr_before_cmp_address+1];//for B_read_not_out_of_bound

    s_waitcnt vmcnt(0)


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

;//due to v10 already add v[vgpr_xor_control_offset] when LDS A,not add again
    ds_write_b32  v10, v[vgpr_B_value_4] offset:8192
    ds_write_b32  v10, v[vgpr_B_value_4+1] offset:8192+256
    ds_write_b32  v10, v[vgpr_B_value_4+2] offset:8192+512
    ds_write_b32  v10, v[vgpr_B_value_4+3] offset:8192+768

    s_waitcnt     lgkmcnt(0)


;//you should move more ,but now just test
    s_add_u32 s[sgpr_NOO_start_address_split],s[sgpr_NOO_start_address_split],128
    s_load_dwordx8 s[sgpr_auxbuf_8:sgpr_auxbuf_8+7], s[sgpr_matrixK_NOO_address:sgpr_matrixK_NOO_address+1], s[sgpr_NOO_start_address_split]




    s_mov_b32 s[sgpr_Loop_NOO_start],0;//if first wave still > sgpr_NOO_16,it should stop



    v_xor_b32 v[vgpr_xor_control],v[vgpr_xor_control],0x1;//change to another set to load

BIG_LOOP:
    s_add_u32 s[sgpr_Loop_NOO_start],s[sgpr_Loop_NOO_start],16


    ;//be careful ,here is ge due to if sgpr_NOO_16 is 16,you just need once
    s_cmp_ge_u32 s[sgpr_Loop_NOO_start],s[sgpr_NOO_16]
    s_cbranch_scc1 FMA_do;//the end,but you still have 1 FMA not done yet


    ;//dont open this
    ;s_add_u32 s[sgpr_NOO_real_idx],s[sgpr_NOO_real_idx],16
    ;s_cmp_gt_u32  s[sgpr_NOO_real_idx], s[sgpr_NOO_16]

AB_LOAD_in_loop:

;//----------------------------load in loop start------------------------------------------------
;//noo 0-3 wave0|noo 4-7 wave1.... everytime add 16
;//sgpr_NOO_real_idx 4 4...4|8 8 ...8|12  12|16 16
    s_add_u32 s[sgpr_NOO_real_idx],s[sgpr_NOO_real_idx],16 
    s_cmp_gt_u32  s[sgpr_NOO_real_idx], s[sgpr_NOO_16];//not use ge due to start from 1 not 0
    s_cbranch_scc0 LOOP_A_read_not_out_of_bound



LOOP_A_wave_read_out_of_bound:;//we assume NOO is factor of 4,I don't want to handle so many conditions...
;//but you still can't loadx4 due to non contiue
;//NOO out of bound set 0
    v_mov_b32 v[vgpr_A_value_4],0.0
    v_mov_b32 v[vgpr_A_value_4+1],0.0
    v_mov_b32 v[vgpr_A_value_4+2],0.0
    v_mov_b32 v[vgpr_A_value_4+3],0.0
;//prevent out of bound,but you should not use these auxbuf
    s_mov_b32 s[sgpr_auxbuf_A_buf2],0
    s_mov_b32 s[sgpr_auxbuf_A_buf2+1],0
    s_mov_b32 s[sgpr_auxbuf_A_buf2+2],0
    s_mov_b32 s[sgpr_auxbuf_A_buf2+3],0
    s_mov_b32 s[sgpr_auxbuf_B_buf2],0
    s_mov_b32 s[sgpr_auxbuf_B_buf2+1],0
    s_mov_b32 s[sgpr_auxbuf_B_buf2+2],0
    s_mov_b32 s[sgpr_auxbuf_B_buf2+3],0

    s_mov_b32 s[sgpr_NOO_out_of_bound_status],1
    s_branch LOOP_write_A_to_lds

LOOP_A_read_not_out_of_bound:
    ;//already add s[sgpr_wave_NOO_offset] ,just add 36 due to 16*2*4 in auxbuf
    ;s_add_u32 s[sgpr_NOO_start_address_split],s[sgpr_NOO_start_address_split],128
    ;s_load_dwordx8 s[sgpr_auxbuf_8:sgpr_auxbuf_8+7], s[sgpr_matrixK_NOO_address:sgpr_matrixK_NOO_address+1], s[sgpr_NOO_start_address_split]

    s_mov_b32 s[sgpr_NOO_out_of_bound_status],0

    s_waitcnt     lgkmcnt(0)

    s_mov_b32 s[sgpr_auxbuf_A_buf2],s[sgpr_auxbuf_8]
    s_mov_b32 s[sgpr_auxbuf_B_buf2],s[sgpr_auxbuf_8+1]
    s_mov_b32 s[sgpr_auxbuf_A_buf2+1],s[sgpr_auxbuf_8+2]
    s_mov_b32 s[sgpr_auxbuf_B_buf2+1],s[sgpr_auxbuf_8+3]
    s_mov_b32 s[sgpr_auxbuf_A_buf2+2],s[sgpr_auxbuf_8+4]
    s_mov_b32 s[sgpr_auxbuf_B_buf2+2],s[sgpr_auxbuf_8+5]
    s_mov_b32 s[sgpr_auxbuf_A_buf2+3],s[sgpr_auxbuf_8+6]
    s_mov_b32 s[sgpr_auxbuf_B_buf2+3],s[sgpr_auxbuf_8+7]

;//read next
    s_add_u32 s[sgpr_NOO_start_address_split],s[sgpr_NOO_start_address_split],128
    s_load_dwordx8 s[sgpr_auxbuf_8:sgpr_auxbuf_8+7], s[sgpr_matrixK_NOO_address:sgpr_matrixK_NOO_address+1], s[sgpr_NOO_start_address_split]





    s_or_saveexec_b64 s[sgpr_before_cmp_address:sgpr_before_cmp_address+1],exec
    ;//if CRS out of bound ,do nothing
    v_cmpx_lt_u32 vcc, v[vgpr_crs_global_id], s[sgpr_CRS]



    s_mov_b32 s[sgpr_buf_crs_address],s[sgpr_span_address]
    s_mov_b32 s[sgpr_buf_crs_address+1],s[sgpr_span_address+1]
    s_lshl_b32    s[sgpr_CRS_1_address], s[sgpr_CRS], 2
    s_mov_b32 s[sgpr_buf_crs_address+2],s[sgpr_CRS_1_address]
    s_mov_b32 s[sgpr_buf_crs_address+3], Srd127_96
    buffer_load_dword v[vgpr_CRS_value], v[vgpr_global_CRS_id_address], s[sgpr_buf_crs_address:sgpr_buf_crs_address+3], 0, offen offset:0

    s_waitcnt vmcnt(0);

;//CRS already read when first time ,just use it
    s_add_u32     s[sgpr_buf_A_address], s[sgpr_matrixAB_address], s[sgpr_auxbuf_A_buf2]
    s_addc_u32    s[sgpr_buf_A_address+1], s[sgpr_matrixAB_address+1], 0
    s_sub_u32 s[sgpr_buf_A_address+2],s[sgpr_NCHW_1_address],s[sgpr_auxbuf_A_buf2]
    s_mov_b32 s[sgpr_buf_A_address+3], Srd127_96
    buffer_load_dword v[vgpr_A_value_4], v[vgpr_CRS_value], s[sgpr_buf_A_address:sgpr_buf_A_address+3], 0, offen offset:0

    s_add_u32     s[sgpr_buf_A_address], s[sgpr_matrixAB_address], s[sgpr_auxbuf_A_buf2+1]
    s_addc_u32    s[sgpr_buf_A_address+1], s[sgpr_matrixAB_address+1], 0
    s_sub_u32 s[sgpr_buf_A_address+2],s[sgpr_NCHW_1_address],s[sgpr_auxbuf_A_buf2+1]
    buffer_load_dword v[vgpr_A_value_4+1], v[vgpr_CRS_value], s[sgpr_buf_A_address:sgpr_buf_A_address+3], 0, offen offset:0


    s_add_u32     s[sgpr_buf_A_address], s[sgpr_matrixAB_address], s[sgpr_auxbuf_A_buf2+2]
    s_addc_u32    s[sgpr_buf_A_address+1], s[sgpr_matrixAB_address+1], 0
    s_sub_u32 s[sgpr_buf_A_address+2],s[sgpr_NCHW_1_address],s[sgpr_auxbuf_A_buf2+2]
    buffer_load_dword v[vgpr_A_value_4+2], v[vgpr_CRS_value], s[sgpr_buf_A_address:sgpr_buf_A_address+3], 0, offen offset:0

    s_add_u32     s[sgpr_buf_A_address], s[sgpr_matrixAB_address], s[sgpr_auxbuf_A_buf2+3]
    s_addc_u32    s[sgpr_buf_A_address+1], s[sgpr_matrixAB_address+1], 0
    s_sub_u32 s[sgpr_buf_A_address+2],s[sgpr_NCHW_1_address],s[sgpr_auxbuf_A_buf2+3]
    buffer_load_dword v[vgpr_A_value_4+3], v[vgpr_CRS_value], s[sgpr_buf_A_address:sgpr_buf_A_address+3], 0, offen offset:0



    s_mov_b64 exec,s[sgpr_before_cmp_address:sgpr_before_cmp_address+1]

LOOP_write_A_to_lds:

    v_mul_lo_u32 v[vgpr_xor_control_offset],v[vgpr_xor_control],s[sgpr_LDS_switch_offset]

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
;read to right,save to bottom    
;//but store to lds,down sore to help load conti after
;//[64][N00]
;   ________________ 
;   |0 256    |64*16  
;   |4 260
;   |8
;   |12_____________
;



    v_lshl_add_u32 v10,v[vgpr_wave_tid],2,v9;//wave tid*4+waveid*16*64
    v_add_u32 v10,v10,v[vgpr_xor_control_offset];//add 0 or 4096 for diff round
    ds_write_b32  v10, v[vgpr_A_value_4]
    ds_write_b32  v10, v[vgpr_A_value_4+1] offset:256
    ds_write_b32  v10, v[vgpr_A_value_4+2] offset:512
    ds_write_b32  v10, v[vgpr_A_value_4+3] offset:768
    s_waitcnt     lgkmcnt(0)



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



;//due to splitk noo already get in A,so B do not need to handle split address
;//vgpr koo already compute before
    s_cmp_eq_u32  s[sgpr_NOO_out_of_bound_status], 0;
    s_cbranch_scc1 LOOP_B_read_not_out_of_bound
 

LOOP_B_read_out_of_bound:
    v_mov_b32 v[vgpr_B_value_4],0.0
    v_mov_b32 v[vgpr_B_value_4+1],0.0
    v_mov_b32 v[vgpr_B_value_4+2],0.0
    v_mov_b32 v[vgpr_B_value_4+3],0.0
    s_branch LOOP_write_B_to_lds


LOOP_B_read_not_out_of_bound:
    s_or_saveexec_b64 s[sgpr_before_cmp_address:sgpr_before_cmp_address+1],exec
    v_cmpx_lt_u32 vcc, v[vgpr_global_k], s[sgpr_K]


    s_add_u32     s[sgpr_buf_B_address], s[sgpr_matrixB_start_address], s[sgpr_auxbuf_B_buf2]
    s_addc_u32    s[sgpr_buf_B_address+1], s[sgpr_matrixB_start_address+1], 0
    s_sub_u32 s[sgpr_buf_B_address+2],s[sgpr_NKOO_1_address],s[sgpr_auxbuf_B_buf2]
    s_mov_b32 s[sgpr_buf_B_address+3], Srd127_96

    s_sub_u32 s[sgpr_B_load_judge],s[sgpr_auxbuf_B_buf2+3],s[sgpr_auxbuf_B_buf2]


;//need add
    s_cmp_eq_u32  s[sgpr_B_load_judge], 12
    s_cbranch_scc1  LOOP_B_conti_read




    buffer_load_dword v[vgpr_B_value_4], v[vgpr_kOO], s[sgpr_buf_B_address:sgpr_buf_B_address+3], 0, offen offset:0



s_add_u32     s[sgpr_buf_B_address], s[sgpr_matrixB_start_address], s[sgpr_auxbuf_B_buf2+1]
s_addc_u32    s[sgpr_buf_B_address+1], s[sgpr_matrixB_start_address+1], 0
s_sub_u32 s[sgpr_buf_B_address+2],s[sgpr_NKOO_1_address],s[sgpr_auxbuf_B_buf2+1]
buffer_load_dword v[vgpr_B_value_4+1], v[vgpr_kOO], s[sgpr_buf_B_address:sgpr_buf_B_address+3], 0, offen offset:0




s_add_u32     s[sgpr_buf_B_address], s[sgpr_matrixB_start_address], s[sgpr_auxbuf_B_buf2+2]
s_addc_u32    s[sgpr_buf_B_address+1], s[sgpr_matrixB_start_address+1], 0
s_sub_u32 s[sgpr_buf_B_address+2],s[sgpr_NKOO_1_address],s[sgpr_auxbuf_B_buf2+2]
buffer_load_dword v[vgpr_B_value_4+2], v[vgpr_kOO], s[sgpr_buf_B_address:sgpr_buf_B_address+3], 0, offen offset:0





s_add_u32     s[sgpr_buf_B_address], s[sgpr_matrixB_start_address], s[sgpr_auxbuf_B_buf2+3]
s_addc_u32    s[sgpr_buf_B_address+1], s[sgpr_matrixB_start_address+1], 0
s_sub_u32 s[sgpr_buf_B_address+2],s[sgpr_NKOO_1_address],s[sgpr_auxbuf_B_buf2+3]
buffer_load_dword v[vgpr_B_value_4+3], v[vgpr_kOO], s[sgpr_buf_B_address:sgpr_buf_B_address+3], 0, offen offset:0


    s_branch LOOP_write_B_to_lds 



LOOP_B_conti_read:



;//split_NOO must %4=0 ,if not, global_load_dwordx4 may read 0
    buffer_load_dwordx4 v[vgpr_B_value_4:vgpr_B_value_4+3], v[11], s[sgpr_buf_B_address:sgpr_buf_B_address+3], 0, offen offset:0


LOOP_write_B_to_lds:

    s_mov_b64 exec,s[sgpr_before_cmp_address:sgpr_before_cmp_address+1];//for B_read_not_out_of_bound

    s_waitcnt vmcnt(0)


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

;//due to v10 already add v[vgpr_xor_control_offset] when LDS A,not add again
;    v_lshl_add_u32 v10,v[vgpr_wave_tid],2,v9;//wave tid*4+waveid*16*64
;    v_add_u32 v10,v10,v[vgpr_xor_control_offset];//add 0 or 4096 for diff round
 
    ds_write_b32  v10, v[vgpr_B_value_4] offset:8192
    ds_write_b32  v10, v[vgpr_B_value_4+1] offset:8192+256
    ds_write_b32  v10, v[vgpr_B_value_4+2] offset:8192+512
    ds_write_b32  v10, v[vgpr_B_value_4+3] offset:8192+768

    s_waitcnt     lgkmcnt(0)




;//----------------------------load in loop end------------------------------------------------

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


;thread0 A0B0 thread1 A0B1(CRS 0 k 4) thread16 A1B0 thread17 A1B1
;NOO 0:loop0
;
;       K
;     v0  v1......v15
;CRS  v16
;
;WRITE OUT
;
;





FMA_do:
    v_xor_b32 v[vgpr_xor_control],v[vgpr_xor_control],0x1;//change to another set to execute
    v_mul_lo_u32 v[vgpr_xor_control_offset],v[vgpr_xor_control],s[sgpr_LDS_switch_offset]

    s_barrier;
 
    ;v_mov_b32 v[vgpr_lds_A_offset],v[vgpr_block_thread_tile_y]
    ;v_mov_b32 v[vgpr_lds_B_offset],v[vgpr_block_thread_tile_x]
    ;//add 0 or 4096 for switch
    v_add_u32 v[vgpr_lds_A_offset],v[vgpr_block_thread_tile_y],v[vgpr_xor_control_offset]
    v_add_u32 v[vgpr_lds_B_offset],v[vgpr_block_thread_tile_x],v[vgpr_xor_control_offset]

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


;//already add v[vgpr_xor_control_offset], not add again
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



//NOO LOOP 3
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


;//NOO LOOP 4
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


;//NOO LOOP 5
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


;//NOO LOOP 6
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




;//NOO LOOP 7
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





;//NOO LOOP 8
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


;//NOO LOOP 9
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


;//NOO LOOP 10
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




;//NOO LOOP 11
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






;//NOO LOOP 12
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


;//NOO LOOP 13
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


;//NOO LOOP 14
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




;//NOO LOOP 15
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

    s_barrier;

loop_jumpto_judge:
    ;//be careful ,here is ge due to if sgpr_NOO_16 is 16,you just need once
    s_cmp_ge_u32 s[sgpr_Loop_NOO_start],s[sgpr_NOO_16]
    s_cbranch_scc0 BIG_LOOP;//the end,but you still have 1 FMA not done yet

        

loop_end:




;       K
;     v0  v1......v15
;CRS  v16
;
;WRITE OUT
;
;


s_or_saveexec_b64 s[sgpr_before_cmp_address:sgpr_before_cmp_address+1],exec
s_cmp_eq_u32  s[sgpr_KCRS_ok], 1
s_cbranch_scc0 write_not_all_group


write_out:
;//for test
    buffer_store_dwordx4 v[vgpr_FMA_value:vgpr_FMA_value+3],v[vgpr_final_offset], s[sgpr_buf_C_address:sgpr_buf_C_address+3], 0, offen offset:0 
    v_lshl_add_u32 v[vgpr_reuse_tmp_write_dis],s[sgpr_CRS],2,v[vgpr_final_offset]
    buffer_store_dwordx4 v[vgpr_FMA_value+4:vgpr_FMA_value+7],v[vgpr_reuse_tmp_write_dis], s[sgpr_buf_C_address:sgpr_buf_C_address+3], 0, offen offset:0
    v_lshl_add_u32 v[vgpr_reuse_tmp_write_dis],s[sgpr_CRS],2,v[vgpr_reuse_tmp_write_dis]
    buffer_store_dwordx4 v[vgpr_FMA_value+8:vgpr_FMA_value+11],v[vgpr_reuse_tmp_write_dis], s[sgpr_buf_C_address:sgpr_buf_C_address+3], 0, offen offset:0
    v_lshl_add_u32 v[vgpr_reuse_tmp_write_dis],s[sgpr_CRS],2,v[vgpr_reuse_tmp_write_dis]
    buffer_store_dwordx4 v[vgpr_FMA_value+12:vgpr_FMA_value+15],v[vgpr_reuse_tmp_write_dis], s[sgpr_buf_C_address:sgpr_buf_C_address+3], 0, offen offset:0
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



    buffer_store_dwordx4 v[vgpr_FMA_value:vgpr_FMA_value+3],v[vgpr_final_offset], s[sgpr_buf_C_address:sgpr_buf_C_address+3], 0, offen offset:0 
    v_lshl_add_u32 v[vgpr_reuse_tmp_write_dis],s[sgpr_CRS],2,v[vgpr_final_offset]
    buffer_store_dwordx4 v[vgpr_FMA_value+4:vgpr_FMA_value+7],v[vgpr_reuse_tmp_write_dis], s[sgpr_buf_C_address:sgpr_buf_C_address+3], 0, offen offset:0
    v_lshl_add_u32 v[vgpr_reuse_tmp_write_dis],s[sgpr_CRS],2,v[vgpr_reuse_tmp_write_dis]
    buffer_store_dwordx4 v[vgpr_FMA_value+8:vgpr_FMA_value+11],v[vgpr_reuse_tmp_write_dis], s[sgpr_buf_C_address:sgpr_buf_C_address+3], 0, offen offset:0
    v_lshl_add_u32 v[vgpr_reuse_tmp_write_dis],s[sgpr_CRS],2,v[vgpr_reuse_tmp_write_dis]
    buffer_store_dwordx4 v[vgpr_FMA_value+12:vgpr_FMA_value+15],v[vgpr_reuse_tmp_write_dis], s[sgpr_buf_C_address:sgpr_buf_C_address+3], 0, offen offset:0
 

 
;    s_waitcnt vmcnt(0)


   

write_over:
    s_waitcnt vmcnt(0);
;    s_barrier;
    s_mov_b64 exec,s[sgpr_before_cmp_address:sgpr_before_cmp_address+1]








;s_cmp_eq_u32  s[sgpr_splitK_idx], 0


;s_cbranch_scc0 xxxx
;s_cmp_eq_u32  s[sgpr_CRS_64], 0
;s_cbranch_scc0 xxxx

;       s_load_dwordx2 s[36:37], s[0:1], 0x50
;       s_waitcnt     lgkmcnt(0) vmcnt(0)
;       v_lshlrev_b32 v124, 2, v0

; global_store_dword  v[124:125], v[vgpr_xor_control], s[36:37]

;       s_waitcnt     vmcnt(0)
 

;v_mov_b32 v[vgpr_xor_control],1
;v_xor_b32 v[vgpr_xor_control],v[vgpr_xor_control],0x1
;v_mul_lo_u32 v[vgpr_xor_control_offset],v[vgpr_xor_control],s[sgpr_LDS_switch_offset]

;//sgpr_matrixC_start_address
;v_mov_b32 v127,4100
;ds_read_b32  v122, v127 offset:0
      ;v_mov_b32 v122,vgpr_xor_control_offset
       ;global_store_dword  v[124:125], v[vgpr_thread_A_4], s[36:37]
;//v[vgpr_lds_A_offset]

;global_store_dword  v[124:125], v[vgpr_block_thread_tile_y], s[36:37]
;global_store_dword  v[124:125], v[vgpr_FMA_value+1], s[36:37]
;global_store_dword  v[124:125], v[vgpr_FMA_value], s[36:37]
       ;//kevin end
xxxx:






    s_endpgm
.Lfunc_end0:
        .size   back_weights, .Lfunc_end0-back_weights
















