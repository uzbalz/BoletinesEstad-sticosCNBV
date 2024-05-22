***Carga de ubicación
macro drop all
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
global run_tags do "$root\Osvaldo\Otros_DTA\etiquetas.do"

cd "${root}\Data\Bank Data\"
use "$dataS\[13]Indicadores_Bancarios_Agr.dta", clear
	gen year = year(dofm(monthly_date))
	gen month = month(dofm(monthly_date))
	su monthly_date
	local time_max = `r(max)'
	su year if monthly_date == `time_max'
		global y_max = `r(max)'
	su month if monthly_date == `time_max'	
		global m_max = `r(max)'
		
		
quietly{
	foreach varl of varlist icap imor_cct liq roa imor_cccn {
		xtset bank_id monthly_date
		egen `varl'_h = mean(`varl'), by(bank_id)
		gen `varl'12 = s12.`varl'
		gen `varl'1 = s1.`varl'
		gen `varl'h = `varl' - `varl'_h
		format `varl'*  %9.2f
		label variable bank_id "Mes: ${y_max}m${m_max}"
		export excel ///
			bank_id `varl' `varl'1 `varl'12  `varl'h if monthly_date == tm(${y_max}m${m_max}) ///
			using "[14]MainStats.xlsx", sheet("`varl'", replace) firstrow(varlabels) keepcellfmt
		*noisily: list bank_id `varl' `varl'1 `varl'12  `varl'h if monthly_date == tm(${y_max}m${m_max})
	}
	foreach varl of varlist cre_cct cre_cce cre_ccct{
		xtset bank_id monthly_date
		egen `varl'_h = mean(`varl'), by(bank_id)
		gen `varl'12 = s12.`varl' / l12.`varl'
		gen `varl'1 = s1.`varl' / l1.`varl'
		gen `varl'h = (`varl' / `varl'_h - 1 ) *100
		format `varl'*  %9.2f
		label variable bank_id "Mes: ${y_max}m${m_max}"
		export excel ///
			bank_id `varl' `varl'1 `varl'12  `varl'h if monthly_date == tm(${y_max}m${m_max}) ///
			using "[14]MainStats.xlsx", sheet("`varl'", replace) firstrow(varlabels) keepcellfmt
		*noisily: list bank_id `varl' `varl'1 `varl'12  `varl'h if monthly_date == tm(${y_max}m${m_max})
	}
noisily: display `"{browse "[14]MainStats.xlsx": Open excel file}"'
}