#!/bin/bash


./scgemm_special  -w 23 -h 17 -c 128 -n 128 -k 128 -s 7 -r 1 -x 1 -y 1
./scgemm_special  -w 17 -h 23 -c 128 -n 128 -k 128 -s 1 -r 7 -x 1 -y 1
./scgemm_special  -w 23 -h 17 -c 128 -n 128 -k 192 -s 7 -r 1 -x 1 -y 1
./scgemm_special  -w 17 -h 23 -c 128 -n 128 -k 192 -s 1 -r 7 -x 1 -y 1
./scgemm_special  -w 8 -h 8 -c 1280 -n 128 -k 192 -s 1 -r 1 -x 1 -y 1
./scgemm_special  -w 8 -h 8 -c 1280 -n 128 -k 320 -s 1 -r 1 -x 1 -y 1
./scgemm_special  -w 8 -h 8 -c 1280 -n 128 -k 384 -s 1 -r 1 -x 1 -y 1
./scgemm_special  -w 8 -h 8 -c 1280 -n 128 -k 448 -s 1 -r 1 -x 1 -y 1
./scgemm_special  -w 23 -h 17 -c 160 -n 128 -k 160 -s 7 -r 1 -x 1 -y 1
./scgemm_special  -w 17 -h 23 -c 160 -n 128 -k 160 -s 1 -r 7 -x 1 -y 1
./scgemm_special  -w 23 -h 17 -c 160 -n 128 -k 192 -s 7 -r 1 -x 1 -y 1
./scgemm_special  -w 17 -h 23 -c 160 -n 128 -k 192 -s 1 -r 7 -x 1 -y 1
./scgemm_special  -w 23 -h 17 -c 192 -n 128 -k 192 -s 7 -r 1 -x 1 -y 1
./scgemm_special  -w 17 -h 17 -c 192 -n 128 -k 192 -s 3 -r 3 -x 2 -y 2
./scgemm_special  -w 17 -h 23 -c 192 -n 128 -k 192 -s 1 -r 7 -x 1 -y 1
./scgemm_special  -w 17 -h 17 -c 192 -n 128 -k 320 -s 3 -r 3 -x 2 -y 2
./scgemm_special  -w 35 -h 35 -c 192 -n 128 -k 32 -s 1 -r 1 -x 1 -y 1
./scgemm_special  -w 35 -h 35 -c 192 -n 128 -k 48 -s 1 -r 1 -x 1 -y 1
./scgemm_special  -w 35 -h 35 -c 192 -n 128 -k 64 -s 1 -r 1 -x 1 -y 1
./scgemm_special  -w 8 -h 8 -c 2048 -n 128 -k 192 -s 1 -r 1 -x 1 -y 1
./scgemm_special  -w 8 -h 8 -c 2048 -n 128 -k 320 -s 1 -r 1 -x 1 -y 1
./scgemm_special  -w 8 -h 8 -c 2048 -n 128 -k 384 -s 1 -r 1 -x 1 -y 1
./scgemm_special  -w 8 -h 8 -c 2048 -n 128 -k 448 -s 1 -r 1 -x 1 -y 1
./scgemm_special  -w 35 -h 35 -c 256 -n 128 -k 48 -s 1 -r 1 -x 1 -y 1
./scgemm_special  -w 35 -h 35 -c 256 -n 128 -k 64 -s 1 -r 1 -x 1 -y 1
./scgemm_special  -w 35 -h 35 -c 288 -n 128 -k 384 -s 3 -r 3 -x 2 -y 2
./scgemm_special  -w 35 -h 35 -c 288 -n 128 -k 48 -s 1 -r 1 -x 1 -y 1
./scgemm_special  -w 35 -h 35 -c 288 -n 128 -k 64 -s 1 -r 1 -x 1 -y 1
./scgemm_special  -w 299 -h 299 -c 3 -n 128 -k 32 -s 3 -r 3 -x 2 -y 2
./scgemm_special  -w 149 -h 149 -c 32 -n 128 -k 64 -s 3 -r 3 -x 1 -y 1
./scgemm_special  -w 149 -h 149 -c 32 -n 128 -k 32 -s 3 -r 3 -x 1 -y 1
./scgemm_special  -w 10 -h 8 -c 384 -n 128 -k 384 -s 3 -r 1 -x 1 -y 1
./scgemm_special  -w 8 -h 10 -c 384 -n 128 -k 384 -s 1 -r 3 -x 1 -y 1
./scgemm_special  -w 10 -h 10 -c 448 -n 128 -k 384 -s 3 -r 3 -x 1 -y 1
./scgemm_special  -w 39 -h 39 -c 48 -n 128 -k 64 -s 5 -r 5 -x 1 -y 1
./scgemm_special  -w 37 -h 37 -c 64 -n 128 -k 96 -s 3 -r 3 -x 1 -y 1
./scgemm_special  -w 73 -h 73 -c 64 -n 128 -k 80 -s 1 -r 1 -x 1 -y 1
./scgemm_special  -w 17 -h 17 -c 768 -n 128 -k 128 -s 1 -r 1 -x 1 -y 1
./scgemm_special  -w 17 -h 17 -c 768 -n 128 -k 160 -s 1 -r 1 -x 1 -y 1
./scgemm_special  -w 17 -h 17 -c 768 -n 128 -k 192 -s 1 -r 1 -x 1 -y 1
./scgemm_special  -w 73 -h 73 -c 80 -n 128 -k 192 -s 3 -r 3 -x 1 -y 1
./scgemm_special  -w 35 -h 35 -c 96 -n 128 -k 96 -s 3 -r 3 -x 2 -y 2
./scgemm_special  -w 37 -h 37 -c 96 -n 128 -k 96 -s 3 -r 3 -x 1 -y 1

