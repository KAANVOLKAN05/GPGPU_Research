clear;
clc;

% This following path will take us to the mcx utils
mcx_utils = "mcx/utils";
addpath(mcx_utils);

% Name of the mcx output file
filename = "KV_v1.mc2";

% Dimentions of the geometry [Nx,Ny,Nz,num of time gates]
dim = dims = [60, 120, 60, 1];

% Loading the fluence rate
fluence_rate = loadmc2(filename, dims, "float");

disp("Loaded array size:");
disp(size(fluence_rate));


% Coordinates of interest (detector position), +1 is because we are 0 indexed

x_mcx = 29;
y_mcx = 90;
z_mcx = 29;

x_idx = x_mcx + 1;
y_idx = y_mcx + 1;
z_idx = z_mcx + 1;


% Variable is named rate but by using the F flag it is already integrated over time, so it is not the rate
center_rate = fluence_rate(x_idx, y_idx, z_idx, 1);

fprintf("Center fluence: %.8e\n", center_rate);


% Around the point of interest

radius = 1;

x_range = (x_mcx - radius : x_mcx + radius) + 1;
y_range = (y_mcx - radius : y_mcx + radius) + 1;
z_range = (z_mcx - radius : z_mcx + radius) + 1;

region = fluence_rate(x_range, y_range, z_range, 1);

region_mean = mean(region(:));
region_std  = std(region(:));
region_min  = min(region(:));
region_max  = max(region(:));

fprintf("Region mean fluence:    %.8e\n", region_mean);
fprintf("Region standard dev: %.8e\n", region_std);
fprintf("Region minimum:      %.8e\n", region_min);
fprintf("Region maximum:      %.8e\n", region_max);
