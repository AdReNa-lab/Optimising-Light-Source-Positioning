function [Illumination_Data_Reduced] = Convhull_Option_Reduction(...
    Illumination_Data, Std_Dev_Selector, Total_Flux_Tolerance, ...
    Standard_Deviation_Tolerance)
%Overview:  
%   Convhull_Option_Reduction.m uses a modified convex hull operation to 
%   reduce the full matrix of positional configurations to only the most 
%   viable by using two figures of merit: the total flux and the standard 
%   deviation. Based on this criteria, this function uses a modified convex
%   hull method to select those points which maximize total flux for a
%   given standard deviation. 
%
%Inputs:
%   Illumination_Data
%       This function requires the structure Illumination_Data calculated
%       in the function Illumination_Calculations.m. It contains the
%       positional information for each combination as well as the
%       respective values for total flux, standard deviation, and the
%       standard deviation as a percentage of the mean flux.  
%
%   Std_Dev_Selector
%       The user can decide to use absolute standard deviation or standard
%       deviation as a percentage of the mean flux as the second figure of
%       merit. To choose the absolute standard deviation, the 
%       Std_Dev_Selector variable should be set to 1, for standard
%       deviation as a percentage of the mean flux it should be set to 0. 
%
%   Total_Flux_Tolerance
%       As standard deviation is not necessarily a perfect descriptor for
%       uniformity, additional data points beyond what is selected by the
%       traditional convex hull function may be of interest. Therefore, the
%       user can provide tolerance values for both total radiant flux and
%       standard deviation.  The Total_Flux_Tolerance represents how far
%       from the convex hull points with regards to total flux a
%       configuration can be and still be presented as a viable option.  
%
%   Standard_Deviation_Tolerance
%       This variable is akin to the Total_Flux_Tolerance but represents
%       how far from the convex hull points with regard to standard
%       deviation a configuration can be and still be presented as a viable
%       option. 
%
%Output: 
%   Illumination_Data_Reduced
%       This is a structure containing the positional information for each
%       combination as well as the respective values for total flux,
%       standard deviation, and the standard deviation as a percentage of
%       the mean flux for the reduced options.  

%These lines of code implement the user's selection between the absolute
%standard deviation and the standard deviation as a percentage of
%illumination. 
if Std_Dev_Selector == 1
    std_dev = Illumination_Data.standard_deviation;
else
    std_dev = Illumination_Data.standard_deviation_percentage;    
end

%Defines the Total_Intensity
I = Illumination_Data.total_flux;

%Loads additional variables
data_theta = Illumination_Data.theta;
data_phi = Illumination_Data.phi;
data_x_position = Illumination_Data.x_position;
data_y_position = Illumination_Data.y_position;
data_height = Illumination_Data.height;

data_Total_Flux = Illumination_Data.total_flux;
data_Std_Dev = Illumination_Data.standard_deviation;
data_Std_Perc = Illumination_Data.standard_deviation_percentage;

%Sort the data according to standard deviation from smallest to largest
[std_dev_sort , In] = sort(std_dev);
I_sort = I(In);

I = I_sort;
std_dev = std_dev_sort;

%Perform same sort on other variables
data_theta = data_theta(In);
data_phi = data_phi(In);
data_x_position = data_x_position(In);
data_y_position = data_y_position(In);
data_height = data_height(In);

data_Total_Flux = data_Total_Flux(In);
data_Std_Dev = data_Std_Dev(In);
data_Std_Perc = data_Std_Perc(In);

%These are the tolerances that the user has already defined
dx = Standard_Deviation_Tolerance;
dy = Total_Flux_Tolerance;

%Matlab script takes the standard deviation and total intensity as the x
%and y values respectively.  It then finds the convex hull of the data set,
%i.e. a subset of points that enclose all other points in the dataset.  
%K is a vector of indices for these points
K = convhull(std_dev, I);

%This convex hull function moves in a counter-clockwise manner, as such, it
%will first select those points which have a low total flux.  We reverse
%the order of this vector for ease of later calculations. 
K = flipud(K);

%Uses the indices to extract the relevant points from the standard
%deviation and intensity data.  
Ks = std_dev(K);
KI = I(K);

%The goal is to achieve a high total intensity with a low standard
%deviation. Therefore, any points that correspond to a high standard 
%deviation and low total intensity can be disregarded.  As the convhull() 
%function chooses points to encompass the entire range of the data, there 
%will be some points that represent a high standard deviation and low 
%intensity. The following lines of code identify these and removes them 
%from the data set.  
[~, idx_upper] = max(KI);

Ks = Ks(1:idx_upper);
KI = KI(1:idx_upper);
K = K(1:idx_upper);

%The indices for all chosen points will be recorded in this vector 
Index_all = [];

for i = 1:length(Ks)-1
    
    %This creates a subset of data that lies between the ith and ith+1
    %points selected by the convex hull method
    std_dev_subset = std_dev(K(i):K(i+1)-1,1);
    intensity_subset = I(K(i):K(i+1)-1,1);
    
    %a linear fit is applied to the two convex hull points 
    slope = (KI(i+1)-KI(i))/(Ks(i+1)-Ks(i));
    int = KI(i) - slope*Ks(i);
    
    %For each standard deviation value from the subset, the corresponding
    %total flux is calculated based on the linear fit 
    linear_fit_y = slope.*std_dev_subset + int;
    
    %The difference between this calculated value and actual value is
    %determined
    difference_y = abs(intensity_subset - linear_fit_y);
    
    %If this value is less than the user-defined tolerance, the data point
    %is saved for further testing.  
    test_y = difference_y <= dy;
    
    %For each total flux value from the subset, the corresponding standard
    %deviation is calculated based on the linear fit.
    linear_fit_x = (intensity_subset-int)./slope;
    
    %The difference between this value and the actual value is determined 
    difference_x = abs(std_dev_subset - linear_fit_x);
    
    %If this value is less than the user-defined tolerance, the data point
    %is saved for further testing.  
    test_x = difference_x <= dx;
    
    %If a given data point is within both the total flux tolerance and the
    %standard deviation tolerance its corresponding value in the test
    %vector will be 1.  If it lies outside of one or both of these
    %tolerances it will be 0. 
    test = test_y.*test_x;
    
    %The indices of the acceptable points are extracted
    index = find(test == 1);
    
    %The indices above refer to the data subsets, they are now corrected to
    %be in line with the overall data set.
    index = index + K(i) - 1;
    
    %The indices are saved
    Index_all = [Index_all; index];
    
end

%This ensures all convex hull points are included in the list of indices of
%filtered data points
Index_all = [Index_all; K];

%This removes any duplicates
Index_unique = unique(Index_all);

%The indices are used to extract the corresponding standard deviation and
%total flux. 
X = std_dev(Index_unique);
Y = I(Index_unique);

%The filtered data is saved as a structure
Illumination_Data_Reduced = struct;

Illumination_Data_Reduced.theta = data_theta(Index_unique);
Illumination_Data_Reduced.phi = data_phi(Index_unique);
Illumination_Data_Reduced.x_position = data_x_position(Index_unique);
Illumination_Data_Reduced.y_position = data_y_position(Index_unique);
Illumination_Data_Reduced.height = data_height(Index_unique);

Illumination_Data_Reduced.total_flux = data_Total_Flux(Index_unique);
Illumination_Data_Reduced.standard_deviation = data_Std_Dev(Index_unique);
Illumination_Data_Reduced.standard_deviation_percentage = ...
    data_Std_Perc(Index_unique);

%This plots the results of the filtering process
figure('units','normalized','outerposition',[0 0 1 1])
plot(std_dev, I, '.r', Ks, KI, 'ok', X, Y, '.b', 'MarkerSize', 8)

if Std_Dev_Selector == 1
    xlabel('Standard Deviation')
else
    xlabel('Standard Deviation (% of the Mean Flux)')
end

ylabel('Total Flux')

title('Convex Hull Option Reduction')


dim = [0.625 0.15 .1 .1];
str = ['Initial Number of Options:  ',...
    num2str(length(Illumination_Data.total_flux))];
str = [str newline 'Reduced Number of Options:  ', num2str(length(X))];
t = annotation('textbox',dim,'String',str,'FitBoxToText','on');
t.FontSize = 14;
t.BackgroundColor = [1 1 1];
t.FaceAlpha = 1;
set(gca,'FontSize',16)
end
