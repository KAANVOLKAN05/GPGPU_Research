# Reserach Notebook

Project: Optimization on GPGPUs

Author: Kaan Volkan

Supervisor: Stuart Brorson

Create Date: 6/27/2026

---
### GIT Setup 
Date: 6/27/2026

1. Created a repo called GPGPU Reserach
2. Added gitignore for VS Code

### C Programming Rewiev

Date: 6/28/2026
1. Reviwed Need-to-know C Programming in the CUDA book
   
### Zoom Meeting
Date: 6/28/2026
1. 2:30pm meeting in your office on Thursday
2. First project would be Mandelbrot set from your github
3. Reading the optimizition book
4. Meetings would be Monday Zoom 8am, Thursday in Person
5. Preferred contact: Email
6. Until the next meeting I will checl out the Mandel code and annote it to my understanding

### Wireless Meeting 1
Date: 7/1/2026
1. Discussed where the server could be placed and resolved concerns regarding the universal power supply
2. The server will have to be connected to a seperate power supply from the server rack to prevent already overloaded ups from going down
3. Discussed networking solutions for remote access
4. Wireless facilities/network officer helped locate unused port and said they would help with setting up remote access
5. Spoke with wireless leadership and got them onboard with the idea

   
### C Coding Review 
Date: 7/2/2026
1. Completed a 6 hour youtube course on C programming as a review
2. Explored online cudo resources

### Server Cooling Adjustment
Date: 7/3/2026
1. Placed wooden spacers between the servers to allow for better circulation
2. This solved the heating issue without the need for an external fan

### Network work (just for shirt time)
Date: 7/6/2026
1. Attempted to connect to the internet (failed)
2. Realized the ethernet cable was not fully in and tried to connect again (failed)
3. Had a chat with the club ethernet administrator 
4. Tried hostname -I and got non club network ID
5. I tried a couple more things, but then we decided to chat on Monday evening to connect to the internet and later set up remote access. 

### Meeting Notes
Date: 7/6/2026
1. July 16 the builder of the computer will come

### Daily Work Note
Date: 7/6/2026
1. Found a resource that can help with multigpu work [CUDA_Multi_GPU_Resource]("https://docs.nvidia.com/cuda/cuda-programming-guide/03-advanced/multi-gpu-systems.html")
2. If hard to understand, first read [GPU_Structure]("https://docs.nvidia.com/cuda/cuda-programming-guide/01-introduction/programming-model.html")

### Following the Book
Date: 7/6/2026
1. Check that GPU capability is above 2.0 for the book, teslak80 is 3.7
2. Find and copy a writable copy of the CUDA samples
3. Attempted to build Samples/5_Simulations/nbody , failed due to "cannot find lglut"
4. Attempted to build and run Samples/1_Utilities/bandwidthTest , succeeded.

### Fixing the internet connection
Date: 7/7/2026

1. Upon 3 hours of futile attempts on fixing the internet connection, which showed us on the wrong IP adress, after deleting configuration, redowloading them, asking people, calling friends and trying with ai, I fixed it by changing the port on the computer. 
2. After this I finnaly cloned my fork of the mandelbrot to the computer 

### Following the Book
Date: 7/7/2026
1. Created and built dist_v1 and dist_v2 applications mentioned in the book
2. Played with the debugging tool cuda-gbd but I still have quite some ways to go with it
3. Moved the following along the book directory under my GPGPU_Research github repo
4. Added a readme explaining it

### Mandelbrot and Book
Date: 7/8/2026
1. Finished until chapter 4 
2. Compiled the mandelbrot (cmake needed an extra flag and make was giving minor errors)
3. I was able to select device and attempted to divide the problem into 2

### Meeting Notes
Date 7/9/2026
1. No need to get a seperate enviorment
2. I will email him the error code that came up with the open gl nbody
3. Try telling glut to use the right gpu
4. We are emailing Ecart to inquire about a dedicated graphincs card
5. Try to see which cpu I am using. 


### Solution to nbody sample problem
Date: 7/11/2026

#### Backround info
With the CUDA instillations prior to 11.7, the instillation includes a number of samples projects to run on the GPU.

One of these projects, nbody, demonstrates the interaction of n bodies that are gravitationally coupled to each other.

#### The error code
While trying to run this program, I got the following error: 

> Windowed mode
> 
> Simulation data stored in video memory
>
> Single precision floating point simulation
> 
> 1 Devices used for simulation
> 
> GPU Device 0: "Kepler" with compute capability 3.7



> Compute 3.7 CUDA device: [Tesla K80]
> 
> CUDA error at bodysystemcuda_impl.h:186 code=999(cudaErrorUnknown) "cudaGraphicsGLRegisterBuffer(&m_pGRes[i], m_pbo[i], cudaGraphicsMapFlagsNone)"

#### Investigative steps
I first took a look at bodysystemcuda_impl.h:186 which was a commented line that had nothing followed by a math equation that was just a plain equation. 

One of the solutions was running the program with the -cpu flag which runs the entire program on the cpu to compare with the GPU speed.

Another solution was running it without the graphics display, whixch worked just fine.

Upon looking at the forums I found people who plugged the display to their actual graphics card which solved the problem, "In my case, I have two GPUs (one of them is an internal GPU) and my screen is plugged to the internal one. When I plugged my screen to the other one, error is vanished." We do not have a graphical dedicated slot.

Also one person mentiopn having solved it with this, "__NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia + (command)". I do not understand what this does so i did not attempt to use it.

#### Actual solution

Adding the flag -hostmem fixed the issue. The porgram runs on the GPU but the memory is transferred to the CPU afterwards with this flag. Since we are running the graphics of our computer on the CPU, I believe this transfer allowed the computer to be able to run the display portion of the program very well.

#### Take Away

Add the -hostmem flag for sample programs when open gl is involved. 


### Figuring out the CPU being used
Date: 7/11/2026

1. Downloaded Library htop
2. Downloaded cmatrix
3. Neofetch

Identified 28 cores with htop. Found out the cpu model to be "Intel Xeon E-52626880 v4" with neofetch. This CPU model has 14 cores. When neofetch showed which cores were being used, it showed all 28 approximatly uniformly used, which may indicate that both are used. An interesting aside is that when running the nbody program with the cpu flag, only a single core is used. 

### Proper Parralellization
Date: 7/11/2026

I changed the Mandelbrot code to run in parallel on 8 GPUs. I made it sufficently modular so it can work with different systems with different numbers of GPU. Another part of this modularity was a header file I developped by copying from the multigpu example given in one of the NVIDIA samples. This file just inlcudes a struct that stores variables that CPU needs to launch each GPU. Perhaps I could write a better explanation of all the changes in a seperate documentation. There is also still some shortcuts I need to cleanup. 

### The Segmentation Error (Core Dumped)
Date:7/11/2026

Below was the error you and I got when try to run the simulation with NY and NX above 800. 
This is because we were creating that lamnda plane withh NX*NY, which is too big for the stack. When instead we decleare some pointers to them, then allocate them to the pinned host memory(which is done by cudaMallocHost() and easies transfer to the GPU and is in the heap I believe), it works.  
> Starting x0 = -5.000000e-01, y0 = 0.000000e+00, w = 3.000000e+00, h = 3.000000e+00, N = 32000
> Configure colorComplexPlane ... 
> Configure colorComplexPlane ... 
> xmin = -2.000000e+00, xmax = 1.000000e+00, ymin = -1.500000e+00, ymax = 1.500000e+00, dx = 3.003003e-03, dy = 3.003003e-03
> Compute initial Mandelbrot ... 
> Segmentation fault (core dumped)

### Color Pallate Changes
Date: 7/12/2026
1. Impplemented the smooth iteraton number formula from https://iquilezles.org/articles/msetsmooth/
2. Te results were very bad due to our color mapping
3. After a lot of manual efforts to get a nive color map, I asked GPT to copy the color pallet this person uses in their animation https://www.shadertoy.com/view/4df3Rn
4. Couple additonal things are that the max number is set to 250 fr the number of colors in the lookup table, this could be changed for sure
5. If the number of iterations to escape is equal to the max nummber which means it could not escape, the lookup table index is set to -1 whic is defined to be black while the table is being set.


### CPU Rendering issue
Date: 7/12/2026

1. To mke the Mandelbrot set more beatifull, a higher window size such as 2000 by 2000 is neccecry. Previsously the limit was 800 by 800 due to the segmentation fault, but after solving that, i tried going up to 5000 which made wonderfull graphs. BUT there is a problem. The Rendering of the Screen takes over 30 second per frame. I am alost sure this is purely caused by the CPU trying to render it because changing the iteration count from 32000 to 320 does not change the time between frames noticably, which means all the latency comes from the CPU. Well, it could also be from the time it takes the GPU to copy the data to the CPU too, which wold not have been a problem if we were directly rendering from the GPU.

### Flashlight program and all open GL applications
Date:7/14/2026

1. I failed to make them work on my computer.

> /usr/local/cuda/bin/nvcc -g -G -Xcompiler "-Wall
> -Wno-deprecated-declarations" -I/usr/local/cuda/samples/common/inc -c
> main.cpp -o main.o
> /usr/local/cuda/bin/nvcc -g -G -Xcompiler "-Wall
> -Wno-deprecated-declarations" -c kernel.cu -o kernel.o
> /usr/local/cuda/bin/nvcc main.o kernel.o -o main.exe
> -L/usr/local/cuda/samples/common/lib/linux/x86_64 -lglut -lGL -lGLU
> -lGLEW
> /usr/bin/ld: /usr/local/cuda/samples/common/lib/linux/x86_64/libGLEW.a(glew.o):
> relocation R_X86_64_32S against `.rodata' can not be used when making
> a PIE object; recompile with -fPIE
> /usr/bin/ld: final link failed
> collect2: error: ld returned 1 exit status
> make: *** [Makefile:17: main.exe] Error 1
2. Turns out the reson behind this is some linux security change, I then tried following ai instructions to debug this by deleting the -L line and manually installing some libraries, it worked but I just got a black secreen.

### More colors
1. I implemented the log log equation to the cpu
2. I also tried to do some work on bettering the color pallaate but it was very bad. I seem to not be able to get a nice graph.
3. Add to the July due list the Multi GPU talking borders. 
### Meeting Notes:

1. In 2 weeks, I join the meeting for the turbiditiy stuff
2. Use LLSPCI to locate which GPU is the weak one


