function [Combinations] = Exclude_Unallowed_Combinations(Combinations) 

%This section of code is used to remove combinations that are unfeasible or
%not permitted within the physical constraints of the system.  Do NOT use
%this file without reviewing the constraints and adjusting them for the
%system in question.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%For a rectangular imaging target, there exists a rectangular pyramid in which
%the light source cannot be placed or it will obstruct the view of the 
%imaging device.  

%%%Remove combinations that lie inside the rectangular pyramid%%%

%Vertices of the rectangular base
%Vertices of the domain (rectangle) being imaged
V1 = [-50, -40, 0];
V2 = [-50,  40, 0];
V3 = [ 50,  40, 0];
V4 = [ 50, -40, 0];

%Position of the camera
V5 = [0, 0, 110];

Pyramid = [V1; V2; V3; V4; V5];

X_tri = Pyramid(:,1);
Y_tri = Pyramid(:,2);
Z_tri = Pyramid(:,3);

%Creates a representation of the rectangular pyramid
TRI = delaunay(X_tri,Y_tri,Z_tri);

x_positions = Combinations(:,3);
y_positions = Combinations(:,4);
H_positions = Combinations(:,5);

%Tests to determine if each x,y,h combination lies within the pyramid
xyz = [x_positions, y_positions, H_positions];
tn = tsearchn([X_tri Y_tri Z_tri], TRI, xyz);
IsInside = ~isnan(tn);

%If the given x,y,h position is outside of the pyramid, the corresponding
%value IsInside == 0, this vector determines all the combinations that lie
%outside of the pyramid
A = find(IsInside == 0);


%The possible combinations are reduced to only include those that do not
%lie within the rectangular pyramid
Combinations = Combinations(A,:);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%For certain combinations of variable values, the principle axis of the 
%light source will never intersect with the illuminated area.  These 
%combinations are eliminated as they can be assumed to be highly
%inefficient.  Removing them will reduce the necessary computing time.  

%Define the vertices of the illuminated area, may be different from those
%listed above for the domain being imaged
V1 = [-50, -40];
V2 = [-50,  40];
V3 = [ 50,  40];
V4 = [ 50, -40];

Area_Illuminated = [V1; V2; V3; V4];

X_tri = Area_Illuminated(:,1);
Y_tri = Area_Illuminated(:,2);

%Creates a representation of the illuminated area
TRI = delaunay(X_tri,Y_tri);

%Based on each combination of variables, it is determined where the 
%principle axis of the light source will intersect with the plane on which 
%the illuminated area lies.
theta = Combinations(:,1);
phi = Combinations(:,2);
x_position = Combinations(:,3);
y_position = Combinations(:,4);
height = Combinations(:,5);

d_along_plate = tan(theta).*height;
y_along_plate = sin(phi).*d_along_plate;
x_along_plate = cos(phi).*d_along_plate;

light_centre_x = x_position + x_along_plate;
light_centre_y = y_position + y_along_plate;


%This section tests whether this intersection point lies within the 
%illuminated area.
xy = [light_centre_x, light_centre_y];
tn = tsearchn([X_tri Y_tri], TRI, xy);
IsInside = ~isnan(tn);
 
%If the given combination of variables produce a beam of light that will
%strike the desired illuminated area, the value of IsInside == 1.  This
%vector identifies the index associated with the combinations that satisfy
%this condition.
A = find(IsInside == 1);
 
%The possible combinations are reduced to include only those where the
%centre of the beam of light will strike the desired illuminated area
Combinations = Combinations(A,:);


end