clear; clc;

SI_UNITS = false;

% SI conversion ratios
PSI_TO_PA = 6894.76;

% specimen dimensions
initial_length = 2.5; % inches

brittle_width = .504; % inches
brittle_thickness = .187; % inches

ductile_width = .5; % inches
ductile_thickness = .191; % inches

brittleData = readmatrix("BrittleData.csv");
ductileData = readmatrix("DuctileData.csv");

% create variables
brittleElongation = brittleData(:,4);
brittleLoad = brittleData(:,2);
brittleArea = brittle_width * brittle_thickness; % in^2

ductileElongation = ductileData(:,4);
ductileLoad = ductileData(:,2);
ductileArea = ductile_width * ductile_thickness; % in^2

% remove erroneous data
brittleElongation = brittleElongation(brittleElongation >= 0); % remove negative elongation
brittleLoad = brittleLoad(brittleElongation >= 0); % remove corresponding load value

ductileLoad = ductileLoad(ductileLoad >= 100); % remove outlier
ductileElongation = ductileElongation(ductileLoad >= 100); % remove corresponding elongation value

% find engineering stress and engineering strain for each sample
% e stress = load/initial normal cross sectional area
% e strain = change in length/initial length
eStressBrittle = brittleLoad/brittleArea; % psi
eStressDuctile = ductileLoad/ductileArea; % psi

eStrainBrittle = brittleElongation/initial_length; % in/in, unitless
eStrainDuctile = ductileElongation/initial_length; % in/in, unitless

% convert e stress to SI units if specified up top (e strain is unitless)
if SI_UNITS
    eStressBrittle = eStressBrittle * PSI_TO_PA;
    eStressDuctile = eStressDuctile * PSI_TO_PA;
end

% estimate Young's Modulus from linear elastic region

% hard-coding a representative slice of the linear elastic region because
% compuatationally determining that is too hard
% representative region is the range of 10000 psi 15000 for both specimens

% find indices in that range
if SI_UNITS
    brittleRegionBottom = find(eStressBrittle >= (10000 * PSI_TO_PA)); % indices with stress above 10 ksi
    brittleRegionTop = find(eStressBrittle <= (15000 * PSI_TO_PA)); % indices with stress below 15 ksi
    brittleRegion = intersect(brittleRegionBottom, brittleRegionTop); % indices with 10 ksi < stress < 15 ksi

    ductileRegionBottom = find(eStressDuctile >= (10000 * PSI_TO_PA)); % indices with stress above 10 ksi
    ductileRegionTop = find(eStressDuctile <= (15000 * PSI_TO_PA)); % indices with stress below 15 ksi
    ductileRegion = intersect(ductileRegionBottom, ductileRegionTop); % indices with 10 ksi < stress < 15 ksi

else   
    brittleRegionBottom = find(eStressBrittle >= 10000); % indices with stress above 10 ksi
    brittleRegionTop = find(eStressBrittle <= 15000); % indices with stress below 15 ksi
    brittleRegion = intersect(brittleRegionBottom, brittleRegionTop); % indices with 10 ksi < stress < 15 ksi

    ductileRegionBottom = find(eStressDuctile >= 10000); % indices with stress above 10 ksi
    ductileRegionTop = find(eStressDuctile <= 15000); % indices with stress below 15 ksi
    ductileRegion = intersect(ductileRegionBottom, ductileRegionTop); % indices with 10 ksi < stress < 15 ksi
end

% find x and y values in that region
brittleElasticY = eStressBrittle(brittleRegion);
brittleElasticX = eStrainBrittle(brittleRegion);

ductileElasticY = eStressDuctile(ductileRegion);
ductileElasticX = eStrainDuctile(ductileRegion);

% find slopes for Young's Modulus
brittleSlope = polyfit(brittleElasticX, brittleElasticY, 1);
brittleE = brittleSlope(1);

ductileSlope = polyfit(ductileElasticX, ductileElasticY, 1);
ductileE = ductileSlope(1);

% find ultimate tensile strengths
brittleTS = max(eStressBrittle);
ductileTS = max(eStressDuctile);

% calculate fracture strengths
brittleFracture = eStressBrittle(end);
ductileFracture = eStressDuctile(end);

% make .2 % offset line for ductile only
ductileOffsetX = eStrainDuctile + .002;
ductileOffsetY = eStrainDuctile * ductileE;
ductileOffsetY = ductileOffsetY(ductileOffsetY < ductileTS); % clip all y values above TS
ductileOffsetX = ductileOffsetX(ductileOffsetY < ductileTS); % and corresponding x values

% find yield strength of ductile
for i = 1:length(eStrainDuctile)
    delta = ((eStrainDuctile(i) - .002) * ductileE) - eStrainDuctile(i); % offset value - e stress
    if delta >= 0 % offset is greater than or equal to stress
        intersectIdx = i;
        break
    end
end
ductileYS = eStressDuctile(intersectIdx);

% make plots
close all

% brittle
figure("Name", "Brittle Engineering Stress vs. Engineering Strain");
hold on
scatter(eStrainBrittle, eStressBrittle, '.', 'r');

title("Engineering Stress vs. Engineering Strain in Brittle Sample");
legend("\sigma_{eng} vs. \epsilon_{eng}");

if SI_UNITS
    xlabel("\epsilon_{eng} (m/m)");
    ylabel("\sigma_{eng} (Pa)");
else
    xlabel("\epsilon_{eng} (in/in)");
    ylabel("\sigma_{eng} (psi)");
end

% ductile
figure("Name", "Ductile Engineering Stress vs. Engineering Strain");
hold on
scatter(eStrainDuctile, eStressDuctile, '.', 'b');
plot(ductileOffsetX, ductileOffsetY, '--k');

title("Engineering Stress vs. Engineering Strain in Ductile Sample");
legend("\sigma_{eng} vs. \epsilon_{eng}", ".2% Offset Line");

if SI_UNITS
    xlabel("\epsilon_{eng} (m/m)");
    ylabel("\sigma_{eng} (Pa)");
else
    xlabel("\epsilon_{eng} (in/in)");
    ylabel("\sigma_{eng} (psi)");
end


% return all calculated values
if SI_UNITS
    brittleEGiga = brittleE/(10^9); % convert to giga range
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
    fprintf("\tDuctile Specimen: %f psi\n", ductileTS);
    
    fprintf("Fracture Strength:\n");
    fprintf("\tBrittle Specimen: %f psi\n", brittleFracture);
    fprintf("\tDuctile Specimen: %f psi\n", ductileFracture);
    
    fprintf("Yield Strength:\n");
    fprintf("\tDuctile Specimen: %f psi\n", ductileYS);
end