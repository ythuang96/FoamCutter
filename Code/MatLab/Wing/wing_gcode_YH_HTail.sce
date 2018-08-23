clear

//
// CNC Wing Cutting
//
// set design varaibles
//

root_filename = 's9026.dat';       // airfoil section file for root
root_chord = 6.3;                   // root chord length [in]

tip_filename = 's9026.dat';        // airfoil section file for tip
tip_chord = 6.3;                    // tip chord length [in]
                                   //root chord has to be greater or equal to tip chord

right_wing = 1;                     // +1 for right (starboard) wing, -1 for left (port)
semi_span = 3;                     // semi-span [in]
LE_sweep = 0;                    // leading edge sweep [deg]
twist = 0.0;                       // twist [deg]

g_filename = 'HTail.txt';         // g-code output file

cutter_width = 23.5;                  // width of CNC cutter [in]
scale_factor = 25.4;                  // CNC conversion inches to units

//
// open and deconstruct airfoil files
//

[root_pts, root_name] = fscanfMat(root_filename);

root_size = size(root_pts)*[1 0]';
root_upper_x = root_pts(1:(root_size+1)/2, 1);
root_upper_y = root_pts(1:(root_size+1)/2, 2);
root_lower_x = root_pts((root_size+1)/2:root_size, 1);
root_lower_y = root_pts((root_size+1)/2:root_size, 2);

[tip_pts, tip_name] = fscanfMat(tip_filename);

tip_size = size(tip_pts)*[1 0]';
tip_upper_x = tip_pts(1:(tip_size+1)/2, 1);
tip_upper_y = tip_pts(1:(tip_size+1)/2, 2);
tip_lower_x = tip_pts((tip_size+1)/2:tip_size, 1);
tip_lower_y = tip_pts((tip_size+1)/2:tip_size, 2);

//
// interpolate using lowest fidelity airfoil
//

root_upper_yp = interp1(root_upper_x,root_upper_y,tip_upper_x);
root_upper_xp = tip_upper_x;

root_lower_yp = interp1(root_lower_x,root_lower_y,tip_lower_x);
root_lower_xp = tip_lower_x;

tip_upper_yp = tip_upper_y;
tip_upper_xp = tip_upper_x;
tip_lower_yp = tip_lower_y;
tip_lower_xp = tip_lower_x;

//
// scale to desired chord length at each cutter
//

root_chord_ext = root_chord + 0.5*(root_chord - tip_chord)*(cutter_width - semi_span)/semi_span;
tip_chord_ext = root_chord - 0.5*(root_chord - tip_chord)*(cutter_width + semi_span)/semi_span;

root_upper_xp = root_chord_ext*root_upper_xp;
root_upper_yp = root_chord_ext*root_upper_yp;

root_lower_xp = root_chord_ext*root_lower_xp;
root_lower_yp = root_chord_ext*root_lower_yp;

tip_upper_xp = tip_chord_ext*tip_upper_xp;
tip_upper_yp = tip_chord_ext*tip_upper_yp;

tip_lower_xp = tip_chord_ext*tip_lower_xp;
tip_lower_yp = tip_chord_ext*tip_lower_yp;

//
// rotate tip by twist angle
//

c4 = tip_chord/4;
twist_rad = (%pi/180)*twist;

tip_upper_xpr = tip_upper_xp*cos(twist_rad) + tip_upper_yp*sin(twist_rad) + c4*(1.0-cos(twist_rad));
tip_upper_ypr = -tip_upper_xp*sin(twist_rad) + tip_upper_yp*cos(twist_rad) + c4*sin(twist_rad);

tip_lower_xpr = tip_lower_xp*cos(twist_rad) + tip_lower_yp*sin(twist_rad) + c4*(1.0-cos(twist_rad));
tip_lower_ypr = -tip_lower_xp*sin(twist_rad) + tip_lower_yp*cos(twist_rad) + c4*sin(twist_rad);

//
// use sweep angle to shift tip relative to root
//

sweep_shift = cutter_width*tan(LE_sweep*%pi/180);

tip_upper_xpr = tip_upper_xpr + sweep_shift;
tip_lower_xpr = tip_lower_xpr + sweep_shift;

//
// move origin to make y-axis all positive
//

y_min = min([root_lower_yp tip_lower_ypr]);
root_upper_yp = root_upper_yp - y_min;
root_lower_yp = root_lower_yp - y_min;
tip_upper_ypr = tip_upper_ypr - y_min;
tip_lower_ypr = tip_lower_ypr - y_min;

//
// swap x-axis to start cut on trailing edge
//

root_upper_xp = root_chord_ext - root_upper_xp;
root_lower_xp = root_chord_ext - root_lower_xp;
tip_upper_xpr = root_chord_ext - tip_upper_xpr;
tip_lower_xpr = root_chord_ext - tip_lower_xpr;

//
// combine upper and lower surfaces
//

root_x = [root_upper_xp; root_lower_xp];
root_y = [root_upper_yp; root_lower_yp];

tip_x = [tip_upper_xpr; tip_lower_xpr];
tip_y = [tip_upper_ypr; tip_lower_ypr];

//
// make a plot of root and tip
//

clf
plot(root_x,root_y,tip_x,tip_y);
ff = gca();
ff.isoview="on";
legend(['root';'tip']);

//
// write g-code file
//

root_x = scale_factor*root_x;
root_y = scale_factor*root_y;
tip_x = scale_factor*tip_x;
tip_y = scale_factor*tip_y;

g_file = mopen(g_filename,'wt')

mfprintf(g_file,'G21\n');
mfprintf(g_file,'M48\n');
mfprintf(g_file,'F80\n');
mfprintf(g_file,'S80\n');

//
// wire arrangement
//
//   right side: <- Z(+)  A(+) up   .. tip of starboard wing or root of port wing
//
//   left side: <- X(+)  Y(+) up    .. root of starboard wing or tip of port wing
//

mfprintf(g_file, 'G1 X   %.3f Y   %.3f Z   %.3f A   %.3f\n',0.0,0.0,0.0,0.0);

if (right_wing > 0) then
    
    mfprintf(g_file, 'G1 X   %.3f Y   %.3f Z   %.3f A   %.3f\n',root_x(1),root_y(1),tip_x(1),tip_y(1));
    mfprintf(g_file,'G4 P5\n')

    for i=length(root_x):-1:1
        mfprintf(g_file, 'G1 X   %.3f Y   %.3f Z   %.3f A   %.3f\n',root_x(i),root_y(i),tip_x(i),tip_y(i));
    end
    
else
    
    mfprintf(g_file, 'G1 X   %.3f Y   %.3f Z   %.3f A   %.3f\n',tip_x(1),tip_y(1),root_x(1),root_y(1));
    mfprintf(g_file,'G4 P5\n')

    for i=length(root_x):-1:1
        mfprintf(g_file, 'G1 X   %.3f Y   %.3f Z   %.3f A   %.3f\n',tip_x(i),tip_y(i),root_x(i),root_y(i));
    end
    
end

mfprintf(g_file, 'G1 X   %.3f Y   %.3f Z   %.3f A   %.3f\n',0.0,0.0,0.0,0.0);  
mfprintf(g_file,'M2');

mclose(g_file);







