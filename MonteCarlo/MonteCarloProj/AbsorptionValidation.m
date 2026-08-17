
myinp = inputdlg({'GPUs to use','Junge','Index of Refraction', 'mua(ignored for this test)', 'mus(set to ~0)','Title'},'Please input data!',1,{111111,3.56,1.09,0.00021,0.0000001, "MonteCarlo"})

%%%GPU SETTINGS%%%
clear cfg cfgs;
cfg.gpuid = myinp{1};
cfg.autopilot = 1; %good to keep 1

%%%%%%%%%%%%%%%%% Imports %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The file below loads a struct with the inverse cdf values stored under FFgenerator.invcdf 
junge = str2num (myinp{2});
index_of_ref = str2num (myinp{3});
FFgenerator = FornierForandTableGenerator(junge, index_of_ref);
disp("Generated Table for Fornier Forand with given parameters")

%%%%%%%%%%%%%%%%% Variables %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
x_src_pos = 250;
y_src_pos = 250;
z_src_pos = 250;

x_dim = 500;
y_dim = 500;
z_dim = 500;

volume = ones(x_dim, y_dim, z_dim);
rand_seed = randi([1 2^31-1],1,1);


%%%%%%%%%%%%%%%%% Volume Parameters %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Below are required
cfg.vol =  uint8(volume); %Defines the size of the volume
mua = str2double(myinp{4});
mus = str2double(myinp{5});
%cfg.prop = [0 0 1 1; mua mus 0.6 1.37];  % Defines the medium properties [mua mus g n], the first one is backround, it is often just set to [0 0 1 1], and does not do anything

%%%%%%%%%%%%%%%%% Source Parameters %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Below are required
cfg.nphoton = 1e4;
cfg.srcpos = [x_src_pos y_src_pos z_src_pos];
cfg.srcdir = [0,0,1];
cfg.srctype = 'pencil';

%%%%%%%%%%%%%%%%% MonteCarlo Settings %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Below are required
cfg.tstart = 0; %starting time of the simulation (in seconds)
cfg.tstep = 5e-10;    %time-gate width of the simulation (in seconds)
cfg.tend = 5e-9;      %ending time of the simulation (in second)
cfg.bc = 'aaaaaa';    %Makes all the walls absorbant
%Below are optional
cfg.seed = rand_seed;



% define phase function using cfg.invcdf
cfg.invcdf = FFgenerator.invcdf;

% define Henyey-Greenstein phase function using cfg.invcdf
%invhg = @(u, g) (1 + g * g - ((1 - g * g) ./ (1 - g + 2 * g * u)).^2) ./ (2 * g);
%cfg.invcdf = invhg(0.01:0.01:1 - 0.01, 0.8);
%%%%%%%%%%%%%%%%% apply mcxlab functions %%%%%%%%%%%%%%%%%%%%%%%%%
mua_list = [0.0000001, 0.00001, 0.0001, 0.001, 0.01, 0.1, 0.5];
values_list = [];
for mua_val = mua_list

    cfg.prop = [0 0 1 1; mua_val mus 0.6 1.37];  % Defines the medium properties [mua mus g n], the first one is backround, it is often just set to [0 0 1 1], and does not do anything
    fluxs = mcxlab(cfg);
    total_flux = sum(fluxs.data, 4);
    value = total_flux(250, 250, 350);
    % logValue = log10(value);
    values_list(end+1) = value;
end

%%%%%%%%%%%%%%%%% Personal Plot Settings %%%%%%%%%%%%%%%%%%%%%%%%%

figure;
hold on;
xlabel('Absorption coefficent');
ylabel('log(Fluence)');
subtitle = sprintf('Junge = %.3f, n = %.3f, mus = %.6g',junge, index_of_ref, mus);
title({'Fluence at 0 degrees vs Absorption coefficents', subtitle});
% scatter(mua_list, values_list, 20);
loglog(mua_list, values_list, 'o');
grid on;
hold off;
filename2 = sprintf('AbsorptionCoeffTest_Junge_%.3f_%.6g_mus_%.6g.png',junge, index_of_ref, mus);
print(filename2, '-dpng', '-r300');

