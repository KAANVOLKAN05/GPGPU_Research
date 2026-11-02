#include <iostream>
#include <string>
#include <cmath>
#include <random>
#include <iomanip>

__device__ double langevinStep(double xPos, double dt, double noiseCoef, double randomNumber);

__device__ double gradV(double xPos);

int main(int argc, char* argv[]) {
    return 0;
}

// Gradient of the 1D double well V(x) = (x^2 - 1)^2
__device__ double gradV(double xPos) {
    return 4.0 * xPos * (xPos * xPos - 1.0);
};

__device__ double langevinStep(double xPos, double dt, double noiseCoef, double randomNumber){
    return xPos - dt * gradV(xPos) + noiseCoef * randomNumber;
};