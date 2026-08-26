


myinp = inputdlg({'GPUs to use','Junge','Index of Refraction', 'mua', 'mus','Title'},'Please input data!',1,{111111,3.4,1.1,0.003,0.03, "MonteCarlo"})

%%% Genrates the Fornier Forand Table
junge = str2num (myinp{2});
index_of_ref = str2num (myinp{3});
FFgenerator = FornierForandTableGenerator(junge, index_of_ref);
disp("Generated Table for Fornier Forand with given parameters")

[x_bins, x_bin_positions] = BoundaryDetectorFunction(DomainSize, DomainProperties, SourcePosition, FornierForandTable);


% Plot

figure;
bar(x_bin_positions, x_bins, 1);
hold on;
plot(x_bin_positions, x_bins, '-');

xlabel('X position (mm)');
ylabel('Escaping photon weight');
subtitle = sprintf('Junge = %.3f, n = %.3f, mua = %.6g, mus = %.6g', junge, index_of_ref, mua, mus);
title({myinp{6}, subtitle});

grid on;
hold off;
grid on;
filename = sprintf('TopDetectorTestFarther_%.3f_n_%.3f_mua_%.6g_mus_%.6g.png',junge, index_of_ref, mua, mus);
print(filename, '-dpng', '-r300');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Information
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf('Total recorded photons: %d\n', length(detw));
fprintf('Photons through +Z center strip: %d\n', sum(selected));
fprintf('Total weight through +Z center strip: %.8g\n', ...
        sum(detw(selected)));




