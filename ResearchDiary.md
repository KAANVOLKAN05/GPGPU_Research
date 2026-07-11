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

With the CUDA instillations prior to 11.7, the instillation includes a number of samples projects to run on the GPU.

One of these projects, nbody, demonstrates the interaction of n bodies that are gravitationally coupled to each other.

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
