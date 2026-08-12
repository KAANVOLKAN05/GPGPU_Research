
%%%GPU SETTINGS%%%
clear cfg cfgs;
% How many GPUs to use
cfg.gpuid = '1';
% cfg.gpuid='11'; % use two GPUs together
cfg.autopilot = 1; %good to keep 1

%%%%%%%%%%%%%%%%% Imports %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The file below loads a struct with the inverse cdf values stored under FFgenerator.invcdf 
load('TableGenerate/FournierForandTable.mat');

%%%%%%%%%%%%%%%%% Variables %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
volume = ones(100, 100, 100);
rand_seed = randi([1 2^31-1],1,1);


%%%%%%%%%%%%%%%%% Volume Parameters %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Below are required
cfg.vol =  uint8(volume); %Defines the size of the volume
cfg.prop = [0 0 1 1; 0.05 0.2 0 1.37];  % Defines the medium properties [mua mus g n], the first one is backround, it is often just set to [0 0 1 1], and does not do anything

%%%%%%%%%%%%%%%%% Source Parameters %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Below are required
cfg.nphoton = 1e6;
cfg.srcpos = [30 30 1];
cfg.srcdir = [0,0,1];
%cfg.srctype = 'pencil';

%%%%%%%%%%%%%%%%% MonteCarlo Settings %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Below are required
cfg.tstart = 0; %starting time of the simulation (in seconds)
cfg.tstep = 5e-10;    %time-gate width of the simulation (in seconds)
cfg.tend = 5e-9;      %ending time of the simulation (in second)

%Below are optional
cfg.seed = rand_seed;



% define phase function using cfg.invcdf
cfg.invcdf = FFgenerator.invcdf;
%flux = mcxlab(cfg);


%%%%%%%%%%%%%%%%% Personal Plot Settings %%%%%%%%%%%%%%%%%%%%%%%%%

fluxs = mcxlab(cfg);
total_flux = sum(fluxs.data, 4);
figure;  %Opens a new figure window and makes it the active plotting window
plotdata = squeeze(log(total_flux(:, 30, :)));
imagesc(plotdata);
axis image; % Makes units on the x and y axis equally spaced
colorbar; % Adds a color scale beside the image
title('Template');
print('Template.png', '-dpng', '-r300');
