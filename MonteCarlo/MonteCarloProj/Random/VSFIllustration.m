u = 4.9;
n = 0.9;

v = (3 - u) / 2;

s = @(x) (4 / (3 * (n - 1)^2)) .* sin(x / 2).^2;

B = @(x) ...
    (1 ./ (4*pi .* (1 - s(x)).^2 .* s(x).^v)) .* ...
    (v .* (1 - s(x)) ...
    - (1 - s(x).^v) ...
    + (s(x) .* (1 - s(x).^v) ...
    - v .* (1 - s(x))) .* sin(x / 2).^(-2)) ...
    + ((1 - s(pi).^v) / ...
    (16*pi * (s(pi) - 1) * s(pi).^v)) .* ...
    (3*cos(x).^2 - 1);

% x in radians
x = linspace(1e-5, pi, 10000);

y = B(x);

figure;
%plot(x, y, 'LineWidth', 1.5);
loglog(x, y, 'LineWidth', 1.5);
xlabel('x (radians)');
ylabel('B(x)');
title('Fournier-Forand Phase Function');
grid on;
xlim([0 pi]);