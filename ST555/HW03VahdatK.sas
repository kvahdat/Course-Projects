* 

Programmed by: Kimia Vahdat
Programmed on: 2020-09-15
Programmed to: ST 555 HW3

;
*Establish librefs and filerefs for incoming files;
X "cd L:/st555/Data/BookData/Data/Clinical Trial Case Study";
filename RawData ".";

X "cd L:/st555/Results/";
libname Results "."; * For comparisons and validations;

*Establish librefs and filerefs for outgoing files;
X "cd S:/ST 555";
libname HW3 ".";


* Setting the global output options, 
  also defining the format search space for defined formats later;
options ps=150 ls=95 number pageno=1 nodate FMTSEARCH=(HW3);


* ods settings to create two output files one pdf and one rtf;
ods listing close;   

ods pdf file="HW3 Vahdat Clinical Report.pdf"; * writing the results in a pdf file;
ods rtf file="HW3 Vahdat Clinical Report.rtf" style=sapphire; * writing the results in a rtf file;
ods powerpoint file="HW3 Vahdat Clinical Report.pptx" style=PowerPointDark; * writing the results in a powerpoint file;

ods trace on;

Data HW3.HW3VahdatSite1;

     infile RawData('Site 1, Baselilne Visit.txt') firstobs=1 dlm='09'x dsd;

     attrib Subj        label="Subject Number"
            sfReas      label="Screen Failure Reason" 
                        length=$50
            sfStatus    label="Screen Failure Status (0 = Failed)" 
                        length= $1
            BioSex      label="Biological Sex" 
                        length= $1
            VisitDate   label="Visit Date" 
                        length= $9
            failDate    label="Failure Notification Date" 
                        length= $9
            sbp         label="Systolic Blood Pressure"
            dbp         label="Diastolic Blood Pressure"
            bpUnits     label="Units (BP)" 
                        length= $5
            pulse       label="Pulse"
            pulseUnits  label="Units (Pulse)" 
                        length= $9
            position    label="Position" 
                        length= $9
            temp        label="Temperature" 
                        format=5.1
            tempUnits   label="Units (Temp)" 
                        length= $1
            weight      label="Weight"
            weightUnits label="Units (Weight)" 
                        length= $2
            pain        label="Pain Score"
            ;

    input Subj sfReas : $50. sfStatus $ BioSex $ VisitDate $    
          failDate $ sbp dbp bpUnits $ pulse pulseUnits $         
          position $ temp tempUnits $ weight weightUnits $   
          pain ;    
 
run;
* Sorting the data;
proc sort data= HW3.HW3VahdatSite1;

     by DESCENDING sfStatus sfReas DESCENDING VisitDate 
        DESCENDING failDate Subj;

run;
* Validating the data1;
proc compare base = HW3.HW3VahdatSite1 compare = Results.hw3dugginssite1 
             out = work.diffs noprint
             outbase outcompare outdiff outnoequal
             method = absolute criterion = 1E-10;
run;

ods rtf exclude EngineHost Attributes;
ods pdf exclude EngineHost Attributes;
ods powerpoint exclude all;

ods noproctitle;

ods output Position=HW3.hw3vahdatposition1; * Saving the results in a sas data;
title "Variable-level Attributes and Sort Information: Site 1";

proc contents data=HW3.HW3VahdatSite1 varnum;
run;

* Site 2;

Data HW3.HW3VahdatSite2;

     infile RawData('Site 2, Baseline Visit.csv') firstobs=1 dlm='2c'x dsd;

     attrib Subj        label="Subject Number"
            sfReas      label="Screen Failure Reason" 
                        length=$50
            sfStatus    label="Screen Failure Status (0 = Failed)" 
                        length= $1
            BioSex      label="Biological Sex" 
                        length= $1
            VisitDate   label="Visit Date" 
                        length= $10
            failDate    label="Failure Notification Date" 
                        length= $10
            sbp         label="Systolic Blood Pressure"
            dbp         label="Diastolic Blood Pressure"
            bpUnits     label="Units (BP)" 
                        length= $5
            pulse       label="Pulse"
            pulseUnits  label="Units (Pulse)" 
                        length= $9
            position    label="Position" 
                        length= $9
            temp        label="Temperature" 
                        format=3.1
            tempUnits   label="Units (Temp)" 
                        length= $1
            weight      label="Weight"
            weightUnits label="Units (Weight)" 
                        length= $2
            pain        label="Pain Score"
            ;

    input Subj sfReas : $50. sfStatus $ BioSex $ VisitDate $    
          failDate $ sbp dbp bpUnits $ pulse pulseUnits $         
          position $ temp tempUnits $ weight weightUnits $   
          pain ;    
 
run;
* Sorting the data;
proc sort data= HW3.HW3VahdatSite2;

     by DESCENDING sfStatus sfReas DESCENDING VisitDate 
        DESCENDING failDate Subj;

run;
* Validating the data;
proc compare base = HW3.HW3VahdatSite2 compare = Results.hw3dugginssite2 
             out = work.diffs noprint
             outbase outcompare outdiff outnoequal
             method = absolute criterion = 1E-10;
run;

ods noproctitle;

ods output Position=HW3.hw3vahdatposition2; * Saving the results in a sas data;

title "Variable-level Attributes and Sort Information: Site 2";

ods rtf exclude EngineHost Attributes;
ods pdf exclude EngineHost Attributes;

proc contents data=HW3.HW3VahdatSite2 varnum;
run;

* Site 3;

Data HW3.HW3VahdatSite3;
     infile RawData('Site 3, Baseline Visit.dat') firstobs=1 
            dlm=' ' dsd;

     attrib Subj        label="Subject Number"
            sfReas      label="Screen Failure Reason" 
                        length=$50
            sfStatus    label="Screen Failure Status (0 = Failed)" 
                        length= $1
            BioSex      label="Biological Sex" 
                        length= $1
            VisitDate   label="Visit Date" 
                        length= $10
            failDate    label="Failure Notification Date" 
                        length= $10
            sbp         label="Systolic Blood Pressure"
            dbp         label="Diastolic Blood Pressure"
            bpUnits     label="Units (BP)" 
                        length= $5
            pulse       label="Pulse"
            pulseUnits  label="Units (Pulse)" 
                        length= $9
            position    label="Position" 
                        length= $9
            temp        label="Temperature" 
                        format=3.1
            tempUnits   label="Units (Temp)" 
                        length= $1
            weight      label="Weight"
            weightUnits label="Units (Weight)" 
                        length= $2
            pain        label="Pain Score"
            ;

    * Using a mix of fixed position and length approach to read the data;
    input     Subj       1-3 
              sfReas   $ 8-27 
              sfStatus $ 59-60 
          @62 BioSex   $ 
          @63 VisitDate $    
          @73 failDate $ 
              sbp        83-85 
              dbp        86-88 
              bpUnits $  89-93 
              pulse      96-97 
              pulseUnits $ 98-106 
              position $ 108-116 
              temp       121-123 
         @124 tempUnits $       
              weight     125-127 
              weightUnits $ 128-129 
         @132 pain;  
    * To make sure that SAS prints IB for every record and the problematic variable
      which is pulse, I use the list command and putlog command;
    list;
    putlog 'The pulse is: ' pulse= ;
              
 
run;

* Sorting the data;
proc sort data= HW3.HW3VahdatSite3;
     by DESCENDING sfStatus sfReas DESCENDING VisitDate 
        DESCENDING failDate Subj;
run;

* Validating the data;
proc compare base = HW3.HW3VahdatSite3 compare = Results.hw3dugginssite3 
             out = work.diffs noprint
             outbase outcompare outdiff outnoequal
             method = absolute criterion = 1E-10;
run;

ods noproctitle;

ods output Position=HW3.hw3vahdatposition3; * Saving the results in a sas data;

title "Variable-level Attributes and Sort Information: Site 3";

ods rtf exclude EngineHost Attributes;
ods pdf exclude EngineHost Attributes;

proc contents data=HW3.HW3VahdatSite3 varnum;
run;
* Summary Statistics;
* Site 1 summary;

ods powerpoint exclude none;

title "Selected Summary Statistics on Baseline Measurements";
title2 "for Patients from Site 1";
footnote j=left h=8pt "Statistic and SAS keyword: Sample size (n), Mean (mean), Standard Deviation (stddev), Median (median), IQR (qrange)";

proc means data=HW3.HW3VahdatSite1 maxdec=1
           nonobs n mean stddev median qrange;

     class pain;

     var weight temp pulse dbp sbp;
run; 

* Site 2 summary;
title "Frequency Analysis of Baseline Positions and Pain Measurements by Blood Pressure Status";
title2 "for Patients from Site 2";

footnote j=left "Hypertension (high blood pressure) begins when systolic reaches 130 or diastolic reaches 80";

ods pdf columns=2; * Setting pdf columns to 2;
* Telling ods not to print the format table;
ods exclude format;

* Defining the a hypertension format for both sbp and dbp;
proc format library=HW3;
     value hp_sbp(fuzz=0) low -< 130= 'Acceptable'
                          130 -  high= 'High';

     value hp_dbp(fuzz=0) low -< 80= 'Acceptable'
                          80  -  high= 'High';
run;
* Defining the frequency tables;
proc freq data=HW3.HW3VahdatSite2 ;
     table position;

     table pain*dbp*sbp/ norow nocol;

     format sbp hp_sbp. dbp hp_dbp.;
run;

ods powerpoint exclude all;

title "Selected Listing of Patients with a Screen Failure and Hypertension";
title2 "for patients from Site 3";

footnote j=left "Hypertension (high blood pressure) begins when systolic reaches 130 or diastolic reaches 80";
footnote2 j=left "Only patients with a screen failure are included.";

ods pdf columns=1; * setting the pdf columns to one again;

* Printing the last table;
proc print data=HW3.HW3VahdatSite3 label;
     id Subj pain;

     var visitDate sfStatus sfReas failDate BioSex sbp
         dbp bpUnits weight weightUnits;

     where sfReas ne " " and (sbp gt 130 or dbp ge 80);
run;



* closing the title;
title;
* closing the footnote;
footnote;
* Closing the trace; 
ods trace off;
* closing the pdf;
ods pdf close;
ods rtf close;
ods powerpoint close;
ods listing;
  
quit;
