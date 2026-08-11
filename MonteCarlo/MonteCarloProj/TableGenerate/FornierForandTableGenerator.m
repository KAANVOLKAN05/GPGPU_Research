%Hello

%The purpose of this code is to generate an inverse cdf sampling table of the fornier forand function which is not easily iversible.

%The process will be as following:
%Solve the FF for angle values 0 to pi with a very fine grid
%Extract a a smaller table of results of unifromly distributed from the output space

N = 1000

theta = linspace(pi, 1e-5, N);

g = cos(theta);
mu = 4
n = 1.1
%Fornier Forand functio
%To easily define the function, I will define v and psi
v = (3 - mu)/2
psi = (4 / (3 * (n-1) ^ 2)) .* ((1 .- g) ./ 2) 
psi_pi = (4/(3*(n-1)^2))
FF = (1 ./ (4*pi .* (1 .- psi) .^ 2 .* psi .^ v)) .* (v .* (1 .- psi) .- (1 .- psi .^ v) .+ (psi .* (1 .- psi .^ v) .- v .* (1 .- psi)) .* ((2 ./ (1 .- g)))) .+ ((1 .- psi_pi .^ v) ./ (16*pi .* (psi_pi .- 1) .* psi_pi .^v)) .* (3 .* (g) .^ 2 .- 1)


save('-mat7-binary', 'FournierForandTable.mat', 'FF', 'theta', 'g', 'mu', 'n', 'v');

%figure;
%loglog(theta, FF);
%xlabel('Scattering Angle \theta (radians)');
%ylabel('Fournier-Forand Phase Function');
%title('Fournier-Forand Phase Function');
%grid on;
%print('FF_vs_theta.png', '-dpng');



