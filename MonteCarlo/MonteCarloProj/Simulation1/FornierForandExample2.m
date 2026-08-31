
myinp = inputdlg({'GPUs to use','Junge','Index of Refraction', 'mua', 'mus'},'Please input data!',1,{111111,3.56,1.09,0.00021,0.00027})

%%%GPU SETTINGS%%%
clear cfg cfgs;
% How many GPUs to use
%cfg.gpuid = '1';
%cfg.gpuid= '111111'; % use six GPUs together
cfg.gpuid = myinp{1};
cfg.autopilot = 1; %good to keep 1

%%%%%%%%%%%%%%%%% Imports %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The file below loads a struct with the inverse cdf values stored under FFgenerator.invcdf 
junge = str2num (myinp{2});
index_of_ref = str2num (myinp{3});
disp('BEFORE FF');
FFgenerator = FornierForandTableGenerator(junge, index_of_ref);
disp('AFTER FF');
disp("Generated Table for Fornier Forand with given parameters")

%%%%%%%%%%%%%%%%% Variables %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
x_src_pos = 250;
y_src_pos = 250;
z_src_pos = 250;

x_dim = 500;
y_dim = 500;
z_dim = 500;

volume = ones(x_dim, y_dim, z_dim);
rand_seed = randi([1 2^31-1],1,1);


%%%%%%%%%%%%%%%%% Volume Parameters %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Below are required
cfg.vol =  uint8(volume); %Defines the size of the volume
mua = str2double(myinp{4});
mus = str2double(myinp{5});
cfg.prop = [0 0 1 1; mua mus 0.6 1.37];  % Defines the medium properties [mua mus g n], the first one is backround, it is often just set to [0 0 1 1], and does not do anything

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
cfg.bc = 'aaaaaa';
%Below are optional
cfg.seed = rand_seed;



% define phase function using cfg.invcdf
cfg.invcdf = FFgenerator.invcdf;

% define Henyey-Greenstein phase function using cfg.invcdf
%invhg = @(u, g) (1 + g * g - ((1 - g * g) ./ (1 - g + 2 * g * u)).^2) ./ (2 * g);
%cfg.invcdf = invhg(0.01:0.01:1 - 0.01, 0.8);
%%%%%%%%%%%%%%%%% apply mcxlab functions %%%%%%%%%%%%%%%%%%%%%%%%%

disp('BEFORE MCX');
fluxs = mcxlab(cfg);
disp('AFTER MCX');

disp('BEFORE SUM');
total_flux = sum(fluxs.data, 4);
disp('AFTER SUM');

%%%%%%%%%%%%%%%%% Personal Plot Settings %%%%%%%%%%%%%%%%%%%%%%%%%

%figure;  %Opens a new figure window and makes it the active plotting window
plotdata = squeeze(log10(total_flux(:, 250, :)));
imagesc(plotdata);
axis image; % Makes units on the x and y axis equally spaced
colorbar; % Adds a color scale beside the image

cb = colorbar;
ylabel(cb, 'log_{10}(Fluence)');
caxis([-10 5]);   % fixed color range for every graph

subtitle = sprintf('Junge = %.3f, n = %.3f, mua = %.6g, mus = %.6g', junge, index_of_ref, mua, mus);
title({
    'Fluence over space'
    subtitle
});
set(gca, 'Position', [0.13 0.10 0.70 0.78]);
print('FluenceOverSpace.png', '-dpng', '-r300');

%%%%%%%%%%%%%%%%% Data Analysis %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

radii = [50, 80, 120, 150];

figure;
hold on;

for radius = radii

    [idx, theta, I, R] = fullCircle2D(total_flux, [250 250 250], [0 0 1], radius, 1);
    logI = log10(I);
    scatter(theta, logI, 'DisplayName', sprintf('Radius = %d', radius));
end

xlabel('Angle (degrees)');
ylabel('log(Fluence)');
subtitle = sprintf('Junge = %.3f, n = %.3f, mua = %.6g, mus = %.6g', junge, index_of_ref, mua, mus);
title({
    'Fluence vs Angle at Different Radii'
    subtitle
});
legend('show');
grid on;
hold off;

print('HGtest.png', '-dpng', '-r300');
