%Hello

%The purpose of this code is to generate an inverse cdf sampling table of the fornier forand function which is not easily iversible.

%The process will be as following:
%Solve the FF for angle values 0 to pi with a very fine grid
%Extract a a smaller table of results of unifromly distributed from the output space

function FFgenerator = FornierForandTableGenerator(mu, n)


    %Defined variables
    N = 100000
    theta = linspace(pi, 1e-4, N);
    g = cos(theta);
    %mu = 4.874
    %n = 1.15

    %Fornier Forand functio
    %To easily define the function, I will define v and psi
    v = (3 - mu)/2;
    psi = (4 / (3 * (n-1) ^ 2)) .* ((1 .- g) ./ 2);
    psi_pi = (4/(3*(n-1)^2));
    FF = (1 ./ (4*pi .* (1 .- psi) .^ 2 .* psi .^ v)) .* (v .* (1 .- psi) .- (1 .- psi .^ v) .+ (psi .* (1 .- psi .^ v) .- v .* (1 .- psi)) .* ((2 ./ (1 .- g)))) .+ ((1 .- psi_pi .^ v) ./ (16*pi .* (psi_pi .- 1) .* psi_pi .^v)) .* (3 .* (g) .^ 2 .- 1);

    % Getting the cumulitive prob of FF
    p_g = 2*pi .* FF; % Multiplying with 2 pi beacsue it will come in while multiplying with the aziumthal angle
    norm = trapz(g, p_g);  %Ideally should be 1 but is not due to numerical stuff
    CDF = cumtrapz(g, p_g);
    trueCDF = CDF ./ norm;

    %% Getting the inverse prob of FF
    u = 0.01:0.001:0.99;
    invcdf = interp1(trueCDF, g, u);



    % Creating a quick little struct for easy access
    FFgenerator.g = g;
    FFgenerator.mu = mu;
    FFgenerator.n = n;
    FFgenerator.v = v;
    FFgenerator.psi = psi;
    FFgenerator.psi_pi = psi_pi;
    FFgenerator.FF = FF;
    FFgenerator.p_g = p_g;
    FFgenerator.norm = norm;
    FFgenerator.CDF = CDF;
    FFgenerator.trueCDF = trueCDF;
    FFgenerator.invcdf = invcdf;

end


%save('-mat7-binary', 'FournierForandTable.mat', 'FFgenerator');
%figure;
%loglog(theta, FF);
%xlabel('Scattering Angle \theta (radians)');
%ylabel('Fournier-Forand Phase Function');
%title('Fournier-Forand Phase Function');
%grid on;
%print('FF_vs_theta.png', '-dpng');



