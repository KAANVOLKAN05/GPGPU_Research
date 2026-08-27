function [x_bins, x_bin_positions] = BoundaryDetectorFunction(DomainSize, DomainProperties, SourcePosition, FornierForandTable, gpuid)
    
    
    cfg.gpuid = gpuid;
    cfg.autopilot = 1;
    cfg.nphoton = 1e7;
    cfg.maxdetphoton = 2e6;

    % Setting the domain size
    x_dim = DomainSize(1);
    y_dim = DomainSize(2);
    z_dim = DomainSize(3);

    volume = ones(x_dim, y_dim, z_dim);
    cfg.vol =  uint8(volume); %Defines the size of the volume
    cfg.unitinmm = 1;
    rand_seed = randi([1 2^31-1],1,1);


    % Setting the source position
    x_src_pos = SourcePosition(1);
    y_src_pos = SourcePosition(2);
    z_src_pos = SourcePosition(3);
    cfg.srcpos = [x_src_pos, y_src_pos, z_src_pos];
    cfg.srcdir = [1, 0, 0];
    cfg.srctype = 'pencil';

    % Setting the domain properties
    mua = DomainProperties(1)
    mus = DomainProperties(2)
    cfg.prop = [0 0 1 1; mua mus 0.9 1.37];  % Defines the medium properties [mua mus g n], the first one is backround, it is often just set to [0 0 1 1], and does not do anything


    %%%%%%%%%%%%%%%%% MonteCarlo Settings %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    cfg.tstart = 0; %starting time of the simulation (in seconds)
    cfg.tstep = 5e-9;    %time-gate width of the simulation (in seconds)
    cfg.tend = 5e-9;      %ending time of the simulation (in second)
    cfg.bc = 'aaaaaa000101';   %Makes all the walls absorbant and +Z and +Y record exiting photons
    cfg.savedetflag = 'dpxv'; %Requests the data of the exiting photons are saved
    cfg.seed = rand_seed;
    % define phase function using cfg.invcdf
    cfg.invcdf = FornierForandTable.invcdf;

    
    % Run the sim
    [flux, detp] = mcxlab(cfg);

    % Analysis is below now


    % Calculate surviving weight of every recorded photon
    detw = mcxdetweight(detp, cfg.prop, cfg.unitinmm);

    % Selecting the photons leaving the +Z plane
    tolerance = 1e-4;
    on_zplus = abs(detp.p(:,3) - z_dim) < tolerance;
    % Selecting the photons on a 1 mm strip through the middle of the +Z plane in the y direction
    y_middle = y_dim / 2;
    dy = 1;
    in_middle_strip = detp.p(:,2) >= y_middle - dy/2 & detp.p(:,2) <  y_middle + dy/2;
    % Photon must leave +Z AND be within middle Y strip
    selected = on_zplus & in_middle_strip;

    % Binning the x axis
    x_edges = 0:1:x_dim;
    x_bin_positions = x_edges(1:end-1) + 0.5;
    x_photon_intensity = zeros(1, x_dim);
    for i = 1:x_dim
        in_x_bin = detp.p(:,1) >= x_edges(i) & detp.p(:,1) <  x_edges(i+1);
        x_photon_intensity(i) = sum(detw(selected & in_x_bin));
    end
    x_bins = x_photon_intensity;
end
