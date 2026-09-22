myinp = inputdlg({'GPUs to use','anistropy', 'mua', 'mus'},'Please input data!',1,{111111,0.8,0.003,0.03})


%%%GPU SETTINGS%%%
clear cfg cfgs;
cfg.gpuid = myinp{1};
cfg.autopilot = 1; %good to keep 1

%%%%%%%%%%%%%%%%% Variables %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
x_src_pos = 50;
y_src_pos = 50;
z_src_pos = 1;

x_dim = 100;
y_dim = 100;
z_dim = 200;

volume = ones(x_dim, y_dim, z_dim);
rand_seed = randi([1 2^31-1],1,1);


%%%%%%%%%%%%%%%%% Volume Parameters %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Below are required
cfg.vol =  uint8(volume); %Defines the size of the volume
mua = str2double(myinp{3});
mus = str2double(myinp{4});
g = str2double(myinp{2});
cfg.prop = [0 0 1 1; mua mus g 1];  % Defines the medium properties [mua mus g n], the first one is backround, it is often just set to [0 0 1 1], and does not do anything


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
cfg.bc = 'ccacca';  % sides are cyclic ends are absorbing
cfg.seed = rand_seed;



%%%%%%%%%%%%%%%%% Padding layers 
cfg.vol(:,:,1)   = 0;   % pad zero layer at top to enables reflectance tally
cfg.vol(:,:,end) = 0;   % pad zero layer at top to enables reflectance tally
cfg.issaveref = 1;

%Running the sim
[flux, detp] = mcxlab(cfg);
cwdref = sum(flux.dref, 4); % not reaaly needed cuz I have 1 gate but just in case

%%
R_mcx = sum(sum(abs(cwdref(:,:,1))));
T_mcx = sum(sum(abs(cwdref(:,:,end))));
%absorbed_fraction = sum(sum(sum(flux.data,4))) * mua * 5e-9;

R_mcx_fraction = R_mcx * 5e-9;
T_mcx_fraction = T_mcx * 5e-9;
%Confirmation_number = R_mcx_fraction + T_mcx_fraction + absorbed_fraction;

%N = 1e7;
%SE_R = sqrt(R_mcx_fraction * (1 - R_mcx_fraction) / N);
%SE_T = sqrt(T_mcx_fraction * (1 - T_mcx_fraction) / N);

% Display results
disp(R_mcx_fraction);
%disp(SE_R);
disp(T_mcx_fraction);
%disp(SE_T);
%disp(absorbed_fraction);
%disp(Confirmation_number);