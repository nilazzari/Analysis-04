libname lib_name "C:\Users\user01";

data prova2.salute2013; 
infile "file_std_salute13_b.dat" lrecl=1945; 
length default=4; 
  
input
 %include "tracciato_salute13_b.txt"; 
;
run;

proc format;
value age
0-4 = "0-4" 
5-9 = "5-9" 
10-14 = "10-14" 
15-19 = "15-19" 
20-24 = "20-24" 
25-29 = "25-29" 
30-34 = "30-34" 
35-39 = "35-39" 
40-44 = "40-44" 
45-49 = "45-49" 
50-54 = "50-54"
55-59 = "55-59"
60-64 = "60-64"
65-69 = "65-69"
70-74 = "70-74"
75-79 = "75-79"
80-84 = "80-84"
85-89 = "85-89"
90-high ="90 e oltre";

 value sex
1="Maschi"
2="Femmine";

value sino
1="No"
2="Si";

value newictus
1="2_No"
2="1_Si, almeno un episodio";

value prepass
0="Non ne ha mai sofferto o ne ha sofferto in passato"  
             /*0 = mai stato malato o era malato in passato */
1="Ne soffre attualmente";    /*1= attualmente malato */

value smoke
1="Fuma"
2-3="Mai fumato o fumava in passato";

value newsmoke
1-2="Fuma o ha fumato in passato"
3="Mai fumato";

value obeso
low-<30="Non obeso"
30-high="Obeso";

value dieta
1="Segue una dieta iposodica"
0="Non segue una dieta iposodica";
 
value MH
low-<26="1_MH minore di 25"
26-<76="2_25 =<MH =<75"
76-high="3_MH maggiore di 75";

value MCS
low-<26="1_MCS minore di 25"
26-<56="2_25=<MCS=<55"
56-high="3_MCS maggiore di 55";

value suffer
0="No evento doloroso negli ultimi tre anni"
1="Almeno un evento doloroso negli ultimi tre anni";

/* dataset con tutte le classi di età */
data prova2.completo;
set prova2.salute2013;
keep sesso eta ictus fumo iper bmi cuore mcs MH EVDOL1 iposo1
     maschio cardiac ipertens new_cardiac new_ipertens dolor;
bmi=peso/((stat/100)**2);

/* dataset con età>=70 */
data prova2.anziani;
set prova2.salute2013;
keep sesso eta ictus fumo iper bmi cuore mcs MH EVDOL1 iposo1
     maschio cardiac ipertens new_cardiac new_ipertens dolor sodio;
bmi=peso/((stat/100)**2);
where eta>=70;

/* Nuove variabili */
if sesso=1 then maschio=1;
else if sesso=2 then maschio=0;

if evdol1=1 then dolor=0;       /* 0: non ha subito eventi dolorosi negli ultimi 3 anni */
 else if evdol1=. then dolor=1;   /* 1: ha subito un qualche tipo di evento doloroso
                                     negli ultimi 3 anni */
                                    
if iposo1=3 then sodio=1;        /* 1: dieta iposodica */
 else if iposo1=. then sodio=0;  /* 0: non segue una dieta iposodica (ma non è detto che
                                    segua un regime alimentare ad alto consumo di sale */

array vett(2) cuore iper;
array riskfac(2) cardiac ipertens;
do i=1 to 2;
if vett(i) in (1,2) then riskfac(i)=0;          /*mai sofferto la malattia o ha avuto la
                                                 malattia in passato */
   else if vett(i) in (3) then riskfac(i)=1;    /* ha attualmente la malattia */
end;

array arr(2) cuore iper;
array newmal(2) new_cardiac new_ipertens;
do i=1 to 2;
if arr(i) in (1) then newmal(i)=0;            /*mai sofferto la malattia */
   else if arr(i) in (2,3) then newmal(i)=1;  /* ha attualmente la malattia o l'ha 
                                                   avuta in passato*/
end;
run;

ods graphics on;
proc freq data=prova2.anziani order=formatted;
tables ictus*(sesso eta cardiac ipertens bmi fumo sodio dolor mcs mh)/nopercent norow chisq 
                 relrisk plots(only)=freqplot(twoway=cluster);
format ictus newictus. eta age. cardiac prepass. ipertens prepass. fumo newsmoke.
sodio dieta. dolor suffer. sesso sex. bmi obeso. mh MH. mcs MCS.;
run;
ods graphics off;

proc freq data=prova2.anziani order=formatted;
tables mh*mcs/ measures;     /*Correlazione di Pearson= 0,8799 */
run;

/* età */
proc freq data=prova2.completo;
tables eta/plots=freqplot;
format eta age.;
run;
proc univariate data=prova2.completo;
var eta;
format eta age.;
run;

/*distribuzione di età e sesso */
proc freq data=prova2.completo;
tables eta*sesso/ ;
format eta age. sesso sex.;
run;

/* distribuzione eta*sesso per dataset completo */
proc univariate data=prova2.completo;
class sesso;
var eta;
format eta age. sesso sex.;
run;
/* distribuzione eta*sesso negli anziani */
proc univariate data=prova2.anziani;
class sesso;
var eta;
format eta age. sesso sex.;
run;

/* Sodio-Ipertensione-Ictus */
/* Controllo eventuale confondente: dieta iposodica */
proc freq data=prova2.anziani order=formatted;
tables ipertens*ictus / nopercent nocol relrisk;
format ictus newictus. ipertens prepass.;
title "Distribuzione di n di ictus in base all'ipertensione";
run;
proc freq data=prova2.anziani order=formatted;
tables sodio*ipertens / nopercent nocol chisq measures relrisk;
format ipertens prepass. sodio dieta.;
title "Distribuzione di casi di ipertensione in base alla dieta iposodica";
run;
proc freq data=prova2.anziani order=formatted;
tables ictus*ipertens /nopercent norow relrisk measures chisq;
format ictus newictus. ipertens prepass.;
run;
/* Stratifichiamo per SODIO*/
proc freq data=prova2.anziani order=formatted;
tables sodio*ipertens*ictus / nocol norow nopercent relrisk cmh chisq 
                                  plots(only)=oddsratioplot(stats);
format ipertens prepass. sodio dieta. ictus newictus.;
title "Stratifcazione in base al consumo di sodio";
run;

/* Fumo-Cuore-Ictus (eventuale confondente= Fumo) format:newsmoke */
proc freq data=prova2.anziani order=formatted;
tables fumo*cardiac / nopercent nocol norow chisq measures relrisk;
title "Distribuzione di casi di malattie cardiache in base all'abitudine
        al fumo";
format cardiac prepass. fumo newsmoke.;
run;
proc freq data=prova2.anziani order=formatted;
tables ictus*cardiac  /nopercent norow relrisk measures chisq;
format ictus newictus. cardiac prepass.;
run;
/* Stratifichiamo per FUMO*/
proc freq data=prova2.anziani order=formatted;
tables fumo*cardiac*ictus / nocol norow nopercent relrisk cmh chisq plots(only)=oddsratioplot(stats);
format cardiac prepass. fumo newsmoke. ictus newictus.;
title "Stratifcazione in base all'abitudine al fumo";
run;
ods rtf close;

/* MCS-Evento doloroso-Ictus */
proc freq data=prova2.anziani order=formatted;
tables mcs*ictus/ nopercent nocol relrisk chisq;
format mcs MCS. ictus newictus.;
run;
proc freq data=prova2.anziani order=formatted;
tables mcs*dolor/ nopercent norow nocol chisq relrisk;
format dolor suffer. mcs MCS.;
run;
proc freq data=prova2.anziani order=formatted;
tables ictus*dolor/ nopercent norow chisq relrisk;
format dolor suffer. ictus newictus.;
run;
/* Straficazione per MCS */
proc freq data=prova2.anziani order=formatted;
tables mcs*dolor*ictus / nocol norow nopercent relrisk cmh chisq plots(only)=oddsratioplot(stats);
format mcs MCS. dolor suffer. ictus newictus.;
title "Stratifcazione in base all'indice MCS";
run;

/* MH-Evento doloroso-Ictus */
proc freq data=prova2.anziani order=formatted;
tables mh*ictus/ nopercent nocol relrisk chisq;
format mh MH. ictus newictus.;
run;
proc freq data=prova2.anziani order=formatted;
tables mh*dolor/ nopercent norow nocol chisq relrisk;
format dolor suffer. mh MH.;
run;
proc freq data=prova2.anziani order=formatted;
tables ictus*dolor/ nopercent norow chisq relrisk;
format dolor suffer. ictus newictus.;
run;
/* Straficazione per MH */
proc freq data=prova2.anziani order=formatted;
tables mh*dolor*ictus / nocol norow nopercent relrisk cmh chisq 
                        plots(only)=oddsratioplot(stats);
format mh MH. dolor suffer. ictus newictus.;
title "Stratifcazione in base al MH ";
run;

/* Sesso-Cuore-Ictus */ 
proc freq data=prova2.anziani order=formatted;
tables sesso*cardiac/ nopercent nocol norow chisq;
format sesso sex. cardiac prepass.;
title "Distribuzione di casi di patologie cardiache in base al sesso";
run;
proc freq data=prova2.anziani order=formatted;
tables sesso*ictus / nopercent nocol chisq relrisk;
title "Distribuzione di casi di ictus per sesso";
format sesso sex. ictus newictus.;
run;
proc freq data=prova2.anziani order=formatted;
tables cardiac*ictus/ nocol nopercent relrisk chisq;
format ipertens prepass. ictus newictus.;
title "Distribuzione di casi di ictus per malattie cardiache";
run;
/* Straficazione per SESSO */
proc freq data=prova2.anziani order=formatted;
tables sesso*cardiac*ictus / nocol norow nopercent relrisk cmh chisq plots(only)=oddsratioplot(stats);
format sesso sex. cardiac prepass. ictus newictus.;
title "Stratifcazione in base al sesso";
run;

/* Ipertensione-Cuore-Ictus */
proc freq data=prova2.anziani order=formatted;
tables ipertens*ictus / nopercent nocol relrisk;
format ictus newictus. ipertens prepass.;
title "Distribuzione di n di ictus in base all'ipertensione";
run;
proc freq data=prova2.anziani order=formatted;
tables cardiac*ipertens / nopercent nocol norow chisq measures relrisk;
format ipertens prepass. cardiac prepass.;
title "Distribuzione di casi di ipertensione e di malattie del cuore";
run;
proc freq data=prova2.anziani order=formatted;
tables ictus*cardiac /nopercent norow relrisk measures chisq;
format ictus newictus. cardiac prepass.;
run;
/* Stratifichiamo per IPERTENSIONE*/
proc freq data=prova2.anziani order=formatted;
tables ipertens*cardiac*ictus / nocol norow nopercent relrisk cmh chisq plots(only)=oddsratioplot(stats);
title "Stratifcazione in base al consumo di sodio";
format ipertens prepass. cardiac prepass. ictus newictus.;
run;

/* Età-Fumo-Ictus (eventuale confondente= età) */
proc freq data=prova2.anziani order=formatted;
tables fumo*ictus / nopercent nocol norow chisq measures relrisk;
title "Distribuzione di casi di ictus in base all'abitudine al fumo";
format ictus newictus. fumo newsmoke.;
run;
proc freq data=prova2.anziani order=formatted;
tables eta*fumo /nopercent norow nocol relrisk measures chisq;
format eta age. fumo newsmoke.;
run;
/* Stratifichiamo per FUMO*/
proc freq data=prova2.anziani order=formatted;
tables eta*fumo*ictus / nocol norow nopercent relrisk cmh chisq plots(only)=oddsratioplot(stats);
format eta age. fumo newsmoke. ictus newictus.;
title "Stratifcazione in base all'età";
run;

ods graphics on;
title 'Regressione logistica con interazione';
proc logistic data=prova2.anziani;
class sesso (ref='Femmine') eta (ref='70-74') 
      cardiac (ref='mai sofferto in passato') 
      ipertens (ref='mai sofferto in passato') bmi (ref='Non obeso') 
      fumo (ref='Mai fumato') dolor (ref='No evento dol') 
      sodio (ref='No dieta iposodica') mcs(ref="3_MCS maggiore di 55") 
      mh(ref="3_MH maggiore di 75") / param=ref;
model ictus (event='1_Si, almeno un episodio') = sesso eta cardiac ipertens bmi fumo dolor sodio mcs mh 
      sodio*ipertens sesso*cuore 
      /include=2 selection=backward 
      slstay=0.05 ctable cl;
      oddsratio ipertens;
format bmi obeso. sesso sex. ictus newictus. eta age. cardiac prepass. ipertens prepass. fumo newsmoke. dolor suffer. sodio dieta. mcs MCS. mh MH.;
run;
ods graphics off;
