u = 4.9;
n = 0.9;
g = 0.9345;

%% Henyey-Greenstein
HG = @(x) (1 / (4*pi)) .* ...
    (1 - g^2) ./ ...
    (1 + g^2 - 2*g.*cos(x)).^(3/2);

%% Fournier-Forand
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

%% x in radians
x = linspace(1e-5, pi, 10000);

y_FF = B(x);
y_HG = HG(x);

%% Fournier-Forand Plot
figure;
loglog(x, y_FF, 'LineWidth', 1.5);
xlabel('x (radians)');
ylabel('FF(x)');
title('Fournier-Forand Phase Function');
grid on;
xlim([1e-5 pi]);

%% Henyey-Greenstein Plot
figure;
loglog(x, y_HG, 'LineWidth', 1.5);
xlabel('x (radians)');
ylabel('HG(x)');
title('Henyey-Greenstein Phase Function');
grid on;
xlim([1e-5 pi]);

figure;
loglog(x, y_FF, 'LineWidth', 1.5);
hold on;
loglog(x, y_HG, 'LineWidth', 1.5);

xlabel('x (radians)');
ylabel('Phase Function');
title('Fournier-Forand vs Henyey-Greenstein');
legend('Fournier-Forand', 'Henyey-Greenstein');
grid on;
xlim([1e-5 pi]);