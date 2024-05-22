***Carga de ubicación
clear all
local usuario substr( "`c(username)'",1,5) //Para funcionar con cualquier usuario en servidor
if `usuario'== "Usuar" global root "F:\DARMACRO" 
else if `usuario' != "Usuar" global root "\\Statadgef\darmacro"
	global home "$root\Osvaldo"
	global source "$home\Data_CNBV_updated"
	global mun_char "$root\Data\Municipalities Characteristics"
		global main "$root\Data\Bank Data"
			global dataS "$main\data\Stata"
			global dataR "$main\data\Raw"
			global results "$main\results"
			global graphs "$main\graphs"
			global temp "$main\temp"
			global logs "$main\log"	
	global run_tags do "${home}\Otros_DTA\etiquetas.do"
	
global dt_codes "\\Statadgef\darmacro\Data\Bank Data\Codes\Data Construction\" 

/* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
* This code authomatically creates the 13-Indicadores Bancarios dataset
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
local dday: di %td today()
local bkup "${root}\Data\Bank Data\Data\Stata\Backups\13_files"
copy "${root}\Data\Bank Data\Data\Stata\[13]Indicadores_Bancarios_Agr.dta" ///
	"`bkup'/[13]Backup_taken_in`dday'.dta", replace
/*
	FILE 1 - PYTHON
This file downloads info from AlertasTempranas
and export it as excel file >>AlertasTempranasMod<<
*/
set sslrelax on  
copy "https://portafolioinfdoctos.cnbv.gob.mx/Documentacion/minfo/040_15b_R2.xls" "//Statadgef/darmacro/Data/Bank Data/Data/Raw/040_15b_R2.xls", replace
set sslrelax off
python script "${dt_codes}/[11a] Execute macros.py"

/*
	FILE 2
This file takes AlertasTempranasMod file and export as dta file.
*/
do "${dt_codes}/[11]Capitalización.do"


/*
	FILE 3
This file automatically download Boletines Estadísticos
and export it as a dta file
*/
do "${dt_codes}/[12]Indicadores_Bancarios_BE.do"


/*
	FILE 4
This file recolect previous files, adds SituaciónFinanciera info
and creates the main dataset
*/
do "${dt_codes}/[13]Covariables_SituaciónFinanciera.do"
