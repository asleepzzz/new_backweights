

CXXFLAGS=`/opt/rocm/bin/hipconfig --cpp_config`" -Wall -O2 -std=c++11  "
LDFLAGS=" -L/opt/rocm/hcc/lib -L/opt/rocm/lib -L/opt/rocm/lib64"\
" -Wl,--rpath=/opt/rocm/hcc/lib -ldl -lm -lpthread -lhc_am "\
" -Wl,--whole-archive -lmcwamp -lhip_hcc -lhsa-runtime64 -lhsakmt -Wl,--no-whole-archive"


make clean;
make all
g++ $CXXFLAGS for.cpp $LDFLAGS
