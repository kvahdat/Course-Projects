*

Programmed by: Kimia Vahdat
Programmed on: 2020-09-5
Programmed to: ST 555 HW2

;

*Establish librefs and filerefs for incoming files;
X "cd L:/st555/Data";
libname InputDS ".";
filename RawData ".";

*Establish librefs and filerefs for outgoing files;
X "cd S:/ST 555";
libname HW2 ".";


* Setting the global output options;
options ps=150 ls=95 number pageno=1 nodate FMTSEARCH=(InputDS);


* ods settings to create two output files one pdf and one rtf;
ods listing close;   

ods pdf file="HW2 Vahdat Baseball Report.pdf" style=journal; * writing the results in a pdf file;
ods rtf file="HW2 Vahdat Baseball Report.rtf" style=sapphire; * writing the results in a rtf file;

ods trace on;

* Reading the Data;
* The first Observation started at row 14 so the option firstobs is set to 14, Also we have two dlm
for this data one is tab and the other is comma which are mentioned in the dlm option;
* To make sure the order of variables are all in the same order as the rtf file, I first put the 
attrib function; 

Data HW2.HW2VahdatBaseball;
     infile RawData('Baseball.dat') firstobs=14 
                                 dlm='2c09'x dsd;
                
     attrib  FName label="First Name" 
             LName label="Last Name"
             Team label="Team at the end of 1986"
             nAtBat label="# of At Bats in 1986"
             nHits label="# of Hits in 1986"
             nHome label= "# of Home Runs in 1986"
             nRuns label="# of Runs in 1986"
             nRBI label="# of RBIs in 1986"
             nBB label="# of Walks in 1986"
             YrMajor label="# of Years in the Major Leagues"
             CrAtBat label="# of At Bats in Career"
             CrHits label="# of Hits in Career"
             CrHome label= "# of Home Runs in Career"
             CrRuns label="# of Runs in Career"
             CrRbi label="# of RBIs in Career"
             CrBB label="# of Walks in Career" 
             League label="League at the end of 1986"
             Division label="Division at the end of 1986"
             Position label="Position(s) Played"
             nOuts label="# of Put Outs in 1986"
             nAssts label="# of Assists in 1986"
             nError label="# of Errors in 1986"
             Salary label="Salary (Thousands of Dollars)"
                    format=DOLLAR10.3
             ;

     length LName $ 11 FName $ 9 Team $ 13 
            Division $ 4 Position $ 2; * Fixing the length of character variables
            because sas only considers 8 characters;

     input LName $ FName $ Team $ nAtBat 50-53 nHits 54-57
           nHome 58-61 nRuns 62-65 nRBI 66-69 nBB 70-73 YrMajor 74-77
           CrAtBat 78-82 CrHits 83-86 CrHome 87-90 CrRuns 91-94
           CrRbi 95-98 CrBB 99-102 League $ Division $ Position $
           nOuts 133-136 nAssts 137-140 nError 141-144 Salary 145-152;

run;

* Excluding all unwanted tables and contents proc title;
ods rtf exclude EngineHost;
ods rtf exclude Attributes;

ods NOPROCTITLE;
ods pdf exclude all; * We don't want this report in the pdf file;

title 'Variable-Level Metadata (Descriptor) Information';

* Reporting the first table, which is a summary of variables in the order of creation;
proc contents data=HW2.HW2VahdatBaseball varnum;
run;

title 'Salary Format Detail';

* Reporting the format of the Salary defined in the Data folder;
proc format fmtlib library=InputDS;
     select Salary;
run;

*From this point on we want the reports to be in both rtf and pdf;
ods pdf exclude none;

title 'Five Number Summaries of Selected Batting Statistics';
title2 h=10pt 'Grouped by League (1986), Division (1986), and Salary Category (1987)';

* Reporting the means table with the requested columns without the label column;
proc means data=HW2.HW2VahdatBaseball min p25 p50 p75 max
           maxdec=2 NOLABELS;
     format Salary Salary.;

     class League Division Salary /MISSING; * To make sure it considers the missing values too;

     var nHits nHome nRuns nRBI nBB; 
run;

title 'Breakdown of Players by Position and Position by Salary';

* Printing two tables one for the position and the other for position by salary group;
proc freq data=HW2.HW2VahdatBaseball;
     format Salary Salary.;

     table Position;

     table Position*Salary/nocum MISSING; * To make sure it considers the missing values too;
run;

title 'Listing of Selected 1986 Players';
footnote h=8pt 'Included: Players with Salaries of at least $1,000,000 or who played for the Chicago Cubs';

proc sort data=HW2.HW2VahdatBaseball
          out=Baseball_sorted; * Creating a temporary file for the sorted data in the work library to work with;

     by League Division Team Descending Salary; * Sorting the data based on Descending Salary and Ascending 
                                                  League Division and Team variables;
run;

proc print data=Baseball_sorted label;
     format Salary DOLLAR12.3 nHits nRuns nRBI nBB Comma5.; * changing the format of the Salary and other numeric
                                                              variables so they match the output in commas and dollar sign;
     id LName FName Position;

     where (Salary ge 1000.000) OR (lowcase(Team) eq "chicago" 
           AND Salary^=. AND lowcase(League) eq "national"); * Setting the conditions, Also making sure that there are no 
                                                               missing values considered and the league is National; 
     var League Division Team Salary nHits nHome nRuns nRBI nBB;

     sum Salary nHits nHome nRuns nRBI nBB; * Adding the sum of these variables at the end;
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
ods listing;
  
quit;


