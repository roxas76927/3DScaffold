%Code for verifying the outputs from optimizers

%Step 1: Create a volume and initialize it to zeros

%%
Input_directory_path = uigetdir(pwd,'Select folder Verification Disk');
Input_directory = dir(strcat(Input_directory_path, '\Disk_Verification.TIF'));

disp (['Selected directory is: ', Input_directory_path]);


%%% Initialize the array using zeros based on the size of the images.

%%% Find a way to put the values below in th program dynamically.(todo)
if(isempty(Input_directory))
    uialert(app.ScaffoldUIFigure,'No TIFF Images Found in specified folder','Error');
    return;
end


FileName=Input_directory(1).name;
temp2 =imread(strcat(relativepath(Input_directory_path), FileName));
disp (FileName)
diskImg =imread(strcat(relativepath(Input_directory_path), FileName));
diskImg=diskImg(:,:,1);

global final_hole_volume
final_hole_volume=zeros(size(diskImg,1), size(diskImg, 2), round(ceil(150)));

%Step 2: Repeatedly copy and put the image into this volume with imfills

%%
for i=50:round(100)
    %final_hole_volume(:,:,i)=imfill(diskImg,'holes');
    final_hole_volume(:,:,i)=diskImg;
end

%Step 3: For an example, see the figure at end points and middle

%%
imshow(final_hole_volume(:,:,100))




%Step 4: Apply a rotation to the volume
%%
ROTATION_Y=45;

global final_hole_volume_rotated

final_hole_volume_rotated = double(imrotate3(final_hole_volume,int8(ROTATION_Y),[0 1 0],'loose'));
imshow(final_hole_volume_rotated(:,:,75))

%%
%Test Section : Checking to see if we have a proper fill and hole
%extraction

sum_projection=mean(final_hole_volume_rotated,3); 
binary_sum_projection = sum_projection > 0;
filled_sum_projection = imfill(sum_projection>0,'holes'); 

difference = filled_sum_projection-binary_sum_projection;


figure,
subplot(221), imshow(sum_projection,[]);title('Rotated Volume');
subplot(222), imshow(difference,[]);title('Extracted shape');
subplot(223), imshow(mean(final_hole_volume,3),[]);title('Original Volume');
%Step 5: Apply Optimization to restore rotation 
%%
    optionsSA=optimoptions('simulannealbnd','MaxIterations', 10,'PlotFcns',...
        {@saplotbestx,@saplotbestf,@saplotx,@saplotf});

    
    [rotationresult,functionvalue] =simulannealbnd(@OptimizeArea_Verification,(10*rand(1,1)),-10,10,optionsSA);

optionsPS=optimoptions('patternsearch','MaxIterations', 10,'PlotFcns',...
        {@saplotbestx,@saplotbestf,@saplotx,@saplotf});
    
  [rotationresultPS, functionvaluePS] =  patternsearch(@OptimizeArea_Verification,(10*rand(1,1)),-10,10,optionsPS);    
    

  optionsSO=optimoptions('surrogateopt','PlotFcns',...
        {@saplotbestx,@saplotbestf,@saplotx,@saplotf});
    
  [rotationresultSO, functionvalueSO] =  surrogateopt(@OptimizeArea_Verification,-10,10);    


  
  optionsPSW=optimoptions('particleswarm','MaxIterations', 10,'PlotFcns',...
        {@saplotbestx,@saplotbestf,@saplotx,@saplotf});
    
  [rotationresultPSW, functionvaluePSW] =  particleswarm(@OptimizeArea_Verification,(10*rand(1,1)),-10,10,optionsPSW);    

    
    