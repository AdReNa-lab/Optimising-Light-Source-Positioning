%This is the main file for the optimisation of light source positioning, it
%will cover each step of the process along with associated instructions on
%each step and the modifications the user needs to perform in order to
%tailor the system to their own set-up 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%    STEP 1    %%% 

%There are five variables for this system.  The position of the light
%source is defined in Cartesian coordinates relative to the centre of the
%illuminated area.  Further to this, a range of allowed angles of 
%illumination in Polar coordinates (theta and phi) relative to the surface 
%normal must be provided by the user. Please see Figure 1a for a schematic
%demonstrating these variables.  

%NOTE: These values are for one light source, in the
%Illumination_Calculations step (Step 3) it is assumed that there are four
%identical light sources which are placed around the illuminated area over 
%two lines of symmetry. It is noted in Step 3 where the user may adjust this.  


%The user must adjust these values accordingly:

%Theta, enter in degrees
theta_range_interval = 45;
theta_range_lower_limit = 0;
theta_range_upper_limit = 85;

%Phi, enter in degrees
phi_range_interval = 45;
phi_range_lower_limit = 0;
phi_range_upper_limit = 90;

%X-Position
x_interval = 45;
x_lower_limit = -100;
x_upper_limit = -10;

%Y-Position 
y_interval = 35;
y_lower_limit = -80;
y_upper_limit = -10;

%Height above illuminated surface (z-position)
H_interval = 50;
H_lower_limit = 10;
H_upper_limit = 110;

%The values provided by the user are collected here into a matrix of input
%variables which will be used to determine all possible combinations
Input_Variables = [theta_range_interval, theta_range_lower_limit, theta_range_upper_limit;...
    phi_range_interval, phi_range_lower_limit, phi_range_upper_limit;...
    x_interval, x_lower_limit, x_upper_limit;...
    y_interval, y_lower_limit, y_upper_limit;...
    H_interval, H_lower_limit, H_upper_limit];

%This function file takes the Input_Variables matrix and outputs a matrix
%of all possible combinations.  Each row represents a possible combination
%while each column represents one of the five variables, theta, phi,
%x-position, y-position, and height in that order.
[Combinations] = Create_Variable_Combinations(Input_Variables);

disp('Step 1 is Complete')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%    STEP 2    %%% 

%Depending upon the lighting system, some of the combinations will be 
%unfeasible.  This may be due to design limitations such as providing an 
%unobstructed view for an imaging device or because certain combinations 
%are inherently inefficient and removing them will reduce the computing time.  

%As this process is highly individual to each lighting system, we
%have provided some general protocols for the removal of unsuitable
%combinations.  These filters can be augmented by the user and additional 
%screening processes can be added as needed.  It should be noted that this 
%step is not integral to the overall code and can be neglected.  

%NOTE: Do NOT use this section without reviewing the file and adjusting the
%values as needed. 

%If no filtering is desired, comment-out the following line.
[Combinations] = Exclude_Unallowed_Combinations(Combinations);

disp('Step 2 is Complete')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%    STEP 3    %%%

%In this step, a grid representing the illuminated area is created based on 
%inputs from the user.  For each point in the grid, the code accounts for 
%the drop in relative intensity due to distance from the light source and 
%angle from the principal axis of the light source (using far field data).
%The code then utilises a cosine flux correction to account for the 
%projected area difference between the light path and surface normal.
%Finally, Lambert’s cosine emission law (and a secondary target-to-lens 
%distance factor) is applied in order to determine the radiant intensity as 
%observed by the imaging objective.

%The output from this function is a structure containing the values of each 
%variable used, the resulting total radiant flux on the illuminated area 
%and the standard deviation across the illuminated area as both an absolute
%value and as a percentage of the mean radiant flux.  
%The user may modify the code to provide additional information as needed.   

%The far field data is required for the calculation, this will typically be
%provided by the supplier of the light source (or measured using a
%goniophotometer). It can be uploaded in any way but should be a two column
%array where the first column is the angle and the second is the relative 
%intensity.  We provide the far field data for a 5mm diameter hemispherical
%LED as an example.

load Far_Field_Data.mat;

%The region of interest must also be defined.  This is the area over which
%it is desired to achieve strong and uniform illumination. The centre of
%this area should lie at the (0,0) point.  The following inputs will form a
%grid for investigation.  The X and Y limits define how far from the (0,0)
%point the grid should extend.  The spacing determines the coarseness of
%the grid and also the area over which the flux is determined. 

X_limit = 53;
X_Spacing = 1;

Y_limit = 40;
Y_Spacing = 1;

Illuminated_Area_Limits = [X_limit, X_Spacing, Y_limit, Y_Spacing];

%It is also necessary to provide the height of the imaging device above the
%illuminated area and it's position in the coordinate system

Camera_Height = 110;
Camera_Position = [0, 0, 110];

%The user must decide if it is required to save the data of the flux for each 
%point within the grid i.e. creating a record of the illumination profile or
%just retaining the figures of merit for each illumination configuration.  
%As the number of possible combinations increases, this array becomes quite 
%large and may cause memory issues.  It is not necessary for optimisation 
%(only the total flux and standard deviation is required) and it is advised
%to not record this when doing a coarse investigation.  This data should 
%only be saved when investigating a few combinations.  If the user 
%wants to save this data, the Flux_Data parameter should be set to 1.  
%Otherwise it should be left as 0.

Flux_Data = 0;

%These calculations are for one light source. It is then assumed that 
%there are four light sources (positionally symmetric) which 
%are positioned around the illuminated area across 2 lines of symmetry.  
%The code responsible for this symmetry is found in lines 154-157 and can
%be modified as desired. 

[Illumination_Data] = Illumination_Calculations(Combinations, Far_Field_Data, Illuminated_Area_Limits, Flux_Data, Camera_Height, Camera_Position);

disp('Step 3 is Complete')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%    STEP 4a   %%%

%In order to choose an optimal illumination configuration, the set of all 
%parameter combinations must be filtered down according to specific figures
%of merit.  Within this step, we provide a method for the user to refine the
%their data set.  Our code uses a modified convex hull method to select 
%configurations which maximize total flux for a given standard deviation.  

%The descriptors used to determine how strong and uniform the illumination
%is are total flux and standard deviation respectively.  Standard deviation
%is provided both as an absolute value and as a percentage of the mean flux.
%The user may select which will be more suitable for their optimisation

%For absolute standard deviation the Std_Dev_Selector value should be 1; 
%for the standard deviation as a percentage of the mean flux it should be 0;

Std_Dev_Selector = 1;

%As total flux and standard deviation (as an absolute value or a percentage
%of the mean flux) are not perfect descriptors for the system, it may be
%necessary to reduce the constraints of the data filter.  Tolerance
%values for these figures of merit are here specified by the user.
Total_Flux_Tolerance = 10^-5;
Standard_Deviation_Tolerance = 10^-6;

[Illumination_Data_Reduced] = Convhull_Option_Reduction(Illumination_Data, Std_Dev_Selector, Total_Flux_Tolerance, Standard_Deviation_Tolerance);

disp('Step 4a is Complete')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%    STEP 4b    %%%

%The following function allows the user to plot and save the plots of each
%combination. It is not recommended to plot all combinations without using
%some method (such as the convex hull operation in Step 4a) to reduce the 
%number of combinations due to the computing power required to plot and save
%a potentially very large number of results.

%It may be desired to plot the area outside of the illuminated area so here
%the user can input the options for the area to be plotted.

X_limit = 110;
X_Spacing = 1;

Y_limit = 90;
Y_Spacing = 1;

Plotted_Area_Limits = [X_limit, X_Spacing, Y_limit, Y_Spacing];

%Plot_Save_Results(Illumination_Data, Plotted_Area_Limits, Illuminated_Area_Limits, Far_Field_Data, Camera_Height);

disp('Step 4b is Complete')