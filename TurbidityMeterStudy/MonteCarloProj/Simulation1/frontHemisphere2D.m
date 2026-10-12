function [indices, thetaDeg, intensity, actualRadius] = ...
    frontHemisphere2D(data, center, srcdir, radius, dr)
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
% OUTPUTS:
%
%   indices
%       N x 3 array containing selected voxel indices:
%
%           [x y z]
%
%   thetaDeg
%       Signed angle of each voxel relative to srcdir, in degrees.
%
%       For srcdir = [0 0 1]:
%
%            theta = 0      -> straight ahead
%            theta > 0      -> toward +X
%            theta < 0      -> toward -X
%
%       Because only the front half is retained:
%
%            -90 <= theta <= 90
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
%   [idx, theta, I, R] = frontHemisphere2D( ...
%       fluence, [30 30 1], [0 0 1], 20, 1);
%
%   scatter(theta, I);
%   xlabel('Angle (degrees)');
%   ylabel('Fluence');
%   grid on;


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Input checking
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Convert to row vectors
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

    % The beam direction must lie in the X-Z plane.
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

    % A discrete grid cannot contain a fractional Y slice, so use the
    % voxel nearest the source.
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
    % Create only the X-Z slice
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    [X, Z] = ndgrid(xMin:xMax, zMin:zMax);

    Y = ySlice * ones(size(X));


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Displacement from source to every candidate voxel
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    dX = X - center(1);
    dY = Y - center(2);
    dZ = Z - center(3);


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Actual distance from source
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    R = sqrt(dX.^2 + dY.^2 + dZ.^2);


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Determine whether point is in front of source
    %
    % Dot product:
    %
    %   displacement . srcdir
    %
    % > 0 : in front
    % = 0 : exactly 90 degrees
    % < 0 : behind
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    forwardDistance = ...
          dX .* srcdir(1) ...
        + dY .* srcdir(2) ...
        + dZ .* srcdir(3);


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Select points approximately at requested radius
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    innerRadius = radius - dr/2;
    outerRadius = radius + dr/2;

    onShell = ...
        (R >= innerRadius) & ...
        (R <  outerRadius);


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Keep only front hemisphere
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    inFront = forwardDistance >= 0;


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Final selection
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    selected = onShell & inFront;


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Extract coordinates
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    Xs = X(selected);
    Ys = Y(selected);
    Zs = Z(selected);

    indices = [Xs, Ys, Zs];

    actualRadius = R(selected);


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Calculate SIGNED angle
    %
    % We work in the X-Z plane.
    %
    % For srcdir = [0 0 1]:
    %
    %               0 deg
    %                 ^
    %                 |
    %       -theta    |    +theta
    %              \  |  /
    %               \ | /
    %                \|/
    %              source
    %
    % Positive angle points toward +X.
    % Negative angle points toward -X.
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
    % Get MCX intensity/fluence value from each selected voxel
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    linearIndices = sub2ind( ...
        size(data), ...
        Xs, ...
        Ys, ...
        Zs);

    intensity = data(linearIndices);


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Sort everything by angle
    %
    % This makes plotting much easier.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    [thetaDeg, order] = sort(thetaDeg);

    indices      = indices(order, :);
    intensity    = intensity(order);
    actualRadius = actualRadius(order);

end