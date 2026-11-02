#include <iostream>
#include <string>
#include <cmath>
#include <random>
#include <iomanip>
#include <vector>
#include <curand_kernel.h>


__global__ void langevinKernel(double* out, int nParticles, double x0, double dt, double noiseCoef, long long nSteps, unsigned long long seed);

__device__ double langevinStep(double xPos, double dt, double noiseCoef, double randomNumber);

__device__ double gradV(double xPos);

int main(int argc, char* argv[]) {
    double xPos = -1.0;
    double dt = 0.01;
    double tMax = 100.0;
    double temp = 0.5;
    int nParticles = 100000;
    unsigned long long seed = 42;


    //Following section is for user flags
    for (int i = 1; i < argc; ++i) {
        std::string flag = argv[i];

        if (flag == "--help" || flag == "-h") {
            std::cout << "Usage: " << argv[0] << " [options]\n"
                << "  --xPos <value>        starting position (default " << xPos << ")\n"
                << "  --dt <value>          time step (default " << dt << ")\n"
                << "  --tMax <value>        simulation time per particle (default " << tMax << ")\n"
                << "  --temp <value>        temperature (default " << temp << ")\n"
                << "  --nParticles <value>  number of particles (default " << nParticles << ")\n"
                << "  --help, -h            show this message\n";
            return 0;
        } else if (flag == "--xPos" && i + 1 < argc) {
            xPos = std::stod(argv[++i]);
        } else if (flag == "--dt" && i + 1 < argc) {
            dt = std::stod(argv[++i]);
        } else if (flag == "--tMax" && i + 1 < argc) {
            tMax = std::stod(argv[++i]);
         } else if (flag == "--temp" && i + 1 < argc) {
            temp = std::stod(argv[++i]);
        } else if (flag == "--nParticles" && i + 1 < argc) {
            nParticles = std::stoi(argv[++i]);
        } else {
            std::cerr << "Unknown or incomplete option: " << flag << '\n';
            return 1;
        }
    }

    //Setting up the GPU memory
    double* d_out;
    cudaMalloc(&d_out, nParticles * sizeof(double));         // array in GPU memory

    int threadsPerBlock = 256;
    int blocks = (nParticles + threadsPerBlock - 1) / threadsPerBlock;

    double noiseCoef = std::sqrt(2.0 * temp * dt);
    long long nSteps = std::llround(tMax / dt);
    langevinKernel<<<blocks, threadsPerBlock>>>(d_out, nParticles, xPos, dt, noiseCoef, nSteps, seed);


    std::vector<double> out(nParticles); //setting up memory on the CPU side
    cudaMemcpy(out.data(), d_out, nParticles * sizeof(double), cudaMemcpyDeviceToHost);
    std::cout << "# xPos = " << xPos << ", dt = " << dt << ", tMax = " << tMax
          << ", temp = " << temp << ", nParticles = " << nParticles
          << ", seed = " << seed << '\n';
    std::cout << std::setprecision(10);
    for (int i = 0; i < nParticles; i++) {
        std::cout << out[i] << '\n';
    }

    cudaFree(d_out);
    return 0;

    


}

// Gradient of the 1D double well V(x) = (x^2 - 1)^2
__device__ double gradV(double xPos) {
    return 4.0 * xPos * (xPos * xPos - 1.0);
};

__device__ double langevinStep(double xPos, double dt, double noiseCoef, double randomNumber){
    return xPos - dt * gradV(xPos) + noiseCoef * randomNumber;
};


__global__ void langevinKernel(double* out, int nParticles, double x0, double dt, double noiseCoef, long long nSteps, unsigned long long seed) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i >= nParticles) return;
    curandStatePhilox4_32_10_t state;
    curand_init(seed, i, 0, &state);

    double x = x0;                                       // start position
    for (long long s = 0; s < nSteps; s++) {
        double r = curand_normal_double(&state); // random num
        x = langevinStep(x, dt, noiseCoef, r);
    }
    out[i] = x;
}