#include <iostream>
#include <string>

double langevinStep(double xPos, double dt, double noiseCoef, double randomNumber);

double gradV(double xPos);

int main(int argc, char* argv[]) {
    double xPos = 0.0;
    double dt = 0.1;
    double tMax = 1.0;

    
    for (int i = 1; i < argc; ++i) {
        std::string flag = argv[i];

        if (flag == "--xPos" && i + 1 < argc) {
            xPos = std::stod(argv[++i]);
        } else if (flag == "--dt" && i + 1 < argc) {
            dt = std::stod(argv[++i]);
        } else if (flag == "--tMax" && i + 1 < argc) {
            tMax = std::stod(argv[++i]);
        } else {
            std::cerr << "Unknown or incomplete option: " << flag << '\n';
            return 1;
        }
    }
    std::cout << "x = " << xPos << ", dt = " << dt << ", tMax = " << tMax << '\n';
}

// Gradient of the 1D double well V(x) = (x^2 - 1)^2
double gradV(double xPos) {
    return 4.0 * xPos * (xPos * xPos - 1.0);
};

double langevinStep(double xPos, double dt, double noiseCoef, double randomNumber){
    return xPos - dt * gradV(xPos) + noiseCoef * randomNumber;
};

