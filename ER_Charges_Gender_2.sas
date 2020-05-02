/*Import Emergency Room Data*/
LIBNAME PUFLIB '/folders/myfolders/SASDATA';
FILENAME IN1 '/folders/myfolders/DOWNLOAD/h197.ssp';
/*Import Full Year Consolidated File*/
LIBNAME PUFLIB '/folders/myfolders/SASDATA';
FILENAME IN1 '/folders/myfolders/DOWNLOAD/h201.ssp';

/*Add a new column called Gender based of SEX field as a string instead of integer*/
Data Work.H201;
	Set PUFLIB.H201;
		if SEX = 2 then Gender='Female';
		else Gender='Male';
run;

/*Add a new column called Emergency_Room_Charges as a duplicate of column ERTC17X for display purposes*/
Data Work.H197E;
	Set PUFLIB.H197E;
	Emergency_Room_Charges=ERTC17X;
run;

/*Load Full Year Consolidated File and sort by Personal Identifier*/
/* Only keep personal indentifier and sex from H201*/ 
PROC SORT DATA=work.H201 (KEEP=DUPERSID Gender) OUT=PERSX;
BY DUPERSID;
RUN;

/*Load Emergency room data file and sort by personal identifier*/
PROC SORT DATA=work.h197e;
BY DUPERSID;
RUN;

/*Merge Full Year Consolidated File with Emergency Room Data File based on personal identifier*/
/*Keep all records from Emergency Room Data file and only related records from Full Year Consolidated file*/
DATA NEWEROM;
MERGE work.h197e (IN=A) PERSX (IN=B);
BY DUPERSID;
IF A;
RUN;
ods noproctitle;
ods graphics / imagemap=on;

/*Summary statistics including mean, standard deviation, min, max, median, and number of observations */
proc means data=WORK.NEWEROM chartype mean std min max median n vardef=df 
		qmethod=os;
	var Emergency_Room_Charges;
	label ERTC17X = "Emergency Room Total Charges";
	class Gender;
run;

/*Generate histograms of distribution of emergency room charges for Gender. Also include statistics inset in the upper right hand corner */
proc univariate data=WORK.NEWEROM vardef=df noprint;
	var Emergency_Room_Charges;
	class Gender;
	histogram Emergency_Room_Charges;
	inset mean std min max median n / position=ne;
run;

/*Sort file WORK.NEWEROM by Gender */
proc sort data=WORK.NEWEROM out=WORK.TempSorted2236;
	by Gender;
run;

/*Generate a boxplot of emergency room charges by Gender and include summary statistics in upper right hand corner */
proc boxplot data=WORK.TempSorted2236;
	plot (Emergency_Room_Charges)*Gender / boxstyle=schematic;
	inset mean stddev min max nobs / position=ne;
run;

/*Delete temp file used for boxplot  */
proc datasets library=WORK noprint;
	delete TempSorted2236;
	run;
	ods noproctitle;
ods graphics / imagemap=on;

/* Performs two tailed t test using Emergency Room Charges as the analysis variable and grouping the results based on Gender  */
/* Generates statistics and charts to display results of the ttest */
/* Defines null hypothesis to be mu1 - mu2 = 0 */
proc ttest data=WORK.NEWEROM sides=2 h0=0 plots(showh0);
	class Gender;
	var Emergency_Room_Charges;
	label ERTC17X = "Emergency Room Total Charges";
run;