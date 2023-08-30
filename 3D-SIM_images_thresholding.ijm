
//Macro for thresholding of 3D-SIM images (super-resolution images). 
//A typical 3D-SIM image contains 3 channels - DAPI and 2 other signals. The macro was tested for replication signal analysis. 

macro "Threshold 3D-SIM images" {
	//choose source directory and directories for processed images
	dir = getDirectory("Choose a source Directory ");
	dir_16bit = getDirectory("Choose a Directory for s16bit images Images ");
	dir_mask = getDirectory("Choose a Directory for masked Images ");
	dir_th = getDirectory("Choose a Directory for thresholded Images ");
	list = getFileList(dir);
	setBatchMode(true);
	for (i=0; i<list.length; i++) {
		path = dir+list[i];
		open(path);
		
	slashIndex = lastIndexOf(path, File.separator);
	name = substring(path, slashIndex, lengthOf(path));
		// choose exactly one nucleus for thresholding, the downstream analysis is possible only for a single cell
		setTool("rectangle");
		waitForUser("Waiting for user to draw a rectangle...");
		run("ROI Manager...");
		roiManager("Add");
		run("Crop");
		slices_s=nSlices;
 		
 		//  normalize signals to prevent oversaturation when converting to 16-bit
 		run("Enhance Contrast...", "saturated=0 normalize process_all use");
 		
		//3D-SIM images come as 32-bit, conversion to 16-bit is necessary
		run("16-bit");
		
		//through the 16-bit conversion hyperstack structure is lost, one has to restore it
		slices_inter=nSlices;
		slices_e =nSlices/3; 
		run("Stack to Hyperstack...", "order=xyczt(default) channels=3 slices=slices_e frames=1 display=Color");
		save(dir_16bit+name+"_16bit.tif");
		rename("image");
		run("Split Channels");
		
		
		selectWindow("C1-image");
		run("Duplicate...", "duplicate");
		rename("C1-image-thr");
		selectWindow("C1-image-thr");
		run("Auto Threshold", "method=Triangle ignore_black white stack use_stack_histogram");
		run("16-bit");
		run("Multiply...", "value=257 stack");
		
		//  normalize signals to get thresholded images 
		imageCalculator("Min create stack", "C1-image-thr", "C1-image"); 
		rename("C1-image-thr2");
		
		
		selectWindow("C2-image");
		run("Duplicate...", "duplicate");
		rename("C2-image-thr");
		selectWindow("C2-image-thr");
		run("Auto Threshold", "method=Triangle ignore_black white stack use_stack_histogram");
		run("16-bit");
		run("Multiply...", "value=257 stack");
		
		// normalize signals to get thresholded images 
		imageCalculator("Min create stack", "C2-image-thr", "C2-image");
		rename("C2-image-thr2");
		
		run("Merge Channels...", "c1=C1-image-thr2 c2=C2-image-thr2 c3=C3-image create keep");
		
		// save thresholded images 
		save(dir_th+name+"-thresh.tif");
		
		
		run("Merge Channels...", "c1=C1-image-thr c2=C2-image-thr c3=C3-image create keep");
		// save masked images
		save(dir_mask+name+"-masked.tif");
		roiManager("delete")
		close("ROI Manager");
		
		close('*');

	
	}
}
