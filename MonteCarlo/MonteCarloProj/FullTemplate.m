
%Info for all these found in https://github.com/fangq/mcx/tree/master/mcxlab README
%%%GPU SETTINGS%%%
clear cfg cfgs;
% How many GPUs to use
cfg.gpuid = '1';
% cfg.gpuid='11'; % use two GPUs together
cfg.autopilot = 1; %good to keep 1


%%%%%%%%%%%%%%%%% Variables %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
volume = ones(100, 100, 100);
rand_seed = randi([1 2^31-1],1,1);


%%%%%%%%%%%%%%%%% Volume Parameters %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Below are required
cfg.vol =  uint8(volume); %Defines the size of the volume
cfg.prop = [0 0 1 1; 0.05 0.2 0 1.37];  % Defines the medium properties [mua mus g n], the first one is backround, it is often just set to [0 0 1 1], and does not do anything

%Below are optional
%cfg.bc = ; %This one is the per-face boundary condition (BC), a strig of 6 letters (case insensitive) for bounding box faces at -x,-y,-z,+x,+y,+z axes. 
%cfg.unitinmm = ;  %defines the length unit for a grid edge length [1.0]
%cfg.shapes = ; example is given in <demo_mcxyz_skinvessel.m>


%%%%%%%%%%%%%%%%% Source Parameters %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Below are required
cfg.nphoton = 1e6;
cfg.srcpos = [30 30 1];
cfg.srcdir = [0,0,1];
%cfg.srctype = 'pencil';

%Below are optional
%cfg.angleinvcdf = ;  %user-specified launch angle distribution for more info check the github
%cfg.{srcparam1,srcparam2} = ;
%cfg.srcpattern = ;
%cfg.srcnum = ;
%cfg.srcid = ;
%cfg.omega = ; %has to do with modulation
%cfg.srciquv = ;
%cfg.lambda = ; Source wavelength for polarized MC
%cfg.issrcfrom0 = ;

%%%%%%%%%%%%%%%%% Detector Parameters %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Below are optional
%cfg.detpos = ;    %An N by 4 array, each row specifying a detector: [x,y,z,radius]
%cfg.maxdetphoton = ;  %Maximum number of photons saved by the detectors [1000000]

%%%%%%%%%%%%%%%%% MonteCarlo Settings %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Below are required
cfg.tstart = 0; %starting time of the simulation (in seconds)
cfg.tstep = 5e-10;    %time-gate width of the simulation (in seconds)
cfg.tend = 5e-9;      %ending time of the simulation (in second)

%Below are optional
cfg.seed = rand_seed;
%cfg.respin = ;
%cfg.isreflect = ;
%cfg.isnormalized = ;
%cfg.isspecular = ;
%cfg.maxgate = ;
%cfg.minenergy = ;
%cfg.invcdf = ; %Good stuff, will be used by Kaan Volkan
%cfg.gscatter = ;


%%%%%%%%%%%%%%%%% Output Parameters %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Below are optioanal
%cfg.savedetflag
%cfg.issaveexit
%cfg.ismomentum
%cfg.issaveref
%cfg.issave2pt
%cfg.issavedet
%cfg.outputtype
%cfg.session



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



