# Optimising Light Source Positioning for Even and Flux-Efficient Illumination

## Statement of Need
Designing imaging systems is a challenge faced by researchers in many fields.  For example, many studies require optical set-ups with uniform illumination for data acquisition which must be rapidly assembled and optimised to meet the needs of each experiment.  Similarly, when prototyping new pieces of equipment with imaging systems, the lighting must be carefully designed.  Non-uniform illumination can contribute to low quality data, particularly so when illumination variation approaches or exceeds the sensitivity range of the capture device. Furthermore, low flux efficiency may negatively impact the reliability of the data and subsequent analysis.
This software is aimed at researchers who are optimising equipment for any application, from fluorescence measurements to image analysis, which require even and flux-efficient illumination.  The code can be easily adjusted to model a variety of light source configurations and rapidly calculates results for many thousands of possible arrangements.  This will significantly reduce the resources required to design an effective lighting system. 

## Dependencies

This software was designed for Matlab R2018a (Version 9.4) and requires the following toolboxes:

* Image Processing Toolbox
* Statistics and Machine Learning Toolbox
* Parallel Computing Toolbox
* MATLAB Distributed Computing Server

## Installation Instructions

In order to install and run this software the following files must be downloaded and saved to the same folder:

**Optimising_Light_Source_Positioning.m**
    
This is the main function file for the software.  In this file, the user provides the required information for each of the following functions. This includes but is not limited to the ranges for each positional variable, details regarding the imaging system specifications such as the size of the illuminated area and the position of the camera, and the tolerances for selecting the most viable configurations.  Documentation within this file advises the user where to change the code to adapt it to their specific needs. 

**Create_Variable_Combinations.m**

The position of the light source is defined in Cartesian coordinates relative to the centre of the illuminated area.  Further to this, a range of allowed angles of illumination in Polar coordinates (theta and phi) relative to the surface normal must be provided by the user.  The user provides limits and resolution for each of these variables in the main function file.  Create_Variable_Combinations.m then takes this information and generates a matrix of all possible positional configurations.  

**Exclude_Unallowed_Combinations.m**

The function Exclude_Unallowed_Combinations.m works to exclude positional configurations that are unfeasible.  The code is currently written such that any positional configuration that will block the field of view of the imaging device will be eliminated.  Furthermore, any configuration in which the principle axis of the light source does not intersect with the illuminated area (as defined by the user in the Exclude_Unallowed_Combinations.m) are deemed unsuitable and removed from the matrix of positional configurations.  

**Far_Field_Data.mat**

In order to calculate the illumination profile, the far field data for the light source is required.  This is usually provided by the manufacturer.  The data should be presented as a two column matrix where the first column is the angle (in degrees ranging from -90 to 90) from the principle axis and the second column is the relative intensity.  The data should be saved as Far_Field_Data.mat or the name of the variable should be modified in the main function file.  

**Illumination_Calculations.m**

Illimination_Calculations.m uses the far field data as well as user provided values to calculate the illumination profile for the light sources in each positional configuration.  In the main function file, the user must provide the name of the variable containing the far field data as well as the size of the illuminated area.  Additionally, the user provides the x and y resolution which defines the coarseness of the grid as well as the area over which the flux is calculated.  The position of the camera must also be provided.  This function file assumes that there are four identical light sources positioned across two lines of symmetry.  This can be adjusted as needed.  

**Convhull_Option_Reduction.m** 

Convhull_Option_Reduction.m uses a modified convex hull operation to reduce the full matrix of positional configurations to only the most viable by using two figures of merit: the total flux and the standard deviation.  The user can decide to use absolute standard deviation or standard deviation as a percentage of the mean flux.  As standard deviation is not necessarily a perfect descriptor for uniformity, additional data points may be of interest. Therefore, the user can provide tolerance values for both total radiant flux and standard deviation to broaden the domain of selected configurations.

**Plot_Save_Results.m**

To visualise the illumination profile of the remaining positional configurations, Plot_Save_Results.m will provide a colormap representing illumination profile and the relative positions of the light sources.  It will also provide the positional information of the light source, the total flux, and the standard deviation of the flux.   

## Contribution Guidelines

To report bugs or seek support please open an issue on this repository.  Contributions to the software are welcome; please open an issue for further discussion. 

## Example Usage & Automated Test

A system is being designed to image thin layer chromatography (TLC) plates which are 100 x 80mm in size.  The imaging device is to be placed at the centre of the system at a height of 110mm.  The maximum dimensions of the system are 200 x 160mm.  Four LED light sources are available which will be placed around the system across two axes of symmetry.  It is desired to determine the optimal position of the light sources to provide even illumination while maintaining sufficient flux to achieve high quality images.  Running the software as is should produce the same results as this example.  

<p align="center">
    <img src="https://github.com/adrena-lab/Optimising-Light-Source-Positioning/blob/Code/Figures/Schematic.png" width="300">
</p>
**Figure 1:**  Schematic illustrating the placement of the light source relative to the illuminated area with all relevant variables.

To reduce the computing time, a coarse investigation of the positional configurations was performed first.  

**Step 1**  
In Optimising_Light_Source_Positioning.m, the following limits and resolutions were provided for each variable.  **Note:** The centre of the system should lie at the (0,0,0) point in the Cartesian coordinate system.  

```
%Theta, enter in degrees
theta_range_interval = 30;
theta_range_lower_limit = 0;
theta_range_upper_limit = 90;

%Phi, enter in degrees
phi_range_interval = 30;
phi_range_lower_limit = 0;
phi_range_upper_limit = 90;

%X-Position
x_interval = 30;
x_lower_limit = -100;
x_upper_limit = -10;

%Y-Position 
y_interval = 20;
y_lower_limit = -80;
y_upper_limit = -10;

%Height above illuminated surface (z-position)
H_interval = 25;
H_lower_limit = 10;
H_upper_limit = 110;
```
Create_Variable_Combinations.m uses this information and will produce 1280 possible configurations; however, not all of these are practical.  

**Step 2**  
In step 2, the impractical configurations are removed from consideration.  There exists a rectangular pyramid wherein the placement of a light source would obstruct the view from the imaging device.  The vertices of this pyramid correspond to the vertices of the area being imaged and the position of the imaging device.  These are provided in Exclude_Unallowed_Combinations.m.

```
%Vertices of the domain (rectangle) being imaged
V1 = [-50, -40,   0];
V2 = [-50,  40,   0];
V3 = [ 50,  40,   0];
V4 = [ 50, -40,   0];
%Position of the imaging device
V5 = [  0,   0, 110];
```
 
The software then determines if any of the combinations lie within this pyramid and excludes them from further consideration.  To further reduce the computational time, any configuration in which the principle axis of the light source does not intersect the illuminated area can be excluded.  The user provides the vertices of the illuminated area (which may be different from the region being imaged) and Exclude_Unallowed_Combinations.m removes these configurations.  Subsequently, only 260 feasible combinations remain for investigation.  

**Step 3**  
Next the software will calculated the illumination profile for each configuration.  In the main function file (Optimising_Light_Source_Positioning.m) the user provides the far field data as well as the limits for the area of interest along with a resolution for the x and y directions and the position of the camera.

```
X_limit = 50;
X_Resolution = 1;
Y_limit = 40;
Y_Resolution = 1;

%Camera Position
Camera_Position = [0, 0, 110];
```

As the width of the TLC plate is 100 x 80 mm the region of interest will extend from -50 to 50 mm along the x-axis and from -40 to 40 mm along the y-axis.  A resolution of 1 mm was chosen; therefore, the flux will be calculated for 1 mm<sup>2</sup>.  The resulting structure, Illumination_Data contains the values for each variable along with the associated total flux, standard deviation, and standard deviation as a percentage of the mean flux.  

**Step 4**  
In order to choose an optimal illumination configuration, the set of all parameter combinations must be filtered down according to specific figures of merit.  Within this step, we provide a method for the user to refine their data set.  Our code uses a modified convex hull method to select configurations which maximize total flux for a given standard deviation.  

The descriptors used to determine how strong and uniform the illumination is are total flux and standard deviation respectively.  Standard deviation is provided both as an absolute value and as a percentage of the mean flux.  The user may select which will be more suitable for their optimisation

For absolute standard deviation the Std_Dev_Selector value should be 1; for the standard deviation as a percentage of the mean flux it should be 0.

As total flux and standard deviation (as an absolute value or a percentage of the mean flux) are not perfect descriptors for the system, it may be necessary to reduce the constraints of the data filter.  Tolerance values for these figures of merit are here specified by the user.

```
Std_Dev_Selector = 1;
Total_Flux_Tolerance = 5*10^-6;
Standard_Deviation_Tolerance = 10^-8;
```

This process further reduces the number of viable configurations from 260 to 26 as shown in Figure 2. 

![](https://github.com/adrena-lab/Optimising-Light-Source-Positioning/blob/Code/Figures/Convhull_Reduction1.png)
**Figure 2:**  The figures of merit, total flux and illumination variation (standard deviation), define the axes against which every parameter-combination is mapped (forming a cloud). The modified convex hull (boundary) of the candidate population is shown in blue and circled.  The values which have been selected based on the user provided tolerances are shown in blue.  

**Step 5**  
The remaining options provided after the modified convhull method was applied can be further reduced based upon user restrictions for minimum total flux or maximum standard deviation.  Furthermore, these final configurations are few enough in number to be plotted without requiring undue computational resources and evaluated by the user.  Examples of these illumination profiles are shown in Figure 3. 

![](https://github.com/adrena-lab/Optimising-Light-Source-Positioning/blob/Code/Figures/Illumination_Pattern_Options1.png)
**Figure 3:**  Illumination profiles for systems with four active light sources denoted by the black circles on the plot. The details of the variable values for these light sources are summarized in a legend on the bottom left of the plot.  These plots represent configuration options 1, 6, 8, & 11. 

The configuration options shown in Figure 3 show increasing standard deviation and total flux from a to b.  Option 8 appeared to provide a good balance between flux efficiency and uniformity.  Therefore, a more in depth analysis could be performed in the vicinity of the light source positions in option 8. 
