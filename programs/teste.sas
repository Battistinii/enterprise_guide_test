proc means data=sashelp.cars;
run;

proc freq data=sashelp.cars;
    tables Origin * Type / chisq; 
run;
