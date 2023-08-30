// Count the number and measure characteristics of active replication sites in 3D-SIM images 
// Foci segmentation is obtained using the 3D ImageJ Suite plugin (https://imagej.net/plugins/3d-imagej-suite/)


macro "Count replication signals" 
	{
	dir1 = getDirectory("Choose Source Directory ");
	dir2 = getDirectory("Choose Results Directory ");
	
	// read in file listing from source directory
	list = getFileList(dir1);
	
	
	setBatchMode(true);
	
	
	
	// loop over the files in the source directory
	for (i=0; i<list.length; i++)
		{
		if (endsWith(list[i], ".tif"))
			{
			filename = dir1 + list[i];
			imagename = list[i];	
			open(filename);
			
			rename("image");
			run("Split Channels");
			
			selectWindow("C3-image");
			run("Duplicate...", "duplicate");
			rename("DAPI-mask");
			selectWindow("DAPI-mask");
			
			run("Convert to Mask", "method=Percentile background=Dark calculate black");
			run("Options...", "iterations=3 count=1 black do=[Fill Holes stack]");
		
			run("Analyze Particles...", "size=100-350 display exclude clear include add stack");
			// the particle size could be adjusted to the current purpose run("Analyze Particles...", "size=3-Infinity display clear summarize add stack");
			if (isOpen("Results")){
			
			selectWindow("Results");
			
			// DAPI signal in 3D-SIM images shows a low contrast and cannot be precisely thresholded
			// The DAPI mask contains holes so one need to use ROI of the nucleus  			
			myArray_1 = newArray(nResults);
			
			for ( j=0; j<nResults; j++ ) { 
    	    myArray_1[j] = getResult("Area", j);
	
			}
			
			
			max_ROI = -1;
			max_area = 0;
			
			for ( r=0; r<myArray_1.length; r++ ) { 
    	    if (myArray_1[r]> max_area){
    	    	max_area = myArray_1[r];
    	    	max_ROI = r;
    	    }
			
			}
			
			
			
			selectWindow("Results");
			run("Close");
			
			// discard signal outside nucleus			
			if (max_ROI != -1 && max_area != 0){
				
				selectWindow("C3-image");
				roiManager("select",max_ROI); 
				run("Clear Outside", "stack");
				
				selectWindow("C2-image");
				roiManager("select",max_ROI); 
				run("Clear Outside", "stack");
				
				selectWindow("C1-image");
				roiManager("select",max_ROI); 
				run("Clear Outside", "stack");
				
				
			}
			
			// segment foci in channel 1 and analyse their characteristics
			selectWindow("C1-image");
			run("3D Fast Filters","filter=MaximumLocal radius_x_pix=2.0 radius_y_pix=2.0 radius_z_pix=2.0 Nb_cpus=4");
			run("3D Spot Segmentation", "seeds_threshold=9000 local_background=0 local_diff=0 radius_0=2 radius_1=4 radius_2=6 weigth=0 radius_max=10 sd_value=1 local_threshold=[Gaussian fit] seg_spot=Maximum watershed volume_min=12 volume_max=1000000 seeds=3D_MaximumLocal spots=C1-image radius_for_seeds=2 output=[Label Image]");
			
		
			run("3D Manager");
			selectWindow("Index");
			Ext.Manager3D_AddImage();
	        Ext.Manager3D_Measure();
	        Ext.Manager3D_SaveResult("M", dir2 + imagename + "_12px_PCNA_foci.csv");
	        Ext.Manager3D_CloseResult("M");
	        Ext.Manager3D_Quantif();
	        Ext.Manager3D_SaveResult("Q", dir2 + imagename + "_INT_12px_PCNA_foci.csv");
	        Ext.Manager3D_CloseResult("Q");
	        Ext.Manager3D_SelectAll();
	        Ext.Manager3D_Delete();
	        selectWindow("3D_MaximumLocal");
			saveAs("Tiff", dir2 + imagename + "_PCNA_MaximumLocal.tif");
			close();
			selectWindow("Index");
			saveAs("Tiff", dir2 + imagename + "_PCNA_segmented.tif");
			close(); 
			
			// segment foci in channel 2 and analyse their characteristics
			selectWindow("C2-image");
			run("3D Fast Filters","filter=MaximumLocal radius_x_pix=2.0 radius_y_pix=2.0 radius_z_pix=2.0 Nb_cpus=4");
			run("3D Spot Segmentation", "seeds_threshold=8000 local_background=0 local_diff=0 radius_0=2 radius_1=4 radius_2=6 weigth=0 radius_max=10 sd_value=1 local_threshold=[Gaussian fit] seg_spot=Maximum watershed volume_min=10 volume_max=1000000 seeds=3D_MaximumLocal spots=C2-image radius_for_seeds=2 output=[Label Image]");
			
			run("3D Manager");
			selectWindow("Index");
			Ext.Manager3D_AddImage();
	        Ext.Manager3D_Measure();
	        Ext.Manager3D_SaveResult("M", dir2 + imagename + "_10px_EdU_foci.csv");
	        Ext.Manager3D_CloseResult("M");
	        Ext.Manager3D_Quantif();
	        Ext.Manager3D_SaveResult("Q", dir2 + imagename + "_INT_10px_EdU_foci.csv");
	        Ext.Manager3D_CloseResult("Q");
	        Ext.Manager3D_SelectAll();
	        Ext.Manager3D_Delete();
	        selectWindow("3D_MaximumLocal");
			saveAs("Tiff", dir2 + imagename + "_EdU_MaximumLocal.tif");
			close();
			selectWindow("Index");
			saveAs("Tiff", dir2 + imagename + "_EdU_segmented.tif");
			close();
			
			
			rois = roiManager("count");
			myArray_2 =  newArray(rois);
			for(roi=0;roi<rois;roi++){
					
						
				myArray_2[roi] = roi; 
					
				}
				
				
			myArray_3 =  Array.deleteIndex(myArray_2, max_ROI);
				
			if (myArray_3.length != 0){
			// delete all ROIs axcept from one that was used for exclusion of cytoplasmic signal  
			roiManager("select", myArray_3);		
			roiManager("delete")
			
			// save the ROI that was used for exclusion of cytoplasmic signal
			roiManager("Save", dir2 + imagename + "_THE_ROI.zip");
				
						
			roiManager("select", 0);
			roiManager("delete");
			close("ROI Manager");
			
			// save thresholded image with nuclear signal only
			run("Merge Channels...", "c1=C1-image c2=C2-image c3=C3-image create keep");
		    save(dir2+imagename+"-cleared.tif");
		    close("*");
		   

			}
			else {
			// save the ROI that was used for exclusion of cytoplasmic signal
			roiManager("Save", dir2 + imagename + "_THE_ROI.zip");
				
						
			roiManager("select", 0);
			roiManager("delete");
			close("ROI Manager");
			// save thresholded image with nuclear signal only
			run("Merge Channels...", "c1=C1-image c2=C2-image c3=C3-image create keep");
		    save(dir2+imagename+"-cleared.tif");
		    close("*");
			}
				
			}
			
			
			else{
				close("*");
			}
			}
		}
	}