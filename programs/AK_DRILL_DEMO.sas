/* ----------------------------------------
Code exported from SAS Enterprise Guide
DATE: Tuesday, October 6, 2026     TIME: 6:01:00 PM
PROJECT: AK_DRILL_DEMO
PROJECT PATH: C:\Projects\AK_DRILL_DEMO.egp
---------------------------------------- */

/* Conditionally delete set of tables or views, if they exists          */
/* If the member does not exist, then no action is performed   */
%macro _eg_conditional_dropds /parmbuff;
	
   	%local num;
   	%local stepneeded;
   	%local stepstarted;
   	%local dsname;
	%local name;

   	%let num=1;
	/* flags to determine whether a PROC SQL step is needed */
	/* or even started yet                                  */
	%let stepneeded=0;
	%let stepstarted=0;
   	%let dsname= %qscan(&syspbuff,&num,',()');
	%do %while(&dsname ne);	
		%let name = %sysfunc(left(&dsname));
		%if %qsysfunc(exist(&name)) %then %do;
			%let stepneeded=1;
			%if (&stepstarted eq 0) %then %do;
				proc sql;
				%let stepstarted=1;

			%end;
				drop table &name;
		%end;

		%if %sysfunc(exist(&name,view)) %then %do;
			%let stepneeded=1;
			%if (&stepstarted eq 0) %then %do;
				proc sql;
				%let stepstarted=1;
			%end;
				drop view &name;
		%end;
		%let num=%eval(&num+1);
      	%let dsname=%qscan(&syspbuff,&num,',()');
	%end;
	%if &stepstarted %then %do;
		quit;
	%end;
%mend _eg_conditional_dropds;


/* Build where clauses from stored process parameters */
%macro _eg_WhereParam( COLUMN, PARM, OPERATOR, TYPE=S, MATCHALL=_ALL_VALUES_, MATCHALL_CLAUSE=1, MAX= , IS_EXPLICIT=0, MATCH_CASE=1);

  %local q1 q2 sq1 sq2;
  %local isEmpty;
  %local isEqual isNotEqual;
  %local isIn isNotIn;
  %local isString;
  %local isBetween;

  %let isEqual = ("%QUPCASE(&OPERATOR)" = "EQ" OR "&OPERATOR" = "=");
  %let isNotEqual = ("%QUPCASE(&OPERATOR)" = "NE" OR "&OPERATOR" = "<>");
  %let isIn = ("%QUPCASE(&OPERATOR)" = "IN");
  %let isNotIn = ("%QUPCASE(&OPERATOR)" = "NOT IN");
  %let isString = (%QUPCASE(&TYPE) eq S or %QUPCASE(&TYPE) eq STRING );
  %if &isString %then
  %do;
	%if "&MATCH_CASE" eq "0" %then %do;
		%let COLUMN = %str(UPPER%(&COLUMN%));
	%end;
	%let q1=%str(%");
	%let q2=%str(%");
	%let sq1=%str(%'); 
	%let sq2=%str(%'); 
  %end;
  %else %if %QUPCASE(&TYPE) eq D or %QUPCASE(&TYPE) eq DATE %then 
  %do;
    %let q1=%str(%");
    %let q2=%str(%"d);
	%let sq1=%str(%'); 
    %let sq2=%str(%'); 
  %end;
  %else %if %QUPCASE(&TYPE) eq T or %QUPCASE(&TYPE) eq TIME %then
  %do;
    %let q1=%str(%");
    %let q2=%str(%"t);
	%let sq1=%str(%'); 
    %let sq2=%str(%'); 
  %end;
  %else %if %QUPCASE(&TYPE) eq DT or %QUPCASE(&TYPE) eq DATETIME %then
  %do;
    %let q1=%str(%");
    %let q2=%str(%"dt);
	%let sq1=%str(%'); 
    %let sq2=%str(%'); 
  %end;
  %else
  %do;
    %let q1=;
    %let q2=;
	%let sq1=;
    %let sq2=;
  %end;
  
  %if "&PARM" = "" %then %let PARM=&COLUMN;

  %let isBetween = ("%QUPCASE(&OPERATOR)"="BETWEEN" or "%QUPCASE(&OPERATOR)"="NOT BETWEEN");

  %if "&MAX" = "" %then %do;
    %let MAX = &parm._MAX;
    %if &isBetween %then %let PARM = &parm._MIN;
  %end;

  %if not %symexist(&PARM) or (&isBetween and not %symexist(&MAX)) %then %do;
    %if &IS_EXPLICIT=0 %then %do;
		not &MATCHALL_CLAUSE
	%end;
	%else %do;
	    not 1=1
	%end;
  %end;
  %else %if "%qupcase(&&&PARM)" = "%qupcase(&MATCHALL)" %then %do;
    %if &IS_EXPLICIT=0 %then %do;
	    &MATCHALL_CLAUSE
	%end;
	%else %do;
	    1=1
	%end;	
  %end;
  %else %if (not %symexist(&PARM._count)) or &isBetween %then %do;
    %let isEmpty = ("&&&PARM" = "");
    %if (&isEqual AND &isEmpty AND &isString) %then
       &COLUMN is null;
    %else %if (&isNotEqual AND &isEmpty AND &isString) %then
       &COLUMN is not null;
    %else %do;
	   %if &IS_EXPLICIT=0 %then %do;
           &COLUMN &OPERATOR 
			%if "&MATCH_CASE" eq "0" %then %do;
				%unquote(&q1)%QUPCASE(&&&PARM)%unquote(&q2)
			%end;
			%else %do;
				%unquote(&q1)&&&PARM%unquote(&q2)
			%end;
	   %end;
	   %else %do;
	       &COLUMN &OPERATOR 
			%if "&MATCH_CASE" eq "0" %then %do;
				%unquote(%nrstr(&sq1))%QUPCASE(&&&PARM)%unquote(%nrstr(&sq2))
			%end;
			%else %do;
				%unquote(%nrstr(&sq1))&&&PARM%unquote(%nrstr(&sq2))
			%end;
	   %end;
       %if &isBetween %then 
          AND %unquote(&q1)&&&MAX%unquote(&q2);
    %end;
  %end;
  %else 
  %do;
	%local emptyList;
  	%let emptyList = %symexist(&PARM._count);
  	%if &emptyList %then %let emptyList = &&&PARM._count = 0;
	%if (&emptyList) %then
	%do;
		%if (&isNotin) %then
		   1;
		%else
			0;
	%end;
	%else %if (&&&PARM._count = 1) %then 
    %do;
      %let isEmpty = ("&&&PARM" = "");
      %if (&isIn AND &isEmpty AND &isString) %then
        &COLUMN is null;
      %else %if (&isNotin AND &isEmpty AND &isString) %then
        &COLUMN is not null;
      %else %do;
	    %if &IS_EXPLICIT=0 %then %do;
			%if "&MATCH_CASE" eq "0" %then %do;
				&COLUMN &OPERATOR (%unquote(&q1)%QUPCASE(&&&PARM)%unquote(&q2))
			%end;
			%else %do;
				&COLUMN &OPERATOR (%unquote(&q1)&&&PARM%unquote(&q2))
			%end;
	    %end;
		%else %do;
		    &COLUMN &OPERATOR (
			%if "&MATCH_CASE" eq "0" %then %do;
				%unquote(%nrstr(&sq1))%QUPCASE(&&&PARM)%unquote(%nrstr(&sq2)))
			%end;
			%else %do;
				%unquote(%nrstr(&sq1))&&&PARM%unquote(%nrstr(&sq2)))
			%end;
		%end;
	  %end;
    %end;
    %else 
    %do;
       %local addIsNull addIsNotNull addComma;
       %let addIsNull = %eval(0);
       %let addIsNotNull = %eval(0);
       %let addComma = %eval(0);
       (&COLUMN &OPERATOR ( 
       %do i=1 %to &&&PARM._count; 
          %let isEmpty = ("&&&PARM&i" = "");
          %if (&isString AND &isEmpty AND (&isIn OR &isNotIn)) %then
          %do;
             %if (&isIn) %then %let addIsNull = 1;
             %else %let addIsNotNull = 1;
          %end;
          %else
          %do;		     
            %if &addComma %then %do;,%end;
			%if &IS_EXPLICIT=0 %then %do;
				%if "&MATCH_CASE" eq "0" %then %do;
					%unquote(&q1)%QUPCASE(&&&PARM&i)%unquote(&q2)
				%end;
				%else %do;
					%unquote(&q1)&&&PARM&i%unquote(&q2)
				%end;
			%end;
			%else %do;
				%if "&MATCH_CASE" eq "0" %then %do;
					%unquote(%nrstr(&sq1))%QUPCASE(&&&PARM&i)%unquote(%nrstr(&sq2))
				%end;
				%else %do;
					%unquote(%nrstr(&sq1))&&&PARM&i%unquote(%nrstr(&sq2))
				%end; 
			%end;
            %let addComma = %eval(1);
          %end;
       %end;) 
       %if &addIsNull %then OR &COLUMN is null;
       %else %if &addIsNotNull %then AND &COLUMN is not null;
       %do;)
       %end;
    %end;
  %end;
%mend _eg_WhereParam;


/* save the current settings of XPIXELS and YPIXELS */
/* so that they can be restored later               */
%macro _sas_pushchartsize(new_xsize, new_ysize);
	%global _savedxpixels _savedypixels;
	options nonotes;
	proc sql noprint;
	select setting into :_savedxpixels
	from sashelp.vgopt
	where optname eq "XPIXELS";
	select setting into :_savedypixels
	from sashelp.vgopt
	where optname eq "YPIXELS";
	quit;
	options notes;
	GOPTIONS XPIXELS=&new_xsize YPIXELS=&new_ysize;
%mend _sas_pushchartsize;

/* restore the previous values for XPIXELS and YPIXELS */
%macro _sas_popchartsize;
	%if %symexist(_savedxpixels) %then %do;
		GOPTIONS XPIXELS=&_savedxpixels YPIXELS=&_savedypixels;
		%symdel _savedxpixels / nowarn;
		%symdel _savedypixels / nowarn;
	%end;
%mend _sas_popchartsize;


/* ---------------------------------- */
/* MACRO: enterpriseguide             */
/* PURPOSE: define a macro variable   */
/*   that contains the file system    */
/*   path of the WORK library on the  */
/*   server.  Note that different     */
/*   logic is needed depending on the */
/*   server type.                     */
/* ---------------------------------- */
%macro enterpriseguide;
%global sasworklocation;
%local tempdsn unique_dsn path;

%if &sysscp=OS %then %do; /* MVS Server */
	%if %sysfunc(getoption(filesystem))=MVS %then %do;
        /* By default, physical file name will be considered a classic MVS data set. */
	    /* Construct dsn that will be unique for each concurrent session under a particular account: */
		filename egtemp '&egtemp' disp=(new,delete); /* create a temporary data set */
 		%let tempdsn=%sysfunc(pathname(egtemp)); /* get dsn */
		filename egtemp clear; /* get rid of data set - we only wanted its name */
		%let unique_dsn=".EGTEMP.%substr(&tempdsn, 1, 16).PDSE"; 
		filename egtmpdir &unique_dsn
			disp=(new,delete,delete) space=(cyl,(5,5,50))
			dsorg=po dsntype=library recfm=vb
			lrecl=8000 blksize=8004 ;
		options fileext=ignore ;
	%end; 
 	%else %do; 
        /* 
		By default, physical file name will be considered an HFS 
		(hierarchical file system) file. 
		*/
		%if "%sysfunc(getoption(filetempdir))"="" %then %do;
			filename egtmpdir '/tmp';
		%end;
		%else %do;
			filename egtmpdir "%sysfunc(getoption(filetempdir))";
		%end;
	%end; 
	%let path=%sysfunc(pathname(egtmpdir));
    %let sasworklocation=%sysfunc(quote(&path));  
%end; /* MVS Server */
%else %do;
	%let sasworklocation = "%sysfunc(getoption(work))/";
%end;
%if &sysscp=VMS_AXP %then %do; /* Alpha VMS server */
	%let sasworklocation = "%sysfunc(getoption(work))";                         
%end;
%if &sysscp=CMS %then %do; 
	%let path = %sysfunc(getoption(work));                         
	%let sasworklocation = "%substr(&path, %index(&path,%str( )))";
%end;
%mend enterpriseguide;

%enterpriseguide


%*--------------------------------------------------------------*
 * Tests the current version against a required version. A      *
 * negative result means that the SAS server version is less    *
 * than the version required.  A positive result means that     *
 * the SAS server version is greater than the version required. *
 * A result of zero indicates that the SAS server is exactly    *
 * the version required.                                        *
 *                                                              *
 * NOTE: The parameter maint is optional.                       *
 *--------------------------------------------------------------*;
%macro _SAS_VERCOMP(major, minor, maint);
    %_SAS_VERCOMP_FV(&major, &minor, &maint, &major, &minor, &maint)
%mend _SAS_VERCOMP;

%*--------------------------------------------------------------*
 * Tests the current version against either the required        *
 * foundation or Viya required version depending on whether the *
 * SYSVLONG version is a foundation or Viya one. A negative     *
 * result means that the SAS server version is less than the    *
 * version required.  A positive result means that the SAS      *
 * server version is greater than the version required. A       *
 * result of zero indicates that the SAS server is exactly the  *
 * version required.                                            *
 *                                                              *
 * NOTE: The *maint parameters are optional.                    *
 *--------------------------------------------------------------*;
%macro _SAS_VERCOMP_FV(fmajor, fminor, fmaint, vmajor, vminor, vmaint);
    %local major;
    %local minor;
    %local maint;
    %local CurMaj;
    %local CurMin;
    %local CurMnt;

    %* Pull the current version string apart.;
    %let CurMaj = %scan(&sysvlong, 1, %str(.));

    %* The Viya version number has a V on the front which means
       we need to adjust the Maint SCAN funtion index and also
       get the appropriate parameters for the major, minor, and
       maint values we need to check against (foundation or Viya);
    %if %eval(&CurMaj EQ V) %then
        %do;
		   %*   MM mm t           MM = Major version , mm = Minor version , t = Maint version ;
		   %* V.03.04M2P07112018 ;

            %let major = &vmajor;
            %let minor = &vminor;
            %let maint = &vmaint;
			%let CurMaj = %scan(&sysvlong, 2, %str(.));
			%* Index is purposely 2 because V is now one of the scan delimiters ;
			%let CurMin = %scan(&sysvlong, 2, %str(.ABCDEFGHIKLMNOPQRSTUVWXYZ));
			%let CurMnt = %scan(&sysvlong, 3, %str(.ABCDEFGHIKLMNOPQRSTUVWXYZ));
        %end;
    %else
        %do;
		    %* M mm    t           M = Major version , mm = Minor version , t = Maint version ;  
		    %* 9.01.02M0P11212005 ;

            %let major = &fmajor;
            %let minor = &fminor;
            %let maint = &fmaint;
			%let CurMin = %scan(&sysvlong, 2, %str(.));
			%let CurMnt = %scan(&sysvlong, 4, %str(.ABCDEFGHIKLMNOPQRSTUVWXYZ));
        %end;

    %* Now perform the version comparison.;
    %if %eval(&major NE &CurMaj) %then
        %eval(&CurMaj - &major);
    %else
        %if %eval(&minor NE &CurMin) %then
            %eval(&CurMin - &minor);
        %else
            %if "&maint" = "" %then
                %str(0);
            %else
                %eval(&CurMnt - &maint);
%mend _SAS_VERCOMP_FV;

%*--------------------------------------------------------------*
 * This macro calls _SAS_VERCONDCODE_FV() with the passed       *
 * version. If the current server version matches or is newer,  *
 * then the true code (tcode) is executed, else the false code  *
 * (fcode) is executed.                                         *
 * Example:                                                     *
 *  %let isV92 =                                                *
 *     %_SAS_VERCONDCODE(9,2,0,                                 *
 *         tcode=%nrstr(Yes),                                   *
 *         fcode=%nrstr(No))                                    *
 *--------------------------------------------------------------*;
%macro _SAS_VERCONDCODE( major, minor, maint, tcode=, fcode= );
    %_SAS_VERCONDCODE_FV( &major, &minor, &maint, &major, &minor, &maint, &tcode, fcode )
%mend _SAS_VERCONDCODE;

%*--------------------------------------------------------------*
 * This macro calls _SAS_VERCOMP_FV() with the passed versions. *
 * If the current server version matches or is newer, then the  *
 * true code (tcode) is executed, else the false code (fcode)   *
 * is executed.                                                 *
 * Example:                                                     *
 *  %let isV92 =                                                *
 *     %_SAS_VERCONDCODE_FV(9,2,0, 3,5,0                        *
 *         tcode=%nrstr(Yes),                                   *
 *         fcode=%nrstr(No))                                    *
 *--------------------------------------------------------------*;
%macro _SAS_VERCONDCODE_FV( fmajor, fminor, fmaint, vmajor, vminor, vmaint, tcode=, fcode= );
    %if %_SAS_VERCOMP_FV(&fmajor, &fminor, &fmaint, &vmajor, &vminor, &vmaint) >= 0 %then
        %do;
        &tcode
        %end;
    %else
        %do;
        &fcode
        %end;
%mend _SAS_VERCONDCODE_FV;

%*--------------------------------------------------------------*
 * Tests the current version to see if it is a Viya version     *
 * number.                                                      *
 * A result of 1 indicates that the SAS server is a Viya        *
 * server.                                                      *
 * A zero result indicates that the server version is not       *
 * that of a Viya server.                                       *
 *--------------------------------------------------------------*;
%macro _SAS_ISVIYA;
    %local Major;

    %* Get the major component of the current version string.;
    %let Major = %scan(&sysvlong, 1, %str(.));

    %* Check if it it V for Viya.;
    %if %eval(&Major EQ V) %then
        %str(1);
    %else
        %str(0);
%mend _SAS_ISVIYA;


ODS PROCTITLE;
OPTIONS DEV=SVG;
GOPTIONS XPIXELS=0 YPIXELS=0;
%macro HTML5AccessibleGraphSupported;
    %if %_SAS_VERCOMP_FV(9,4,4, 0,0,0) >= 0 %then ACCESSIBLE_GRAPH;
%mend;
FILENAME EGHTMLX TEMP;
ODS HTML5(ID=EGHTMLX) FILE=EGHTMLX
    OPTIONS(BITMAP_MODE='INLINE')
    %HTML5AccessibleGraphSupported
    ENCODING='utf-8'
    STYLE=HTMLBlue
    NOGTITLE
    NOGFOOTNOTE
    GPATH=&sasworklocation
;

/*   START OF NODE: Import Data (ak_drilling_demo_synthetic_3000_v3_rigs_consistent.csv)   */
%LET _CLIENTTASKLABEL='Import Data (ak_drilling_demo_synthetic_3000_v3_rigs_consistent.csv)';
%LET _CLIENTPROCESSFLOWNAME='Process Flow';
%LET _CLIENTPROJECTPATH='C:\Projects\AK_DRILL_DEMO.egp';
%LET _CLIENTPROJECTPATHHOST='SAS-122SM74';
%LET _CLIENTPROJECTNAME='AK_DRILL_DEMO.egp';

/* --------------------------------------------------------------------
   Code generated by a SAS task
   
   Generated on Tuesday, October 6, 2026 at 5:34:27 PM
   By task:     Import Data Wizard
   
   Source file:
   C:\Users\ad50620\Downloads\ak_drilling_demo_synthetic_3000_v3_rigs_
   consistent.csv
   Server:      Local File System
   
   Output data: WORK.AK_DRILLING_DEMO_SYNTHETIC__0001
   Server:      Local
   -------------------------------------------------------------------- */

DATA WORK.AK_DRILLING_DEMO_SYNTHETIC__0001;
    LENGTH
        Operation_ID     $ 13
        Operation_Date     8
        Year               8
        Month              8
        Quarter          $ 2
        Project_Name     $ 28
        Country          $ 13
        Region           $ 12
        Site             $ 18
        Service_Type     $ 19
        Rig_ID           $ 6
        Operator_Name    $ 16
        Shift            $ 5
        Rock_Type        $ 18
        Weather_Condition $ 12
        Target_Meters      8
        Drilled_Meters     8
        Operating_Hours    8
        Downtime_Hours     8
        Downtime_Reason  $ 21
        Fuel_Consumption_Liters   8
        Labor_Cost_USD     8
        Equipment_Cost_USD   8
        Fuel_Cost_USD      8
        Total_Cost_USD     8
        Completed_Wells    8
        Safety_Incidents   8
        Near_Miss_Events   8
        Quality_Score      8
        Operation_Status $ 13
        Data_Scenario    $ 6 ;
    FORMAT
        Operation_ID     $CHAR13.
        Operation_Date   YYMMDD10.
        Year             BEST4.
        Month            BEST2.
        Quarter          $CHAR2.
        Project_Name     $CHAR28.
        Country          $CHAR13.
        Region           $CHAR12.
        Site             $CHAR18.
        Service_Type     $CHAR19.
        Rig_ID           $CHAR6.
        Operator_Name    $CHAR16.
        Shift            $CHAR5.
        Rock_Type        $CHAR18.
        Weather_Condition $CHAR12.
        Target_Meters    BEST5.
        Drilled_Meters   BEST5.
        Operating_Hours  BEST4.
        Downtime_Hours   BEST3.
        Downtime_Reason  $CHAR21.
        Fuel_Consumption_Liters BEST5.
        Labor_Cost_USD   BEST7.
        Equipment_Cost_USD BEST7.
        Fuel_Cost_USD    BEST6.
        Total_Cost_USD   BEST8.
        Completed_Wells  BEST1.
        Safety_Incidents BEST1.
        Near_Miss_Events BEST1.
        Quality_Score    BEST4.
        Operation_Status $CHAR13.
        Data_Scenario    $CHAR6. ;
    INFORMAT
        Operation_ID     $CHAR13.
        Operation_Date   YYMMDD10.
        Year             BEST4.
        Month            BEST2.
        Quarter          $CHAR2.
        Project_Name     $CHAR28.
        Country          $CHAR13.
        Region           $CHAR12.
        Site             $CHAR18.
        Service_Type     $CHAR19.
        Rig_ID           $CHAR6.
        Operator_Name    $CHAR16.
        Shift            $CHAR5.
        Rock_Type        $CHAR18.
        Weather_Condition $CHAR12.
        Target_Meters    BEST5.
        Drilled_Meters   BEST5.
        Operating_Hours  BEST4.
        Downtime_Hours   BEST3.
        Downtime_Reason  $CHAR21.
        Fuel_Consumption_Liters BEST5.
        Labor_Cost_USD   BEST7.
        Equipment_Cost_USD BEST7.
        Fuel_Cost_USD    BEST6.
        Total_Cost_USD   BEST8.
        Completed_Wells  BEST1.
        Safety_Incidents BEST1.
        Near_Miss_Events BEST1.
        Quality_Score    BEST4.
        Operation_Status $CHAR13.
        Data_Scenario    $CHAR6. ;
    INFILE 'C:\Users\ad50620\AppData\Roaming\SAS\EnterpriseGuide\EGTEMP\SEG-38376-2849ec28\contents\ak_drilling_demo_synthetic_3000_v3_rigs_consistent-c442908b553b4946b889c03d1dcea868.txt'
        LRECL=280
        ENCODING="WLATIN1"
        TERMSTR=CRLF
        DLM='7F'x
        MISSOVER
        DSD ;
    INPUT
        Operation_ID     : $CHAR13.
        Operation_Date   : ?? YYMMDD10.
        Year             : ?? BEST4.
        Month            : ?? BEST2.
        Quarter          : $CHAR2.
        Project_Name     : $CHAR28.
        Country          : $CHAR13.
        Region           : $CHAR12.
        Site             : $CHAR18.
        Service_Type     : $CHAR19.
        Rig_ID           : $CHAR6.
        Operator_Name    : $CHAR16.
        Shift            : $CHAR5.
        Rock_Type        : $CHAR18.
        Weather_Condition : $CHAR12.
        Target_Meters    : ?? COMMA5.
        Drilled_Meters   : ?? COMMA5.
        Operating_Hours  : ?? COMMA4.
        Downtime_Hours   : ?? COMMA3.
        Downtime_Reason  : $CHAR21.
        Fuel_Consumption_Liters : ?? COMMA5.
        Labor_Cost_USD   : ?? COMMA7.
        Equipment_Cost_USD : ?? COMMA7.
        Fuel_Cost_USD    : ?? COMMA6.
        Total_Cost_USD   : ?? COMMA8.
        Completed_Wells  : ?? BEST1.
        Safety_Incidents : ?? BEST1.
        Near_Miss_Events : ?? BEST1.
        Quality_Score    : ?? COMMA4.
        Operation_Status : $CHAR13.
        Data_Scenario    : $CHAR6. ;
RUN;


%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: Query Builder   */
%LET _CLIENTTASKLABEL='Query Builder';
%LET _CLIENTPROCESSFLOWNAME='Process Flow';
%LET _CLIENTPROJECTPATH='C:\Projects\AK_DRILL_DEMO.egp';
%LET _CLIENTPROJECTPATHHOST='SAS-122SM74';
%LET _CLIENTPROJECTNAME='AK_DRILL_DEMO.egp';

%_eg_conditional_dropds(WORK.QUERY_FOR_AK_DRILLING_DEMO__F4A5);

PROC SQL;
   CREATE TABLE WORK.QUERY_FOR_AK_DRILLING_DEMO__F4A5 AS 
   SELECT t1.Operation_ID, 
          t1.Operation_Date, 
          t1.Year, 
          t1.Month, 
          t1.Quarter, 
          t1.Project_Name, 
          t1.Country, 
          t1.Region, 
          t1.Site, 
          t1.Service_Type, 
          t1.Rig_ID, 
          t1.Operator_Name, 
          t1.Shift, 
          t1.Rock_Type, 
          t1.Weather_Condition, 
          t1.Target_Meters, 
          t1.Drilled_Meters, 
          t1.Operating_Hours, 
          t1.Downtime_Hours, 
          t1.Downtime_Reason, 
          t1.Fuel_Consumption_Liters, 
          t1.Labor_Cost_USD, 
          t1.Equipment_Cost_USD, 
          t1.Fuel_Cost_USD, 
          t1.Total_Cost_USD, 
          t1.Completed_Wells, 
          t1.Safety_Incidents, 
          t1.Near_Miss_Events, 
          t1.Quality_Score, 
          t1.Operation_Status, 
          t1.Data_Scenario, 
          /* Target_Achievement_Pct */
            ((Drilled_Meters / Target_Meters)) FORMAT=PERCENT6.2 AS Target_Achievement_Pct, 
          /* Meters_Variance */
            (Drilled_Meters - Target_Meters) FORMAT=COMMA6.2 AS Meters_Variance, 
          /* Meters_Per_Hour */
            (Drilled_Meters / Operating_Hours) FORMAT=COMMA6.2 AS Meters_Per_Hour, 
          /* Cost_Per_Meter */
            (Total_Cost_USD / Drilled_Meters) FORMAT=COMMA6.2 AS Cost_Per_Meter, 
          /* Fuel_Per_Meter */
            (Fuel_Consumption_Liters / Drilled_Meters) FORMAT=COMMA6.2 AS Fuel_Per_Meter, 
          /* Operational_Status */
            (ifc(Operation_Status='Above Target','Superó Objetivo',
            ifc(Operation_Status='On Target','Cumplió Objetivo',
            ifc(Operation_Status='Below Target','Bajo Objetivo',
            ifc(Operation_Status='Interrupted','Operación Interrumpida',
            'Revisión de Seguridad'))))) FORMAT=$CHAR50. AS Operational_Status
      FROM WORK.AK_DRILLING_DEMO_SYNTHETIC__0001 t1;
QUIT;



%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: One-Way Frequencies 1   */
%LET _CLIENTTASKLABEL='One-Way Frequencies 1';
%LET _CLIENTPROCESSFLOWNAME='Process Flow';
%LET _CLIENTPROJECTPATH='C:\Projects\AK_DRILL_DEMO.egp';
%LET _CLIENTPROJECTPATHHOST='SAS-122SM74';
%LET _CLIENTPROJECTNAME='AK_DRILL_DEMO.egp';

/* -------------------------------------------------------------------
   Code generated by SAS Task

   Generated on: Tuesday, October 6, 2026 at 5:58:50 PM
   By task: One-Way Frequencies 1

   Input Data: Local:WORK.QUERY_FOR_AK_DRILLING_DEMO__F4A5
   Server:  Local
   ------------------------------------------------------------------- */

%_eg_conditional_dropds(WORK.SORT_4CBA);
/* -------------------------------------------------------------------
   Sort data set Local:WORK.QUERY_FOR_AK_DRILLING_DEMO__F4A5
   ------------------------------------------------------------------- */

PROC SQL;
	CREATE VIEW WORK.SORT_4CBA AS
		SELECT T.Operational_Status
	FROM WORK.QUERY_FOR_AK_DRILLING_DEMO__F4A5 as T
;
QUIT;

TITLE;
TITLE1 "Cumplimiento de Objetivos";
FOOTNOTE;
FOOTNOTE1 "The FREQ Procedure";
ODS GRAPHICS ON;
PROC FREQ DATA=WORK.SORT_4CBA
	ORDER=INTERNAL
;
	TABLES Operational_Status /  SCORES=TABLE plots(only)=freq;
RUN;
ODS GRAPHICS OFF;
/* -------------------------------------------------------------------
   End of task code
   ------------------------------------------------------------------- */
RUN; QUIT;
%_eg_conditional_dropds(WORK.SORT_4CBA);
TITLE; FOOTNOTE;


%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: Bar Chart   */
%LET _CLIENTTASKLABEL='Bar Chart';
%LET _CLIENTPROCESSFLOWNAME='Process Flow';
%LET _CLIENTPROJECTPATH='C:\Projects\AK_DRILL_DEMO.egp';
%LET _CLIENTPROJECTPATHHOST='SAS-122SM74';
%LET _CLIENTPROJECTNAME='AK_DRILL_DEMO.egp';

/* -------------------------------------------------------------------
   Code generated by SAS Task

   Generated on: Tuesday, October 6, 2026 at 5:58:50 PM
   By task: Bar Chart

   Input Data: Local:WORK.QUERY_FOR_AK_DRILLING_DEMO__F4A5
   Server:  Local
   ------------------------------------------------------------------- */

%_eg_conditional_dropds(WORK.SORTTEMPTABLESORTED_C46F);
/* -------------------------------------------------------------------
   Sort data set Local:WORK.QUERY_FOR_AK_DRILLING_DEMO__F4A5
   ------------------------------------------------------------------- */

PROC SQL;
	CREATE VIEW WORK.SORTTEMPTABLESORTED_C46F AS
		SELECT T.Target_Achievement_Pct
	FROM WORK.QUERY_FOR_AK_DRILLING_DEMO__F4A5 as T
;
QUIT;
Axis1
	STYLE=1
	WIDTH=1
	MINOR=NONE


;
Axis2
	STYLE=1
	WIDTH=1
	LABEL=(   "Tg_Achiev_Pct")

	VALUE=(ANGLE=45)

;
TITLE;
TITLE1 "Target Cumplimento Distribution";
FOOTNOTE;
FOOTNOTE1 "Generated by SAS (&_SASSERVERNAME, &SYSSCPL) on %TRIM(%QSYSFUNC(DATE(), NLDATE20.)) at %TRIM(%QSYSFUNC(TIME(), NLTIMAP25.))";
PROC GCHART DATA=WORK.SORTTEMPTABLESORTED_C46F
;
	VBAR3D 
	 Target_Achievement_Pct
 /
	SHAPE=BLOCK
FRAME	TYPE=FREQ
	COUTLINE=CX000080
	RAXIS=AXIS1
	MAXIS=AXIS2
;
/* -------------------------------------------------------------------
   End of task code
   ------------------------------------------------------------------- */
RUN; QUIT;
%_eg_conditional_dropds(WORK.SORTTEMPTABLESORTED_C46F);
TITLE; FOOTNOTE;
PATTERN1;
PATTERN2;
PATTERN3;


%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: Summary Statistics   */
%LET _CLIENTTASKLABEL='Summary Statistics';
%LET _CLIENTPROCESSFLOWNAME='Process Flow';
%LET _CLIENTPROJECTPATH='C:\Projects\AK_DRILL_DEMO.egp';
%LET _CLIENTPROJECTPATHHOST='SAS-122SM74';
%LET _CLIENTPROJECTNAME='AK_DRILL_DEMO.egp';

/* -------------------------------------------------------------------
   Code generated by SAS Task

   Generated on: Tuesday, October 6, 2026 at 5:58:50 PM
   By task: Summary Statistics

   Input Data: Local:WORK.QUERY_FOR_AK_DRILLING_DEMO__F4A5
   Server:  Local
   ------------------------------------------------------------------- */

%_eg_conditional_dropds(WORK.SORTTEMPTABLESORTED_30A0);
/* -------------------------------------------------------------------
   Sort data set Local:WORK.QUERY_FOR_AK_DRILLING_DEMO__F4A5
   ------------------------------------------------------------------- */

PROC SQL;
	CREATE VIEW WORK.SORTTEMPTABLESORTED_30A0 AS
		SELECT T.Target_Achievement_Pct, T.Meters_Per_Hour, T.Quality_Score, T.Cost_Per_Meter, T.Rig_ID
	FROM WORK.QUERY_FOR_AK_DRILLING_DEMO__F4A5 as T
;
QUIT;
/* -------------------------------------------------------------------
   Run the Means Procedure
   ------------------------------------------------------------------- */
TITLE;
TITLE1 "Datos Operativos por RIG";
FOOTNOTE;
FOOTNOTE1 "Generated by SAS (&_SASSERVERNAME, &SYSSCPL) on %TRIM(%QSYSFUNC(DATE(), NLDATE20.)) at %TRIM(%QSYSFUNC(TIME(), NLTIMAP25.))";
PROC MEANS DATA=WORK.SORTTEMPTABLESORTED_30A0
	FW=12
	PRINTALLTYPES
	CHARTYPE
	NWAY
	VARDEF=DF 	
		MEAN 
		STD 
		MIN 
		MAX 
		N	;
	VAR Target_Achievement_Pct Meters_Per_Hour Quality_Score Cost_Per_Meter;
	CLASS Rig_ID /	ORDER=UNFORMATTED ASCENDING;

RUN;
/* -------------------------------------------------------------------
   End of task code
   ------------------------------------------------------------------- */
RUN; QUIT;
%_eg_conditional_dropds(WORK.SORTTEMPTABLESORTED_30A0);
TITLE; FOOTNOTE;


%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: Box Plot   */
%LET _CLIENTTASKLABEL='Box Plot';
%LET _CLIENTPROCESSFLOWNAME='Process Flow';
%LET _CLIENTPROJECTPATH='C:\Projects\AK_DRILL_DEMO.egp';
%LET _CLIENTPROJECTPATHHOST='SAS-122SM74';
%LET _CLIENTPROJECTNAME='AK_DRILL_DEMO.egp';

/* -------------------------------------------------------------------
   Code generated by SAS Task

   Generated on: Tuesday, October 6, 2026 at 5:58:50 PM
   By task: Box Plot

   Input Data: Local:WORK.QUERY_FOR_AK_DRILLING_DEMO__F4A5
   Server:  Local
   ------------------------------------------------------------------- */

%_eg_conditional_dropds(WORK.SORTTEMPTABLESORTED_EF86);
/* -------------------------------------------------------------------
   Sort data set Local:WORK.QUERY_FOR_AK_DRILLING_DEMO__F4A5
   ------------------------------------------------------------------- */

PROC SQL;
	CREATE VIEW WORK.SORTTEMPTABLESORTED_EF86 AS
		SELECT T.Rig_ID, T.Target_Achievement_Pct
	FROM WORK.QUERY_FOR_AK_DRILLING_DEMO__F4A5 as T
;
QUIT;
SYMBOL1 	INTERPOL=BOX	VALUE=CIRCLE
	HEIGHT=1
	MODE=EXCLUDE
;
Axis1
	STYLE=1
	WIDTH=1
	MINOR=NONE

;
Axis2
	STYLE=1
	WIDTH=1
	MINOR=NONE

;
TITLE;
TITLE1 "Desempeño Equipo de Perforación";
FOOTNOTE;
FOOTNOTE1 "Generated by SAS (&_SASSERVERNAME, &SYSSCPL) on %TRIM(%QSYSFUNC(DATE(), NLDATE20.)) at %TRIM(%QSYSFUNC(TIME(), NLTIMAP25.))";
PROC GPLOT DATA=WORK.SORTTEMPTABLESORTED_EF86
;
	PLOT Target_Achievement_Pct * Rig_ID/
	VAXIS=AXIS1

	HAXIS=AXIS2

;
/* -------------------------------------------------------------------
   End of task code
   ------------------------------------------------------------------- */
RUN; QUIT;
%_eg_conditional_dropds(WORK.SORTTEMPTABLESORTED_EF86);
TITLE; FOOTNOTE;
GOPTIONS RESET = SYMBOL;

%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: Scatter Plot   */
%LET _CLIENTTASKLABEL='Scatter Plot';
%LET _CLIENTPROCESSFLOWNAME='Process Flow';
%LET _CLIENTPROJECTPATH='C:\Projects\AK_DRILL_DEMO.egp';
%LET _CLIENTPROJECTPATHHOST='SAS-122SM74';
%LET _CLIENTPROJECTNAME='AK_DRILL_DEMO.egp';

/* -------------------------------------------------------------------
   Code generated by SAS Task

   Generated on: Tuesday, October 6, 2026 at 5:58:50 PM
   By task: Scatter Plot

   Input Data: Local:WORK.QUERY_FOR_AK_DRILLING_DEMO__F4A5
   Server:  Local
   ------------------------------------------------------------------- */

%_eg_conditional_dropds(WORK.SORTTEMPTABLESORTED_0DE3);
/* -------------------------------------------------------------------
   Sort data set WORK.QUERY_FOR_AK_DRILLING_DEMO__F4A5
   ------------------------------------------------------------------- */
PROC SORT
	DATA=WORK.QUERY_FOR_AK_DRILLING_DEMO__F4A5(KEEP=Cost_Per_Meter Meters_Per_Hour Rig_ID)
	OUT=WORK.SORTTEMPTABLESORTED_0DE3
	;
	BY Rig_ID;
RUN;
	SYMBOL1
	INTERPOL=NONE
	HEIGHT=10pt
	VALUE=CIRCLE
	LINE=1
	WIDTH=2

	CV = _STYLE_
;
Axis1
	STYLE=1
	WIDTH=1
	MINOR=NONE


;
Axis2
	STYLE=1
	WIDTH=1
	MINOR=NONE


;
TITLE;
TITLE1 "Productividad vs Costo por Metro";
FOOTNOTE;
FOOTNOTE1 "Generated by SAS (&_SASSERVERNAME, &SYSSCPL) on %TRIM(%QSYSFUNC(DATE(), NLDATE20.)) at %TRIM(%QSYSFUNC(TIME(), NLTIMAP25.))";
PROC GPLOT DATA=WORK.SORTTEMPTABLESORTED_0DE3
 NOCACHE ;
PLOT Meters_Per_Hour * Cost_Per_Meter / 
	VAXIS=AXIS1

	HAXIS=AXIS2

FRAME ;
	BY Rig_ID;
/* -------------------------------------------------------------------
   End of task code
   ------------------------------------------------------------------- */
RUN; QUIT;
%_eg_conditional_dropds(WORK.SORTTEMPTABLESORTED_0DE3);
TITLE; FOOTNOTE;
GOPTIONS RESET = SYMBOL;

%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: Box Plot   */
%LET _CLIENTTASKLABEL='Box Plot';
%LET _CLIENTPROCESSFLOWNAME='Process Flow';
%LET _CLIENTPROJECTPATH='C:\Projects\AK_DRILL_DEMO.egp';
%LET _CLIENTPROJECTPATHHOST='SAS-122SM74';
%LET _CLIENTPROJECTNAME='AK_DRILL_DEMO.egp';

/* -------------------------------------------------------------------
   Code generated by SAS Task

   Generated on: Tuesday, October 6, 2026 at 5:58:50 PM
   By task: Box Plot

   Input Data: Local:WORK.QUERY_FOR_AK_DRILLING_DEMO__F4A5
   Server:  Local
   ------------------------------------------------------------------- */

%_eg_conditional_dropds(WORK.SORTTEMPTABLESORTED_E75F);
/* -------------------------------------------------------------------
   Sort data set Local:WORK.QUERY_FOR_AK_DRILLING_DEMO__F4A5
   ------------------------------------------------------------------- */

PROC SQL;
	CREATE VIEW WORK.SORTTEMPTABLESORTED_E75F AS
		SELECT T.Rock_Type, T.Meters_Per_Hour
	FROM WORK.QUERY_FOR_AK_DRILLING_DEMO__F4A5 as T
;
QUIT;
SYMBOL1 	INTERPOL=BOX	VALUE=CIRCLE
	HEIGHT=1
	MODE=EXCLUDE
;
Axis1
	STYLE=1
	WIDTH=1
	MINOR=NONE

;
Axis2
	STYLE=1
	WIDTH=1
	MINOR=NONE

;
TITLE;
TITLE1 "Productividad por Tipo de Roca";
FOOTNOTE;
FOOTNOTE1 "Generated by SAS (&_SASSERVERNAME, &SYSSCPL) on %TRIM(%QSYSFUNC(DATE(), NLDATE20.)) at %TRIM(%QSYSFUNC(TIME(), NLTIMAP25.))";
PROC GPLOT DATA=WORK.SORTTEMPTABLESORTED_E75F
;
	PLOT Meters_Per_Hour * Rock_Type/
	VAXIS=AXIS1

	HAXIS=AXIS2

;
/* -------------------------------------------------------------------
   End of task code
   ------------------------------------------------------------------- */
RUN; QUIT;
%_eg_conditional_dropds(WORK.SORTTEMPTABLESORTED_E75F);
TITLE; FOOTNOTE;
GOPTIONS RESET = SYMBOL;

%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: Box Plot   */
%LET _CLIENTTASKLABEL='Box Plot';
%LET _CLIENTPROCESSFLOWNAME='Process Flow';
%LET _CLIENTPROJECTPATH='C:\Projects\AK_DRILL_DEMO.egp';
%LET _CLIENTPROJECTPATHHOST='SAS-122SM74';
%LET _CLIENTPROJECTNAME='AK_DRILL_DEMO.egp';

/* -------------------------------------------------------------------
   Code generated by SAS Task

   Generated on: Tuesday, October 6, 2026 at 5:58:50 PM
   By task: Box Plot

   Input Data: Local:WORK.QUERY_FOR_AK_DRILLING_DEMO__F4A5
   Server:  Local
   ------------------------------------------------------------------- */

%_eg_conditional_dropds(WORK.SORTTEMPTABLESORTED_FD6B);
/* -------------------------------------------------------------------
   Sort data set Local:WORK.QUERY_FOR_AK_DRILLING_DEMO__F4A5
   ------------------------------------------------------------------- */

PROC SQL;
	CREATE VIEW WORK.SORTTEMPTABLESORTED_FD6B AS
		SELECT T.Weather_Condition, T.Target_Achievement_Pct
	FROM WORK.QUERY_FOR_AK_DRILLING_DEMO__F4A5 as T
;
QUIT;
SYMBOL1 	INTERPOL=BOX	VALUE=CIRCLE
	HEIGHT=1
	MODE=EXCLUDE
;
Axis1
	STYLE=1
	WIDTH=1
	MINOR=NONE

;
Axis2
	STYLE=1
	WIDTH=1
	MINOR=NONE

;
TITLE;
TITLE1 "Cumplimiento de Objetivos por Clima";
FOOTNOTE;
FOOTNOTE1 "Generated by SAS (&_SASSERVERNAME, &SYSSCPL) on %TRIM(%QSYSFUNC(DATE(), NLDATE20.)) at %TRIM(%QSYSFUNC(TIME(), NLTIMAP25.))";
PROC GPLOT DATA=WORK.SORTTEMPTABLESORTED_FD6B
;
	PLOT Target_Achievement_Pct * Weather_Condition/
	VAXIS=AXIS1

	HAXIS=AXIS2

;
/* -------------------------------------------------------------------
   End of task code
   ------------------------------------------------------------------- */
RUN; QUIT;
%_eg_conditional_dropds(WORK.SORTTEMPTABLESORTED_FD6B);
TITLE; FOOTNOTE;
GOPTIONS RESET = SYMBOL;

%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: One-Way Frequencies   */
%LET _CLIENTTASKLABEL='One-Way Frequencies';
%LET _CLIENTPROCESSFLOWNAME='Process Flow';
%LET _CLIENTPROJECTPATH='C:\Projects\AK_DRILL_DEMO.egp';
%LET _CLIENTPROJECTPATHHOST='SAS-122SM74';
%LET _CLIENTPROJECTNAME='AK_DRILL_DEMO.egp';

/* -------------------------------------------------------------------
   Code generated by SAS Task

   Generated on: Tuesday, October 6, 2026 at 5:58:50 PM
   By task: One-Way Frequencies

   Input Data: Local:WORK.QUERY_FOR_AK_DRILLING_DEMO__F4A5
   Server:  Local
   ------------------------------------------------------------------- */

%_eg_conditional_dropds(WORK.SORT_29F4);
/* -------------------------------------------------------------------
   Sort data set Local:WORK.QUERY_FOR_AK_DRILLING_DEMO__F4A5
   ------------------------------------------------------------------- */

PROC SQL;
	CREATE VIEW WORK.SORT_29F4 AS
		SELECT T.Downtime_Reason
	FROM WORK.QUERY_FOR_AK_DRILLING_DEMO__F4A5 as T
;
QUIT;

TITLE;
TITLE1 "¿Cuál es la causa más frecuente de pérdida de productividad?";
FOOTNOTE;
FOOTNOTE1 "Generated by SAS (&_SASSERVERNAME, &SYSSCPL) on %TRIM(%QSYSFUNC(DATE(), NLDATE20.)) at %TRIM(%QSYSFUNC(TIME(), NLTIMAP25.))";
PROC FREQ DATA=WORK.SORT_29F4
	ORDER=INTERNAL
;
	TABLES Downtime_Reason /  SCORES=TABLE;
RUN;
/* -------------------------------------------------------------------
   End of task code
   ------------------------------------------------------------------- */
RUN; QUIT;
%_eg_conditional_dropds(WORK.SORT_29F4);
TITLE; FOOTNOTE;


%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: Summary Statistics   */
%LET _CLIENTTASKLABEL='Summary Statistics';
%LET _CLIENTPROCESSFLOWNAME='Process Flow';
%LET _CLIENTPROJECTPATH='C:\Projects\AK_DRILL_DEMO.egp';
%LET _CLIENTPROJECTPATHHOST='SAS-122SM74';
%LET _CLIENTPROJECTNAME='AK_DRILL_DEMO.egp';

/* -------------------------------------------------------------------
   Code generated by SAS Task

   Generated on: Tuesday, October 6, 2026 at 5:58:50 PM
   By task: Summary Statistics

   Input Data: Local:WORK.QUERY_FOR_AK_DRILLING_DEMO__F4A5
   Server:  Local
   ------------------------------------------------------------------- */

%_eg_conditional_dropds(WORK.SORTTEMPTABLESORTED_E823);
/* -------------------------------------------------------------------
   Sort data set Local:WORK.QUERY_FOR_AK_DRILLING_DEMO__F4A5
   ------------------------------------------------------------------- */

PROC SQL;
	CREATE VIEW WORK.SORTTEMPTABLESORTED_E823 AS
		SELECT T.Downtime_Hours, T.Downtime_Reason
	FROM WORK.QUERY_FOR_AK_DRILLING_DEMO__F4A5 as T
;
QUIT;
/* -------------------------------------------------------------------
   Run the Means Procedure
   ------------------------------------------------------------------- */
TITLE;
TITLE1 "Summary Statistics: Downtime Analysis";
TITLE2 "Results";
FOOTNOTE;
FOOTNOTE1 "Generated by SAS (&_SASSERVERNAME, &SYSSCPL) on %TRIM(%QSYSFUNC(DATE(), NLDATE20.)) at %TRIM(%QSYSFUNC(TIME(), NLTIMAP25.))";
PROC MEANS DATA=WORK.SORTTEMPTABLESORTED_E823
	FW=12
	PRINTALLTYPES
	CHARTYPE
	NWAY
	VARDEF=DF 	
		MEAN 
		STD 
		MIN 
		MAX 
		N	;
	VAR Downtime_Hours;
	CLASS Downtime_Reason /	ORDER=UNFORMATTED ASCENDING;

RUN;
/* -------------------------------------------------------------------
   End of task code
   ------------------------------------------------------------------- */
RUN; QUIT;
%_eg_conditional_dropds(WORK.SORTTEMPTABLESORTED_E823);
TITLE; FOOTNOTE;


%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: Scatter Plot 1   */
%LET _CLIENTTASKLABEL='Scatter Plot 1';
%LET _CLIENTPROCESSFLOWNAME='Process Flow';
%LET _CLIENTPROJECTPATH='C:\Projects\AK_DRILL_DEMO.egp';
%LET _CLIENTPROJECTPATHHOST='SAS-122SM74';
%LET _CLIENTPROJECTNAME='AK_DRILL_DEMO.egp';

/* -------------------------------------------------------------------
   Code generated by SAS Task

   Generated on: Tuesday, October 6, 2026 at 5:58:50 PM
   By task: Scatter Plot 1

   Input Data: Local:WORK.QUERY_FOR_AK_DRILLING_DEMO__F4A5
   Server:  Local
   ------------------------------------------------------------------- */

%_eg_conditional_dropds(WORK.SORTTEMPTABLESORTED_B6AA);
/* -------------------------------------------------------------------
   Sort data set Local:WORK.QUERY_FOR_AK_DRILLING_DEMO__F4A5
   ------------------------------------------------------------------- */

PROC SQL;
	CREATE VIEW WORK.SORTTEMPTABLESORTED_B6AA AS
		SELECT T.Quality_Score, T.Meters_Per_Hour
	FROM WORK.QUERY_FOR_AK_DRILLING_DEMO__F4A5 as T
;
QUIT;
	SYMBOL1
	INTERPOL=NONE
	HEIGHT=10pt
	VALUE=CIRCLE
	LINE=1
	WIDTH=2

	CV = _STYLE_
;
Axis1
	STYLE=1
	WIDTH=1
	MINOR=NONE


;
Axis2
	STYLE=1
	WIDTH=1
	MINOR=NONE


;
TITLE;
TITLE1 "Scatter Plot: Calidad vs Productividad";
FOOTNOTE;
FOOTNOTE1 "Generated by SAS (&_SASSERVERNAME, &SYSSCPL) on %TRIM(%QSYSFUNC(DATE(), NLDATE20.)) at %TRIM(%QSYSFUNC(TIME(), NLTIMAP25.))";
PROC GPLOT DATA=WORK.SORTTEMPTABLESORTED_B6AA
;
PLOT Meters_Per_Hour * Quality_Score / 
	VAXIS=AXIS1

	HAXIS=AXIS2

FRAME ;
/* -------------------------------------------------------------------
   End of task code
   ------------------------------------------------------------------- */
RUN; QUIT;
%_eg_conditional_dropds(WORK.SORTTEMPTABLESORTED_B6AA);
TITLE; FOOTNOTE;
GOPTIONS RESET = SYMBOL;

%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: Line Plot   */
%LET _CLIENTTASKLABEL='Line Plot';
%LET _CLIENTPROCESSFLOWNAME='Process Flow';
%LET _CLIENTPROJECTPATH='C:\Projects\AK_DRILL_DEMO.egp';
%LET _CLIENTPROJECTPATHHOST='SAS-122SM74';
%LET _CLIENTPROJECTNAME='AK_DRILL_DEMO.egp';

/* -------------------------------------------------------------------
   Code generated by SAS Task

   Generated on: Tuesday, October 6, 2026 at 5:58:50 PM
   By task: Line Plot

   Input Data: Local:WORK.QUERY_FOR_AK_DRILLING_DEMO__F4A5
   Server:  Local
   ------------------------------------------------------------------- */

%_eg_conditional_dropds(WORK.SORTTEMPTABLESORTED_B4F9);
/* -------------------------------------------------------------------
   Sort data set WORK.QUERY_FOR_AK_DRILLING_DEMO__F4A5
   ------------------------------------------------------------------- */
PROC SORT
	DATA=WORK.QUERY_FOR_AK_DRILLING_DEMO__F4A5(KEEP=Quarter Target_Achievement_Pct Year)
	OUT=WORK.SORTTEMPTABLESORTED_B4F9
	;
	BY Year Quarter;
RUN;
SYMBOL1
	INTERPOL=JOIN
	HEIGHT=10pt
	VALUE=NONE
	LINE=1
	WIDTH=2

	CV = _STYLE_
;
Axis1
	STYLE=1
	WIDTH=1
	MINOR=NONE


;
Axis2
	STYLE=1
	WIDTH=1
	MINOR=NONE


;
TITLE;
TITLE1 "¿Estamos mejorando nuestro cumplimiento de objetivos de perforación año tras año?";
FOOTNOTE;
FOOTNOTE1 "Generated by SAS (&_SASSERVERNAME, &SYSSCPL) on %TRIM(%QSYSFUNC(DATE(), NLDATE20.)) at %TRIM(%QSYSFUNC(TIME(), NLTIMAP25.))";
PROC GPLOT DATA = WORK.SORTTEMPTABLESORTED_B4F9
 NOCACHE ;
PLOT Target_Achievement_Pct * Quarter  /
 	VAXIS=AXIS1

	HAXIS=AXIS2

FRAME;
	BY Year;
/* -------------------------------------------------------------------
   End of task code
   ------------------------------------------------------------------- */
RUN; QUIT;
%_eg_conditional_dropds(WORK.SORTTEMPTABLESORTED_B4F9);
TITLE; FOOTNOTE;
GOPTIONS RESET = SYMBOL;

%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: Linear Regression   */
%LET _CLIENTTASKLABEL='Linear Regression';
%LET _CLIENTPROCESSFLOWNAME='Process Flow';
%LET _CLIENTPROJECTPATH='C:\Projects\AK_DRILL_DEMO.egp';
%LET _CLIENTPROJECTPATHHOST='SAS-122SM74';
%LET _CLIENTPROJECTNAME='AK_DRILL_DEMO.egp';

/* -------------------------------------------------------------------
   Code generated by SAS Task

   Generated on: Tuesday, October 6, 2026 at 5:58:50 PM
   By task: Linear Regression

   Input Data: Local:WORK.QUERY_FOR_AK_DRILLING_DEMO__F4A5
   Server:  Local
   ------------------------------------------------------------------- */
ODS GRAPHICS ON;

%_eg_conditional_dropds(WORK.SORTTEMPTABLESORTED_67C3,
		WORK.TMP1TEMPTABLEFORPLOTS_6CE9);
/* -------------------------------------------------------------------
   Determine the data set's type attribute (if one is defined)
   and prepare it for addition to the data set/view which is
   generated in the following step.
   ------------------------------------------------------------------- */
DATA _NULL_;
	dsid = OPEN("WORK.QUERY_FOR_AK_DRILLING_DEMO__F4A5", "I");
	dstype = ATTRC(DSID, "TYPE");
	IF TRIM(dstype) = " " THEN
		DO;
		CALL SYMPUT("_EG_DSTYPE_", "");
		CALL SYMPUT("_DSTYPE_VARS_", "");
		END;
	ELSE
		DO;
		CALL SYMPUT("_EG_DSTYPE_", "(TYPE=""" || TRIM(dstype) || """)");
		IF VARNUM(dsid, "_NAME_") NE 0 AND VARNUM(dsid, "_TYPE_") NE 0 THEN
			CALL SYMPUT("_DSTYPE_VARS_", "_TYPE_ _NAME_");
		ELSE IF VARNUM(dsid, "_TYPE_") NE 0 THEN
			CALL SYMPUT("_DSTYPE_VARS_", "_TYPE_");
		ELSE IF VARNUM(dsid, "_NAME_") NE 0 THEN
			CALL SYMPUT("_DSTYPE_VARS_", "_NAME_");
		ELSE
			CALL SYMPUT("_DSTYPE_VARS_", "");
		END;
	rc = CLOSE(dsid);
	STOP;
RUN;

/* -------------------------------------------------------------------
   Data set WORK.QUERY_FOR_AK_DRILLING_DEMO__F4A5 does not need to be sorted.
   ------------------------------------------------------------------- */
DATA WORK.SORTTEMPTABLESORTED_67C3 &_EG_DSTYPE_ / VIEW=WORK.SORTTEMPTABLESORTED_67C3;
	SET WORK.QUERY_FOR_AK_DRILLING_DEMO__F4A5(KEEP=Meters_Per_Hour Downtime_Hours Operating_Hours &_DSTYPE_VARS_);
RUN;
TITLE;
TITLE1 "Linear Regression Results";
FOOTNOTE;
FOOTNOTE1 "Generated by SAS (&_SASSERVERNAME, &SYSSCPL) on %TRIM(%QSYSFUNC(DATE(), NLDATE20.)) at %TRIM(%QSYSFUNC(TIME(), NLTIMAP25.))";
PROC REG DATA=WORK.SORTTEMPTABLESORTED_67C3
		PLOTS(ONLY)=RESIDUALHISTOGRAM
	;
	Linear_Regression_Model: MODEL Meters_Per_Hour = Downtime_Hours Operating_Hours
		/		SELECTION=NONE
	;
RUN;
QUIT;

/* -------------------------------------------------------------------
   End of task code
   ------------------------------------------------------------------- */
RUN; QUIT;
%_eg_conditional_dropds(WORK.SORTTEMPTABLESORTED_67C3,
		WORK.TMP1TEMPTABLEFORPLOTS_6CE9);
TITLE; FOOTNOTE;
ODS GRAPHICS OFF;


%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: One-Way Frequencies 2   */
%LET _CLIENTTASKLABEL='One-Way Frequencies 2';
%LET _CLIENTPROCESSFLOWNAME='Process Flow';
%LET _CLIENTPROJECTPATH='C:\Projects\AK_DRILL_DEMO.egp';
%LET _CLIENTPROJECTPATHHOST='SAS-122SM74';
%LET _CLIENTPROJECTNAME='AK_DRILL_DEMO.egp';

/* -------------------------------------------------------------------
   Code generated by SAS Task

   Generated on: Tuesday, October 6, 2026 at 5:58:50 PM
   By task: One-Way Frequencies 2

   Input Data: Local:WORK.QUERY_FOR_AK_DRILLING_DEMO__F4A5
   Server:  Local
   ------------------------------------------------------------------- */

%_eg_conditional_dropds(WORK.SORT_3465);
/* -------------------------------------------------------------------
   Sort data set Local:WORK.QUERY_FOR_AK_DRILLING_DEMO__F4A5
   ------------------------------------------------------------------- */

PROC SQL;
	CREATE VIEW WORK.SORT_3465 AS
		SELECT T.Operational_Status
	FROM WORK.QUERY_FOR_AK_DRILLING_DEMO__F4A5 as T
;
QUIT;

TITLE;
TITLE1 "One-Way Frequencies";
TITLE2 "Results";
FOOTNOTE;
FOOTNOTE1 "Generated by SAS (&_SASSERVERNAME, &SYSSCPL) on %TRIM(%QSYSFUNC(DATE(), NLDATE20.)) at %TRIM(%QSYSFUNC(TIME(), NLTIMAP25.))";
PROC FREQ DATA=WORK.SORT_3465
	ORDER=INTERNAL
;
	TABLES Operational_Status /  SCORES=TABLE;
RUN;
/* -------------------------------------------------------------------
   End of task code
   ------------------------------------------------------------------- */
RUN; QUIT;
%_eg_conditional_dropds(WORK.SORT_3465);
TITLE; FOOTNOTE;


%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: Generalized Linear Models   */
%LET _CLIENTTASKLABEL='Generalized Linear Models';
%LET _CLIENTPROCESSFLOWNAME='Process Flow';
%LET _CLIENTPROJECTPATH='C:\Projects\AK_DRILL_DEMO.egp';
%LET _CLIENTPROJECTPATHHOST='SAS-122SM74';
%LET _CLIENTPROJECTNAME='AK_DRILL_DEMO.egp';

/* -------------------------------------------------------------------
   Code generated by SAS Task

   Generated on: Tuesday, October 6, 2026 at 5:58:50 PM
   By task: Generalized Linear Models

   Input Data: Local:WORK.QUERY_FOR_AK_DRILLING_DEMO__F4A5
   Server:  Local
   ------------------------------------------------------------------- */
ODS GRAPHICS ON;

%_eg_conditional_dropds(WORK.SORTTEMPTABLESORTED_332C,
		WORK.TMP1TEMPTABLEFORPLOTSANDPRE_3955);
/* -------------------------------------------------------------------
   Sort data set Local:WORK.QUERY_FOR_AK_DRILLING_DEMO__F4A5
   ------------------------------------------------------------------- */

PROC SQL;
	CREATE VIEW WORK.SORTTEMPTABLESORTED_332C AS
		SELECT T.Meters_Per_Hour, T.Operating_Hours, T.Downtime_Hours, T.Shift, T.Weather_Condition, T.Rock_Type
	FROM WORK.QUERY_FOR_AK_DRILLING_DEMO__F4A5 as T
;
QUIT;
TITLE;
TITLE1 "Generalized Linear Models Analysis";
FOOTNOTE;
FOOTNOTE1 "Generated by SAS (&_SASSERVERNAME, &SYSSCPL) on %TRIM(%QSYSFUNC(DATE(), NLDATE20.)) at %TRIM(%QSYSFUNC(TIME(), NLTIMAP25.))";
PROC GENMOD DATA=WORK.SORTTEMPTABLESORTED_332C
		PLOTS(ONLY)=NONE
;
	CLASS Shift Weather_Condition Rock_Type
	;
	MODEL Meters_Per_Hour=	Operating_Hours Downtime_Hours Shift Weather_Condition Rock_Type
		/
	;
RUN; QUIT;

/* -------------------------------------------------------------------
   End of task code
   ------------------------------------------------------------------- */
RUN; QUIT;
%_eg_conditional_dropds(WORK.SORTTEMPTABLESORTED_332C,
		WORK.TMP1TEMPTABLEFORPLOTSANDPRE_3955);
TITLE; FOOTNOTE;
ODS GRAPHICS OFF;


%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;

;*';*";*/;quit;run;
ODS _ALL_ CLOSE;
