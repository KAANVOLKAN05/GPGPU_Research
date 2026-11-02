#include <iostream>
#include <string>
#include <cmath>
#include <random>
#include <iomanip>

double langevinStep(double xPos, double dt, double noiseCoef, double randomNumber);

double gradV(double xPos);

int main(int argc, char* argv[]) {
    double xPos = -1.0;
    double dt = 0.01;
    double tMax = 100.0;
    double temp = 0.5;
    double nParticles = 100;

    
    for (int i = 1; i < argc; ++i) {
        std::string flag = argv[i];

        if (flag == "--xPos" && i + 1 < argc) {
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

    //AI guidance on the simple random num
    unsigned long long seed = 42;                       // seed
    std::mt19937_64 rng(seed);                          // the generator
    std::normal_distribution<double> normal(0.0, 1.0);  // mean 0, std dev 1


    std::cout << "# x = " << xPos << ", dt = " << dt << ", tMax = " << tMax << '\n';
    std::cout << std::setprecision(10);

    //We are using the function V(x) = (x^2 - 1)^2
    // x_{n+1} = x_n - dt * V'(x_n) + sqrt(2 * T * dt) * xi_n
    //noiseCoef = sqrt(2 * T * dt)
    double noiseCoef = std::sqrt(2.0 * temp * dt);
    int nSteps = tMax / dt;
    for (int p = 0; p < nParticles; p++) {
        double x = xPos;
        for (int i=1 ; i<= nSteps ; i++ ){
            double randomNumber = normal(rng);
            x = langevinStep(x , dt , noiseCoef , randomNumber);
        }
        std::cout << x << '\n'; 

    }
}

// Gradient of the 1D double well V(x) = (x^2 - 1)^2
double gradV(double xPos) {
    return 4.0 * xPos * (xPos * xPos - 1.0);
};

double langevinStep(double xPos, double dt, double noiseCoef, double randomNumber){
    return xPos - dt * gradV(xPos) + noiseCoef * randomNumber;
};

