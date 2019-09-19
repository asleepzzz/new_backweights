LLVM=/opt/clang+llvm-8.0.0-x86_64-linux-gnu-ubuntu-16.04
MC=${LLVM}/bin/llvm-mc
CPU=gfx906
ARCH=amdgcn
LLD=${LLVM}/bin/ld.lld
HIPCC=/opt/rocm/bin/hipcc
CC=g++



all: for

for:
	${MC} -arch=${ARCH} -mcpu=${CPU} bw_schedule.s -filetype=obj -o bw_schedule.o
	${LLD} -shared bw_schedule.o -o bw_schedule.co
	${MC} -arch=${ARCH} -mcpu=${CPU} bw_special.s -filetype=obj -o bw_special.o
	${LLD} -shared bw_special.o -o bw_special.co
	${MC} -arch=${ARCH} -mcpu=${CPU} bw_crs64.s -filetype=obj -o bw_crs64.o
	${LLD} -shared bw_crs64.o -o bw_crs64.co
	${MC} -arch=${ARCH} -mcpu=${CPU} bw_k64.s -filetype=obj -o bw_k64.o
	${LLD} -shared bw_k64.o -o bw_k64.co
	${MC} -arch=${ARCH} -mcpu=${CPU} add.s -filetype=obj -o add.o
	${LLD} -shared add.o -o add.co

clean:
	rm *.co *.o for
