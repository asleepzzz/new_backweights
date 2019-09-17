

CXXFLAGS=`/opt/rocm/bin/hipconfig --cpp_config `" -Wall -O2 -fopenmp -std=c++11  "
LDFLAGS=" -L/opt/rocm/hcc/lib -L/opt/rocm/lib -L/opt/rocm/lib64 -L/opt/intel/mkl/lib/intel64 -L/opt/intel/lib/intel64"\
" -Wl,--rpath=/opt/rocm/hcc/lib:/opt/intel/mkl/lib/intel64:/opt/intel/lib/intel64 -ldl -lm -lpthread -lhc_am -lmkl_rt -lmkldnn"\
" -Wl,--whole-archive -lmcwamp -lhip_hcc -lhsa-runtime64 -lhsakmt -Wl,--no-whole-archive "


make clean;
make all
g++ $CXXFLAGS for.cpp $LDFLAGS
