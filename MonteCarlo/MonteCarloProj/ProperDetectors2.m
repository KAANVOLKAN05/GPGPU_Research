disp("RUNNING NEW +Z DETECTOR VERSION");
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
tol = 1e-4;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Select photons leaving the +Z boundary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

on_zplus = abs(detp.p(:,3) - z_dim) < tol;

% Take a 1-mm-wide strip centered at Y = 15
y_middle = y_dim / 2;
dy = 1;

in_middle_strip = ...
    detp.p(:,2) >= y_middle - dy/2 & ...
    detp.p(:,2) <  y_middle + dy/2;

% Photon must leave +Z AND be within middle Y strip
selected = on_zplus & in_middle_strip;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Bin selected photons according to X
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

x_edges = 0:1:x_dim;
x_centers = x_edges(1:end-1) + 0.5;

x_signal = zeros(1, x_dim);

for i = 1:x_dim

    in_x_bin = ...
        detp.p(:,1) >= x_edges(i) & ...
        detp.p(:,1) <  x_edges(i+1);

    x_signal(i) = sum(detw(selected & in_x_bin));

end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Plot
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure;

bar(x_centers, x_signal, 1);
hold on;
plot(x_centers, x_signal, '-');

xlabel('X position (mm)');
ylabel('Escaping photon weight');
subtitle = sprintf('Junge = %.3f, n = %.3f, mua = %.6g, mus = %.6g', junge, index_of_ref, mua, mus);
title({myinp{6}, subtitle});

grid on;
hold off;
grid on;
filename = sprintf('TopDetectorTest_%.3f_n_%.3f_mua_%.6g_mus_%.6g.png',junge, index_of_ref, mua, mus);
print(filename, '-dpng', '-r300');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Information
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf('Total recorded photons: %d\n', length(detw));
fprintf('Photons through +Z center strip: %d\n', sum(selected));
fprintf('Total weight through +Z center strip: %.8g\n', ...
        sum(detw(selected)));