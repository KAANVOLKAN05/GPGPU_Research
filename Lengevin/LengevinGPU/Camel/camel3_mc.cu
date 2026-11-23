#include <iostream>
#include <fstream>
#include <string>
#include <cmath>
#include <iomanip>
#include <vector>
#include <curand_kernel.h>

// Stops the program with a message if a CUDA call failed.
// Without this, a kernel built for the wrong architecture fails silently and the output is all zeros.
#define CUDA_CHECK(call)                                                          \
    do {                                                                          \
        cudaError_t err = (call);                                                 \
        if (err != cudaSuccess) {                                                 \
            std::cerr << "CUDA error: " << cudaGetErrorString(err)                \
                      << " (" << __FILE__ << ":" << __LINE__ << ")\n";            \
            std::exit(1);                                                         \
        }                                                                         \
    } while (0)


__global__ void langevinKernel(unsigned int* hist, int nParticles, double x0, double y0, double sigma,
                               double dt, double noiseCoef, long long nSteps, long long saveEvery,
                               int nBins, double L, unsigned long long seed);

__device__ void langevinStep(double& xPos, double& yPos, double dt, double noiseCoef, double rx, double ry);

__device__ void gradV(double xPos, double yPos, double& dVdx, double& dVdy);

__device__ void addToHist(unsigned int* hist, int frame, double xPos, double yPos, int nBins, double L);


int main(int argc, char* argv[]) {
    double xPos = 0.0;
    double yPos = 0.0;
    double sigma = 0.2;          // width of the starting Gaussian (0 = all particles start at one point)
    double dt = 0.005;           // x^5 term makes the force stiff, dt = 0.01 is unstable for |x| > ~2.5
    double tMax = 20.0;
    double temp = 0.25;
    int nParticles = 1000000;
    int nSaves = 100;
    int nBins = 100;
    double L = 2.5;              // histogram covers [-L, L] x [-L, L]
    unsigned long long seed = 42;
    std::string outName = "camel3";


    //Following section is for user flags
    for (int i = 1; i < argc; ++i) {
        std::string flag = argv[i];

        if (flag == "--help" || flag == "-h") {
            std::cout << "Usage: " << argv[0] << " [options]\n"
                << "  --xPos <value>        starting x of the Gaussian (default " << xPos << ")\n"
                << "  --yPos <value>        starting y of the Gaussian (default " << yPos << ")\n"
                << "  --sigma <value>       width of the starting Gaussian (default " << sigma << ")\n"
                << "  --dt <value>          time step (default " << dt << ")\n"
                << "  --tMax <value>        simulation time per particle (default " << tMax << ")\n"
                << "  --temp <value>        temperature (default " << temp << ")\n"
                << "  --nParticles <value>  number of particles (default " << nParticles << ")\n"
                << "  --nSaves <value>      number of saved frames after t = 0 (default " << nSaves << ")\n"
                << "  --nBins <value>       histogram bins per axis (default " << nBins << ")\n"
                << "  --L <value>           histogram range [-L, L] (default " << L << ")\n"
                << "  --seed <value>        random seed (default " << seed << ")\n"
                << "  --out <name>          output name, writes <name>_hist.bin and <name>_meta.txt (default " << outName << ")\n"
                << "  --help, -h            show this message\n";
            return 0;
        } else if (flag == "--xPos" && i + 1 < argc) {
            xPos = std::stod(argv[++i]);
        } else if (flag == "--yPos" && i + 1 < argc) {
            yPos = std::stod(argv[++i]);
        } else if (flag == "--sigma" && i + 1 < argc) {
            sigma = std::stod(argv[++i]);
        } else if (flag == "--dt" && i + 1 < argc) {
            dt = std::stod(argv[++i]);
        } else if (flag == "--tMax" && i + 1 < argc) {
            tMax = std::stod(argv[++i]);
        } else if (flag == "--temp" && i + 1 < argc) {
            temp = std::stod(argv[++i]);
        } else if (flag == "--nParticles" && i + 1 < argc) {
            nParticles = std::stoi(argv[++i]);
        } else if (flag == "--nSaves" && i + 1 < argc) {
            nSaves = std::stoi(argv[++i]);
        } else if (flag == "--nBins" && i + 1 < argc) {
            nBins = std::stoi(argv[++i]);
        } else if (flag == "--L" && i + 1 < argc) {
            L = std::stod(argv[++i]);
        } else if (flag == "--seed" && i + 1 < argc) {
            seed = std::stoull(argv[++i]);
        } else if (flag == "--out" && i + 1 < argc) {
            outName = argv[++i];
        } else {
            std::cerr << "Unknown or incomplete option: " << flag << '\n';
            return 1;
        }
    }

    double noiseCoef = std::sqrt(2.0 * temp * dt);
    long long nSteps = std::llround(tMax / dt);
    long long saveEvery = nSteps / nSaves;
    if (saveEvery < 1) saveEvery = 1;
    int nFrames = static_cast<int>(nSteps / saveEvery) + 1;   // frame 0 is t = 0, same as the Python code

    //Setting up the GPU memory: one nBins x nBins count grid per saved frame
    size_t histSize = static_cast<size_t>(nFrames) * nBins * nBins;
    unsigned int* d_hist;
    CUDA_CHECK(cudaMalloc(&d_hist, histSize * sizeof(unsigned int)));
    CUDA_CHECK(cudaMemset(d_hist, 0, histSize * sizeof(unsigned int)));

    int threadsPerBlock = 256;
    int blocks = (nParticles + threadsPerBlock - 1) / threadsPerBlock;

    langevinKernel<<<blocks, threadsPerBlock>>>(d_hist, nParticles, xPos, yPos, sigma, dt, noiseCoef,
                                                nSteps, saveEvery, nBins, L, seed);
    CUDA_CHECK(cudaGetLastError());          // catches launch errors (e.g. wrong -arch)
    CUDA_CHECK(cudaDeviceSynchronize());     // catches errors while the kernel runs

    std::vector<unsigned int> hist(histSize); //setting up memory on the CPU side
    CUDA_CHECK(cudaMemcpy(hist.data(), d_hist, histSize * sizeof(unsigned int), cudaMemcpyDeviceToHost));
    CUDA_CHECK(cudaFree(d_hist));

    // Raw counts, layout [frame][ix][iy], same layout as np.histogram2d output stacked over frames
    std::ofstream binFile(outName + "_hist.bin", std::ios::binary);
    binFile.write(reinterpret_cast<const char*>(hist.data()), histSize * sizeof(unsigned int));
    binFile.close();

    // Everything Python needs to rebuild the arrays
    std::ofstream metaFile(outName + "_meta.txt");
    metaFile << std::setprecision(17)
             << "nFrames " << nFrames << '\n'
             << "nBins " << nBins << '\n'
             << "L " << L << '\n'
             << "dt " << dt << '\n'
             << "saveEvery " << saveEvery << '\n'
             << "nParticles " << nParticles << '\n'
             << "temp " << temp << '\n'
             << "xPos " << xPos << '\n'
             << "yPos " << yPos << '\n'
             << "sigma " << sigma << '\n'
             << "seed " << seed << '\n';
    metaFile.close();

    std::cout << "# xPos = " << xPos << ", yPos = " << yPos << ", sigma = " << sigma
              << ", dt = " << dt << ", tMax = " << tMax << ", temp = " << temp
              << ", nParticles = " << nParticles << ", seed = " << seed << '\n'
              << "# wrote " << nFrames << " frames of " << nBins << "x" << nBins
              << " bins to " << outName << "_hist.bin\n";

    return 0;
}

// Gradient of the three-hump camel function
// V(x, y) = 2x^2 - 1.05x^4 + x^6/6 + xy + y^2
__device__ void gradV(double xPos, double yPos, double& dVdx, double& dVdy) {
    double x2 = xPos * xPos;
    dVdx = 4.0 * xPos - 4.2 * x2 * xPos + x2 * x2 * xPos + yPos;
    dVdy = xPos + 2.0 * yPos;
};

__device__ void langevinStep(double& xPos, double& yPos, double dt, double noiseCoef, double rx, double ry) {
    double dVdx, dVdy;
    gradV(xPos, yPos, dVdx, dVdy);
    xPos = xPos - dt * dVdx + noiseCoef * rx;
    yPos = yPos - dt * dVdy + noiseCoef * ry;
};

// Adds one particle to the histogram of one frame. Particles outside [-L, L]^2 are dropped,
// same as np.histogram2d. x = L exactly goes in the last bin, also same as numpy.
__device__ void addToHist(unsigned int* hist, int frame, double xPos, double yPos, int nBins, double L) {
    if (xPos < -L || xPos > L || yPos < -L || yPos > L) return;
    double binWidth = 2.0 * L / nBins;
    int ix = static_cast<int>((xPos + L) / binWidth);
    int iy = static_cast<int>((yPos + L) / binWidth);
    if (ix == nBins) ix = nBins - 1;
    if (iy == nBins) iy = nBins - 1;
    size_t index = (static_cast<size_t>(frame) * nBins + ix) * nBins + iy;
    atomicAdd(&hist[index], 1u);   // many particles can hit the same bin at the same time
};


__global__ void langevinKernel(unsigned int* hist, int nParticles, double x0, double y0, double sigma,
                               double dt, double noiseCoef, long long nSteps, long long saveEvery,
                               int nBins, double L, unsigned long long seed) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i >= nParticles) return;
    curandStatePhilox4_32_10_t state;
    curand_init(seed, i, 0, &state);

    // Starting Gaussian
    double2 r0 = curand_normal2_double(&state);   // two normal random numbers per call
    double x = x0 + sigma * r0.x;
    double y = y0 + sigma * r0.y;
    addToHist(hist, 0, x, y, nBins, L);

    int frame = 1;
    for (long long s = 0; s < nSteps; s++) {
        double2 r = curand_normal2_double(&state);
        langevinStep(x, y, dt, noiseCoef, r.x, r.y);

        if ((s + 1) % saveEvery == 0) {
            addToHist(hist, frame, x, y, nBins, L);
            frame++;
        }
    }
}
