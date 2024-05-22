quietly{
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
* Correr macros (usando python)


	import excel "${dataR}/040_15b_R2_mod.xlsx", sheet("Sheet") firstrow clear

	replace  cve_institucion = cve_institucion[_n-1] if cve_institucion == ""
		drop if cve_periodo == .

	rename (cve_institucion ICAP CapitalNeto) (bank_id icap capital_neto)	
		
	destring, replace

	gen year = floor(cve_periodo/100)
	gen month = cve_periodo - year * 100
	gen monthly_date = ym(year, month)
		format monthly_date %tm
	replace capital_neto = capital_neto / 1E9

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
	noisily di "Capitalización actualizado a `max_year'm`max_month'"
	save "${dataS}\[11]Capitalización.dta", replace

}
