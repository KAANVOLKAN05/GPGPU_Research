clear;
clc;

% ============================================================
% Angular fluence sampling for an MCX .mc2 volume
%
% Samples the MCX fluence at points located a fixed distance d
% from the source, only in front of the source.
%
% Default geometry:
%   source position  = [29, 0, 29]
%   source direction = +y
%   sampling plane   = x-y plane
%
% Angle convention:
%    0 degrees = straight ahead along +y
%  -90 degrees = toward -x
%  +90 degrees = toward +x
%
% Because the MCX JSON uses OutputType = "F", the loaded values
% are gate-integrated fluence, not fluence rate.
% ============================================================


% ---------------- USER SETTINGS ----------------

% This following path will take us to the mcx utils
mcx_utils = "mcx/utils";
addpath(mcx_utils);
% Path to the MCX .mc2 output file.
mc2_file =  "KV_v1.mc2";

% MCX volume dimensions: [Nx, Ny, Nz, Nt].
% Your current simulation has one time gate.
dims = [60, 120, 60, 1];

% Time gate to examine.
time_gate = 1;

% Source position in MCX coordinates.
% MCX coordinates are zero-based because OriginType is true.
source_pos = [29, 0, 29];

% Distance from the source, in voxel units.
% With the default LengthUnit, one voxel is usually 1 mm.
d = 20;

% Angular sampling range and resolution.
angle_min = 90;
angle_max = 90;
angle_step = 1;

% Sampling plane:
%   "xy" = sweep sideways in x while moving forward in y
%   "yz" = sweep vertically in z while moving forward in y
sampling_plane = "xy";

% Set true to use a logarithmic y-axis.
use_log_y = false;

% Output filenames.
plot_file = "fluence_vs_angle.png";
data_file = "fluence_vs_angle.csv";


% ---------------- LOAD MCX DATA ----------------


if exist(mc2_file, "file") ~= 2
    error("Could not find MCX output file: %s", mc2_file);
end

if time_gate < 1 || time_gate > dims(4)
    error("time_gate must be between 1 and %d.", dims(4));
end

fluence_all = loadmc2(mc2_file, dims, "float");

% loadmc2 may return a 3-D array when Nt = 1.
if ndims(fluence_all) == 3
    if time_gate ~= 1
        error("The loaded file contains only one time gate.");
    end
    F = fluence_all;
else
    F = fluence_all(:, :, :, time_gate);
end

[nx, ny, nz] = size(F);


% ---------------- BUILD SAMPLE POINTS ----------------

angles_deg = (angle_min : angle_step : angle_max)';
angles_rad = angles_deg * pi / 180;

sx = source_pos(1);
sy = source_pos(2);
sz = source_pos(3);

switch lower(sampling_plane)

    case "xy"
        % Angle 0 points along +y.
        % Positive angles bend toward +x.
        xq = sx + d .* sin(angles_rad);
        yq = sy + d .* cos(angles_rad);
        zq = sz + zeros(size(angles_rad));

    case "yz"
        % Angle 0 points along +y.
        % Positive angles bend toward +z.
        xq = sx + zeros(size(angles_rad));
        yq = sy + d .* cos(angles_rad);
        zq = sz + d .* sin(angles_rad);

    otherwise
        error('sampling_plane must be either "xy" or "yz".');
end


% ---------------- CHECK DOMAIN BOUNDS ----------------

% MCX coordinates corresponding to the stored voxel centers are:
%   x = 0 ... Nx-1
%   y = 0 ... Ny-1
%   z = 0 ... Nz-1
inside = ...
    xq >= 0 & xq <= nx - 1 & ...
    yq >= 0 & yq <= ny - 1 & ...
    zq >= 0 & zq <= nz - 1;

if ~any(inside)
    error(["None of the requested points are inside the MCX volume. " ...
           "Reduce d or change the angle range."]);
end

if any(~inside)
    fprintf("Warning: %d of %d sample points are outside the volume and will be omitted.\n", ...
            sum(~inside), numel(inside));
end


% ---------------- TRILINEAR INTERPOLATION ----------------

% interpn evaluates the fluence at non-integer MCX coordinates.
% This is better than rounding every sample to the nearest voxel.
fluence_samples = NaN(size(angles_deg));

fluence_samples(inside) = interpn( ...
    0:nx-1, ...
    0:ny-1, ...
    0:nz-1, ...
    F, ...
    xq(inside), ...
    yq(inside), ...
    zq(inside), ...
    "linear" ...
);


% ---------------- SAVE NUMERICAL VALUES ----------------

valid_angles = angles_deg(inside);
valid_x = xq(inside);
valid_y = yq(inside);
valid_z = zq(inside);
valid_fluence = fluence_samples(inside);

fid = fopen(data_file, "w");

if fid < 0
    error("Could not create output data file: %s", data_file);
end

fprintf(fid, "angle_deg,x,y,z,fluence\n");

for i = 1:numel(valid_angles)
    fprintf(fid, "%.8f,%.8f,%.8f,%.8f,%.12e\n", ...
            valid_angles(i), ...
            valid_x(i), ...
            valid_y(i), ...
            valid_z(i), ...
            valid_fluence(i));
end

fclose(fid);


% ---------------- CREATE PLOT ----------------

figure("visible", "off");

scatter(valid_angles, valid_fluence, 12, valid_fluence, "filled");
hold on;
plot(valid_angles, valid_fluence, "-");
hold off;

xlabel("Angle from source direction (degrees)");
ylabel("Fluence (normalized MCX units)");

title(sprintf( ...
    "Fluence at distance d = %.3g voxels, %s plane", ...
    d, upper(sampling_plane) ...
));

grid on;
colorbar;

if use_log_y
    set(gca, "yscale", "log");
end

print(plot_file, "-dpng", "-r300");


% ---------------- PRINT SUMMARY ----------------

[max_fluence, max_index] = max(valid_fluence);

fprintf("\nAngular sampling complete.\n");
fprintf("Sampling plane:       %s\n", upper(sampling_plane));
fprintf("Distance:             %.6g voxel units\n", d);
fprintf("Valid sample points:  %d\n", numel(valid_angles));
fprintf("Maximum fluence:      %.8e\n", max_fluence);
fprintf("Angle at maximum:     %.3f degrees\n", valid_angles(max_index));
fprintf("Plot saved as:        %s\n", plot_file);
fprintf("Values saved as:      %s\n", data_file);
