***Carga de ubicación
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
		
		
************************** INSTRUCCIONES *******************************
* 1
* Descargar la base de http://portafoliodeinformacion.cnbv.gob.mx/bm1/Paginas/alertas.aspx
* NOMBRE: Resumen de cómputo
* Abrir el excel con macros: (11-OB) Macros_ICAP
* Correr la macro en el archivo Resumen de Cómputo

clear
edit


replace  cve_institucion = cve_institucion[_n-1] if cve_institucion == ""
	drop if cve_periodo == .

rename (cve_institucion capitalneto) (bank_id capital_neto )	
	
destring, replace

gen year = floor(cve_periodo/100)
gen month = cve_periodo - year * 100
gen monthly_date = ym(year, month)
	format monthly_date %tm
replace capital_neto = capital_neto / 1000000000

drop year month cve_periodo

$run_tags

replace bank_id = 0 if bank_id == 5

sort bank_id monthly_date
label variable capital_neto "Capital Neto en mmdp"
label variable icap "Índice de capitalización"
	
quietly{
	preserve
		gen year = year(dofm(monthly_date))
		gen month = month(dofm(monthly_date))
		su monthly_date
		local max_date = `r(max)'
			su month if monthly_date == `max_date'
			local max_month = `r(max)'
			su year if monthly_date == `max_date'
			local max_year = `r(max)'
	restore
}
label data "Capitalización. Actualizado a `max_year'm`max_month'"
save "$dataS\[11_OB]Capitalización.dta", replace







/*
rename (cve_institucion total) (bank_id capital_neto)

destring, replace

gen year = floor(cve_periodo/100)
gen month = cve_periodo - year * 100
gen monthly_date = ym(year, month)
	format monthly_date %tm
replace capital_neto = capital_neto / 1000000000

drop year month cve_periodo

label variable capital_neto "Capital Neto en mmdp"
save "$dataS\[TEMP]CapitalNeto.dta", replace

* 2
* Ir a la hoja de BD y ordenar en filas a Bancos y Periodo y filtrar por Clave
* Buscar la clave: 4021750 (ICAP)
* Copiar y pegar el resultado :)

clear
edit

replace  cve_institucion = cve_institucion[_n-1] if cve_institucion == ""
	drop if cve_periodo == .

rename (cve_institucion total) (bank_id icap)
destring, replace

gen year = floor(cve_periodo/100)
gen month = cve_periodo - year * 100
gen monthly_date = ym(year, month)
	format monthly_date %tm

drop year month cve_periodo

label variable icap "ICAP -- Alertas Tempranas"
save "$dataS\[TEMP]ICAP.dta", replace


***FUSIONAR
use "$dataS\[TEMP]CapitalNeto.dta", clear
	merge 1:1 bank_id monthly_date using "$dataS\[TEMP]ICAP.dta"
	keep if _merge == 3
	drop _merge
keep if (bank_id >= 40000 & bank_id <50000) | bank_id == 5
replace bank_id = 0 if bank_id == 5
compress
save "$dataS\[11_OB]Capitalización.dta", replace
	
rm "$dataS\[TEMP]CapitalNeto.dta" 
rm "$dataS\[TEMP]ICAP.dta"
	
	-----
	
drop in 1 
drop in 1
rename var1 bank_str
local x = tm(2022m4) 
local mm = `x'  //último mes
forvalues j = 2(3)100{
	local k = `j' + 1
	local l = `k' + 1
	capture{
	rename var`j'  icap`mm'
	rename var`k'  ccb`mm'
	rename var`l'  ccf`mm'
	}
	local mm = `mm' - 1
}
reshape long icap ccb ccf, i(bank_str) j(monthly_date)
format monthly_date %tm 
rename bank_str bank_labels
destring icap ccb ccf, replace

*Obteniendo los números
merge m:1 bank_labels using "$root\Osvaldo\Otros_DTA\Covars\Banks_ID.dta"
	replace bank_id = 0 if bank_labels == "Total Banca Múltiple"
	drop if bank_id == .
	drop _merge
	
keep bank_id monthly_date icap ccb ccf
order bank_id monthly_date icap ccb ccf

compress
gen year = year(dofm(monthly_date))
	su year
	global yy = r(max)
gen month = month(dofm(monthly_date)) 
	su month if year == ${yy}
	global mm = r(max)
	
*Etiquetas finales
label data "ICAP de Alertas tempranas ${yy}m${mm}. Last update: `c(current_date)' by `c(username)'"

label variable icap "ICAP --Alertas tempranas"
label variable ccb  "CCB --Alertas tempranas"
label variable ccf  "CCF --Alertas tempranas"
save "$dataS\[11_OB]ICAP_2022plus.dta", replace
*/