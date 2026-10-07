/* --------------------------------------------------------------------
   AK_DRILL_DEMO_REFACTORED.sas
   Refactored SAS 9 version of the Enterprise Guide workflow.

   Purpose:
   - Preserve the original business logic and KPI definitions.
   - Remove EG-specific wrapper code not required for execution.
   - Keep the workflow maintainable and easier to review.

   Notes:
   - This script is designed as a direct, maintainable replacement for the
     exported EG workflow while preserving the analytical outputs.
   - All divide-by-zero conditions are explicitly protected.
   - No new business calculations were introduced.
   -------------------------------------------------------------------- */

options validvarname=v7;
options nosymbolgen nomlogic;

/* --------------------------------------------------------------------
   1. Source file and data preparation
   -------------------------------------------------------------------- */

%let INPUT_FILE = "C:\Users\ad50620\Downloads\ak_drilling_demo_synthetic_3000_v3_rigs_consistent.csv";

proc import
    file=&INPUT_FILE
    out=work.AK_DRILLING_DEMO_SYNTHETIC__0001
    dbms=csv
    replace;
    getnames=yes;
    guessingrows=max;
run;

/*
   Preserve all original KPI and field logic while keeping the workflow maintainable.
   The original Enterprise Guide workflow creates a cleaned table named
   WORK.QUERY_FOR_AK_DRILLING_DEMO__F4A5 and derives the following metrics:
   - Target_Achievement_Pct
   - Meters_Variance
   - Meters_Per_Hour
   - Cost_Per_Meter
   - Fuel_Per_Meter
   - Operational_Status
*/

data work.QUERY_FOR_AK_DRILLING_DEMO__F4A5;
    set work.AK_DRILLING_DEMO_SYNTHETIC__0001;

    length Operational_Status_Label $ 50;

    /* Preserve original field names and types as closely as practical. */
    format
        Operation_Date YYMMDD10.
        Target_Achievement_Pct PERCENT6.2
        Meters_Variance COMMA6.2
        Meters_Per_Hour COMMA6.2
        Cost_Per_Meter COMMA6.2
        Fuel_Per_Meter COMMA6.2
        Labor_Cost_USD COMMA7.
        Equipment_Cost_USD COMMA7.
        Fuel_Cost_USD COMMA6.
        Total_Cost_USD COMMA8.
        Quality_Score COMMA4.;

    /* ----------------------------------------------------------------
       Business logic preserved from original workflow:
       - Target achievement is drilled meters / target meters.
       - Variance is drilled meters minus target meters.
       - Productivity is drilled meters / operating hours.
       - Cost per meter is total cost / drilled meters.
       - Fuel per meter is fuel liters / drilled meters.
       - Operational status label translation to Spanish is preserved.
    ---------------------------------------------------------------- */

    if missing(Target_Meters) or Target_Meters = 0 then do;
        Target_Achievement_Pct = .;
    end;
    else do;
        Target_Achievement_Pct = Drilled_Meters / Target_Meters;
    end;

    if missing(Drilled_Meters) or missing(Target_Meters) then do;
        Meters_Variance = .;
    end;
    else do;
        Meters_Variance = Drilled_Meters - Target_Meters;
    end;

    if missing(Drilled_Meters) or missing(Operating_Hours) or Operating_Hours = 0 then do;
        Meters_Per_Hour = .;
    end;
    else do;
        Meters_Per_Hour = Drilled_Meters / Operating_Hours;
    end;

    if missing(Drilled_Meters) or Drilled_Meters = 0 then do;
        Cost_Per_Meter = .;
    end;
    else do;
        Cost_Per_Meter = Total_Cost_USD / Drilled_Meters;
    end;

    if missing(Drilled_Meters) or Drilled_Meters = 0 then do;
        Fuel_Per_Meter = .;
    end;
    else do;
        Fuel_Per_Meter = Fuel_Consumption_Liters / Drilled_Meters;
    end;

    /* Preserve the original Operation_Status value and create a separate reporting label. */
    select (upcase(strip(Operation_Status)));
        when ('ABOVE TARGET') Operational_Status_Label = 'Superó Objetivo';
        when ('ON TARGET') Operational_Status_Label = 'Cumplió Objetivo';
        when ('BELOW TARGET') Operational_Status_Label = 'Bajo Objetivo';
        when ('INTERRUPTED') Operational_Status_Label = 'Operación Interrumpida';
        otherwise Operational_Status_Label = 'Revisión de Seguridad';
    end;

    if missing(Year) and not missing(Operation_Date) then do;
        Year = year(Operation_Date);
    end;
    if missing(Month) and not missing(Operation_Date) then do;
        Month = month(Operation_Date);
    end;
    if missing(Quarter) and not missing(Operation_Date) then do;
        Quarter = cats('Q', qtr(Operation_Date));
    end;
run;

/* --------------------------------------------------------------------
   2. Operational status distribution
   -------------------------------------------------------------------- */

ods graphics on;

proc freq data=work.QUERY_FOR_AK_DRILLING_DEMO__F4A5;
    tables Operational_Status_Label / plots=freqplot;
    title 'Cumplimiento de Objetivos';
run;

/* --------------------------------------------------------------------
   3. Target achievement distribution
   -------------------------------------------------------------------- */

proc sgplot data=work.QUERY_FOR_AK_DRILLING_DEMO__F4A5;
    histogram Target_Achievement_Pct / scale=percent;
    density Target_Achievement_Pct / type=kernel;
    xaxis label='Target Achievement %';
    yaxis label='Percent';
    title 'Target Cumplimento Distribution';
run;

/* --------------------------------------------------------------------
   4. Summary statistics by rig
   -------------------------------------------------------------------- */

proc means data=work.QUERY_FOR_AK_DRILLING_DEMO__F4A5 n mean std min max;
    class Rig_ID;
    var Target_Achievement_Pct Meters_Per_Hour Quality_Score Cost_Per_Meter;
    title 'Datos Operativos por RIG';
run;

/* --------------------------------------------------------------------
   5. Rig productivity / cost balance
   -------------------------------------------------------------------- */

proc sql;
    create table work.RIG_PRODUCTIVITY_COST_BALANCE as
    select
        Rig_ID,
        mean(Target_Achievement_Pct) as Avg_Target_Achievement_Pct format=percent8.2,
        mean(Meters_Per_Hour) as Avg_Meters_Per_Hour format=comma10.2,
        mean(Cost_Per_Meter) as Avg_Cost_Per_Meter format=dollar12.2,
        case
            when mean(Cost_Per_Meter) is null or mean(Cost_Per_Meter) = 0 then .
            else mean(Meters_Per_Hour) / mean(Cost_Per_Meter)
        end as Productivity_Cost_Balance_Score format=comma10.4
    from work.QUERY_FOR_AK_DRILLING_DEMO__F4A5
    group by Rig_ID
    order by Productivity_Cost_Balance_Score desc;
quit;

proc print data=work.RIG_PRODUCTIVITY_COST_BALANCE noobs;
    var Rig_ID Avg_Target_Achievement_Pct Avg_Meters_Per_Hour Avg_Cost_Per_Meter Productivity_Cost_Balance_Score;
    title 'Rig Productivity-Cost Balance Ranking';
run;

/* --------------------------------------------------------------------
   6. Rig performance and productivity plots
   -------------------------------------------------------------------- */

proc sgplot data=work.QUERY_FOR_AK_DRILLING_DEMO__F4A5;
    vbox Target_Achievement_Pct / category=Rig_ID;
    title 'Desempeño Equipo de Perforación';
run;

proc sgplot data=work.QUERY_FOR_AK_DRILLING_DEMO__F4A5;
    scatter x=Cost_Per_Meter y=Meters_Per_Hour / group=Rig_ID;
    title 'Productividad vs Costo por Metro';
    xaxis label='Cost per Meter';
    yaxis label='Meters per Hour';
run;

proc sgplot data=work.QUERY_FOR_AK_DRILLING_DEMO__F4A5;
    vbox Meters_Per_Hour / category=Rock_Type;
    title 'Productividad por Tipo de Roca';
run;

proc sgplot data=work.QUERY_FOR_AK_DRILLING_DEMO__F4A5;
    vbox Target_Achievement_Pct / category=Weather_Condition;
    title 'Cumplimiento de Objetivos por Clima';
run;

/* --------------------------------------------------------------------
   7. Downtime analysis
   -------------------------------------------------------------------- */

proc freq data=work.QUERY_FOR_AK_DRILLING_DEMO__F4A5;
    tables Downtime_Reason / plots=freqplot;
    title '¿Cuál es la causa más frecuente de pérdida de productividad?';
run;

proc sql;
    create table work.DOWNTIME_SUMMARY as
    select
        Downtime_Reason,
        count(*) as Incident_Count,
        mean(Downtime_Hours) as Avg_Downtime_Hours format=comma10.2,
        sum(Downtime_Hours) as Total_Downtime_Hours format=comma10.2
    from work.QUERY_FOR_AK_DRILLING_DEMO__F4A5
    group by Downtime_Reason
    order by Total_Downtime_Hours desc;
quit;

proc print data=work.DOWNTIME_SUMMARY noobs;
    var Downtime_Reason Incident_Count Avg_Downtime_Hours Total_Downtime_Hours;
    title 'Summary Statistics: Downtime Analysis';
run;

proc sgplot data=work.QUERY_FOR_AK_DRILLING_DEMO__F4A5;
    vbar Downtime_Reason / response=Downtime_Hours stat=sum datalabel;
    title 'Downtime Analysis';
run;

/* --------------------------------------------------------------------
   8. Quality vs productivity and trend monitoring
   -------------------------------------------------------------------- */

proc sgplot data=work.QUERY_FOR_AK_DRILLING_DEMO__F4A5;
    scatter x=Quality_Score y=Meters_Per_Hour;
    title 'Scatter Plot: Calidad vs Productividad';
    xaxis label='Quality Score';
    yaxis label='Meters per Hour';
run;

proc sql;
    create table work.TREND_SUMMARY as
    select
        Year,
        Quarter,
        mean(Target_Achievement_Pct) as Avg_Target_Achievement_Pct format=percent8.2,
        mean(Meters_Per_Hour) as Avg_Meters_Per_Hour format=comma10.2
    from work.QUERY_FOR_AK_DRILLING_DEMO__F4A5
    group by Year, Quarter
    order by Year, Quarter;
quit;

proc sgplot data=work.TREND_SUMMARY;
    series x=Quarter y=Avg_Target_Achievement_Pct / group=Year markers;
    xaxis label='Quarter';
    yaxis label='Average Target Achievement %';
    title '¿Estamos mejorando nuestro cumplimiento de objetivos de perforación año tras año?';
run;

/* --------------------------------------------------------------------
   9. Regression and generalized linear model analysis
   -------------------------------------------------------------------- */

proc reg data=work.QUERY_FOR_AK_DRILLING_DEMO__F4A5 plots=none;
    model Meters_Per_Hour = Downtime_Hours Operating_Hours;
    title 'Linear Regression Results';
run;
quit;

proc genmod data=work.QUERY_FOR_AK_DRILLING_DEMO__F4A5;
    class Shift Weather_Condition Rock_Type;
    model Meters_Per_Hour = Operating_Hours Downtime_Hours Shift Weather_Condition Rock_Type / dist=normal link=identity;
    title 'Generalized Linear Models Analysis';
run;
quit;

ods graphics off;

/* --------------------------------------------------------------------
   10. Final reporting dataset
   -------------------------------------------------------------------- */

proc sql;
    create table work.FINAL_DRILLING_KPIS as
    select
        Operation_ID,
        Operation_Date,
        Year,
        Month,
        Quarter,
        Project_Name,
        Country,
        Region,
        Site,
        Service_Type,
        Rig_ID,
        Operator_Name,
        Shift,
        Rock_Type,
        Weather_Condition,
        Target_Meters,
        Drilled_Meters,
        Operating_Hours,
        Downtime_Hours,
        Downtime_Reason,
        Fuel_Consumption_Liters,
        Labor_Cost_USD,
        Equipment_Cost_USD,
        Fuel_Cost_USD,
        Total_Cost_USD,
        Completed_Wells,
        Safety_Incidents,
        Near_Miss_Events,
        Quality_Score,
        Operation_Status,
        Data_Scenario,
        Target_Achievement_Pct,
        Meters_Variance,
        Meters_Per_Hour,
        Cost_Per_Meter,
        Fuel_Per_Meter
    from work.QUERY_FOR_AK_DRILLING_DEMO__F4A5;
quit;

/* --------------------------------------------------------------------
   NEW ANALYSIS BLOCK
   Location choice:
   This block is inserted immediately after the "Summary statistics by rig"
   section and before the productivity/cost balance ranking. That is the
   correct point in the workflow because the script has already created the
   final KPI variables for each operation and the dataset is now ready for
   rig-level performance evaluation across productivity, downtime, and quality.
   This preserves the existing logic and adds a new analysis only.
   -------------------------------------------------------------------- */

proc sql;
    create table work.RIG_CONSISTENT_SUMMARY as
    select
        Rig_ID,
        count(*) as Operation_Count,
        mean(Meters_Per_Hour) as Avg_Meters_Per_Hour format=comma10.2,
        mean(Downtime_Hours) as Avg_Downtime_Hours format=comma10.2,
        mean(Quality_Score) as Avg_Quality_Score format=comma10.2,
        mean(Target_Achievement_Pct) as Avg_Target_Achievement_Pct format=percent8.2,
        median(Meters_Per_Hour) as Median_Meters_Per_Hour format=comma10.2,
        median(Downtime_Hours) as Median_Downtime_Hours format=comma10.2,
        median(Quality_Score) as Median_Quality_Score format=comma10.2
    from work.QUERY_FOR_AK_DRILLING_DEMO__F4A5
    group by Rig_ID
    order by Avg_Meters_Per_Hour desc, Avg_Downtime_Hours asc, Avg_Quality_Score desc;
quit;

proc sql;
    create table work.RIG_CONSISTENT_PERFORMANCE as
    select
        s.Rig_ID,
        s.Operation_Count,
        s.Avg_Meters_Per_Hour,
        s.Avg_Downtime_Hours,
        s.Avg_Quality_Score,
        s.Avg_Target_Achievement_Pct,
        s.Median_Meters_Per_Hour,
        s.Median_Downtime_Hours,
        s.Median_Quality_Score,
        p.Median_Productivity,
        p.Median_Downtime,
        p.Median_Quality,
        case
            when s.Avg_Meters_Per_Hour >= p.Median_Productivity
             and s.Avg_Downtime_Hours <= p.Median_Downtime
             and s.Avg_Quality_Score >= 90
            then 1
            else 0
        end as Consistently_High_Performance
    from work.RIG_CONSISTENT_SUMMARY as s
    cross join (
        select
            median(Avg_Meters_Per_Hour) as Median_Productivity,
            median(Avg_Downtime_Hours) as Median_Downtime,
            median(Avg_Quality_Score) as Median_Quality
        from work.RIG_CONSISTENT_SUMMARY
    ) as p;
quit;

proc report data=work.RIG_CONSISTENT_PERFORMANCE nowd;
    columns Rig_ID
            Operation_Count
            Avg_Meters_Per_Hour
            Avg_Downtime_Hours
            Avg_Quality_Score
            Avg_Target_Achievement_Pct
            Consistently_High_Performance;

    define Rig_ID / group 'Rig ID';
    define Operation_Count / display 'Operations';
    define Avg_Meters_Per_Hour / display 'Avg Meters/Hour';
    define Avg_Downtime_Hours / display 'Avg Downtime Hours';
    define Avg_Quality_Score / display 'Avg Quality Score';
    define Avg_Target_Achievement_Pct / display 'Avg Target Achievement';
    define Consistently_High_Performance / display 'Consistently High Performer';

    title 'Rig Performance: High Productivity, Low Downtime, and High Quality';
run;

proc sql;
    create table work.TOP_RIGS_CONSISTENT_PERFORMANCE as
    select
        Rig_ID,
        Operation_Count,
        Avg_Meters_Per_Hour,
        Avg_Downtime_Hours,
        Avg_Quality_Score,
        Avg_Target_Achievement_Pct,
        Consistently_High_Performance
    from work.RIG_CONSISTENT_PERFORMANCE
    where Consistently_High_Performance = 1
    order by Avg_Meters_Per_Hour desc,
             Avg_Downtime_Hours asc,
             Avg_Quality_Score desc;
quit;

proc print data=work.TOP_RIGS_CONSISTENT_PERFORMANCE noobs;
    var Rig_ID
        Operation_Count
        Avg_Meters_Per_Hour
        Avg_Downtime_Hours
        Avg_Quality_Score
        Avg_Target_Achievement_Pct
        Consistently_High_Performance;

    title 'Recommended Rigs: Consistently High Productivity with Low Downtime and High Quality';
run;

/* --------------------------------------------------------------------
   NEW BUSINESS ANALYSIS:
   Rig resilience under operational stress
   Business question:
   Which rigs maintain strong productivity even in adverse weather and
   disruption-heavy conditions while keeping downtime low and quality high?

   Insert this block immediately after the "Summary statistics by rig"
   section and before the "Rig productivity / cost balance" section.
   -------------------------------------------------------------------- */

data work.RIG_RESILIENCE_STAGING;
    set work.QUERY_FOR_AK_DRILLING_DEMO__F4A5;

    if Weather_Condition in ('Rain', 'High Wind', 'Extreme Heat', 'Storm') then do;
        Adv_Weather_Flag = 1;
    end;
    else do;
        Adv_Weather_Flag = 0;
    end;
run;

proc sql;
    create table work.RIG_RESILIENCE_ANALYSIS as
    select
        Rig_ID,

        /* Overall rig performance */
        mean(Meters_Per_Hour) as Overall_MPH format=comma10.2,
        mean(Downtime_Hours) as Overall_Downtime format=comma10.2,
        mean(Quality_Score) as Overall_Quality format=comma10.2,
        mean(Target_Achievement_Pct) as Overall_Target_Ach format=percent8.2,

        /* Adverse-weather performance */
        mean(case when Adv_Weather_Flag = 1 then Meters_Per_Hour else . end)
            as Adv_MPH format=comma10.2,

        mean(case when Adv_Weather_Flag = 1 then Downtime_Hours else . end)
            as Adv_Downtime format=comma10.2,

        mean(case when Adv_Weather_Flag = 1 then Quality_Score else . end)
            as Adv_Quality format=comma10.2,

        sum(Adv_Weather_Flag) as Adv_Weather_Ops,

        sum(case when Adv_Weather_Flag = 1 and Downtime_Hours > 0 then 1 else 0 end)
            as Adv_Downtime_Cnt
    from work.RIG_RESILIENCE_STAGING
    group by Rig_ID
    order by Rig_ID;
quit;

data work.RIG_RESILIENCE_ANALYSIS;
    set work.RIG_RESILIENCE_ANALYSIS;

    /* If a rig has no adverse-weather records, set the values to missing to keep the analysis honest. */
    if missing(Adv_MPH) then do;
        Adv_MPH = .;
        Adv_Downtime = .;
        Adv_Quality = .;
    end;

    /* Resilience ratio: how much productivity is preserved under stress relative to overall productivity */
    if missing(Overall_MPH) or Overall_MPH = 0 then do;
        Resilience_Ratio = .;
    end;
    else do;
        Resilience_Ratio = Adv_MPH / Overall_MPH;
    end;

    /* Business score:
       - rewards rigs that keep productivity high under stress
       - penalizes rigs with more downtime in harsh conditions
       - requires quality to remain strong
    */
    if missing(Adv_Quality) then do;
        Weather_Resilience_Score = .;
    end;
    else do;
        Weather_Resilience_Score =
            (Adv_MPH / (Overall_MPH + 1e-9))
            * (Adv_Quality / 100)
            * (1 - (Adv_Downtime / (Overall_Downtime + 1)));
    end;

    format
        Overall_MPH comma10.2
        Overall_Downtime comma10.2
        Overall_Quality comma10.2
        Adv_MPH comma10.2
        Adv_Downtime comma10.2
        Adv_Quality comma10.2
        Resilience_Ratio percent8.2
        Weather_Resilience_Score comma10.4;
run;

proc sort data=work.RIG_RESILIENCE_ANALYSIS;
    by descending Weather_Resilience_Score;
run;

proc print data=work.RIG_RESILIENCE_ANALYSIS noobs;
    var Rig_ID
        Adv_Weather_Ops
        Overall_MPH
        Adv_MPH
        Overall_Downtime
        Adv_Downtime
        Overall_Quality
        Adv_Quality
        Resilience_Ratio
        Weather_Resilience_Score;
    title 'Rig Resilience Under Adverse Weather and Operational Stress';
run;

%put NOTE: Refactored workflow completed. Final data available in WORK.QUERY_FOR_AK_DRILLING_DEMO__F4A5 and related analysis tables.;
