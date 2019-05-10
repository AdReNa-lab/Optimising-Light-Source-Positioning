function Plot_Save_Results(Illumination_Data_Reduced,...
    Plotted_Area_Limits, Illuminated_Area_Limits, Far_Field_Data,...
    Camera_Position)

%Overview:
%   To visualise the illumination profile of the remaining positional 
%   configurations, Plot_Save_Results.m will provide a colormap 
%   representing illumination profile and the relative positions of the 
%   light sources. It will also provide the positional information of the
%   light source, the total flux, and the standard deviation of the flux.
%
%Inputs:
%	Illumination_Data_Reduced
%       Structure provided by Convhull_Option_Reduction.m.  This contains
%       the positional information for each configuration as well as the
%       total flux, standard deviation, and standard deviation as a
%       percentage of the mean flux.
%
%	Plotted_Area_Limits
%       This input is a vector specified in 
%       Optimising_Light_Source_Positioning.m.  It contains the x and y
%       limits of the area of interest for visualisation as well as the
%       resolution for the calculations.  This region may be larger than
%       the illuminated area.  
%
%	Illuminated_Area_Limits
%       This input is a vector specified in 
%       Optimising_Light_Source_Positioning.m for
%       Illumination_Calculations.m.  These limits describe the region over
%       which even and intense illumination is desired.  
%
%	Far_Field_Data
%       The far field data is required.  The variable name for the data was 
%       provided for Illumination_Calculations.m.
%
%	Camera_Position
%       The x,y,z position of the camera/imaging device.
%
%Output:
%   Figure as described in the overview which is saved to the current
%   directory

X_limit = Plotted_Area_Limits(1);
X_spacing = Plotted_Area_Limits(2);
Y_limit = Plotted_Area_Limits(3);
Y_spacing = Plotted_Area_Limits(4);

%Formation of the grid
x_grid = -1 * X_limit:X_spacing:X_limit;
y_grid = -1 * Y_limit:Y_spacing:Y_limit;

    X = zeros(1, length(x_grid)-1);
    Y = zeros(1, length(y_grid)-1);

    for i = 1:length(x_grid)-1
        for j = 1:length(y_grid)-1

            x = (x_grid(i) + x_grid(i+1))/2;
            y = (y_grid(j) + y_grid(j+1))/2;
            X(i) = x;
            Y(j) = y;
        end
    end
    
    
%The far field data is read in here
Far_Field_x = Far_Field_Data(:,1);
Far_Field_y = Far_Field_Data(:,2);

S = size(Illumination_Data_Reduced.theta);
number_combinations = S(1);

for option = 1:number_combinations
    
    %Selects correct value for each variable for each combination
    theta = Illumination_Data_Reduced.theta(option);
    phi = Illumination_Data_Reduced.phi(option);
    x_position = Illumination_Data_Reduced.x_position(option);
    y_position = Illumination_Data_Reduced.y_position(option);
    height = Illumination_Data_Reduced.height(option);
    std_data = Illumination_Data_Reduced.standard_deviation(option);
    std_perc = ...
        Illumination_Data_Reduced.standard_deviation_percentage(option);
    flux_data = Illumination_Data_Reduced.total_flux(option);


    %Determines the position the centre of the light beam strikes the
    %illuminated area
    d_along_plate = tan(theta)*height;
    y_along_plate = sin(phi)*d_along_plate;
    x_along_plate = cos(phi)*d_along_plate;

    light_centre_x = x_position + x_along_plate;
    light_centre_y = y_position + y_along_plate;

    %Pre-allocates the flux grid 
    Flux = zeros(length(y_grid)-1, length(x_grid)-1);

    for i = 1:length(x_grid)-1
        for j = 1:length(y_grid)-1

            x = (x_grid(i) + x_grid(i+1))/2;
            y = (y_grid(j) + y_grid(j+1))/2;

            %Determines the distance from the source
            true_distance_from_source = pdist2([x, y, 0], [x_position,...
                y_position, height]);
            
            %Determines the reduction in intensity from the source due to
            %distance
            Intensity_distance = 1/(true_distance_from_source)^2;

            %Determines the angle from the central beam of light to the
            %grid position
            v1 = [x, y, 0] - [x_position, y_position, height];
            v2 = [light_centre_x, light_centre_y, 0] - [x_position,...
                y_position, height];
            CosTheta = dot(v1,v2)/(norm(v1)*norm(v2));
            Angle_from_source = acos(CosTheta);

            %Converts the angle to degrees 
            Angle_from_source_deg = Angle_from_source*180/pi;
            
            %Locates the points nearest to this angle in the far field
            %data and linearly interpolates as needed. If the angle exceeds 
            %that provided by the far field data, the value of the relative
            %intensity drop is assumed to be equal to zero.
            if Angle_from_source_deg <= max(Far_Field_x)
                high = find(Far_Field_x >= Angle_from_source_deg, 1);
                low = find(Far_Field_x <= Angle_from_source_deg, 1,...
                    'last');

                Intensity_angle = Far_Field_y(high) +...
                    (Angle_from_source_deg - Far_Field_x(high))*...
                    ((Far_Field_y(low)-Far_Field_y(high))/...
                    (Far_Field_x(low)-Far_Field_x(high)));
            else
                Intensity_angle = 0;
            end
            
            %The overall intensity drop is calculated
            Intensity_drop = Intensity_distance * Intensity_angle;
            
            %Determines the angle from the position on the grid to the 
            %light source for the application of the cosine rule
            v1 = [0, 0, 1];
            v2 = [x_position, y_position, height] - [x, y, 0];
            v2 = v2/norm(v2);
            
            CosTheta = dot(v1,v2);

            Flux(j,i) = CosTheta * Intensity_drop * X_spacing * Y_spacing;
            
            
            %Determines the angle from the position on the grid to the
            %location of the imaging device
            
            %This vector, v1 is a unit vector describing the position of
            %the imaging device at the centre of the illuminated area.
            v1 = [0, 0, 1];
            v2 = [x, y, 0] - [0, 0, Camera_Position(3)];
            v2 = -1.*v2/norm(v2);
            
            Cos_Image_rule = dot(v1, v2);
            
            Flux(j,i) = Flux(j,i)*Cos_Image_rule;
            
        end
    end
    
    %These calculations have been for one light source; it is assumed there
    %are four light sources with equal values for each variable and that
    %they are positioned around the illuminated area across two axes of
    %symmetry.  
    Flux1 = Flux;
    Flux2 = flipud(Flux);
    Flux3 = fliplr(Flux);
    Flux4 = flipud(fliplr(Flux)); %#ok<FLUDLR>
	%The comment above prevents a Matlab warning regarding efficiency of 
    %line 131
	
    Flux_total = Flux1+Flux2+Flux3+Flux4;   

figure('units','normalized','outerposition',[0 0 1 1])    
hold on

%If it is desired to plot only one of the light sources, substitute
%Flux_total with Flux1 or Flux2 or so on...
s = surf(X, Y, Flux_total);
rotate3d on
axis equal
colorbar
xlim([-X_limit, X_limit])
xlabel('X')
ylim([-Y_limit, Y_limit])
ylabel('Y')
s.EdgeColor = 'none';

%optional limit for colorbar axis, change maximum and minimum as needed
% minimum = 0;
% maximum = 15*10^-5;
% caxis([minimum maximum])


z3d = 1.1*max(max(Flux_total));

plot3(x_position, y_position, z3d, 'ok', 'MarkerSize',6, 'LineWidth', 2)
plot3(-x_position, y_position, z3d, 'ok', 'MarkerSize',6, 'LineWidth', 2)
plot3(x_position, -y_position, z3d, 'ok', 'MarkerSize',6, 'LineWidth', 2)
plot3(-x_position, -y_position, z3d, 'ok', 'MarkerSize',6, 'LineWidth', 2)

%Region of Interest

X_limit_ROI = Illuminated_Area_Limits(1);
Y_limit_ROI = Illuminated_Area_Limits(3);

plot3([X_limit_ROI, X_limit_ROI], [-Y_limit_ROI, Y_limit_ROI], [z3d, z3d], '--k')
plot3([-X_limit_ROI, -X_limit_ROI], [-Y_limit_ROI, Y_limit_ROI], [z3d, z3d], '--k')
plot3([-X_limit_ROI, X_limit_ROI], [Y_limit_ROI, Y_limit_ROI], [z3d, z3d], '--k')
plot3([-X_limit_ROI, X_limit_ROI], [-Y_limit_ROI, -Y_limit_ROI], [z3d, z3d], '--k')

dim = [.1 .1 .3 .3];
str1 = ['X-Position:  ', num2str(x_position), 'mm'];
str2 = [str1 newline 'Y-Position:  ', num2str(y_position), 'mm'];
str3 = [str2 newline 'Height:  ', num2str(height), 'mm'];
str4 = [str3 newline 'Theta:  ', num2str(round(theta*180/pi)), char(176)];
str5 = [str4 newline 'Phi:  ', num2str(round(phi*180/pi)), char(176)];
str6 = [str5 newline 'Std Dev: ', num2str(std_data, '%10.5e')];
str7 = [str6 newline 'Total Flux: ', num2str(flux_data)];
str = [str7 newline 'Std Perc: ', num2str(std_perc), '%'];
annotation('textbox',dim,'String',str,'FitBoxToText','on');
set(gcf, 'units','normalized','outerposition',[0 0 1 1])

theta = round(theta*180/pi);
phi = round(phi*180/pi);
str = [num2str(option), '  theta-', num2str(theta), '_phi-',...
    num2str(phi), '_x-', num2str(x_position), '_y-',...
    num2str(y_position), '_H-', num2str(height)];
saveas(gcf, str, 'jpeg')

close 
end
