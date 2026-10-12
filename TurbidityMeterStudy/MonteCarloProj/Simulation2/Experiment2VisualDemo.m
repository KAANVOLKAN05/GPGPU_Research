
myinp = inputdlg({'GPUs to use','Junge','Index of Refraction', 'mua', 'mus'},'Please input data!',1,{111111,3.56,1.09,0.0001,0.3})

%%%GPU SETTINGS%%%
clear cfg cfgs;
% How many GPUs to use
 % use six GPUs together
cfg.gpuid = myinp{1};
cfg.autopilot = 1; %good to keep 1

%%%%%%%%%%%%%%%%% Fornier Forand Generation %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The function below generates a fornier forand inverse table
junge = str2num (myinp{2});
index_of_ref = str2num (myinp{3});
FFgenerator = FornierForandTableGenerator(junge, index_of_ref);
disp("Generated Table for Fornier Forand with given parameters")

%%%%%%%%%%%%%%%%% Variables %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

voxel_size = 0.2;  % mm per voxel

x_src_pos = 15 / voxel_size;
y_src_pos = 15 / voxel_size;
z_src_pos = 1 / voxel_size;

x_dim = 30 / voxel_size;
y_dim = 30 / voxel_size;
z_dim = 80 / voxel_size;

volume = ones(x_dim, y_dim, z_dim);
rand_seed = randi([1 2^31-1],1,1);


%%%%%%%%%%%%%%%%% Volume Parameters %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Below are required
cfg.vol =  uint8(volume); %Defines the size of the volume
mua = str2double(myinp{4});
mus = str2double(myinp{5});
cfg.prop = [0 0 1 1; mua mus 0.94 1.37];  % Defines the medium properties [mua mus g n], the first one is backround, it is often just set to [0 0 1 1], and does not do anything

%%%%%%%%%%%%%%%%% Source Parameters %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Below are required
cfg.nphoton = 1e7;
cfg.srcpos = [x_src_pos y_src_pos z_src_pos];
cfg.srcdir = [0,0,1];
%cfg.srctype = 'pencil';

%%%%%%%%%%%%%%%%% MonteCarlo Settings %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Below are required
cfg.tstart = 0; %starting time of the simulation (in seconds)
cfg.tstep = 5e-9;    %time-gate width of the simulation (in seconds)
cfg.tend = 5e-9;      %ending time of the simulation (in second)
cfg.bc = 'aaaaaa';
%Below are optional
cfg.seed = rand_seed;
cfg.unitinmm = voxel_size;



% define phase function using cfg.invcdf
%cfg.invcdf = FFgenerator.invcdf;

% define Henyey-Greenstein phase function using cfg.invcdf
invhg = @(u, g) (1 + g * g - ((1 - g * g) ./ (1 - g + 2 * g * u)).^2) ./ (2 * g);
cfg.invcdf = invhg(0.01:0.01:1 - 0.01, 0.8);
%%%%%%%%%%%%%%%%% apply mcxlab functions %%%%%%%%%%%%%%%%%%%%%%%%%

fluxs = mcxlab(cfg);


total_flux = sum(fluxs.data, 4);


%%%%%%%%%%%%%%%%% Personal Plot Settings %%%%%%%%%%%%%%%%%%%%%%%%%

figure;  %Opens a new figure window and makes it the active plotting window
%figure('Position', [100, 100, 1200, 400]);
plotdata = squeeze(log10(total_flux(:, y_src_pos, :)));
z_mm = (1:z_dim) * voxel_size;
x_mm = (1:x_dim) * voxel_size;

imagesc(z_mm, x_mm, plotdata);
%axis normal;
axis image; % Makes units on the x and y axis equally spaced
colorbar; % Adds a color scale beside the image
xlabel('x axis (mm)');
ylabel('z axis (mm)');
xticks(0:5:80);
cb = colorbar;
ylabel(cb, 'log_{10}(Fluence)');
caxis([4 6]);   % fixed color range for every graph

subtitle = sprintf('Junge = %.3f, n = %.3f, mua = %.6g, mus = %.6g', junge, index_of_ref, mua, mus);
title({
    'Fluence over space'
    subtitle
});
%set(gca, 'Position', [0.13 0.10 0.70 0.78]);
print('Experiment2Visualision.png', '-dpng', '-r600');
