function [Illumination_Data] = Illumination_Calculations(Combinations, Far_Field_Data, Illuminated_Area_Limits, Flux_Data, Camera_Position)

%Set up structure for data
Illumination_Data = struct;

%The far field data is loaded
Far_Field_x = Far_Field_Data(:,1);
Far_Field_y = Far_Field_Data(:,2);

%These are the user-defined limits for the grid describing the illuminated
%area
X_limit = Illuminated_Area_Limits(1);
X_spacing = Illuminated_Area_Limits(2);
Y_limit = Illuminated_Area_Limits(3);
Y_spacing = Illuminated_Area_Limits(4);

%Formation of the grid
x_grid = -1 * X_limit:X_spacing:X_limit;
y_grid = -1 * Y_limit:Y_spacing:Y_limit;

%Determines the total number of combinations being investigated
S = size(Combinations);
number_combinations = S(1);

%Variables are pre-allocated for speed. 
data_theta = zeros(number_combinations,1);
data_phi = zeros(number_combinations,1);
data_x_position = zeros(number_combinations,1);
data_y_position = zeros(number_combinations,1);
data_height = zeros(number_combinations,1);

data_Std_Dev = zeros(number_combinations,1);
data_Total_Flux = zeros(number_combinations,1);
data_Std_Perc = zeros(number_combinations, 1);

%The data_Flux_total variable can be very large and require excessive
%memory.  As it is not necessary for optimisation is can be excluded.  It
%is not recommended to record this data when investigating large number of
%combinations.  
if Flux_Data == 1
    data_Flux_total = zeros(length(y_grid)-1, length(x_grid)-1, number_combinations);
end

theta_combinations = Combinations(:,1);
phi_combinations = Combinations(:,2);
x_position_combinations = Combinations(:,3);
y_position_combinations = Combinations(:,4);
height_combinations = Combinations(:,5);

parfor option = 1:number_combinations
    
    %Selects correct value for each variable for each combination
    theta = theta_combinations(option);
    phi = phi_combinations(option);
    x_position = x_position_combinations(option);
    y_position = y_position_combinations(option);
    height = height_combinations(option);
    
    %Determines the point at which the primary axis of the light source 
    %intersects the illuminated area
    d_along_plate = tan(theta)*height;
    y_along_plate = sin(phi)*d_along_plate;
    x_along_plate = cos(phi)*d_along_plate;

    light_centre_x = x_position + x_along_plate;
    light_centre_y = y_position + y_along_plate;

    %Pre-allocates the flux grid 
    Flux = zeros(length(y_grid)-1, length(x_grid)-1);

    for i = 1:length(x_grid)-1
        for j = 1:length(y_grid)-1

            %For graphing purposes, the x,y coordinate for each section of
            %the grid is recorded as its centre
            x = (x_grid(i) + x_grid(i+1))/2;
            y = (y_grid(j) + y_grid(j+1))/2;

            %Determines the distance from the source
            true_distance_from_source = pdist2([x, y, 0], [x_position, y_position, height]);
            
            %Determines the reduction in intensity from the source due to
            %distance
            Intensity_distance = 1/(true_distance_from_source)^2;

            %Determines the angle from the central beam of light to the
            %grid position
            v1 = [x, y, 0] - [x_position, y_position, height];
            v2 = [light_centre_x, light_centre_y, 0] - [x_position, y_position, height];
            CosTheta = dot(v1,v2)/(norm(v1)*norm(v2));
            Angle_from_source = acos(CosTheta);

            %Converts the angle to degrees 
            Angle_from_source_deg = Angle_from_source*180/pi;
            
            %Locates the points nearest to this angle in the far field
            %data and linearly interpolates as needed. If the angle exceeds that provided by the far field
            %data, the value of the relative intensity drop is assumed to
            %be equal to zero.
            if Angle_from_source_deg <= max(Far_Field_x)
                high = find(Far_Field_x >= Angle_from_source_deg, 1);
                low = find(Far_Field_x <= Angle_from_source_deg, 1, 'last');

                Intensity_angle = Far_Field_y(high) + (Angle_from_source_deg - Far_Field_x(high))*((Far_Field_y(low)-Far_Field_y(high))/(Far_Field_x(low)-Far_Field_x(high)));
            else
                Intensity_angle = 0;
            end
            
            %The overall intensity drop is calculated
            Intensity_drop = Intensity_distance * Intensity_angle;
            
            %Determines the angle from the position on the grid to the 
            %light source for the application of the cosine rule to account 
            %for the projected area difference between the light path and 
            %surface normal
            v1 = [0, 0, 1];
            v2 = [x_position, y_position, height] - [x, y, 0];
            v2 = v2/norm(v2);
            
            CosTheta = dot(v1,v2);
            
            Flux(j,i) = CosTheta * Intensity_drop * X_spacing * Y_spacing;
            
            %Determines the distance between the position on the gird to
            %the imaging device and accounts for the drop in relative
            %intensity due to this distance
            
            dist_grid_camera = pdist2([x, y, 0], Camera_Position);
            
            Flux(j,i) = Flux(j,i)/(dist_grid_camera^2);
            
            %Determines the angle from the position on the grid to the
            %location of the imaging device
            
            %This vector, v1 is a unit vector describing the position of
            %the imaging device at the centre of the illuminated area.
            v1 = Camera_Position;
            v1 = v1/norm(v1);
            v2 = [x, y, 0] - [0, 0, Camera_Position(3)];
            v2 = -1.*v2/norm(v2);
            
            Cos_Image_rule = dot(v1, v2);
            
            %Lambert’s cosine emission law is applied 
            Flux(j,i) = Flux(j,i)*Cos_Image_rule;
            
        end
    end
    
    %These calculations have been for one light source; it is assumed there
    %are four idential light sources with that are symmetrically positioned 
	%around the illuminated area across two axes of symmetry.
	%This can be altered as needed
    Flux1 = Flux;
    Flux2 = flipud(Flux);
    Flux3 = fliplr(Flux);
    Flux4 = flipud(fliplr(Flux)); %#ok<FLUDLR>
	%The comment above prevents a Matlab warning regarding efficiency of line 157
	
    %The total flux is the sum of that of each light source
    Flux_total = Flux1+Flux2+Flux3+Flux4;
    
    %Records all the inputs for each combination investigated
    data_theta(option) = theta;
    data_phi(option) = phi;
    data_x_position(option) = x_position;
    data_y_position(option) = y_position;
    data_height(option) = height;
    
    %Records all the results for each combination investigated 
    data_Std_Dev(option) = std2(Flux_total); 
    data_Total_Flux(option) = sum(sum(Flux_total));
    data_Std_Perc(option) = data_Std_Dev(option)/mean(mean(Flux_total))*100;
    
    if Flux_Data == 1
        data_Flux_total(:,:, option) = Flux_total;
    end
    
    
end

%Records the data as a structure
Illumination_Data.theta = data_theta;
Illumination_Data.phi = data_phi;
Illumination_Data.x_position = data_x_position;
Illumination_Data.y_position = data_y_position;
Illumination_Data.height = data_height;

Illumination_Data.total_flux = data_Total_Flux;
Illumination_Data.standard_deviation = data_Std_Dev;
Illumination_Data.standard_deviation_percentage = data_Std_Perc;

if Flux_Data == 1
    Illumination_Data.flux_data = data_Flux_total;
end

end

