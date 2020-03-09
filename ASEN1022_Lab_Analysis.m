%% ASEN 1022 Spring 2020 Tensile Test Lab Analysis: Group 33
%% Authors and Description
% Group Members: Madelyn Albright, Annelene Belknap, Tycho Cinquini, Julian Claxton
% 
% March 9, 2020
%
% This program reads data from a tensile test in .csv format for two
% samples: A brittle specimen and a ductile specimen. The program uses this
% data to create engineering stress vs. engineering strain diagrams and
% estimates each material's properties.
% 
% Input:
%
%   - "ASEN1022_Feb21_Brittle_Data.csv" and "ASEN1022_Jan28_Ductile_Data.csv"
%   - Initial dimensions of each specimen
%
% Output:
%
%   - Young's Modulus:           (Brittle and ductile)
%   - Ultimate Tensile Strength: (Brittle and ductile)
%   - Fracture Strength:         (Brittle and ductile)
%   - Yield Strength:            (Ductile only)
%
%% Set Up Initial Values

clear; clc;

% Boolean used to determine whether results are given in SI or Imperial
% units - user defined
SI_UNITS = false;

% Psi to Pa conversion ratio
PSI_TO_PA = 6894.76;

% Define specimen dimensions (in imperial units)
initial_length = 1; % inches

brittle_width = .504; % inches
brittle_thickness = .187; % inches
brittleArea = brittle_width * brittle_thickness; % in^2

ductile_width = .5; % inches
ductile_thickness = .191; % inches
ductileArea = ductile_width * ductile_thickness; % in^2

%% Read Data from Files and Clean Errors

% Read data into matrices
brittleData = readmatrix("ASEN1022_Feb21_Brittle_Data.csv");
ductileData = readmatrix("ASEN1022_Jan28_Ductile_Data.csv");

% Create variables for elongation and load
brittleElongation = brittleData(:,4);
brittleLoad = brittleData(:,2);

ductileElongation = ductileData(:,4);
ductileLoad = ductileData(:,2);

% Remove erroneous data
brittleElongation = brittleElongation(brittleElongation >= 0); % remove negative elongation
brittleLoad = brittleLoad(brittleElongation >= 0); % remove corresponding load value

ductileLoad = ductileLoad(ductileLoad >= 100); % remove post fracture load value
ductileElongation = ductileElongation(ductileLoad >= 100); % remove corresponding elongation value

%% Calculate Engineering Stress and Strain

% Eng. stress = load/initial normal cross sectional area
% Eng. strain = change in length/initial length

eStressBrittle = brittleLoad/brittleArea; % psi
eStressDuctile = ductileLoad/ductileArea; % psi

eStrainBrittle = brittleElongation/initial_length; % in/in, unitless
eStrainDuctile = ductileElongation/initial_length; % in/in, unitless

% Convert stress to SI if specified up top (e strain is unitless)
if SI_UNITS
    eStressBrittle = eStressBrittle * PSI_TO_PA;
    eStressDuctile = eStressDuctile * PSI_TO_PA;
end

%% Estimate Young's Modulus

% Hard-coding a representative slice of the linear elastic region
% Representative region is the range of 0 psi 15000 psi for both specimens

% find indices in that range
if SI_UNITS
    % find region in SI units
    brittleRegion = find(eStressBrittle <= (15000 * PSI_TO_PA)); % indices with stress < 15 ksi
    ductileRegion = find(eStressDuctile <= (15000 * PSI_TO_PA)); % indices with stress below 15 ksi

else   
    % find region in american units
    brittleRegion = find(eStressBrittle <= 15000); % indices with stress < 15 ksi
    ductileRegion = find(eStressDuctile <= 15000); % indices with stress below 15 ksiend
end

% find x and y values in that region
brittleElasticY = eStressBrittle(brittleRegion);
brittleElasticX = eStrainBrittle(brittleRegion);

ductileElasticY = eStressDuctile(ductileRegion);
ductileElasticX = eStrainDuctile(ductileRegion);

% Find slopes for Young's Modulus
brittleSlope = polyfit(brittleElasticX, brittleElasticY, 1);
brittleE = brittleSlope(1);

ductileSlope = polyfit(ductileElasticX, ductileElasticY, 1);
ductileE = ductileSlope(1);

%% Ultimate Tensile Strength

brittleTS = max(eStressBrittle);
ductileTS = max(eStressDuctile);

%% Fracture Strength

brittleFracture = eStressBrittle(end);
ductileFracture = eStressDuctile(end);

%% Yield Strength

% Make .2 % offset line for ductile only
ductileOffsetX = eStrainDuctile + .002; % Offset x values
ductileOffsetY = eStrainDuctile * ductileE; % Apply Young's Modulus for slope
ductileOffsetY = ductileOffsetY(ductileOffsetY < ductileTS); % Clip all y values above TS
ductileOffsetX = ductileOffsetX(ductileOffsetY < ductileTS); % and corresponding x values

% Find intersect of .2% offset line and stress-strain line
for i = 1:length(eStrainDuctile)
    delta = ((eStrainDuctile(i) - .002) * ductileE) - eStrainDuctile(i); % offset value - e stress
    if delta >= 0 % offset is greater than or equal to stress (lines intersect)
        intersectIdx = i;
        break
    end
end
ductileYS = eStressDuctile(intersectIdx);

%% Plot Data
close all

% Brittle stress-strain plot
figure("Name", "Brittle Engineering Stress vs. Engineering Strain");
hold on
scatter(eStrainBrittle, eStressBrittle, '.', 'r');

title("Engineering Stress vs. Engineering Strain in Brittle Sample", 'FontSize', 13);
legend("\sigma_{eng} vs. \epsilon_{eng}", 'FontSize', 14);

if SI_UNITS
    xlabel("\epsilon_{eng} (m/m)", 'FontSize', 14);
    ylabel("\sigma_{eng} (Pa)", 'FontSize', 14);
else
    xlabel("\epsilon_{eng} (in/in)", 'FontSize', 14);
    ylabel("\sigma_{eng} (psi)", 'FontSize', 14);
end

% Ductile stress-strain plot
figure("Name", "Ductile Engineering Stress vs. Engineering Strain");
hold on
scatter(eStrainDuctile, eStressDuctile, '.', 'b');
plot(ductileOffsetX, ductileOffsetY, '--k');

title("Engineering Stress vs. Engineering Strain in Ductile Sample", 'FontSize', 13);
legend("\sigma_{eng} vs. \epsilon_{eng}", ".2% Offset Line", 'FontSize', 14);

if SI_UNITS
    xlabel("\epsilon_{eng} (m/m)", 'FontSize', 14);
    ylabel("\sigma_{eng} (Pa)", 'FontSize', 14);
else
    xlabel("\epsilon_{eng} (in/in)", 'FontSize', 14);
    ylabel("\sigma_{eng} (psi)", 'FontSize', 14);
end

%% Output Calculated Values

if SI_UNITS
    brittleEGiga = brittleE/(10^9); % Convert to Gpa
    ductileEGiga = ductileE/(10^9);
    
    brittleTSGiga = brittleTS/(10^9);
    ductileTSGiga = ductileTS/(10^9);
    
    brittleFractureGiga = brittleFracture/(10^9);
    ductileFractureGiga = ductileFracture/(10^9);
    
    ductileYSGiga = ductileYS/(10^9);
    
    fprintf("Young's Modulus (E):\n");
    fprintf("\tBrittle Specimen: %f GPa\n", brittleEGiga);
    fprintf("\tDuctile Specimen: %f GPa\n\n", ductileEGiga);
    
    fprintf("Ultimate Tensile Strength (T.S.):\n");
    fprintf("\tBrittle Specimen: %f GPa\n", brittleTSGiga);
    fprintf("\tDuctile Specimen: %f GPa\n\n", ductileTSGiga);
    
    fprintf("Fracture Strength:\n");
    fprintf("\tBrittle Specimen: %f Gpa\n", brittleFractureGiga);
    fprintf("\tDuctile Specimen: %f Gpa\n\n", ductileFractureGiga);
    
    fprintf("Yield Strength:\n");
    fprintf("\tDuctile Specimen: %f Gpa\n", ductileYSGiga);
    
else
    fprintf("Young's Modulus (E):\n");
    fprintf("\tBrittle Specimen: %f psi\n", brittleE);
    fprintf("\tDuctile Specimen: %f psi\n\n", ductileE);
    
    fprintf("Ultimate Tensile Strength (T.S.):\n");
    fprintf("\tBrittle Specimen: %f psi\n", brittleTS);
    fprintf("\tDuctile Specimen: %f psi\n\n", ductileTS);
    
    fprintf("Fracture Strength:\n");
    fprintf("\tBrittle Specimen: %f psi\n", brittleFracture);
    fprintf("\tDuctile Specimen: %f psi\n\n", ductileFracture);
    
    fprintf("Yield Strength:\n");
    fprintf("\tDuctile Specimen: %f psi\n", ductileYS);
end