mcxroot = '/home/student/GPGPU_Research/MonteCarlo';
addpath('/home/student/GPGPU_Research/MonteCarlo/mcx/utils');
addpath(fullfile(mcxroot, 'mcxlab'));
addpath(fullfile(mcxroot, 'utils'));
rehash;

% only clear cfg to avoid accidentally clearing other useful data
clear cfg cfgs;





% Number of photons to simulate
cfg.nphoton = 1e6;
% Dimentions of the simulation in mm
xdim = 100;
ydim = 100;
zdim = 100;
cfg.vol = uint8(ones(xdim, ydim, zdim));
% Position of the source
cfg.srcpos = [30 30 1];
% Direction of the source
cfg.srcdir = [0 0 1];

% How many GPUs to use
cfg.gpuid = '11';
% cfg.gpuid='11'; % use two GPUs together
cfg.autopilot = 1; %good to keep 1

%Properties of the medium, the first one is the properteis of the outside
%Second one is the inside of our volume
cfg.prop = [0 0 1 1; 0.005 0.1 0 1.37]; 

%Start time, end time, and time step
cfg.tstart = 0;
cfg.tend = 5e-9;
cfg.tstep = 1e-10;

% calculate the flux distribution with the given config
flux = mcxlab(cfg);

%% define cfg as a struct array to run multiple simulations

cfgs(1) = cfg;
cfgs(2) = cfg;
cfgs(1).isreflect = 0;
cfgs(2).isreflect = 1;
cfgs(2).detpos = [30 20 1 1; 30 40 1 1; 20 30 1 1; 40 30 1 1];
% calculate the flux and partial path lengths for the two configurations
[fluxs, detps] = mcxlab(cfgs);

imagesc(squeeze(log(fluxs(1).data(:, 30, :, 1))) - squeeze(log(fluxs(2).data(:, 30, :, 1))));
