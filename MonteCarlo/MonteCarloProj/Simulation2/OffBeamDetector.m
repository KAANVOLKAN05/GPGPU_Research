


myinp = inputdlg({'GPUs to use','Junge','Index of Refraction', 'mua', 'mus','z_dim','Title'},'Please input data!',1,{111111,3.4,1.1,0.003,0.03,100, "MonteCarlo"})
gpuid = myinp{1};
mua = str2double(myinp{4});
mus = str2double(myinp{5});
z_dim = str2double(myinp{6});



%%% Genrates the Fornier Forand Table
junge = str2num (myinp{2});
index_of_ref = str2num (myinp{3});
FFgenerator = FornierForandTableGenerator(junge, index_of_ref);
disp("Generated Table for Fornier Forand with given parameters")


DomainSize = [200,30,z_dim];
SourcePosition = [1,15,50];
DomainProperties = [mua, mus, 0.9, 1.2];
[x_bins, x_bin_positions] = BoundaryDetectorFunction(DomainSize, DomainProperties, SourcePosition, FFgenerator, gpuid);


% Plot

figure;
bar(x_bin_positions, x_bins, 1);
hold on;
plot(x_bin_positions, x_bins, '-');

xlabel('X position (mm)');
ylabel('Escaping photon weight');
subtitle = sprintf('Junge = %.3f, n = %.3f, mua = %.6g, mus = %.6g', junge, index_of_ref, mua, mus);
title({myinp{7}, subtitle});

grid on;
hold off;
grid on;
filename = sprintf('TopDetectorTestFarther_%.3f_n_%.3f_mua_%.6g_mus_%.6g.png',junge, index_of_ref, mua, mus);
print(filename, '-dpng', '-r300');
disp("Final")






