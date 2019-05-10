function [Combinations] = Create_Variable_Combinations(Input_Variables)
%Overview: 
%   Create_Variable_Combinations.m uses the information the user provides
%   about the possible range of positions and generates a matrix of all
%   possible configurations.
%
%Input:
%   Input_Variables
%       The position of the light source is defined in Cartesian 
%       coordinates relative to the centre of the illuminated area. Further
%       to this, a range of allowed angles of illumination in Polar
%       coordinates (theta and phi) relative to the surface normal must be
%       provided by the user. The user provides limits and resolution for
%       each of these variables in the main function file,
%       Optimising_Light_Source_Positioning.m.
%       Note: Theta and phi should be entered in degrees and will be 
%       converted to radians. 
%
%Output:
%   Combinations
%       This is a matrix containing all possible positional configurations.
%


%Theta
theta_range_interval = Input_Variables(1,1);
theta_range_lower_limit = Input_Variables(1,2);
theta_range_upper_limit = Input_Variables(1,3);
theta_range_range_length = fix(abs((theta_range_upper_limit...
    -theta_range_lower_limit))/theta_range_interval)+1;

%Phi
phi_range_interval = Input_Variables(2,1);
phi_range_lower_limit = Input_Variables(2,2);
phi_range_upper_limit = Input_Variables(2,3);
phi_range_length = fix(abs((phi_range_upper_limit-...
    phi_range_lower_limit))/phi_range_interval)+1;

%X-Position
x_interval = Input_Variables(3,1);
x_lower_limit = Input_Variables(3,2);
x_upper_limit = Input_Variables(3,3);
x_range_length = fix(abs((x_upper_limit-x_lower_limit))/x_interval)+1;

%Y-Position 
y_interval = Input_Variables(4,1);
y_lower_limit = Input_Variables(4,2);
y_upper_limit = Input_Variables(4,3);
y_range_length = fix(abs((y_upper_limit-y_lower_limit))/y_interval)+1;

%Height above illuminated surface
H_interval = Input_Variables(5,1);
H_lower_limit = Input_Variables(5,2);
H_upper_limit = Input_Variables(5,3);
H_range_length = fix(abs((H_upper_limit-H_lower_limit)/H_interval))+1;

%A full factorial design is used to create all possible combinations for 
%each value of each variable provided above
Combinations = fullfact([theta_range_range_length, phi_range_length, ...
    x_range_length, y_range_length, H_range_length]);
Combinations(:,1) = (theta_range_lower_limit + (Combinations(:,1)-1).*...
    theta_range_interval).*pi/180;
Combinations(:,2) = (phi_range_lower_limit + (Combinations(:,2)-1).*...
    phi_range_interval).*pi/180;
Combinations(:,3) = x_lower_limit + (Combinations(:,3)-1).*x_interval;
Combinations(:,4) = y_lower_limit + (Combinations(:,4)-1).*y_interval;
Combinations(:,5) = H_lower_limit + (Combinations(:,5)-1).*H_interval;

end

