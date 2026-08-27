


myinp = inputdlg({'GPUs to use','Junge','Index of Refraction', 'mua', 'mus','Title'},'Please input data!',1,{111111,3.4,1.1,0.003,0.03, "MonteCarlo"})
gpuid = myinp{1};
mua = str2double(myinp{4});
mus = str2double(myinp{5});



%%% Genrates the Fornier Forand Table
junge = str2num (myinp{2});
index_of_ref = str2num (myinp{3});
FFgenerator = FornierForandTableGenerator(junge, index_of_ref);
disp("Generated Table for Fornier Forand with given parameters")


% Setting up the results folder
resultsFolder = 'MC_Results';
dataFolder = fullfile(resultsFolder, 'data');
if ~exist(resultsFolder, 'dir')
    mkdir(resultsFolder);
end
if ~exist(dataFolder, 'dir')
    mkdir(dataFolder);
end
summaryFile = fullfile(resultsFolder, 'summary.csv');
if ~exist(summaryFile, 'file')
    fid = fopen(summaryFile, 'w');
    fprintf(fid, ...
        ['RunID,Junge,n,mua,mus,' ...
        'DomainX,DomainY,DomainZ,' ...
        'SourceX,SourceY,SourceZ,' ...
        'TotalSignal,MeanBinWeight,MedianBinWeight,StdBinWeight,' ...
        'MinBinWeight,MaxBinWeight,PeakPosition,' ...
        'WeightedMeanPosition,WeightedMedianPosition,' ...
        'WeightedStdPosition,WeightedSkewness,WeightedKurtosis\n']);
    fclose(fid);
end


SourcePosition = [1,15,50];
DomainProperties = [mua, mus, 0.9, 1.2];
runNumber = 1;
for z_dim = 60:5:100
    % Initializing the run number and parameters
    runID = sprintf('run_%06d', runNumber);
    DomainSize = [100,30,z_dim];

    % Running the Sim
    [x_bins, x_bin_positions] = BoundaryDetectorFunction(DomainSize, DomainProperties, SourcePosition, FFgenerator, gpuid);
    
    % Converting to column vectors 
    w = x_bins(:);
    x = x_bin_positions(:);


    % Writing the summuary stats


    totalSignal = sum(w);

    meanBinWeight = mean(w);
    medianBinWeight = median(w);
    stdBinWeight = std(w);

    minBinWeight = min(w);
    maxBinWeight = max(w);
    [~, peakIndex] = max(w);
    peakPosition = x(peakIndex);
    if totalSignal > 0

        % Weighted mean position / centroid
        weightedMeanPosition = sum(w .* x) / totalSignal;


        % Weighted standard deviation
        weightedStdPosition = sqrt( ...
            sum(w .* (x - weightedMeanPosition).^2) / totalSignal);


        % Weighted median position
        cumulativeWeight = cumsum(w) / totalSignal;

        medianIndex = find(cumulativeWeight >= 0.5, 1, 'first');

        weightedMedianPosition = x(medianIndex);

        % Weighted skewness
        if weightedStdPosition > 0

            weightedSkewness = sum(w .* (x - weightedMeanPosition).^3) / totalSignal / weightedStdPosition^3;

            weightedKurtosis = sum(w .* (x - weightedMeanPosition).^4) / totalSignal / weightedStdPosition^4;

        else

            weightedSkewness = NaN;
            weightedKurtosis = NaN;

        end
    else

        weightedMeanPosition = NaN;
        weightedMedianPosition = NaN;
        weightedStdPosition = NaN;
        weightedSkewness = NaN;
        weightedKurtosis = NaN;
    end

    dataFilename = fullfile(dataFolder,[runID '.mat']);


    save(dataFilename, ...
        'x_bins', ...
        'x_bin_positions', ...
        'DomainSize', ...
        'DomainProperties', ...
        'SourcePosition', ...
        'junge', ...
        'index_of_ref', ...
        'mua', ...
        'mus');
    
    % ================= SAVE SUMMARY =================

    fid = fopen(summaryFile, 'a');

    fprintf(fid, ...
        ['%s,%.10g,%.10g,%.10g,%.10g,' ...
        '%d,%d,%d,' ...
        '%.10g,%.10g,%.10g,' ...
        '%.10g,%.10g,%.10g,%.10g,' ...
        '%.10g,%.10g,%.10g,' ...
        '%.10g,%.10g,%.10g,%.10g,%.10g\n'], ...

        runID, ...
        junge, ...
        index_of_ref, ...
        mua, ...
        mus, ...

        DomainSize(1), ...
        DomainSize(2), ...
        DomainSize(3), ...

        SourcePosition(1), ...
        SourcePosition(2), ...
        SourcePosition(3), ...

        totalSignal, ...
        meanBinWeight, ...
        medianBinWeight, ...
        stdBinWeight, ...
        minBinWeight, ...
        maxBinWeight, ...
        peakPosition, ...
        weightedMeanPosition, ...
        weightedMedianPosition, ...
        weightedStdPosition, ...
        weightedSkewness, ...
        weightedKurtosis);

    fclose(fid);

    runNumber = runNumber + 1;
end







