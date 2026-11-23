#include <iostream>
#include <fstream>
#include <string>
#include <cmath>
#include <cstdint>
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


__global__ void initKernel(double* x, double* y, curandStatePhilox4_32_10_t* states, int nParticles,
                           double x0, double y0, double sigma, unsigned long long seed);

__global__ void langevinKernel(double* x, double* y, curandStatePhilox4_32_10_t* states, int nParticles,
                               double dt, double noiseCoef, long long nSteps);

__device__ void langevinStep(double& xPos, double& yPos, double dt, double noiseCoef, double rx, double ry);

__device__ void gradV(double xPos, double yPos, double& dVdx, double& dVdy);

void writeNpyHeader(std::ofstream& f, const std::string& descr, const std::vector<size_t>& shape);


int main(int argc, char* argv[]) {
    double xPos = 0.0;
    double yPos = 0.0;
    double sigma = 0.2;          // width of the starting Gaussian (0 = all particles start at one point)
    double dt = 0.005;           // x^5 term makes the force stiff, dt = 0.01 is unstable for |x| > ~2.5
    double tMax = 20.0;
    double temp = 0.25;
    int nParticles = 1000000;
    long long saveEvery = 40;    // save positions every n steps (40 * 0.005 = every 0.2 time units)
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
                << "  --saveEvery <value>   save positions every n steps (default " << saveEvery << ")\n"
                << "  --seed <value>        random seed (default " << seed << ")\n"
                << "  --out <name>          writes <name>_pos.npy and <name>_t.npy (default " << outName << ")\n"
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
        } else if (flag == "--saveEvery" && i + 1 < argc) {
            saveEvery = std::stoll(argv[++i]);
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
    if (saveEvery < 1) saveEvery = 1;
    long long nFrames = nSteps / saveEvery + 1;   // frame 0 is t = 0, same as the Python code

    double fileGB = 2.0 * sizeof(float) * nParticles * nFrames / 1e9;
    std::cout << "# xPos = " << xPos << ", yPos = " << yPos << ", sigma = " << sigma
              << ", dt = " << dt << ", tMax = " << tMax << ", temp = " << temp
              << ", nParticles = " << nParticles << ", saveEvery = " << saveEvery
              << ", seed = " << seed << '\n'
              << "# " << nFrames << " frames, output size " << std::setprecision(3) << fileGB << " GB\n";

    //Setting up the GPU memory: current positions and one random number generator per particle.
    //These stay on the GPU between frames, so GPU memory use does not grow with the number of frames.
    double* d_x;
    double* d_y;
    curandStatePhilox4_32_10_t* d_states;
    CUDA_CHECK(cudaMalloc(&d_x, nParticles * sizeof(double)));
    CUDA_CHECK(cudaMalloc(&d_y, nParticles * sizeof(double)));
    CUDA_CHECK(cudaMalloc(&d_states, nParticles * sizeof(curandStatePhilox4_32_10_t)));

    int threadsPerBlock = 256;
    int blocks = (nParticles + threadsPerBlock - 1) / threadsPerBlock;

    //Setting up memory on the CPU side, one frame at a time
    std::vector<double> x(nParticles), y(nParticles);
    std::vector<float> frame(2 * static_cast<size_t>(nParticles));   // [x of all particles, y of all particles]

    // Output file, shape (nFrames, 2, nParticles): pos[k, 0] is x at frame k, pos[k, 1] is y
    std::ofstream posFile(outName + "_pos.npy", std::ios::binary);
    writeNpyHeader(posFile, "<f4", {static_cast<size_t>(nFrames), 2, static_cast<size_t>(nParticles)});

    std::vector<double> times(nFrames);

    initKernel<<<blocks, threadsPerBlock>>>(d_x, d_y, d_states, nParticles, xPos, yPos, sigma, seed);
    CUDA_CHECK(cudaGetLastError());

    for (long long k = 0; k < nFrames; k++) {
        if (k > 0) {
            // Move every particle forward saveEvery steps
            langevinKernel<<<blocks, threadsPerBlock>>>(d_x, d_y, d_states, nParticles, dt, noiseCoef, saveEvery);
            CUDA_CHECK(cudaGetLastError());
        }

        // cudaMemcpy waits for the kernel to finish before copying
        CUDA_CHECK(cudaMemcpy(x.data(), d_x, nParticles * sizeof(double), cudaMemcpyDeviceToHost));
        CUDA_CHECK(cudaMemcpy(y.data(), d_y, nParticles * sizeof(double), cudaMemcpyDeviceToHost));

        // Simulation runs in double, saved as float to halve the file size
        for (int i = 0; i < nParticles; i++) {
            frame[i] = static_cast<float>(x[i]);
            frame[nParticles + i] = static_cast<float>(y[i]);
        }
        posFile.write(reinterpret_cast<const char*>(frame.data()), frame.size() * sizeof(float));
        times[k] = k * saveEvery * dt;
    }
    posFile.close();

    std::ofstream tFile(outName + "_t.npy", std::ios::binary);
    writeNpyHeader(tFile, "<f8", {static_cast<size_t>(nFrames)});
    tFile.write(reinterpret_cast<const char*>(times.data()), nFrames * sizeof(double));
    tFile.close();

    std::cout << "# wrote " << outName << "_pos.npy and " << outName << "_t.npy\n";

    CUDA_CHECK(cudaFree(d_x));
    CUDA_CHECK(cudaFree(d_y));
    CUDA_CHECK(cudaFree(d_states));
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

// Sets up each particle's random number generator and draws its starting position
__global__ void initKernel(double* x, double* y, curandStatePhilox4_32_10_t* states, int nParticles,
                           double x0, double y0, double sigma, unsigned long long seed) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i >= nParticles) return;
    curand_init(seed, i, 0, &states[i]);

    double2 r = curand_normal2_double(&states[i]);   // two normal random numbers per call
    x[i] = x0 + sigma * r.x;
    y[i] = y0 + sigma * r.y;
}

// Moves each particle forward nSteps steps, continuing from where the last call stopped
__global__ void langevinKernel(double* x, double* y, curandStatePhilox4_32_10_t* states, int nParticles,
                               double dt, double noiseCoef, long long nSteps) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i >= nParticles) return;

    // Work on local copies (registers), write back once at the end
    curandStatePhilox4_32_10_t state = states[i];
    double xi = x[i];
    double yi = y[i];

    for (long long s = 0; s < nSteps; s++) {
        double2 r = curand_normal2_double(&state);
        langevinStep(xi, yi, dt, noiseCoef, r.x, r.y);
    }

    x[i] = xi;
    y[i] = yi;
    states[i] = state;
}

// Writes the header of a .npy file so np.load knows the dtype and shape.
// The data is then written right after it, in C order.
// descr: "<f4" for float, "<f8" for double, "<u4" for unsigned int
void writeNpyHeader(std::ofstream& f, const std::string& descr, const std::vector<size_t>& shape) {
    std::string shapeStr = "(";
    for (size_t s : shape) shapeStr += std::to_string(s) + ", ";
    shapeStr += ")";
    std::string header = "{'descr': '" + descr + "', 'fortran_order': False, 'shape': " + shapeStr + ", }";
    size_t total = 10 + header.size() + 1;                       // magic + version + length + header + '\n'
    header += std::string((64 - total % 64) % 64, ' ') + '\n';   // data starts on a 64-byte boundary
    uint16_t headerLen = static_cast<uint16_t>(header.size());

    f.write("\x93NUMPY\x01\x00", 8);
    f.write(reinterpret_cast<const char*>(&headerLen), 2);       // little-endian on x86
    f << header;
}
