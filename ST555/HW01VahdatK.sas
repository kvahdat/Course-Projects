*

Programmed by: Kimia Vahdat
Programmed on: 2020-08-24
Programmed to: ST 555 HW1

;

*Establish librefs and filerefs for incoming files;
X "cd L:/st555/Data";
libname InputDS ".";


*Establish librefs and filerefs for outgoing files;
X "cd S:/ST 555";
libname HW1 ".";


* Setting the global output options;
options ps=150 ls=95 number pageno=1 nodate;


* ods settings ;
ods listing close; 
ods pdf file="HW1 Vahdat Shoes Report.pdf" style=Festival; * writing the results in a pdf file;
ods trace on;


* Excluding all unwanted tables and contents proc title;
ods exclude EngineHost;
ods NOPROCTITLE;
title 'Descriptor Information Before Sorting';
* Getting the first page tables using proc contents in the variable creation order;
proc contents data=InputDS.SHOES varnum;
run; 
* Sorting the data by region, locale region and product in descending order;
proc sort data=InputDS.SHOES 
          out=SHOES; * Saving the sorted data in the SAS work library;
     by Region Subsidiary descending Product;
run;
title 'Descriptor Information After Sorting';
* Adding the second page tables using the sorted data which is saved in the work libraryin the variable creation order;
* Additionally, I excluded the EngineHost table again;
ods exclude EngineHost;
proc contents data=SHOES varnum;
run;
title 'Listing of Amounts';
title2 h=8pt 'Including Region and Subsidiary within Region Totals'; * setting the second title font 8pt;
proc print data=SHOES label;
     * Splitting the tables by region, locale and product (with the ordered data);
     by Region Subsidiary descending Product;
     * Setting the same variables as identifiers so that we can get all other variables based on these;
     id Region Subsidiary Product;
     * Setting the formats and labels for all variables;
     * The dollar formats have been chosen in a way so we do not waste any extra space;
     attrib date label="Reporting Date" format=yymmdd10. 
            Sales label="Reseller's Sales" format=DOLLAR11.0 
            Inventory label="Reseller's Inventory" format=DOLLAR12.0
            Returns label="Reseller's Return" format=DOLLAR10.0
            Stores label="Number of Stores in Subsidiary"
            Region label="Sales Region"
            Subsidiary label="Locale within Region"
            Product label="Product Description";
     * Setting which variables will show in the tables and in what order;
     var date Sales Inventory Returns Stores;
     * Setting which variables should be summed;
     sum Sales Inventory Returns;
     * Setting the level (variable) by which variables should be summed;
     sumby Subsidiary;
run;
* Telling ods not to print the format table;
ods exclude format;
* Defining the new format based on the values of returns;
proc format fmtlib;
     value tier(fuzz=0)  low -< 600='Tier 1'
                         600 -< 1400='Tier 2'
                         1400 -< 3500='Tier 3'
                         3500 <- high='Tier 4'
;
run;
* Defining the titles and footnotes;
title 'Selected Numerical Summaries of Shoe Sales';
title2 h=8pt 'by Type, Region, and Returns Classification';
footnote j=l 'Excluding Slipper and Sandal';
footnote2 j=l 'Tier 1=Up tp $600, Tier 2=Up to $1400, Tier 3=Up to $3500, Tier 4=Over $3500';
* Creating the numerical table with proc means;
proc means data=SHOES nonobs n min q1 median q3 max maxdec = 1; * Only returning the specific statistics mentioned in the HW1 pdf.
     Also, setting the maximum decimal points to be 1 and removing the number of observations from the table;
     * Telling sas by which variables we want the statistics, maintaining the order; 
     class Region Product Returns;
     * Telling SAS for which variables we want the statistics;
     var Stores Sales Inventory;
     * Setting the formats and labels for all variables;
     attrib date label="Reporting Date" format=yymmdd10. 
            Sales label="Reseller's Sales" format=DOLLAR11.0 
            Inventory label="Reseller's Inventory" format=DOLLAR12.0
            Returns label="Reseller's Return" format=tier.
            Stores label="Number of Stores in Subsidiary"
            Region label="Sales Region"
            Subsidiary label="Locale within Region"
            Product label="Product Description";
     * Setting the condition to exclude product type sandal and slipper from the data;
     where lowcase(Product) not in ("sandal" "slipper");
run;
title 'Frequency of Stores by Region and Region by Product';
title2 'and Region by Returns Classification';
proc freq data=SHOES;
      * Creating the first frquency table in which number of stores each region is counted;
      table Region ;
      * Setting the formats and labels for all variables;
      attrib date label="Reporting Date" format=yymmdd10.
            Sales label="Reseller's Sales" format=DOLLAR11.0 
            Inventory label="Reseller's Inventory" format=DOLLAR12.0
            Returns label="Reseller's Return" format=tier.
            Stores label="Number of Stores in Subsidiary"
            Region label="Sales Region"
            Subsidiary label="Locale within Region"
            Product label="Product Description";
      * Creating tables for frequencies of Region times product and Region times reseller's return;
      tables Region*Product / nocum; * Excluding the cumulative frequencies;
      tables Region*Returns / nocum nocol; * Excluding the columns percentages and cumulative frequencies;
      * Again setting the condition to exclude product type sandal and slipper from the data;
      where lowcase(Product) not in ("sandal" "slipper"); 
      * Telling SAS to count the regions based on the stores;
      weight Stores; 
run;
* closing the title;
title;
* closing the footnote;
footnote;
* Closing the trace; 
ods trace off;
* closing the pdf;
ods pdf close;
ods listing;
  
quit;


