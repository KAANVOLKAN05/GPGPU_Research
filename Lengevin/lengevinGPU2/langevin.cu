// =============================================================================
// langevin.cu
//
// 2D Langevin Monte Carlo on the GPU (CUDA), translated from the Python
// notebook FokkervsMC_2D.ipynb.
//
// What the program does:
//   1. Places n_particles at random around (x0, y0) (Gaussian, width sigma).
//   2. Moves every particle with the Langevin (Euler-Maruyama) update:
//        x_new = x - dt * dV/dx + sqrt(2*temp*dt) * random_normal
//        y_new = y - dt * dV/dy + sqrt(2*temp*dt) * random_normal
//   3. Every save_every steps, counts how many particles are in each bin of
//      a 2D grid (a histogram), directly on the GPU.
//   4. At the end, writes all histograms and the times to raw binary files.
//
// Only the histograms leave the GPU. The particle positions stay on the GPU
// the whole time, so the computer's RAM is barely used.
//
// Build (K80 = compute capability 3.7):
//   nvcc -O2 -arch=sm_37 -Wno-deprecated-gpu-targets langevin.cu -o langevin
//
// Run:
//   ./langevin                      (seed 42, output prefix "run")
//   ./langevin 7 gpu0               (seed 7,  output prefix "gpu0")
//   ./langevin 7 gpu0 125000        (same, but with 125000 particles)
//
// Output files:
//   <prefix>_counts.bin : int64,   shape (n_saves+1, n_bins, n_bins)
//   <prefix>_t.bin      : float64, shape (n_saves+1,)
// =============================================================================

#include <cstdio>
#include <cstdlib>
#include <cmath>
#include <vector>
#include <string>
#include <curand_kernel.h>


// -----------------------------------------------------------------------------
// Which potential to use.
//   0 = double well   V = -a x^2/2 + b x^4/4 + c y^2/2
//   1 = camel back    V = 2x^2 - 1.05x^4 + x^6/6 + xy + y^2
// Change this number and recompile to switch.
// -----------------------------------------------------------------------------
#define USE_CAMEL 1


// -----------------------------------------------------------------------------
// CUDA_CHECK
//
// Every CUDA function returns an error code. If something goes wrong (out of
// memory, bad launch, ...) CUDA does NOT stop the program on its own; it just
// returns an error and keeps going, which usually ends in a file full of zeros.
// This macro checks the code and stops the program with a readable message.
// -----------------------------------------------------------------------------
#define CUDA_CHECK(call)                                                     \
    do {                                                                     \
        cudaError_t err = (call);                                            \
        if (err != cudaSuccess) {                                            \
            printf("CUDA error: %s\n  at %s line %d\n",                      \
                   cudaGetErrorString(err), __FILE__, __LINE__);             \
            exit(1);                                                         \
        }                                                                    \
    } while (0)


// -----------------------------------------------------------------------------
// SimParams
//
// All simulation settings in one place. It is passed by value to every kernel,
// so each GPU thread gets its own read-only copy.
// -----------------------------------------------------------------------------
struct SimParams {
    // potential coefficients (only used by the double well)
    double a, b, c;

    // physics and time stepping
    double temp;          // temperature (same as alpha in the FD code)
    double dt;            // time step
    double t_max;         // end time

    // starting Gaussian
    double x0, y0;        // center
    double sigma;         // width

    // particles and random numbers
    int n_particles;
    unsigned long long seed;

    // histogram: n_bins x n_bins bins covering [-L, L] x [-L, L]
    double L;
    int n_bins;

    // how many histograms to save (plus one extra for t = 0)
    int n_saves;

    // derived values, computed in main() from the ones above
    double noise_coef;    // sqrt(2 * temp * dt)
    int n_steps;          // total number of time steps
    int save_every;       // steps between two saved histograms
    int n_frames;         // n_saves + 1
};


// =============================================================================
// DEVICE FUNCTIONS
// These run on the GPU and are called from inside the kernels.
// Each call works on ONE particle.
// =============================================================================

// -----------------------------------------------------------------------------
// gradV
//
// Gradient of the potential at one point (x, y).
//   in : x, y  -> position of one particle
//        p     -> parameters (a, b, c for the double well)
//   out: dVdx, dVdy -> written through the references
//
// This is the ONLY function that knows which potential is used.
// -----------------------------------------------------------------------------
__device__ void gradV(double x, double y, const SimParams& p,
                      double& dVdx, double& dVdy)
{
#if USE_CAMEL == 1
    // Double well: V = -a x^2/2 + b x^4/4 + c y^2/2
    dVdx = -p.a * x + p.b * x * x * x;
    dVdy =  p.c * y;
#else
    // Three-hump camel: V = 2x^2 - 1.05x^4 + x^6/6 + xy + y^2
    // (a, b, c are not used here)
    dVdx = 4.0 * x - 4.2 * x * x * x + x * x * x * x * x + y;
    dVdy = x + 2.0 * y;
#endif
}


// -----------------------------------------------------------------------------
// langevin_step
//
// Moves ONE particle forward by one time step dt.
//   in/out: x, y   -> position, overwritten with the new position
//   in/out: state  -> this particle's random number generator, advanced
//   in    : p      -> parameters (dt, noise_coef, and whatever gradV needs)
// -----------------------------------------------------------------------------
__device__ void langevin_step(double& x, double& y,
                              curandStatePhilox4_32_10_t& state,
                              const SimParams& p)
{
    // force from the potential
    double dVdx, dVdy;
    gradV(x, y, p, dVdx, dVdy);

    // two independent standard normal random numbers (mean 0, std 1)
    double2 z = curand_normal2_double(&state);

    // Euler-Maruyama update, same as the Python langevin_step
    x = x - p.dt * dVdx + p.noise_coef * z.x;
    y = y - p.dt * dVdy + p.noise_coef * z.y;
}


// =============================================================================
// KERNELS
// These are launched from main(). The GPU runs one thread per particle.
// Thread number i works ONLY on particle i (x[i], y[i], states[i]).
// =============================================================================

// -----------------------------------------------------------------------------
// init_particles
//
// Sets up the random number generator of every particle and places every
// particle at its random starting position.
//   in : p      -> n_particles, x0, y0, sigma, seed
//   out: x, y   -> starting positions          (device arrays, length n)
//   out: states -> one random generator each  (device array,  length n)
// -----------------------------------------------------------------------------
__global__ void init_particles(double* x, double* y,
                               curandStatePhilox4_32_10_t* states,
                               SimParams p)
{
    // which particle does this thread handle?
    int i = blockIdx.x * blockDim.x + threadIdx.x;

    // the last block can have more threads than particles left; those threads
    // have nothing to do
    if (i >= p.n_particles) return;

    // Give particle i its own random number stream.
    // Same seed for all, but the particle number i picks a different
    // "subsequence", so no two particles get the same random numbers.
    curand_init(p.seed, i, 0, &states[i]);

    // starting position: Gaussian around (x0, y0) with width sigma
    double2 z = curand_normal2_double(&states[i]);
    x[i] = p.x0 + p.sigma * z.x;
    y[i] = p.y0 + p.sigma * z.y;
}


// -----------------------------------------------------------------------------
// advance_particles
//
// Moves every particle forward by n_steps_chunk time steps.
//   in/out: x, y, states  -> positions and random generators (device arrays)
//   in    : n_steps_chunk -> how many steps to take (normally save_every)
//   in    : p             -> parameters
// -----------------------------------------------------------------------------
__global__ void advance_particles(double* x, double* y,
                                  curandStatePhilox4_32_10_t* states,
                                  int n_steps_chunk, SimParams p)
{
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i >= p.n_particles) return;

    // Copy this particle's data into local variables.
    // Local variables live in the thread's own fast storage (registers),
    // so the loop below does not have to touch the big arrays every step.
    double xi = x[i];
    double yi = y[i];
    curandStatePhilox4_32_10_t state = states[i];

    // take the steps
    for (int step = 0; step < n_steps_chunk; step++) {
        langevin_step(xi, yi, state, p);
    }

    // write the results back to the big arrays
    x[i] = xi;
    y[i] = yi;
    states[i] = state;
}


// -----------------------------------------------------------------------------
// histogram2d
//
// Counts how many particles are in each bin of the 2D grid.
// Same bins as the Python code: np.linspace(-L, L, n_bins + 1) in x and y.
//   in : x, y   -> positions (device arrays, length n)
//   in : p      -> n_particles, L, n_bins
//   out: counts -> one frame of n_bins * n_bins counts (device array).
//                  MUST be all zeros before the kernel runs.
//
// Layout: the count for bin (ix, iy) is stored at counts[ix * n_bins + iy],
// so ix (the x bin) is the first index, same as np.histogram2d.
// -----------------------------------------------------------------------------
__global__ void histogram2d(const double* x, const double* y,
                            unsigned long long* counts, SimParams p)
{
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i >= p.n_particles) return;

    // width of one bin
    double bin_width = (2.0 * p.L) / p.n_bins;

    // which bin is this particle in?
    // (x + L) shifts the range [-L, L] to [0, 2L], then divide by bin width
    int ix = (int)floor((x[i] + p.L) / bin_width);
    int iy = (int)floor((y[i] + p.L) / bin_width);

    // Particles outside [-L, L] are not counted (numpy does the same).
    if (ix < 0 || ix >= p.n_bins) return;
    if (iy < 0 || iy >= p.n_bins) return;

    // Add 1 to that bin.
    // Many threads can hit the same bin at the same moment. A normal
    // "counts[bin] += 1" would then lose some of the additions.
    // atomicAdd makes the threads take turns, so every particle is counted.
    atomicAdd(&counts[ix * p.n_bins + iy], 1ULL);
}


// =============================================================================
// HOST FUNCTIONS
// These run on the CPU.
// =============================================================================

// -----------------------------------------------------------------------------
// write_binary
//
// Writes a block of memory to a file, byte for byte, with no header.
//   in : path  -> file name
//   in : data  -> pointer to the data (in normal CPU memory)
//   in : bytes -> how many bytes to write
//   out: true if it worked, false if not
// -----------------------------------------------------------------------------
bool write_binary(const char* path, const void* data, size_t bytes)
{
    FILE* f = fopen(path, "wb");     // "wb" = write, binary mode
    if (f == NULL) {
        printf("Could not open %s for writing\n", path);
        return false;
    }

    size_t written = fwrite(data, 1, bytes, f);
    fclose(f);

    if (written != bytes) {
        printf("Could not write all data to %s\n", path);
        return false;
    }
    return true;
}


// =============================================================================
// MAIN
// =============================================================================
int main(int argc, char** argv)
{
    // -------------------------------------------------------------------------
    // 1. Settings
    // -------------------------------------------------------------------------
    SimParams p;

    // starting Gaussian (same for both potentials)
    p.x0 = 0.0;
    p.y0 = 0.0;
    p.sigma = 0.2;

    p.temp = 0.25;
    p.n_particles = 1000000;
    p.seed = 42;
    p.n_saves = 100;
    p.n_bins = 100;

#if USE_CAMEL == 0
    // double well, same values as the Python notebook
    p.a = 1.0;
    p.b = 2.0;
    p.c = 1.0;
    p.dt = 0.01;
    p.t_max = 4.0;
    p.L = 2.0;
#else
    // camel back, same values as the Python notebook
    p.a = 0.0;     // not used
    p.b = 0.0;     // not used
    p.c = 0.0;     // not used
    p.dt = 0.005;  // smaller step: the x^5 term makes the force large
    p.t_max = 20.0;
    p.L = 2.5;
#endif

    // command line: [seed] [output prefix] [number of particles]
    std::string prefix = "run";
    if (argc > 1) p.seed = strtoull(argv[1], NULL, 10);
    if (argc > 2) prefix = argv[2];
    if (argc > 3) p.n_particles = atoi(argv[3]);

    // derived values
    p.noise_coef = sqrt(2.0 * p.temp * p.dt);
    p.n_steps = (int)round(p.t_max / p.dt);   // round() avoids 399.999 -> 399
    p.save_every = p.n_steps / p.n_saves;
    p.n_frames = p.n_saves + 1;               // +1 for the t = 0 histogram

    // print what is about to run
    cudaDeviceProp prop;
    CUDA_CHECK(cudaGetDeviceProperties(&prop, 0));
    printf("GPU          : %s\n", prop.name);
    printf("Potential    : %s\n", USE_CAMEL ? "camel back" : "double well");
    printf("Particles    : %d\n", p.n_particles);
    printf("Seed         : %llu\n", p.seed);
    printf("dt, t_max    : %g, %g\n", p.dt, p.t_max);
    printf("Steps        : %d (save every %d)\n", p.n_steps, p.save_every);
    printf("Histogram    : %d x %d bins on [-%g, %g]\n",
           p.n_bins, p.n_bins, p.L, p.L);

    // -------------------------------------------------------------------------
    // 2. Allocate memory
    // -------------------------------------------------------------------------
    // Sizes in bytes
    size_t n = p.n_particles;
    size_t bins_per_frame = (size_t)p.n_bins * p.n_bins;
    size_t total_bins = bins_per_frame * p.n_frames;

    size_t bytes_positions = n * sizeof(double);
    size_t bytes_states = n * sizeof(curandStatePhilox4_32_10_t);
    size_t bytes_counts = total_bins * sizeof(unsigned long long);
    size_t bytes_times = p.n_frames * sizeof(double);

    // GPU memory (the "d_" prefix means "device", i.e. on the GPU).
    // These pointers can only be used by kernels and cudaMemcpy,
    // NOT read directly by CPU code.
    double* d_x = NULL;
    double* d_y = NULL;
    curandStatePhilox4_32_10_t* d_states = NULL;
    unsigned long long* d_counts = NULL;

    CUDA_CHECK(cudaMalloc(&d_x, bytes_positions));
    CUDA_CHECK(cudaMalloc(&d_y, bytes_positions));
    CUDA_CHECK(cudaMalloc(&d_states, bytes_states));
    CUDA_CHECK(cudaMalloc(&d_counts, bytes_counts));

    // start every histogram at zero
    CUDA_CHECK(cudaMemset(d_counts, 0, bytes_counts));

    // CPU memory (the "h_" prefix means "host", i.e. normal RAM).
    // Only the histograms and times come back to the CPU (~8 MB).
    std::vector<unsigned long long> h_counts(total_bins);
    std::vector<double> h_times(p.n_frames);

    // -------------------------------------------------------------------------
    // 3. How many threads to launch
    // -------------------------------------------------------------------------
    // Threads come in blocks. 256 threads per block is a common choice.
    // Enough blocks are launched to cover every particle (rounding up).
    int threads_per_block = 256;
    int blocks = (p.n_particles + threads_per_block - 1) / threads_per_block;

    // -------------------------------------------------------------------------
    // 4. Starting positions
    // -------------------------------------------------------------------------
    init_particles<<<blocks, threads_per_block>>>(d_x, d_y, d_states, p);
    CUDA_CHECK(cudaGetLastError());        // was the launch OK?
    CUDA_CHECK(cudaDeviceSynchronize());   // did the kernel finish without error?

    // -------------------------------------------------------------------------
    // 5. Histogram of the starting positions (frame 0, t = 0)
    // -------------------------------------------------------------------------
    // d_counts + 0 * bins_per_frame is the start of frame 0
    histogram2d<<<blocks, threads_per_block>>>(d_x, d_y, d_counts, p);
    CUDA_CHECK(cudaGetLastError());
    CUDA_CHECK(cudaDeviceSynchronize());
    h_times[0] = 0.0;

    // -------------------------------------------------------------------------
    // 6. Time loop: move, then histogram, n_saves times
    // -------------------------------------------------------------------------
    for (int k = 1; k <= p.n_saves; k++) {

        // move all particles forward by save_every steps
        advance_particles<<<blocks, threads_per_block>>>(
            d_x, d_y, d_states, p.save_every, p);
        CUDA_CHECK(cudaGetLastError());
        CUDA_CHECK(cudaDeviceSynchronize());

        // where frame k starts inside the big counts array
        unsigned long long* frame_k = d_counts + k * bins_per_frame;

        // count particles into frame k
        histogram2d<<<blocks, threads_per_block>>>(d_x, d_y, frame_k, p);
        CUDA_CHECK(cudaGetLastError());
        CUDA_CHECK(cudaDeviceSynchronize());

        // time of this frame
        h_times[k] = k * p.save_every * p.dt;

        // progress message every 10 frames
        if (k % 10 == 0) {
            printf("  saved frame %3d / %d   (t = %.3f)\n",
                   k, p.n_saves, h_times[k]);
        }
    }

    // -------------------------------------------------------------------------
    // 7. Copy all histograms from the GPU to the CPU
    // -------------------------------------------------------------------------
    CUDA_CHECK(cudaMemcpy(h_counts.data(), d_counts, bytes_counts,
                          cudaMemcpyDeviceToHost));

    // Quick sanity check: how many particles were inside the grid
    // in the first and in the last frame (should be <= n_particles).
    unsigned long long inside_first = 0;
    unsigned long long inside_last = 0;
    for (size_t j = 0; j < bins_per_frame; j++) {
        inside_first += h_counts[j];
        inside_last += h_counts[(size_t)p.n_saves * bins_per_frame + j];
    }
    printf("Particles inside grid: first frame %llu, last frame %llu (of %d)\n",
           inside_first, inside_last, p.n_particles);

    // -------------------------------------------------------------------------
    // 8. Write the results to disk
    // -------------------------------------------------------------------------
    std::string counts_file = prefix + "_counts.bin";
    std::string times_file = prefix + "_t.bin";

    bool ok1 = write_binary(counts_file.c_str(), h_counts.data(), bytes_counts);
    bool ok2 = write_binary(times_file.c_str(), h_times.data(), bytes_times);

    if (ok1 && ok2) {
        printf("Wrote %s and %s\n", counts_file.c_str(), times_file.c_str());
    }

    // -------------------------------------------------------------------------
    // 9. Free the GPU memory
    // (the std::vector buffers free themselves)
    // -------------------------------------------------------------------------
    CUDA_CHECK(cudaFree(d_x));
    CUDA_CHECK(cudaFree(d_y));
    CUDA_CHECK(cudaFree(d_states));
    CUDA_CHECK(cudaFree(d_counts));

    return (ok1 && ok2) ? 0 : 1;
}


// =============================================================================
// Reading the output in Python
// =============================================================================
//
//   import numpy as np
//
//   n_saves, n_bins, L = 100, 100, 2.0        # must match the C++ settings
//
//   counts = np.fromfile("run_counts.bin", dtype=np.int64)
//   counts = counts.reshape(n_saves + 1, n_bins, n_bins)
//   t_history = np.fromfile("run_t.bin", dtype=np.float64)
//
//   # same normalization as np.histogram2d(..., density=True)
//   bin_area = (2 * L / n_bins) ** 2
//   P_history = counts / (counts.sum(axis=(1, 2), keepdims=True) * bin_area)
//
//   bins = np.linspace(-L, L, n_bins + 1)     # for the plotting/RMS cells
//
// For several GPUs, add the counts arrays of all runs together first,
// then normalize.
// =============================================================================
