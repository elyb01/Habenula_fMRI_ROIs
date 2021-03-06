% Ely 30 Aug 2017, adapted from older DBSRew version and MNI_biopt_BP_CC_FIX.m 

% NB: run par_MNI_extract_voxelwise_TS.sh before running this script and correct_Pairopt_headers.sh after

home='/sc/orga/projects/sterne04a/hb_rFMRI_7T_3T_HCP';
cd(home);
fprintf('Generates fMRI ROIs from Bandpass + CompCor + ICAFIX denoised 3T data.\n\n');
sublist=importdata('sublists/sublist.txt');
% set up subject loop
% parfor s=1:68
for s=1:68
        leftTS=importdata(sprintf('MNI_ROIs/Hb_TSregion/%d_left_Hb_region_voxelTS_BP_CC_FIX.txt',sublist(s))); headL=leftTS(1:3,:); leftTS=leftTS(4:4803,:);
	rightTS=importdata(sprintf('MNI_ROIs/Hb_TSregion/%d_right_Hb_region_voxelTS_BP_CC_FIX.txt',sublist(s))); headR=rightTS(1:3,:); rightTS=rightTS(4:4803,:);
    
        % create a blank matrix corresponding to each nifti voxel
        blank=zeros(91,109,91);
	imgL=blank;
	imgR=blank;
							    
	tcR=tril(corr(rightTS),-1); % unique triangle of correlation matrix
	stcR=sort(tcR(:),'descend'); % sort correlation coefficients high to low
	stcR=stcR(stcR>0);
	txtR=sprintf('%s/MNI_ROIs/Hb_Pairopt/%d_right_Pairopt_correlations.txt',home,sublist(s));
	[y,x]=find(tcR==stcR(1)); %find voxels with max correlation
	max1=stcR(1);
	imgR(headR(1,x)+1,headR(2,x)+1,headR(3,x)+1) = max1;
	imgR(headR(1,y)+1,headR(2,y)+1,headR(3,y)+1) = max1;
	row=[max1 x y headR(:,x)'];
        row=[row; max1 x y headR(:,y)'];
	cmax=sort([tcR(y,:) tcR(:,y)' tcR(:,x)' tcR(x,:)]','descend');
	cmax=cmax(cmax~=0);
	for i=1:length(cmax)
		[yy,xx]=find(tcR==cmax(i));
		if xx ~= x && imgR(headR(1,xx)+1,headR(2,xx)+1,headR(3,xx)+1) == 0 || cmax(i) > imgR(headR(1,xx)+1,headR(2,xx)+1,headR(3,xx)+1)
			imgR(headR(1,xx)+1,headR(2,xx)+1,headR(3,xx)+1) = cmax(i);
			row=[row; cmax(i) xx yy headR(:,xx)'];
		end
		if yy ~= y && imgR(headR(1,yy)+1,headR(2,yy)+1,headR(3,yy)+1) == 0 || cmax(i) > imgR(headR(1,yy)+1,headR(2,yy)+1,headR(3,yy)+1)
			imgR(headR(1,yy)+1,headR(2,yy)+1,headR(3,yy)+1) = cmax(i);
			row=[row; cmax(i) xx yy headR(:,yy)'];
		end
	end	
	dlmwrite(txtR,row,'delimiter',' ');

	tcL=tril(corr(leftTS),-1); % unique triangle of correlation matrix
	stcL=sort(tcL(:),'descend'); % sort correlation coefficients high to low
	stcL=stcL(stcL>0);
	txtL=sprintf('%s/MNI_ROIs/Hb_Pairopt/%d_left_Pairopt_correlations.txt',home,sublist(s));
	[y,x]=find(tcL==stcL(1)); %find voxels with max correlation
	max1=stcL(1);
	imgL(headL(1,x)+1,headL(2,x)+1,headL(3,x)+1) = max1;
	imgL(headL(1,y)+1,headL(2,y)+1,headL(3,y)+1) = max1;
	row=[max1 x y headL(:,x)'];
        row=[row; max1 x y headL(:,y)'];
	cmax=sort([tcL(y,:) tcL(:,y)' tcL(:,x)' tcL(x,:)]','descend');
	cmax=cmax(cmax~=0);
	for i=1:length(cmax)
		[yy,xx]=find(tcL==cmax(i));
		if xx ~= x && imgL(headL(1,xx)+1,headL(2,xx)+1,headL(3,xx)+1) == 0 || cmax(i) > imgL(headL(1,xx)+1,headL(2,xx)+1,headL(3,xx)+1)
			imgL(headL(1,xx)+1,headL(2,xx)+1,headL(3,xx)+1) = cmax(i);
			row=[row; cmax(i) xx yy headL(:,xx)'];
		end
		if yy ~= y && imgL(headL(1,yy)+1,headL(2,yy)+1,headL(3,yy)+1) == 0 || cmax(i) > imgL(headL(1,yy)+1,headL(2,yy)+1,headL(3,yy)+1)
			imgL(headL(1,yy)+1,headL(2,yy)+1,headL(3,yy)+1) = cmax(i);
			row=[row; cmax(i) xx yy headL(:,yy)'];
		end
	end	
	dlmwrite(txtL,row,'delimiter',' ');

        % create the output nifti files
        niiL=make_nii(imgL,[2, 2, 2]);
        niiR=make_nii(imgR,[2, 2, 2]);
        save_nii(niiL,sprintf('%s/MNI_ROIs/Hb_Pairopt/%d_left_Pairopt_Hb_MNI_BP_CC_FIX_full.nii',home,sublist(s)));
        fprintf('Subject %d left done\n',sublist(s));
        save_nii(niiR,sprintf('%s/MNI_ROIs/Hb_Pairopt/%d_right_Pairopt_Hb_MNI_BP_CC_FIX_full.nii',home,sublist(s)));
        fprintf('Subject %d right done\n\n',sublist(s));
end
fprintf('Script complete; now run nifti header correction script\n');


%%%%%% BONEYARD %%%%%%
%    dirs={'right' 'left'};
%    for d=[1 2]
%        % get the name of the timeseries file
%        infile=sprintf('voxelwise_ts_%s.txt',char(dirs(d)));
%        in=fopen(infile,'r');
%        % create the formatting string for textscan (has to match the
%        % number of columns, i.e. the number of voxels
%        format=repmat('%f',[1 length(str2num(fgetl(in)))]);
%        % reset the position counter
%        frewind(in);
%        % fix the formatting of the imported data
%        tmp=textscan(in,format);
%        fclose(in);
%        tmp=cell2mat(tmp);
%        % split apart header (voxel positions) and timeseries data
%        head=tmp(1:3,:);
%        data=tmp(4:903,:);
%        % create a blank matrix corresponding to each nifti voxel
%        blank=zeros(86,103,86);
%        img=blank;
        % set up a loop to go through each voxel
        % calculate voxel-to-voxel timeseries correlation and 
        % set value of matrix index corresponding to that voxel
     %   for v=1:length(leftTS(1,:))
     %       cL=corrcoef(leftTS(:,v));
     %       imgL(headL(1,v)+1,headL(2,v)+1,headL(3,v)+1)=cL(1,2);
     %   end
