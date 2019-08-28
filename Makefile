LLVM=/opt/clang+llvm-8.0.0-x86_64-linux-gnu-ubuntu-16.04
MC=${LLVM}/bin/llvm-mc
CPU=gfx906
ARCH=amdgcn
LLD=${LLVM}/bin/ld.lld
HIPCC=/opt/rocm/bin/hipcc
CC=g++



all: for

for:
	${MC} -arch=${ARCH} -mcpu=${CPU} for.s -filetype=obj -o for.o
	${LLD} -shared for.o -o for.co

clean:
	rm *.co *.o for
