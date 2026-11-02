#include <iostream>
#include <string>
#include <cmath>
#include <random>
#include <iomanip>
#include <vector>


__global__ void testKernel(double* out, int nParticles);

__device__ double langevinStep(double xPos, double dt, double noiseCoef, double randomNumber);

__device__ double gradV(double xPos);

int main(int argc, char* argv[]) {
    double xPos = -1.0;
    double dt = 0.01;
    double tMax = 100.0;
    double temp = 0.5;
    int nParticles = 100000;

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
    testKernel<<<blocks, threadsPerBlock>>>(d_out, nParticles);


    std::vector<double> out(nParticles); //setting up memory on the CPU side
    cudaMemcpy(out.data(), d_out, nParticles * sizeof(double), cudaMemcpyDeviceToHost);
    for (int i = 0; i < 20; i++) {
    std::cout << i << ' ' << out[i] << '\n';
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

__global__ void testKernel(double* out, int nParticles) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;  // this thread's global index
    if (i < nParticles) {                                    // skip spare threads past the end
        out[i] = gradV(i * 0.1);                    // something easy to check
    }
}