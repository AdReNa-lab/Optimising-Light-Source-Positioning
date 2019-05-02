# Optimising Light Source Positioning for Even and Flux-Efficient Illumination

Designing imaging systems is a challenge faced by researchers in many fields.  For example, many studies require optical set-ups with uniform illumination for data acquisition which must be rapidly assembled and optimised to meet the needs of each experiment.  Similarly, when prototyping new pieces of equipment with imaging systems, the lighting must be carefully designed.  Non-uniform illumination can contribute to low quality data, particularly so when illumination variation approaches or exceeds the sensitivity range of the capture device. Furthermore, low flux efficiency may negatively impact the reliability of the data and subsequent analysis.
This software is aimed at researchers who are optimising equipment for any application, from fluorescence measurements to image analysis, which require even and flux-efficient illumination.  The code can be easily adjusted to model a variety of light source configurations and rapidly calculates results for many thousands of possible arrangements.  This will significantly reduce the resources required to design an effective lighting system. 

## Dependencies

This software was designed for Matlab R2018a (Version 9.4) and requires the following toolboxes:

* Image Processing Toolbox
* Statistics and Machine Learning Toolbox
* Parallel Computing Toolbox
* MATLAB Distributed Computing Server

## Installation instructions

In order to install and run this software the following files must be downloaded and saved to the same folder:

**Optimising_Light_Source_Positioning.m**
    
This is the main function file for the software.  In this file, the user provides the required information for each of the following functions. This includes but is not limited to the ranges for each positional variable, details regarding the imaging system specifications such as the size of the illuminated area and the position of the camera, and the tolerances for selecting the most viable configurations.  Documentation within this file advises the user where to change the code to adapt it to their specific needs. 

**Create_Variable_Combinations.m**

The position of the light source is defined in Cartesian coordinates relative to the centre of the illuminated area.  Further to this, a range of allowed angles of illumination in Polar coordinates (theta and phi) relative to the surface normal must be provided by the user.  The user provides limits and resolution for each of these varialbes in the main function file.  Create_Variable_Combinations.m then takes this information and generates a matrix of all possible positional configurations.  

**Exclude_Unallowed_Combinations.m**

The function Exclude_Unallowed_Combinations.m works to exclude positional configurations that are unfeasible.  The code is currently written such that any positional configuration that will block the field of view of the imaging device will be eliminated.  Furthermore, any configuration in which the principle axis of the light source does not intersect with the illuminated area (as defined by the user in the Exclude_Unallowed_Combinations.m) are deemed unsuitable and removed from the matrix of positional configurations.  

**Far_Field_Data.mat**

In order to calculate the illumination profile, the far field data for the light source is required.  This is usually provided by the manufacturer.  The data should be presented as a two column matrix where the first column is the angle (in degrees ranging from -90 to 90) from the principle axis and the second column is the relative intensity.  The data should be saved as Far_Field_Data.mat or the name of the variable should be modified in the main function file.  

**Illumination_Calculations.m**

Illimination_Calculations.m uses the far field data as well as user provided values to calculate the illumination profile for the light sources in each positional configureation.  In the main function file, the user must provide the name of the varialbe containing the far field data as well as the size of the illuminated area.  Additionally, the user provides the x and y resolution which defines the coarseness of the grid as well as the area over which the flux is calculated.  The position of the camera must also be provided.  This function file assumes that there are four identical light sources positioned across two lines of symmetry.  This can be adjusted as needed.  

**Convhull_Option_Reduction.m** 

Convhull_Option_Reduction.m uses a modified convex hull operation to reduce the full matrix of positional configurations to only the most viable by using two figures of merit: the total flux and the standard deviation.  The user can decide to use absolute standard deviation or standard deviation as a percentage of the mean flux.  As standard deviation is not necessarily a perfect descriptor for uniformity, additional data points may be of interest. Therefore, the user can provide tolerance values for both total radiant flux and
standard deviation to broaden the domain of selected configurations.

**Plot_Save_Results.m**

To visualise the illumination profile of the remaining positional configureations, Plot_Save_Results.m will provide a colormap represening illumination profile and the relative positions of the light sources.  It will also provide the positional information of the light source, the total flux, and the standard deviation of the flux.    

## Example usage

<img src="https://github.com/adrena-lab/Optimising-Light-Source-Positioning/blob/Code/Figures/Schematic.png" width="48">


## Contribution Guidelines

To report bugs or seek support please open an issue on this repository.  Contributions to the software are welcome; please open an issue for further discussion.  
