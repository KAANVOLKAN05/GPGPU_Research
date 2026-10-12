clear;
clc;


% lets define the size of the domain
Lx = 10;
Ly = 10;
Lz = 10;

% lets define the number of grid points
Nx = 11;
Ny = 11;
Nz = 11;

% lets calculate the grid distances
dx = Lx/(Nx-1);
dy = Ly/(Ny-1);
dz = Lz/(Nz-1);

% lets discritisize the domain 
x_domain = linspace(0,Lx,Nx);
y_domain = linspace(0,Ly,Ny);
z_domain = linspace(0,Lz,Nz);

% lets discritisize angles
N_theta = 9;
N_psi = 9; 
theta_domain = linspace(0,pi,N_theta);
psi_domain = linspace(0,2*pi,N_psi);

% lets initilize the space to zeros
I = zeros(Nx,Ny,Nz,N_theta,N_psi);

% Source position direction and intensity
Source_position = [Lx/2,0,Lz/2];
Source_direction = [pi/2,pi/2];
Source_intensity = 1;
Source_position_index = [Lx/2,0,Lz/2] + 1;
Source_direction_index = [5,3];

% Directions array

Omega_x = zeros(N_theta,N_psi);
Omega_y = zeros(N_theta,N_psi);
Omega_z = zeros(N_theta,N_psi);

for t = 1:N_theta
    for p = 1:N_psi

        theta = theta_domain(t);
        psi   = psi_domain(p);

        Omega_x(t,p) = sin(theta)*cos(psi);
        Omega_y(t,p) = sin(theta)*sin(psi);
        Omega_z(t,p) = cos(theta);

    end
end

% setting the Source Value
I(Source_position_index(1),Source_position_index(2),Source_position_index(3),Source_direction_index(1),Source_direction_index(2));



% setting the IOPs
mua = 0.003;   % absorption coefficient
mus = 0.03;    % scattering coefficient













