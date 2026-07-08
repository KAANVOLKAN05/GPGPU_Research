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

### Following the Book
Date: 7/7/2026
1. Created and built dist_v1 and dist_v2 applications mentioned in the book
2. Played with the debugging tool cuda-gbd but I still have quite some ways to go with it
3. Moved the following along the book directory under my GPGPU_Research github repo
4. Added a readme explaining it