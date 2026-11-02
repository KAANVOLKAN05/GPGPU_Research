

% This code is AI written, I claim no originality beyond telliing it to make it according to the inptu file
T = 0.5;                                  % must match --temp
x = load("positions_GPU.txt");                % skips lines starting with #

V = @(x) (x.^2 - 1).^2;
Z = quadgk(@(x) exp(-V(x) / T), -Inf, Inf);

edges = linspace(-2, 2, 81);              % 80 bins
centers = (edges(1:end-1) + edges(2:end)) / 2;
binWidth = edges(2) - edges(1);
counts = histc(x, edges);
counts = counts(1:end-1);                 % histc's last bin only counts x == 2 exactly
density = counts / (numel(x) * binWidth); % normalize like a probability density

xs = linspace(-2, 2, 400);
figure("visible", "off");                 % no display on the server
bar(centers, density, 1); hold on;
plot(xs, exp(-V(xs) / T) / Z, "r", "linewidth", 2);
xlabel("x"); ylabel("p(x)"); legend("simulation", "Boltzmann");
print("distribution_GPU.png", "-dpng");