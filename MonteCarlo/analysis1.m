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

center_rate = fluence_rate(x_idx, y_idx, z_idx, 1);

fprintf("Center fluence rate: %.8e\n", center_rate);
