// Author: Sebastian Rhode & modified by Dennis Vollweiter
// Date: 2011-04-26 - modified: 2015-11-29

version_number = 2.0;

// marco for plotting mutiple lines (infinite number of ROIs) inside one plot
// only works with time-lapse images
// does not work with image 5D format

// -------------------------------------------------------------------------------------------------------------------------------------------------
// Define functions for array manipulation
// Adapted from http://www.richardwheeler.net/contentpages/text.php?gallery=ImageJ_Macros&file=Array_Tools&type=ijm

//Returns the maximum of the array
function maxOfArray(array) {
min=0;
for (a=0; a<lengthOf(array); a++) {
min=minOf(array[a], min);
}
max=min;
for (a=0; a<lengthOf(array); a++) {
max=maxOf(array[a], max);
}
return max;
}

function maxOfArray2D(array, NumberOfROI) {
//max = 0;
temporary = newArray(fr);
for (i=NumberOfROI; i<=(NumberOfROI+fr-1); i++) {
temporary[i-NumberOfROI] = array[(NumberOfROI-1) + (i-NumberOfROI)*numROI];
}
max = maxOfArray(temporary);
return max;
}

function minOfArray2D(array, NumberOfROI) {
min = 0;
temporary = newArray(fr);
for (i=NumberOfROI; i<=(NumberOfROI+fr-1); i++) {
temporary[i-NumberOfROI] = array[(NumberOfROI-1) + (i-NumberOfROI)*numROI];
}
min = minOfArray(temporary);
return min;
}

//Returns the indices at which a value occurs within an array
function indexOfArray(array, value) {
count=0;
for (a=0; a<lengthOf(array); a++) {
if (array[a]==value) {
count++;
}
}
if (count>0) {
indices=newArray(count);
count=0;
for (a=0; a<lengthOf(array); a++) {
if (array[a]==value) {
indices[count]=a;
count++;
}
}
return indices;
}
}

//Returns the minimum of the array
function minOfArray(array) {
max=0;
for (a=0; a<lengthOf(array); a++) {
max=maxOf(array[a], max);
}
min=max;
for (a=0; a<lengthOf(array); a++) {
min=minOf(array[a], min);
}
return min;
}

// -------------------------------------------------------------------------------------------------------------------------------------------------


// get title from active window
title_orig = getTitle();
selectWindow(title_orig);
imagedir = getInfo("image.directory")
imagefilename = getInfo("image.filename")
//print(imagedir);
//print(imagedir + imagefilename);
// get dimension from original image
getDimensions(w,h,ch,sl,fr);
//print("X :",w,"Y :",h,"CHANNELS :",ch,"SLICES :",sl,"FRAMES :",fr);

setBatchMode(true);
// create maximum & minmum intensity projetion
////run("Z Project...", "start=1 stop="+toString(fr)+" projection=[Max Intensity]");
////getStatistics(areaMax, meanMax, minMax, maxMax);
////selectWindow(title_orig);
////run("Z Project...", "start=1 stop="+toString(fr)+" projection=[Min Intensity]");
// determine the maximum pixel value to adjust the y-scaling of the plot
////getStatistics(areaMin, meanMin, minMin, maxMin);
////close();

Dialog.create("Multiple ROI Kinetics");
Dialog.addMessage("Version Number: " + toString(version_number,1));
Dialog.addNumber("Intervall [ms]",2000);
Dialog.addCheckbox("Plot Data Points", false);
Dialog.addNumber("Line Width for Lines",1);
Dialog.addNumber("Line Width for ROIs",0.5);
//Dialog.addCheckbox("Inculde Min & Max in result table", false);
Dialog.addCheckbox("Save Results as TXT-File", true);
Dialog.addCheckbox("Save Results as XLS-File", true);
//Dialog.addCheckbox("Show Results in Python - MatPlotLib", false);

Dialog.show();
timeframe = Dialog.getNumber();
plotpoints = Dialog.getCheckbox();
lw_plot = Dialog.getNumber();
lw_roi = Dialog.getNumber();
//minmax = Dialog.getCheckbox();
savetxt = Dialog.getCheckbox();
savexls = Dialog.getCheckbox();
//openmpl = Dialog.getCheckbox();

run("Set Measurements...", "  mean display redirect=None decimal=3");
//if (minmax == true){
//    run("Set Measurements...", "  mean min display redirect=None decimal=3");
//    }
//else if (minmax == false){
//    run("Set Measurements...", "  mean display redirect=None decimal=3");
//    }

// specify plot dimensions
run("Profile Plot Options...", "width=600 height=600 minimum=0 maximum=0 draw");

// -------------------------------------------------------------------------------------------------------------------------------------------------

frames = newArray(fr);

// -------------------------------------------------------------------------------------------------------------------------------------------------

// Get number of ROIs
numROI = roiManager("Count");

if (numROI == 0) {
exit("No ROIs selected!");
}

// Create array for labels (called 'lb'): "Mean1", "Mean2", "Mean3", ...
lb = newArray(numROI);
for (i=1; i<=numROI; i++) {
lb[i-1] = "Mean"+toString(i);
}

// create color list for ROIs
NumberColors = 7; // Number of color values (see list below)
colorvalues = newArray(NumberColors*numROI);

for (i=1; i<=numROI; i++) {
colorvalues[NumberColors*i-7] = "red"; // color for ROI 1
//print(NumberColors*i-7+" red");
colorvalues[NumberColors*i-6] = "green"; // color for ROI 2
colorvalues[NumberColors*i-5] = "magenta"; // color for ROI 3
colorvalues[NumberColors*i-4] = "black"; // color for ROI 4
colorvalues[NumberColors*i-3] = "orange"; // color for ROI 5
colorvalues[NumberColors*i-2] = "blue"; // color for ROI 6
colorvalues[NumberColors*i-1] = "yellow"; // color for ROI 7. For ROI 8: da capo
}


// adjust color properties for all ROIs
for (i=1; i<=numROI; i++) {
roiManager("Select", i-1);
colorvalue = colorvalues[i-1]; // List.get(toString(i)); // used to be i
roiManager("Set Color", colorvalue);
roiManager("Set Line Width", lw_roi);
}

// Calculate results table
roiManager("Deselect");
roiManager("Multi Measure");

// create array containing the frame numbers = Add time points to results table
for (i=1; i<=fr; i++) {
frames[i-1] = i * timeframe;
//setResult("Time", i-1, i * timeframe);
//setResult("Time (ms)", i-1, frames[i-1]);
}


// Create ROIs with values from results table
ROIs = newArray(numROI*fr);
for (i=1; i<=numROI; i++) {
for (j=1; j<=fr; j++){
ROIs[(i-1) + (j-1)*numROI] = getResult(lb[i-1],j-1);
}
}

// -------------------------------------------------------------------------------------------------------------------------------------------------
// Scaling the plot: Find maximum & minimum y-value of all selected rois, for setting Y_Max & Y_MIN on the y-axis.

ROImaxima = newArray(numROI);
ROIminima = newArray(numROI);


for (i=1; i<=numROI; i++) {
ROImaxima[i-1] = maxOfArray2D(ROIs, i);
}
for (i=1; i<=numROI; i++) {
ROIminima[i-1] = minOfArray2D(ROIs, i);
}

Y_MIN = minOfArray(ROIminima);
Y_MAX = maxOfArray(ROImaxima);
//print (Y_MAX, Y_MIN);

// -------------------------------------------------------------------------------------------------------------------------------------------------

// do the plots

roi1 = newArray(fr);
for (i=1; i<=fr; i++) {
roi1[i-1] = ROIs[0 + (i-1)*numROI];
}

Plot.create("Fluorescence", "Time [ms]", "Mean Intensity [cts]", frames, roi1);
//Plot.setLimits(1, fr*timeframe*1.02, minMin*1.3, maxMax*0.7);
Plot.setLimits(1, fr*timeframe*1.02, Y_MIN*0.95, Y_MAX*1.02);
Plot.setLineWidth(lw_plot);
if (plotpoints == true) {
Plot.add("Circle", frames, roi1);
}

for (k=2; k<=numROI; k++) {
temporary = newArray(fr);
for (i=k; i<=(k+fr-1); i++) {
temporary[i-k] = ROIs[(k-1) + (i-k)*numROI];
}
Plot.setColor(colorvalues[k-1]); // List.get(toString(k)));
Plot.add("Line", frames, temporary);

Y_Val =  1 - ((maxOfArray(temporary)-Y_MIN*0.95) / (Y_MAX*1.02-Y_MIN*0.95));
INDEX = indexOfArray(temporary, maxOfArray(temporary));
X_Val = INDEX[0] / (fr*1.02);
Plot.addText(toString(k), X_Val, Y_Val);

if (plotpoints == true) {
Plot.add("Circle", frames, temporary);
}
}

// ROI 1
Plot.setColor(colorvalues[0]); // List.get(toString(1)));

Y_Val =  1 - ((maxOfArray(roi1)-Y_MIN*0.95) / (Y_MAX*1.02-Y_MIN*0.95));
INDEX = indexOfArray(roi1, maxOfArray(roi1));
X_Val = INDEX[0] / (fr*1.02);
Plot.addText("1", X_Val, Y_Val);

// display the plot
Plot.show();
setBatchMode(false);

// -------------------------------------------------------------------------------------------------------------------------------------------------


if (savetxt == true) {
if (nResults==0) {
exit("Results table is empty");
}
else {
path = imagedir + imagefilename + "_RAW.txt";
//print(path);
saveAs("Measurements", path);
}
}

if (savexls == true) {
// save contents of Results table in Excel
if (nResults==0) {
exit("Results table is empty");
}
else {
path = imagedir + imagefilename + "_RAW.xls";
//print(path);
saveAs("Measurements", path);
//exec("cmd", "/c", "start", "excel.exe", "c:\\Results.xls");
}
}

//if (openmpl == true) {
//if (nResults==0) {
//exit("Results table is empty");
//}
//else {
//path = imagedir + imagefilename + "_Results.txt";
//saveAs("Measurements", path);
//exec("cmd", "/c","start", "python.exe", "c:/Dokumente und
//Einstellungen/sebastian.rhode/Eigene
//Dateien/Sebi/Projects_TILL/LA_Software/Online_Analysis/kinetics_FIJI.py",
//"run");
//}
//}
