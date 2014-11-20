function [xdot,y] = CrazyFlieModel(t,x,u,Ixx,Iyy,Izz,Km,varargin)
% States
% x
% y
% z
% phi (roll)
% theta (pitch)
% psi (yaw)
% xdot
% ydot
% zdot
% phidot
% thetadot
% psidot

% Inputs: omega^2 for each rotor

% Set outputs
y = x(1:6); % These are things we directly measure (outputs)

% Parameters from physical measurements
m = 22.4/1000; % Mass in kg
Ixx = 0.006*Ixx;
Iyy = 0.006*Iyy;
Izz = 0.01*Izz;

Km = (10^-9)*Km;

I = diag([Ixx,Iyy,Izz]); % Inertia matrix
invI = diag(1./[Ixx,Iyy,Izz]); % inverse of I
g = 9.81;
Kf = (1.426531127550046e-09)*g/1000; % Fit from experiments with digital scale
L = 0.043; % Distance from rotor to COM (in m)

% states
phi = x(4);
theta = x(5);
psi = x(6);

phidot = x(10);
thetadot = x(11);
psidot = x(12);

% Note the permutation here!!!
w1 = u(1); % These are omega^2
w2 = u(4);
w3 = u(3);
w4 = u(2);

% Rotation matrix from body to world frames
R = rpy2rotmat([phi;theta;psi]);

% Thrust from each from. Thrust = kf*omega^2
F1 = Kf*w1; 
F2 = Kf*w2;
F3 = Kf*w3;
F4 = Kf*w4;

% Moments. km*omega^2
M1 = Km*w1;
M2 = Km*w2;
M3 = Km*w3;
M4 = Km*w4;


xyz_ddot = (1/m)*([0;0;-m*g] + R*[0;0;F1+F2+F3+F4]);

pqr = rpydot2angularvel([phi;theta;psi],[phidot;thetadot;psidot]);
pqr = R'*pqr;

pqr_dot = invI*([L*(F2-F4);L*(F3-F1);(M1-M2+M3-M4)] - cross(pqr,I*pqr));

% Now, convert pqr_dot to rpy_ddot
[Phi, dPhi] = angularvel2rpydotMatrix([phi;theta;psi]);

Rdot =  [ 0, sin(phi)*sin(psi) + cos(phi)*cos(psi)*sin(theta),   cos(phi)*sin(psi) - cos(psi)*sin(phi)*sin(theta); ...
    0, cos(phi)*sin(psi)*sin(theta) - cos(psi)*sin(phi), - cos(phi)*cos(psi) - sin(phi)*sin(psi)*sin(theta); ...
    0,                              cos(phi)*cos(theta),                               -cos(theta)*sin(phi)]*phidot + ...
    [ -cos(psi)*sin(theta), cos(psi)*cos(theta)*sin(phi), cos(phi)*cos(psi)*cos(theta); ...
    -sin(psi)*sin(theta), cos(theta)*sin(phi)*sin(psi), cos(phi)*cos(theta)*sin(psi); ...
    -cos(theta),         -sin(phi)*sin(theta),         -cos(phi)*sin(theta)]*thetadot + ...
    [ -cos(theta)*sin(psi), - cos(phi)*cos(psi) - sin(phi)*sin(psi)*sin(theta), cos(psi)*sin(phi) - cos(phi)*sin(psi)*sin(theta); ...
    cos(psi)*cos(theta),   cos(psi)*sin(phi)*sin(theta) - cos(phi)*sin(psi), sin(phi)*sin(psi) + cos(phi)*cos(psi)*sin(theta); ...
    0,                                                  0,                                                0]*psidot;

rpy_ddot = Phi*R*pqr_dot + reshape((dPhi*[phidot;thetadot;psidot]),3,3)*R*pqr + ...
    Phi*Rdot*pqr;

xdot = [x(7:12);xyz_ddot;rpy_ddot];


end


