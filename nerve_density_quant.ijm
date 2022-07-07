file_name = getInfo("image.filename");
file_dir = getInfo("image.directory");

//ratio of pixel to um
pmR = 1947/1210.02

size_z = getInfo("SizeZ");
z_mid = round(size_z/2);
Z_start = newArray(z_mid-5, z_mid+1);
Z_stop = newArray(z_mid-1, z_mid+5);

//roi-xy size in um
size_m = 80;



run("8-bit");

//color threshold to filter hair roi out
ref_thre = 30;
rename("raw");

for (i=0; i<Z_start.length; i++){
  selectWindow("raw");
  run("Z Project...", "start="+Z_start[i]+" stop="+Z_stop[i]+" projection=[Max Intensity]");
  rename("raw_z-"+Z_start[i]+"-"+Z_stop[i]);
  current_title = "raw_z-"+Z_start[i]+"-"+Z_stop[i];
  
  //close previous ROI manager
  if (isOpen("ROI Manager")) {
    selectWindow("ROI Manager");
    run("Close");
  }

  //get ROI
  get_ROI(current_title, size_m);
  measure_ROI_intensity(current_title, file_name, file_dir, Z_start[i], Z_stop[i], ref_thre);
  close(current_title);
  run("Clear Results");
  //close previous ROI manager
  if (isOpen("ROI Manager")) {
    selectWindow("ROI Manager");
    run("Close");
  }
  
  run("Collect Garbage");

}

close("raw");

function get_ROI(title, size_m) {
  selectWindow(title);
  Stack.setChannel(1);
  setMinAndMax(0, 100);
  setTool("multipoint");
  waitForUser("Please select center points for all areas of interest. Click OK when done");
  run("Clear Results");
  run("Measure");
  for (i=0; i<nResults; i++) {
    px = getResult("X",i);
    py = getResult("Y",i);
    size_p = size_m*pmR;
    px_p = px*pmR-0.5*size_p;
    py_p = py*pmR-0.5*size_p;

    makeRectangle(px_p, py_p, size_p, size_p); //the coordinates index from the top left, like a 2D array
    roiManager("Add");
    run("Select None");
  }
  run("Clear Results");
  

} 



function measure_ROI_intensity(title, file_name, file_dir, Z_start, Z_stop, ref_thre) {
  selectWindow(title);
  Stack.setChannel(2);
  run("Clear Results");
  n = roiManager("count");
  run("Set Measurements...", "area mean standard min center bounding shape integrated stack redirect=None decimal=3");
  for (i=0; i<n; i++) {
    selectWindow(title);
    roiManager("select", i);
    Roi.getBounds(x,y,w,h);

    // get ref channel
    Stack.setChannel(1);
    run("Measure");
    ref_max = getResult("Max", 3*i);
    setResult("roi-id",  3*i, i);
    setResult("type",  3*i, "all-Ref");
    setResult("coord-x",  3*i, x);
    setResult("coord-y",  3*i, y);
    setResult("coord-w",  3*i, w);
    setResult("coord-h",  3*i, h);
    setResult("Refmax", 3*i, ref_max);

    // get signal channel all ROI background
    Stack.setChannel(2);
    run("Duplicate...", "duplicate");
    rename("roi");
    run("Measure");
    setResult("roi-id",  3*i+1, i);
    setResult("type",  3*i+1, "all");
    setResult("coord-x",  3*i+1, x);
    setResult("coord-y",  3*i+1, y);
    setResult("coord-w",  3*i+1, w);
    setResult("coord-h",  3*i+1, h);
    setResult("Refmax", 3*i+1, ref_max);

    // get signal channel filtered signal
    run("Duplicate...", "duplicate");
    rename("roi-cp");
    run("Auto Threshold", "method=Yen white");
    run("Create Selection");
    selectWindow("roi");
    run("Restore Selection");
    run("Measure");
    setResult("roi-id",  3*i+2, i);
    setResult("type",  3*i+2, "filtered");
    setResult("coord-x",  3*i+2, x);
    setResult("coord-y",  3*i+2, y);
    setResult("coord-w",  3*i+2, w);
    setResult("coord-h",  3*i+2, h);
    setResult("Refmax", 3*i+2, ref_max);

    close("roi");
    close("roi-cp");
    
    updateResults(); 
  }

  for (row=0; row<nResults; row++) {
    setResult("image_directory", row, file_dir);
    setResult("images", row, file_name);
    setResult("z_start", row, Z_start);
    setResult("z_stop", row, Z_stop);
    
    if (getResult("Refmax", row) > ref_thre) {
      setResult("ContainBackgroundSignal?", row, "Yes");
    } else {
      setResult("ContainBackgroundSignal?", row, "No");
    }
    
    if (getResult("Max", row) > 60) {
      setResult("ContainSignal?", row, "Yes");
    } else {
      setResult("ContainSignal?", row, "No");
    }
  }

  updateResults(); 
  saveAs("Results", file_dir + "Results_"+file_name+"_"+Z_start+"-"+Z_stop+".csv");
        
}