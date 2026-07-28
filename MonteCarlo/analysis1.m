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
