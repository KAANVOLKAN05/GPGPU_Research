function [indices, thetaDeg, intensity, actualRadius] = ...
    fullCircle2D(data, center, srcdir, radius, dr)

% INPUTS:
%
%   data
%       3-D array containing MCX fluence/intensity values.
%
%   center
%       Source position in MATLAB voxel-index coordinates:
%       [x y z]
%
%   srcdir
%       Source direction:
%       [dx dy dz]
%
%       For this X-Z slice function, the Y component should be zero.
%       Example:
%           srcdir = [0 0 1];
%
%   radius
%       Desired distance from the source, in voxels.
%
%   dr
%       Thickness of the sampling shell, in voxels.
%
%
% OUTPUTS:
%
%   indices
%       N x 3 array containing selected voxel indices:
%
%           [x y z]
%
%   thetaDeg
%       Signed angle relative to srcdir, in degrees.
%
%       For srcdir = [0 0 1]:
%
%            theta =    0   -> +Z, straight ahead
%            theta =   90   -> +X
%            theta =  -90   -> -X
%            theta = +/-180 -> -Z, directly behind
%
%       Full angular range:
%
%            -180 <= theta <= 180
%
%   intensity
%       MCX data value at each selected voxel.
%
%   actualRadius
%       Actual distance of every selected voxel from the source.
%
%
% EXAMPLE:
%
%   fluence = sum(flux.data, 4);
%
%   [idx, theta, I, R] = fullCircle2D( ...
%       fluence, [250 250 250], [0 0 1], 100, 1);
%
%   scatter(theta, log(I));
%   xlabel('Angle (degrees)');
%   ylabel('log(Fluence)');
%   xlim([-180 180]);
%   grid on;


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Input checking
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    center = double(center(:).');
    srcdir = double(srcdir(:).');


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Normalize source direction
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    srcNorm = norm(srcdir);

    if srcNorm == 0
        error('srcdir cannot be [0 0 0].');
    end

    srcdir = srcdir / srcNorm;


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % This function uses an X-Z slice
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if abs(srcdir(2)) > 1e-12
        error(['For this X-Z slice function, srcdir(2) must be zero. ', ...
               'Example: srcdir = [0 0 1].']);
    end


    gridSize = size(data);

    Nx = gridSize(1);
    Ny = gridSize(2);
    Nz = gridSize(3);


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Choose Y slice
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    ySlice = round(center(2));

    if ySlice < 1 || ySlice > Ny
        error('The source Y position lies outside the data volume.');
    end


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Find search region
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    outerRadius = radius + dr/2;

    xMin = max(1, floor(center(1) - outerRadius));
    xMax = min(Nx, ceil(center(1) + outerRadius));

    zMin = max(1, floor(center(3) - outerRadius));
    zMax = min(Nz, ceil(center(3) + outerRadius));


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Create X-Z slice
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    [X, Z] = ndgrid(xMin:xMax, zMin:zMax);

    Y = ySlice * ones(size(X));


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Displacement from source
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    dX = X - center(1);
    dY = Y - center(2);
    dZ = Z - center(3);


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Distance from source
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    R = sqrt(dX.^2 + dY.^2 + dZ.^2);


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Select points at requested radius
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    innerRadius = radius - dr/2;
    outerRadius = radius + dr/2;

    onShell = ...
        (R >= innerRadius) & ...
        (R <  outerRadius);


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % FULL 360 DEGREE SELECTION
    %
    % Unlike the previous function, we DO NOT remove points
    % behind the source.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    selected = onShell;


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Extract coordinates
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    Xs = X(selected);
    Ys = Y(selected);
    Zs = Z(selected);

    indices = [Xs, Ys, Zs];

    actualRadius = R(selected);


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Calculate signed angle
    %
    % For srcdir = [0 0 1]:
    %
    %                    0 deg
    %                      +Z
    %                       ^
    %                       |
    %          -90 deg      |      +90 deg
    %             -X <------o------> +X
    %                       |
    %                       |
    %                       v
    %                      -Z
    %                  +/-180 deg
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    sX = srcdir(1);
    sZ = srcdir(3);

    dot2D = ...
        sX .* dX(selected) + ...
        sZ .* dZ(selected);

    cross2D = ...
        sZ .* dX(selected) - ...
        sX .* dZ(selected);

    thetaDeg = atan2d(cross2D, dot2D);


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Get MCX intensity/fluence
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    linearIndices = sub2ind( ...
        size(data), ...
        Xs, ...
        Ys, ...
        Zs);

    intensity = data(linearIndices);


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Sort by angle
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    [thetaDeg, order] = sort(thetaDeg);

    indices      = indices(order, :);
    intensity    = intensity(order);
    actualRadius = actualRadius(order);

end
