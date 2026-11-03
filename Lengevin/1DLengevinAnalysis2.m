% This code is AI written, I claim no originality beyond telling it to make it according to the input file
T = 0.5;                                  % must match --temp
a = 2;                                    % must match simulation's a
b = 1;                                    % must match simulation's b
x = load("positions_gpu.txt");            % skips lines starting with #

V = @(x) -a * x.^2 / 2 + b * x.^4 / 4;
Z = quadgk(@(x) exp(-V(x) / T), -Inf, Inf);

L = 2 * sqrt(a / b);                      % wells sit at ±sqrt(a/b); plot out to twice that
edges = linspace(-L, L, 81);              % 80 bins
centers = (edges(1:end-1) + edges(2:end)) / 2;
binWidth = edges(2) - edges(1);
counts = histc(x, edges);
counts = counts(1:end-1);                 % histc's last bin only counts x == L exactly
density = counts / (numel(x) * binWidth); % normalize like a probability density

xs = linspace(-L, L, 400);
figure("visible", "off");                 % no display on the server
bar(centers, density, 1); hold on;
plot(xs, exp(-V(xs) / T) / Z, "r", "linewidth", 2);
xlabel("x"); ylabel("p(x)"); legend("simulation", "Boltzmann");
print("distribution_GPU.png", "-dpng");