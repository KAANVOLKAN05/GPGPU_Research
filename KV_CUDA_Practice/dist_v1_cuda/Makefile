
NVCC = /usr/local/cuda/bin/nvcc
NVCC_FLAGS = -g -G -Xcompiler -Wall -arch=sm_37
main.exe: kernel.cu
	$(NVCC) $(NVCC_FLAGS) $^ -o $@ 
