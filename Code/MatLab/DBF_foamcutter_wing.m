%% DBF Foamcutter for Wing
% This code is modified by Yuting Huang (ythuang96@gmail.com) based on
% Dr.Anderson's code written on Scilab.
% Please report all bug to the author's email address.
% Last updated: 1/13/2019

% This is written for DBF foamcutting, to generate G-code from wing
% prameters.
clear all; close all; clc;

%% Enter Parameters Below
% airfoil section file for root
root_filename = 'AH-79-100.dat';
% root chord length [in]
root_chord = 6;

% airfoil section file for tip
tip_filename = 'E216.dat';
% tip chord length [in]
tip_chord = 3;
% root chord has to be greater or equal to tip chord

% +1 for right wing, -1 for left wing
right_wing = 1;

% semi-span [in]
semi_span = 3;

% leading edge sweep [deg]
LE_sweep = 0;

% twist [deg]
twist = 0.0;

% g-code output file name
g_filename = 'HTail';

% width of CNC cutter [in]
cutter_width = 39;
% scale the cord length to accomodaate for broken trailing edge
% recommend using 1.2, then cut trailing edge with a blade to desired
% length.
scale_factor = 1.2;

%% ------------------------------------------------------------------------
%% ------------------------------------------------------------------------
%% ------------------------------------------------------------------------
%% ------------------------------------------------------------------------
%% Open File
fid = fopen(root_filename);
temp = textscan(fid,'%f %f','headerLines', 1);
fclose(fid);
root_pts = [temp{1}, temp{2}];

fid = fopen(tip_filename);
temp = textscan(fid,'%f %f','headerLines', 1);
fclose(fid);
tip_pts = [temp{1}, temp{2}];
clear temp fid;

%% Deconstruct Airfoil into Upper and Lower Parts
root_size = size(root_pts,1);
root_turn_point = find(root_pts(:,2)<0,1) - 1;
root_upper_x = root_pts(1:root_turn_point, 1);
root_upper_y = root_pts(1:root_turn_point, 2);
root_lower_x = root_pts(root_turn_point:root_size, 1);
root_lower_y = root_pts(root_turn_point:root_size, 2);

tip_size = size(tip_pts,1);
tip_turn_point = find(tip_pts(:,2)<0,1) - 1;
tip_upper_x = tip_pts(1:tip_turn_point, 1);
tip_upper_y = tip_pts(1:tip_turn_point, 2);
tip_lower_x = tip_pts(tip_turn_point:tip_size, 1);
tip_lower_y = tip_pts(tip_turn_point:tip_size, 2);

%% Interpolate
n = 301;
root_upper_yp = interp1(root_upper_x,root_upper_y,linspace(1,0,n)','linear','extrap');
root_upper_xp = linspace(1,0,n)';
root_lower_yp = interp1(root_lower_x,root_lower_y,linspace(0,1,n)','linear','extrap');
root_lower_xp = linspace(0,1,n)';

tip_upper_yp = interp1(tip_upper_x,tip_upper_y,linspace(1,0,n)','linear','extrap');
tip_upper_xp = linspace(1,0,n)';
tip_lower_yp = interp1(tip_lower_x,tip_lower_y,linspace(0,1,n)','linear','extrap');
tip_lower_xp = linspace(0,1,n)';

%% Scale to Chord Length
% chord length on machine
root_chord_ext = root_chord + ...
    0.5*(root_chord - tip_chord)*(cutter_width - semi_span)/semi_span;
tip_chord_ext = root_chord - ...
    0.5*(root_chord - tip_chord)*(cutter_width + semi_span)/semi_span;

root_upper_xp = root_chord_ext*root_upper_xp;
root_upper_yp = root_chord_ext*root_upper_yp;

root_lower_xp = root_chord_ext*root_lower_xp;
root_lower_yp = root_chord_ext*root_lower_yp;

tip_upper_xp = tip_chord_ext*tip_upper_xp;
tip_upper_yp = tip_chord_ext*tip_upper_yp;

tip_lower_xp = tip_chord_ext*tip_lower_xp;
tip_lower_yp = tip_chord_ext*tip_lower_yp;

%% Rotate Tip by Twist Angle
c4 = tip_chord/4;
twist_rad = (pi/180)*twist;

tip_upper_xpr = tip_upper_xp*cos(twist_rad) ...
    + tip_upper_yp*sin(twist_rad) + c4*(1.0-cos(twist_rad));
tip_upper_ypr = -tip_upper_xp*sin(twist_rad) ...
    + tip_upper_yp*cos(twist_rad) + c4*sin(twist_rad);

tip_lower_xpr = tip_lower_xp*cos(twist_rad) ...
    + tip_lower_yp*sin(twist_rad) + c4*(1.0-cos(twist_rad));
tip_lower_ypr = -tip_lower_xp*sin(twist_rad) ...
    + tip_lower_yp*cos(twist_rad) + c4*sin(twist_rad);

%% Use Sweep Angle to Shift Tip Relative to Root
sweep_shift = cutter_width*tan(LE_sweep*pi/180);

tip_upper_xpr = tip_upper_xpr + sweep_shift;
tip_lower_xpr = tip_lower_xpr + sweep_shift;

%% Swap x-axis to Start Cut on Trailing Edge
root_upper_xp = root_chord_ext - root_upper_xp;
root_lower_xp = root_chord_ext - root_lower_xp;
tip_upper_xpr = root_chord_ext - tip_upper_xpr;
tip_lower_xpr = root_chord_ext - tip_lower_xpr;

%% Combine Upper and Lower Surfaces
root_x = [root_upper_xp; root_lower_xp];
root_y = [root_upper_yp; root_lower_yp];

tip_x = [tip_upper_xpr; tip_lower_xpr];
tip_y = [tip_upper_ypr; tip_lower_ypr];

%% Make a Plot of Root and Tip
set(0,'defaultlinelinewidth',2)
set(0,'defaultaxeslinewidth',1)
set(0,'defaultaxesfontsize',20)

figure(1); set(1,'position',[0 0 1920 1080]); hold on;
plot(root_x,root_y);
plot(tip_x,tip_y);
legend1 = legend('Root','Tip');
set(legend1,'interpreter','latex'); set(legend1,'fontsize',18);
title('Wing on FoamCutter','interpreter','latex','fontsize',25);
xlabel('X [in]','interpreter','latex','fontsize',25);
ylabel('Y [in]','interpreter','latex','fontsize',25);
axis equal; grid on;

%% Write G-code File
root_x = scale_factor*root_x*25.4;
root_y = scale_factor*root_y*25.4;
tip_x = scale_factor*tip_x*25.4;
tip_y = scale_factor*tip_y*25.4;

fidw = fopen([g_filename '.txt'],'wt');

fprintf(fidw,'G21\n'); fprintf(fidw,'M48\n');
fprintf(fidw,'F80\n'); fprintf(fidw,'S80\n');

fprintf(fidw,'G1  X % 8.3f  Y % 8.3f  Z % 8.3f  A % 8.3f\n',0,0,0,0);

if right_wing > 0
    fprintf(fidw, 'G1  X % 8.3f  Y % 8.3f  Z % 8.3f  A % 8.3f\n', ...
        root_x(1),root_y(1),tip_x(1),tip_y(1));
    fprintf(fidw, 'G4 P5\n');
    for i=length(root_x):-1:1
        fprintf(fidw, 'G1  X % 8.3f  Y % 8.3f  Z % 8.3f  A % 8.3f\n', ...
            root_x(i),root_y(i),tip_x(i),tip_y(i));
    end
else
    fprintf(fidw, 'G1  X % 8.3f  Y % 8.3f  Z % 8.3f  A % 8.3f\n', ...
        tip_x(1),tip_y(1),root_x(1),root_y(1));
    fprintf(fidw, 'G4 P5\n');
    for i=length(root_x):-1:1
        fprintf(fidw, 'G1  X % 8.3f  Y % 8.3f  Z % 8.3f  A % 8.3f\n', ...
            tip_x(i),tip_y(i),root_x(i),root_y(i));
    end
end

fprintf(fidw, 'G1  X % 8.3f  Y % 8.3f  Z % 8.3f  A % 8.3f\n',0,0,0,0);
fprintf(fidw,'M2');

fclose(fidw);

