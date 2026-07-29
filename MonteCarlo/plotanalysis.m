clear;
clc;

% This following path will take us to the mcx utils
mcx_utils = "mcx/utils";
addpath(mcx_utils);

% Name of the mcx output file
filename = "KV_v1.mc2";

dims = [60, 120, 60, 1];

fluence = loadmc2(filename, dims, "float");

% Since you only have 1 time gate, take that 3D volume
F = fluence(:, :, :, 1);

% ----------------------------------------
% Choose what to plot
% ----------------------------------------

% Raw values can have a huge dynamic range, so log scale is usually better
Flog = log10(F + eps);

% Only plot voxels above a threshold
threshold = max(F(:)) * 1e-6;
mask = F >= threshold;

% Build coordinate arrays
% Use 0-based MCX-style coordinates on the axes
[x, y, z] = ndgrid(0:59, 0:119, 0:59);

% Extract only the selected voxels
xv = x(mask);
yv = y(mask);
zv = z(mask);
cv = Flog(mask);

% ----------------------------------------
% Make figure without displaying it
% ----------------------------------------
figure("visible", "off");

scatter3(xv, yv, zv, 12, cv, "filled");

xlabel("x");
ylabel("y");
zlabel("z");
title("3D heat map of log10 fluence");
colorbar;

axis equal;
grid on;
view(45, 25);

% Save to file
print("fluence_3d.png", "-dpng", "-r300");