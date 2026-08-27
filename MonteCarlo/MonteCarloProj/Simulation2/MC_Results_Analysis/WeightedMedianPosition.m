% The following code is fully written by AI and I take no credit for it.
% I told it how my data structure looks and asked for the code that plots the 2 columns against each other
% I have looked over it and confirmed that the code works

clear;
close all;
clc;

filename = '../MC_Results/summary.csv';

fid = fopen(filename, 'r');

% Skip header
header = fgetl(fid);

% 1 string column (RunID) + 22 numerical columns
formatSpec = ['%s' repmat('%f', 1, 22)];

data = textscan(fid, formatSpec, ...
    'Delimiter', ',', ...
    'CollectOutput', false);

fclose(fid);

mua = data{4};
mus = data{5};

z_dim = data{8};

weightedMedianPosition = data{20};
unique_mus = unique(mus);
unique_mua = unique(mua);
for i = 1:length(unique_mus)

    current_mus = unique_mus(i);

    figure;
    hold on;

    for j = 1:length(unique_mua)

        current_mua = unique_mua(j);

        % Select runs having this mus AND this mua
        selected = ...
            abs(mus - current_mus) < 1e-12 & ...
            abs(mua - current_mua) < 1e-12;

        current_z = z_dim(selected);
        current_median = weightedMedianPosition(selected);


        % Sort by z dimension
        [current_z, order] = sort(current_z);
        current_median = current_median(order);


        % Plot
        plot(current_z, current_median, ...
            '-o', ...
            'DisplayName', sprintf('mua = %.4f', current_mua));

    end


    xlabel('Z dimension (mm)');
    ylabel('Weighted median position (mm)');

    title(sprintf( ...
        'Weighted Median Position vs Z Dimension, mus = %.4f', ...
        current_mus));

    legend('show', 'location', 'eastoutside');

    grid on;
    hold off;

end