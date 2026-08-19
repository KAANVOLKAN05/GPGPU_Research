myinp = inputdlg({'GPUs to use','Junge','Index of Refraction', 'mua', 'mus','Title'},'Please input data!',1,{111111,3.4,1.1,0.003,0.03, "MonteCarlo"})

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
x_src_pos = 1;
y_src_pos = 15;
z_src_pos = 50;


x_dim = 100;
y_dim = 30;
z_dim = 100;

volume = ones(x_dim, y_dim, z_dim);
rand_seed = randi([1 2^31-1],1,1);

%%%%%%%%%%%%%%%%% Volume Parameters %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Below are required
cfg.vol =  uint8(volume); %Defines the size of the volume
cfg.unitinmm = 1;
mua = str2double(myinp{4});
mus = str2double(myinp{5});
cfg.prop = [0 0 1 1; mua mus 0.9 1.37];  % Defines the medium properties [mua mus g n], the first one is backround, it is often just set to [0 0 1 1], and does not do anything

%%%%%%%%%%%%%%%%% Source Parameters %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Below are required
cfg.nphoton = 1e6;

cfg.srcpos = [x_src_pos, y_src_pos, z_src_pos];
cfg.srcdir = [1, 0, 0];
cfg.srctype = 'pencil';

%%%%%%%%%%%%%%%%% MonteCarlo Settings %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Below are required
cfg.tstart = 0; %starting time of the simulation (in seconds)
cfg.tstep = 5e-9;    %time-gate width of the simulation (in seconds)
cfg.tend = 5e-9;      %ending time of the simulation (in second)
cfg.bc = 'aaaaaa000101';   %Makes all the walls absorbant and +Z and +Y record exiting photons
cfg.savedetflag = 'dpxv'; %Requests the data of the exiting photons are saved
%Below are optional
cfg.seed = rand_seed;

% define phase function using cfg.invcdf
cfg.invcdf = FFgenerator.invcdf;


%Run the sim
[flux, detp] = mcxlab(cfg);

% Analyze photons leaving the +Y boundary
% Calculate surviving weight of every recorded photon
detw = mcxdetweight(detp, cfg.prop, cfg.unitinmm);

% Middle of the +Y face in X
x_middle = x_dim / 2;
dx = 1;
tol = 1e-4;

% Determining tyhe photon exits through the top
on_zplus = abs(detp.p(:,3) - z_dim) < tol;

% Determining the photon is in the middle strip
in_middle_strip = detp.p(:,1) >= x_middle - dx/2 & detp.p(:,1) <  x_middle + dx/2;

y_middle = y_dim / 2;   % 15
dy = 1;

in_middle_strip = detp.p(:,2) >= y_middle - dy/2 & detp.p(:,2) <  y_middle + dy/2;

% Full agreement with our conditions
selected = on_zplus & in_middle_strip;

% Binning based on the z dimention
x_edges = 0:1:x_dim;
x_centers = x_edges(1:end-1) + 0.5;

x_signal = zeros(1, x_dim);

for i = 1:x_dim

    in_x_bin = ...
        detp.p(:,1) >= x_edges(i) & ...
        detp.p(:,1) < x_edges(i+1);

    x_signal(i) = sum(detw(selected & in_x_bin));
end

figure;
plot(x_centers, x_signal, '-o');

xlabel('X position (mm)');
ylabel('Escaping photon weight');
title('Signal on +Z detector plane');
grid on;


fprintf('Total recorded photons: %d\n', length(detw));
fprintf('Photons through +Y center strip: %d\n', sum(selected));
fprintf('Total weight through +Y center strip: %.8g\n', sum(detw(selected)));