global RAW_IMAGE_ARRAY;
global IMAGE_ARRAY_DOWNSIZED;
global FILTER_FLAG;
global FILTERED_IMAGE_ARRAY;
global FULL_IMAGE_ARRAY_FILTERED;
global BONE_PROJECTION;
global HOLE_PROJECTION;
global IMG_DATA_DB_ROT3;
global IMG_DATA_DB_ROT3_FULL;
global THICKNESS_ESTIMATE;


%global IMG_DATA_DB_ROT3_FULL;
%global FILTERED_IMAGE_ARRAY;
%global FULL_IMAGE_ARRAY_FILTERED;
%global FILTER_FLAG;
%global RAW_IMAGE_ARRAY;
%global IMG_DATA_DB_ROT3;
%global THICKNESS_ESTIMATE;
%global IMG_DATA_DB_ROT3_FULL;
%global IMG_DATA_DB_ROT3;
%global RAW_IMAGE_ARRAY;
%global SLICE_SLIDER_VALUE;
%global FILTER_FLAG;
%global RAW_WINDOW;
%global IMAGE_ARRAY_DOWNSIZED;
%global FILTER_WINDOW;


%Step 1: Image Acquisition

Input_directory_path = uigetdir(pwd,'Select folder containing CT-Scan Slices');
Input_directory = dir(strcat(Input_directory_path, '\*.TIF'));

disp (['Selected directory is: ', Input_directory_path]);

disp(['Input Directory has ', num2str(length(Input_directory)), ' Slices']);

%%% Initialize the array using zeros based on the size of the images.

%%% Find a way to put the values below in th program dynamically.(todo)
if(isempty(Input_directory))
    uialert(app.ScaffoldUIFigure,'No TIFF Images Found in specified folder','Error');
    return;
end


FileName=Input_directory(1).name;
temp =imread(strcat(relativepath(Input_directory_path), FileName));
RAW_IMAGE_ARRAY = zeros(size(temp,1),size(temp,2), length(Input_directory));

disp('Creating slices volume... ');


%d = uiprogressdlg(app.ScaffoldUIFigure,'Title','Please Wait',...
%    'Message','Importing and creating slices volume... ');
%app.ScaffoldUIFigure.Visible = 'off';
%app.ScaffoldUIFigure.Visible = 'on';
for i=1:length(Input_directory)
 %   d.Value = i/length(Input_directory);
    FileNames=Input_directory(i).name;
    temp=imread(strcat(relativepath(Input_directory_path), FileNames));
    temp=temp(:,:,1);
    RAW_IMAGE_ARRAY(:,:,i)=temp;
end
%d.close();
disp('Slices volume created successfully!');



% prompt = {'Please specify downscaling factor of volume (+ve Integer). Enter 1 if full resolution needed: '};
% dlgtitle = 'Input';
% dims = [1 55];
% definput = {num2str(5)};
% downscaling_factor = inputdlg(prompt,dlgtitle,dims,definput);

downscaling_factor="1";

% if(isempty(downscaling_factor))
%     uialert(app.ScaffoldUIFigure,'Please provide a downscaling value','No Input Provided!','Icon','warning');
%     return;
% end



IMAGE_ARRAY_DOWNSIZED =RAW_IMAGE_ARRAY(1:str2double(downscaling_factor):end, 1:str2double(downscaling_factor):end, 1:str2double(downscaling_factor):end);


% RAW_WINDOW = imshow(IMAGE_ARRAY_DOWNSIZED(:,:,1),[],'Parent',app.UIRaw);
% app.DataLoadedLamp.Color = 'green';

% app.SliceSlider.Limits = [1 size(IMAGE_ARRAY_DOWNSIZED,3)];
% app.SliceSlider.Enable = true;
 
FILTER_FLAG =0;


%Step 2: Applying Filters for Preprocessing

% d = uiprogressdlg(app.ScaffoldUIFigure,'Title','Please Wait',...
%     'Message','Applying Selected Filters... ','Indeterminate','on');

FILTERED_IMAGE_ARRAY = IMAGE_ARRAY_DOWNSIZED;
% if(app.NoiseFilterCheckBox.Value == 1)
    %%% Remove Noise (todo)
    %%% Bilateral Filtering? (todo)
% end

% if(app.FillHolesCheckBox.Value ==1)
    %%% Fill Holes (todo)
% end

% if(app.BinaryThresholdingCheckBox.Value ==1)
    %%% Applying binary thresholding
    disp('Applying Binary Thresholding... ');
    
    level = 255*graythresh(IMAGE_ARRAY_DOWNSIZED(:)./255);
    
    IMAGE_ARRAY_DOWNSIZED_binarized= double(imbinarize(IMAGE_ARRAY_DOWNSIZED,level));
    FILTERED_IMAGE_ARRAY = IMAGE_ARRAY_DOWNSIZED_binarized;
    
    level = 255*graythresh(RAW_IMAGE_ARRAY(:)./255);
    
    raw_image_array_binarized= double(imbinarize(RAW_IMAGE_ARRAY,level));
    FULL_IMAGE_ARRAY_FILTERED = raw_image_array_binarized;
    
% end

% if(app.ConnectedComponentsCheckBox.Value ==1)
    %%% Finding largest connected components and storing it in the array
    disp('Finding Lagest Connected Component... ');
    
    Connected_Components = bwconncomp(FILTERED_IMAGE_ARRAY);
    largestCompIndex = 0;
    tempLen=0;
    
    for i =1:Connected_Components.NumObjects
        temp = length(Connected_Components.PixelIdxList{1,i});
        if temp >tempLen
            tempLen = temp;
            largestCompIndex = i;
        end
    end
    
    %%% Using the connected component indices, make the pixels in that much
    %%% selection as 1. This will filter out all the disconnected pixels
    
    %%% Display Maximum connected component details (todo)
    image_array_donwsized_binarized_masked = zeros(size(FILTERED_IMAGE_ARRAY));
    image_array_donwsized_binarized_masked (Connected_Components.PixelIdxList{1,largestCompIndex}) = 1;
    FILTERED_IMAGE_ARRAY = image_array_donwsized_binarized_masked;
% end
% d.close();
% FILTER_WINDOW = imshow(FILTERED_IMAGE_ARRAY(:,:,int64(SLICE_SLIDER_VALUE)),[],'Parent',app.UIFilter);
disp('Bone volume pre-processed successfully!');
FILTER_FLAG =1;
%%% We saved the above array here in previous script, make it work without it(todo)

%Step 3: Applying Rotation optimization to the volume


% if(FILTER_FLAG==0)
%     uialert(app.ScaffoldUIFigure,'Please Apply Filters before proceeding with optimization...','Filters not applied!','Icon','warning');
%     return;
% end
% fig = figure('Name','Preview of Optimization','NumberTitle','off');

% if(app.DisplayOptimizationStatsCheckBox.Value ==1)
    
    options=optimoptions('simulannealbnd','MaxIterations', app.OptimizationiterationsEditField.Value,'PlotFcns',...
        {@saplotbestx,@saplotbestf,@saplotx,@saplotf});

    % else
%     
%     options=optimoptions('simulannealbnd','MaxIterations', app.OptimizationiterationsEditField.Value);
% end

 
% d = uiprogressdlg(app.ScaffoldUIFigure,'Title','Please Wait',...
%     'Message','Performing Rotation Optimization... ','Indeterminate','on');

[rotationresult,functionvalue] =simulannealbnd(@optimizeRotationMaxArea,(10*rand(1,3)),app.LowerBoundforangleEditField.Value,app.UpperBoundforangleEditField.Value, options);


close all
disp(['Optimization completed successfully! The optimal angles are (ZYX): ',num2str(rotationresult), ' with an area of ', num2str(abs(functionvalue)) , ' units']);
% d.close();

%%% Plug in the rotationresult values into the rotation values below (todo)

%%% Change the FILTERED_IMAGE_ARRAY to RAW_IMAGE_ARRAY later when everything is working. Right now it runs into out of memory problem(todo)
% d = uiprogressdlg(app.ScaffoldUIFigure,'Title','Please Wait',...
%     'Message','Generating Previews... ','Indeterminate','on');

imgDataDBROT1 = double(imrotate3(FILTERED_IMAGE_ARRAY,int8(rotationresult(1)),[0 1 0]));
IMG_DATA_DB_ROT3 = double(imrotate3(imgDataDBROT1 ,int8(rotationresult(2)),[1 0 0]));
%IMG_DATA_DB_ROT3 = double(imrotate3(imgDataDBROT2 ,int8(rotationresult(3)),[1 0 0]));


sum_projection=mean(IMG_DATA_DB_ROT3,3);

binary_sum_projection = (sum_projection>0);

filled_sum_projection = imfill(binary_sum_projection,'holes');


binary_hole_projection =double(abs(filled_sum_projection-binary_sum_projection));



BONE_PROJECTION = imshow(sum_projection,[],'Parent',app.UIBONE_PROJECTION);
HOLE_PROJECTION = imshow(binary_hole_projection,[],'Parent',app.UIHOLE_PROJECTION);

% d.close();


% d = uiprogressdlg(app.ScaffoldUIFigure,'Title','Please Wait',...
%     'Message','Applying rotations to Full Volume... ','Indeterminate','on');


imgDataDBROT1_Full = double(imrotate3(FULL_IMAGE_ARRAY_FILTERED,int8(rotationresult(1)),[0 1 0]));
IMG_DATA_DB_ROT3_FULL = double(imrotate3(imgDataDBROT1 ,int8(rotationresult(2)),[1 0 0]));

%%%Only doing rotation along X and Y axis for this dataset

% d.close();




disp('Rotation completed!');





%Step 4: Calculate the missing Region and create STL file



if(exist('STL_Outputs\','dir'))
    %  disp('WARNING: Output folder exists. New outputs will overwrite old data!');
    
else
    disp('No output folder found, creating folder now... ');
    mkdir('STL_Outputs');
    disp('Output folder created!');
    
end




%%% Consider below variable as 'A'
sum_projection=mean(IMG_DATA_DB_ROT3_FULL,3);

%%% Note: we create binarized version of sum_projection for hole
%%% calculation, and the original sum version is used for thickness
%%% estimation.
binary_sum_projection = (sum_projection>0);

%%% Consider below variable as 'B'
filled_sum_projection = imfill(binary_sum_projection,'holes');


%%% B is a superset of A, which contains A as well as pixels of the hole
%%% region. Now we can obtain the hole region pixels by subtraction (B-A)

binary_hole_projection =abs(filled_sum_projection-binary_sum_projection);

%%% This projection is the final shape of the hole that we can use to
%%% create the final volume for printing. Now we need to replicate this
%%% shape for <thickness> times along Z-Axis to obtain required depth.


%%% Step 5: Calculating Thickness of the volume

%%% Thickness of the bone can be considered as the sum of all the voxels
%%% along the depth of the bone, when each voxel is a unit value of 1.


%%% Put the notes here (todo)
struct_elem1 = strel('square',5);
binary_hole_eroded=imopen(binary_hole_projection, struct_elem1);

struct_elem2 = strel('square', 31);
binary_hole_dilated = imdilate(binary_hole_eroded,struct_elem2, 'same');

binIntersection = binary_hole_dilated&binary_sum_projection;

%   THICKNESS_ESTIMATE= round(100* mean(nonzeros(double(binIntersection).*sum_projection)));

%THICKNESS ESTIMATE GOES HERE



sum_projection=sum(IMG_DATA_DB_ROT3_FULL,3);
disp(size(IMG_DATA_DB_ROT3_FULL))
%figure, imshow(IMG_DATA_DB_ROT3_FULL(:,:,150),[])
% if(app.UseLocalFractureSiteButton.Value == true)
%     
%     
%     binary_sum_projection = (sum_projection>0);
%     
%     filled_sum_projection = imfill(binary_sum_projection,'holes');
%     
%     binary_hole_projection =abs(filled_sum_projection-binary_sum_projection);
%     
%     struct_elem1 = strel('square',app.StructingElement1SizeErosionEditField.Value);
%     binary_hole_eroded=imopen(binary_hole_projection, struct_elem1);
%     
%     struct_elem2 = strel('square', app.StructingElement2SizeDilationEditField.Value);
%     binary_hole_dilated = imdilate(binary_hole_eroded,struct_elem2, 'same');
%     
%     binIntersection = binary_hole_dilated&binary_sum_projection;
%     
%     THICKNESS_ESTIMATE= round(mean(nonzeros(double(binIntersection).*sum_projection)));
%     
% else
  

THICKNESS_ESTIMATE= round(mean(nonzeros(sum_projection)));
    
% end
% uialert(app.ScaffoldUIFigure,['Estimated Thickness is: ', num2str(THICKNESS_ESTIMATE)],'Thickness Estimation Complete!','Icon','success');


%END OF THICKNESS ESTIMATION


% prompt = {'Please verify thickness of scaffold. Below value is automatically calculated : '};
% dlgtitle = 'Input';
% dims = [1 55];
% definput = {num2str(THICKNESS_ESTIMATE)};
% final_thickness = inputdlg(prompt,dlgtitle,dims,definput);

final_thickness = THICKNESS_ESTIMATE;

final_hole_volume=zeros(size(IMG_DATA_DB_ROT3_FULL,1), size(IMG_DATA_DB_ROT3_FULL, 2), round(ceil(str2double(final_thickness))));

for i=1:round(str2double(final_thickness))
    final_hole_volume(:,:,i)=imfill(binary_hole_eroded,'holes');
end

disp('Scaffold volume created!');

disp('Creating isosurface of scaffold... ');


isosurface_of_hole_caps = isocaps(final_hole_volume,.5);
isosurface_of_hole_wall = isosurface(final_hole_volume,.5);

isosurface_of_hole_volume = isosurface_of_hole_wall;
isosurface_of_hole_volume.vertices = [isosurface_of_hole_volume.vertices; isosurface_of_hole_caps.vertices];
isosurface_of_hole_volume.faces = [isosurface_of_hole_volume.faces; ...
    isosurface_of_hole_caps.faces + length(isosurface_of_hole_wall.vertices(:,1))];


% isosurface_of_hole_volume = isosurface(final_hole_volume,.5);
%patchVolume = patch(isosurf);
%patchFilled = convhulln(isosurf)

%%% Test if patch conversion is needed or not (todo)
disp('Isosurface created successfully!');

disp('Writing scaffold volume to disk... ');

% d = uiprogressdlg(app.ScaffoldUIFigure,'Title','Please Wait',...
%     'Message','Writing scaffold volume to disk... ','Indeterminate','on');


stlwrite('..\STL_Outputs\scaffold_volume.stl',isosurface_of_hole_volume);
% d.close();

disp('Scaffold STL written to disk! Find it in STL_Outputs Folder!');
% uialert(app.ScaffoldUIFigure,'Scaffold STL written to disk! Find it in STL_Outputs Folder!','Scaffold STL Created!','Icon','success');

