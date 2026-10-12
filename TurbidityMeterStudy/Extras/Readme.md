# MCX Writeup


The purpose of this page is to document my mcx procesees for future referal.


## Downloading MCX

Downloaded mcx via the following steps 
1. Go to https://mcx.space/
2. In the mcx home page click the orange download button titled "Download v2025.10"
3. It takes you to the download page https://mcx.space/wiki/?Get
4. I clicked the top left titled MCX v2025.10
5. Takes me to the page https://mcx.space/wiki/?keywords=register&tool=mcx&ref=mcxwiki
6. Here you an register or not, which takes you to aother downloadd page https://sourceforge.net/projects/mcx/files/mc
x%20binary/.
7. Here I choose 2025.10 (Kilo-Kelvin) and downloaded the version for linux.
8. For my purposes, I have mcx downloaded under student/GPGPU_Research/MonteCarlo

## Getting started

*These steps are copied from the mcx home/learning page*

1. cd mcx/bin
2. run ./mcx -- This gives an overview of the program
3. run ./mxc -L -- This displays all the available GPUs
4. run ./mcx --bench --T This displays all available benchmark tests
5. run ./mcx --bench cube60b

## Selecting multiple GPUs
This is a mini-section on a specific problem I have faced. Since we installed a new GPU for the graphics purposes (not computation), the computer now also recognizes it, and mcx tries to use it despite its weak computational performance. In order to not use it, we must use the flag -G '01'. With this flag the 1s mean to enable the GPU and 0s mean to disable it. First, I run ./mcx -L to list the GPUs and upon realizing that the GPU I want to exclude is the one with index 0(the first one), I can run my programs with -G '01' flag. For using multiple GPUs , I must specify which ones to use with the same flag. For example, if I want to exclude the first GPU and use the second, third and fourth , I can run ./mcx --bench cube60b -G '0111'.

## Creating a geometry

1. As a template, I use the examples listed in https://mcx.space/cloud/
2. I strongly encourage refering to these as a starting point as they are also rendered online so one can fiddle around and see the results of their changes.
3. The youtube videos by the creator of the program are also increadibly helpfull https://www.youtube.com/watch?v=TnfmrO12jI0&t=875s
4. I have used ai to add descriptions for what each line of the json file means to refer back to. It does not help as much as the videos but is still a good resource to refer back to, you can find it under the file labeled cube60 annotated.







