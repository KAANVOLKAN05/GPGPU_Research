clear;
clc;

scriptDir = fileparts(mfilename('fullpath'));

matFolder = fullfile(scriptDir, '..', 'MC_Results', 'data_v2');
outputFolder = fullfile(scriptDir, '..', 'MC_Results', 'runs');

if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

files = dir(fullfile(matFolder, 'run_*.mat'));

fprintf('Found %d MAT files.\n', length(files));

for i = 1:length(files)

    data = load(fullfile(matFolder, files(i).name));

    x = data.x_bin_positions(:);
    y = data.x_bins(:);

    [~, runID, ~] = fileparts(files(i).name);

    csvFile = fullfile(outputFolder, [runID '.csv']);

    fid = fopen(csvFile, 'w');
    fprintf(fid, 'x_bin_position,x_bin\n');

    for j = 1:length(x)
        fprintf(fid, '%.10g,%.10g\n', x(j), y(j));
    end

    fclose(fid);
end

fprintf('Created %d CSV files in:\n%s\n', length(files), outputFolder);
