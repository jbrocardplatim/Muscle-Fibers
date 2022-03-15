//Macro de délimitatin de fibres musculaires et mesure d'agrégats vacuolaires intenses
//Prérequis : deux images ouvertes finissant par _mCherry_0RG.tif et _FITC_ORG.tif
//@Jacques Brocard, 2019 pour Mathilde Chivet, éq. Marty du Grenoble Institut des Neurosciences
//modified in 2021 foe Maximilian Mcclusky
dir=getDirectory("image");
if (lengthOf(dir)==0) exit("Open Images First !");
if (isOpen("Log")){
	selectWindow("Log");
	run("Close");
}
selectImage(1);
ImageN=getTitle();
//Tester le nom des images ouvertes pour identifier FITC et mCherry
FITC=substring(ImageN,lengthOf(ImageN)-12,lengthOf(ImageN)-8);
if (FITC=="FITC"){
	radical=substring(ImageN,0,lengthOf(ImageN)-12);
	rename("FITC_vac");
	selectImage(2);
	rename("mCherry");
}else{
	rename("mCherry");
	selectImage(2);
	ImageN=getTitle();
	radical=substring(ImageN,0,lengthOf(ImageN)-12);
	rename("FITC_vac");
}

//Améliorer et seuiller l'image mCherry
selectWindow("mCherry");
run("Subtract Background...", "rolling=50 sliding disable");
run("Smooth");
if (isOpen("ROI Manager")) {roiManager("Select",0);}
run("Copy");
run("Close");
run("Internal Clipboard");
//run("Threshold...");
setAutoThreshold("Huang dark");
waitForUser("Choose a HIGH threshold... \n ...and click OK");
run("Convert to Mask");
run("Options...", "iterations=3 count=1 black do=Nothing");
run("Close-");
rename("mCherry");

//Améliorer et seuiller l'image FITC
selectWindow("FITC_vac");
run("Subtract Background...", "rolling=50 sliding disable");
run("Smooth");
if (isOpen("ROI Manager")) {roiManager("Select",0);}
run("Copy");
run("Close");
run("Internal Clipboard");
rename("FITC_vac");
run("Internal Clipboard");
//run("Threshold...");
setAutoThreshold("Huang dark");
waitForUser("Choose a LOW threshold... \n ...and click OK");
run("Convert to Mask");
run("Close-");
run("Invert");
rename("FITC");

//Combiner les deux images binaires FITC et mCherry pour obtenir un masque des fibres musculaires
imageCalculator("OR create", "mCherry","FITC");
selectWindow("Result of mCherry");
run("Invert");
run("Options...", "iterations=6 count=1 black do=Nothing");
run("Open");
rename("mask");
selectWindow("FITC");
close();
selectWindow("mCherry");
close();

analyze_fibers();
close("mask");


function analyze_fibers () {
	//Transformer les fibres musculaires en ROIs à partir de mask et y mesurer le signal FITC
	selectWindow("mask");
	run("Analyze Particles...", "size=1500-15000 pixel exclude clear add");
	selectWindow("FITC_vac");
	run("Enhance Contrast", "saturated=0.35");
	run("Set Measurements...", "min median redirect=None decimal=3");
	roiManager("Measure");

	//Colorer en rouge et compter les ROIs à agrégats, càd celles pour lesquelles Max > 5x Mediane
	nROIs=roiManager("Count");
	vac=0;
	for (i=0 ; i<nROIs; i++) {
	    roiManager("Select", i);
	    med = getResult("Median",i);
	    max = getResult("Max",i);
	    if (max/med>5){
			roiManager("Set Color", "red");
			vac++;
	    }
	}
	selectWindow("Results");
	run("Close");

	//Sauvegarder mask, les ROIs et l'image FITC traitée
	roiManager("Deselect");
	roiManager("Save", dir+radical+"mask.zip");
	roiManager("Show None");
	selectWindow("mask");
	saveAs("Tiff", dir+radical+"mask.tif");
	close();
	selectWindow("FITC_vac");
	saveAs("Tiff", dir+radical+"FITC_vac.tif");
	run("From ROI Manager");
	roiManager("Show All without labels");
	selectWindow("ROI Manager");
	run("Close");
	
	//Ecrire et sauvegarder le décompte final des fibres
	print("% fibers w/ vac = " + floor(10000*vac/nROIs)/100);
	print("Meaning : " + vac + " out of " + nROIs);
	selectWindow("Log");
	saveAs("Text", dir+radical+"log.txt");

}