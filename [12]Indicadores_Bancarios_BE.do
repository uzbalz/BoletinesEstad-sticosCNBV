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
clear

/*  Instrucciones
¡NOTA!: Es un código automático :3 (actualizar en 2023)
Únicamente es necesario descargar el boletín estadístico en la carpeta 
  Raw/Boletines estadísticos.
  
 ADVERTENCIA
  Ten cuidado si CNBV cambia los nombres de los bancos o pone indicativos
*/

/*
Notas:
	Se añadió una fila al boletín 2023m2 para un mejor ajuste
*/
global y0 = 2015
global y1 = 2024
global m0 = 1
global m1 = 12

global dataBE "${dataR}/Boletines Estadísticos/B"


// Get a list of files in the directory
local files : dir "${dataBE}" files "*[rm]*"


// Loop through the list and delete files that match the pattern
foreach file in `files' {
   rm "${dataBE}/`file'" // Use "erase" instead of "del" on non-Windows systems
}



*=====================================
* Descarga de bases
*======================================
/*
quietly{

local html_cnbv "https://portafolioinfo.cnbv.gob.mx/PortafolioInformacion"
local html_cnbv "https://portafolioinfo.cnbv.gob.mx/_layouts/15/download.aspx?SourceUrl=https://portafolioinfo.cnbv.gob.mx/PortafolioInformacion"

//Process of downloading info...
forvalues y = $y0 / $y1  {
	forvalues m = $m0 / $m1 {
		
		// Detecting if file already exists
		local 0m : di %02.0f `m'
		local ym = ym(`y',`m')
		
		local existing_file = fileexists("${dataBE}/`y'/BE_BM_`y'`0m'.xlsx") + fileexists("${dataBE}/`y'/BE_BM_`y'`0m'.xlsm") + fileexists("${dataBE}/`y'/BE_BM_`y'`0m'.xls")
		
 		if `existing_file' == 0 { 
			capture{
				if `ym' < ym(2019, 7) copy "`html_cnbv'/BE_BM_`y'`0m'.xls" "${dataBE}/`y'/BE_BM_`y'`0m'.xls", replace
				if `ym' == ym(2019, 7) & `ym' == ym(2019, 8) copy "`html_cnbv'/BE_BM_`y'`0m'.xlsx" "${dataBE}/`y'/BE_BM_`y'`0m'.xlsx", replace
				if `ym' >= ym(2019, 9) & `ym' <= ym(2020, 3) copy "`html_cnbv'/BE_BM_`y'`0m'.xlsm" "${dataBE}/`y'/BE_BM_`y'`0m'.xlsm", replace
				if `ym' >= ym(2020, 4) & `ym' <= ym(2020, 8) copy "`html_cnbv'/BE_BM_`y'`0m'.xlsx" "${dataBE}/`y'/BE_BM_`y'`0m'.xlsx", replace
				if `ym' >= ym(2020, 9) & `ym' <= ym(2020, 10) copy "`html_cnbv'/BE_BM_`y'`0m'.xlsm" "${dataBE}/`y'/BE_BM_`y'`0m'.xlsm", replace
				if `ym' >= ym(2020, 11) & `ym' <= ym(2021, 2) copy "`html_cnbv'/BE_BM_`y'`0m'.xlsx" "${dataBE}/`y'/BE_BM_`y'`0m'.xlsx", replace
				if `ym' >= ym(2021,  3) & `ym' <= ym(2021, 11) copy "`html_cnbv'/BE_BM_`y'`0m'.xlsm" "${dataBE}/`y'/BE_BM_`y'`0m'.xlsm", replace
				if `ym' >= ym(2021, 12) & `ym' != ym(2023, 8) copy "`html_cnbv'/BE_BM_`y'`0m'.xlsx" "${dataBE}/`y'/BE_BM_`y'`0m'.xlsx", replace	
				if `ym' == ym(2023, 8) | `ym' == ym(2023, 9) copy "`html_cnbv'/BE_BM_%20`y'`0m'.xlsx"  "${dataBE}/`y'/BE_BM_`y'`0m'.xlsx", replace
			}

		if _rc != 0{
			noisily: di "Base `y'_`m' no encontrada. Actualizar más tarde"
			exit			
		}			
		}
	}
}
}

//Process of checking that excel files
clear
forvalues y = 2023 / $y1  {
	forvalues m = $m0 / $m1 {
		local 0m : di %02.0f `m'
		capture import excel using "${dataBE}/`y'/BE_BM_`y'`0m'.xlsx", describe
		if _rc != 0{
			noisily: di "corrupted file detected at `y'`0m'"
			capture: rm "${dataBE}/`y'/BE_BM_`y'`0m'.xlsx"
		}
	}
}
*/


*=====================================
* ICAP
*======================================
quietly{
*Loop over time
forvalues y = $y0 / $y1  {
	forvalues m = $m0 / $m1 {
			local 0m : di %02.0f `m'
			local ym `y'`0m'
			scalar errorin = `y'`0m'
	
		clear
			*Importing the excel file. Specifically the sheet Art_121
			if tm(`y'm`m') <= tm(2017,12){
				local c_range_i "B7:B7"
				local c_range_v "B9:F57"
			}
			if tm(`y'm`m') <= tm(2019m7){
				local c_range_i "B7:B7"
				local c_range_v "B10:F61"
			}
			if tm(`y'm`m') < tm(2023m1){
				local c_range_i "B8:B8"
				local c_range_v "B8:F60"
			}
			if tm(`y'm`m') >  tm(2022m12){
				local c_range_i "B7:B7"
				local c_range_v "B9:F60"
			}
			
			*Importing the notes (TRY MULTIPLE TIMES)
			local m_opts cellrange(`c_range_i') clear allstring
			capture{
			if ym(`y',`m') <= ym(2017, 12) import excel "${dataBE}/`y'/BE_BM_`ym'.xls", sheet("Art_121 ") `m_opts'
			if ym(`y',`m') > ym(2017, 12) & ym(`y',`m') <= ym(2019, 6) import excel "${dataBE}/`y'/BE_BM_`ym'.xls", sheet("Art_121 ") `m_opts'
			if ym(`y',`m') == ym(2019, 7) import excel "${dataBE}/`y'/BE_BM_`ym'.xlsx", sheet("Art_121 ") `m_opts'
			if ym(`y',`m') == ym(2019, 8) import excel "${dataBE}/`y'/BE_BM_`ym'.xlsx", sheet("Art_121") `m_opts'
			if ym(`y',`m') >= ym(2019, 9) & ym(`y',`m') <= ym(2020, 3) import excel "${dataBE}/`y'/BE_BM_`ym'.xlsm", sheet("Art_121") `m_opts'
			if ym(`y',`m') >= ym(2020, 4) & ym(`y',`m') <= ym(2020, 8) import excel "${dataBE}/`y'/BE_BM_`ym'.xlsx", sheet("Art_121") `m_opts'
			if ym(`y',`m') >= ym(2020, 9) & ym(`y',`m') <= ym(2020, 10) import excel "${dataBE}/`y'/BE_BM_`ym'.xlsm", sheet("Art_121") `m_opts'
			if ym(`y',`m') >= ym(2020, 11) & ym(`y',`m') <= ym(2021, 2) import excel "${dataBE}/`y'/BE_BM_`ym'.xlsx", sheet("Art_121") `m_opts'
			if ym(`y',`m') >= ym(2021, 3) & ym(`y',`m') <= ym(2021, 11) import excel "${dataBE}/`y'/BE_BM_`ym'.xlsm", sheet("Art_121") `m_opts'
			if ym(`y',`m') >= ym(2021, 12) import excel "${dataBE}/`y'/BE_BM_`ym'.xlsx", sheet("Art_121") `m_opts'
			} 
			if _rc != 0 {
				di "ERROR DETECTADO EN `y'm`m'"
				continue
			}
				rename B icap_info
				gen monthly_date = ym(`y',`m')
				save "${dataBE}\[rm]infoICAP_`y'_`m'.dta", replace
				
			*Importing the values //No capture is needed
			local m_opts cellrange(`c_range_v') clear allstring
			if ym(`y',`m') <= ym(2019, 6) import excel "${dataBE}/`y'/BE_BM_`ym'.xls", sheet("Art_121 ") `m_opts'
			if ym(`y',`m') == ym(2019, 7) import excel "${dataBE}/`y'/BE_BM_`ym'.xlsx", sheet("Art_121 ") `m_opts'
			if ym(`y',`m') == ym(2019, 8) import excel "${dataBE}/`y'/BE_BM_`ym'.xlsx", sheet("Art_121") `m_opts'
			if ym(`y',`m') >= ym(2019, 9) & ym(`y',`m') <= ym(2020, 3) import excel "${dataBE}/`y'/BE_BM_`ym'.xlsm", sheet("Art_121") `m_opts'
			if ym(`y',`m') >= ym(2020, 4) & ym(`y',`m') <= ym(2020, 8) import excel "${dataBE}/`y'/BE_BM_`ym'.xlsx", sheet("Art_121") `m_opts'
			if ym(`y',`m') >= ym(2020, 9) & ym(`y',`m') <= ym(2020, 10) import excel "${dataBE}/`y'/BE_BM_`ym'.xlsm", sheet("Art_121") `m_opts'
			if ym(`y',`m') >= ym(2020, 11) & ym(`y',`m') <= ym(2021, 2) import excel "${dataBE}/`y'/BE_BM_`ym'.xlsx", sheet("Art_121") `m_opts'
			if ym(`y',`m') >= ym(2021, 3) & ym(`y',`m') <= ym(2021, 11) import excel "${dataBE}/`y'/BE_BM_`ym'.xlsm", sheet("Art_121") `m_opts'
			if ym(`y',`m') >= ym(2021, 12) import excel "${dataBE}/`y'/BE_BM_`ym'.xlsx", sheet("Art_121") `m_opts'
			
			
			*Renaming variables because they are read different in BE
			ds
			local var_list `r(varlist)'
			capture: rename (`var_list') (bank_str ccf_be ccb_be icap_be cat_cap_be)
				destring  ccf_be ccb_be icap_be, force replace
			
			gen monthly_date = ym(`y',`m')
			merge m:1 monthly_date using "${dataBE}\[rm]infoICAP_`y'_`m'.dta", nogenerate
				compress
			noisily di "." _cont
			save "${dataBE}\[rm]BE_BM_`y'_`m'.dta", replace

	} // End month cycle
} // End year cycle

*Appending all values and cleaning
clear
forvalues y = $y0 / $y1  {
	forvalues m = $m0 / $m1 {
		capture: append using "${dataBE}\[rm]BE_BM_`y'_`m'.dta", force
			capture: rm "${dataBE}\[rm]BE_BM_`y'_`m'.dta"
			capture: rm "${dataBE}\[rm]infoICAP_`y'_`m'.dta"
	}
}

*Renaming banks
replace bank_str = "Banca Múltiple" if strpos(bank_str, "Banca Múltiple") > 0
replace bank_str = "Banca Múltiple" if strpos(bank_str, "Sistema") > 0
replace bank_str = subinstr(bank_str, " *", "", .)
replace bank_str = subinstr(bank_str, "*", "", .)
replace bank_str = "Banco Covalto" if strpos(bank_str, "Finterra") > 0
replace bank_str = "BNP Paribas México" if strpos(bank_str, "BNP") > 0
replace bank_str = "Ve por Más" if strpos(bank_str, "Ve por Más") > 0
replace bank_str = "BBVA México" if strpos(bank_str, "BBVA") > 0
replace bank_str = "Bancrea" if strpos(bank_str, "Bancrea") > 0
replace bank_str = "KEB Hana México" if strpos(bank_str, "Hana") > 0
replace bank_str = "J.P. Morgan" if strpos(bank_str, "Morgan") > 0
replace bank_str = "Accendo Banco" if strpos(bank_str, "Accendo") > 0
replace bank_str = "ABC Capital" if strpos(bank_str, "ABC") > 0
replace bank_str = "Famsa" if strpos(bank_str, "Famsa") > 0
replace bank_str = "Bancoppel" if strpos(bank_str, "BanCoppel") > 0
replace bank_str = "Intercam Banco" if strpos(bank_str, "Inter Banco") > 0 
replace bank_str = "Credit Suisse" if strpos(bank_str, "Suisse") > 0 
replace bank_str = "UBS" if strpos(bank_str, "UBS") > 0 

drop if strpos(bank_str, "CCB") > 0
drop if strpos(bank_str, "ICAP") > 0
drop if strpos(bank_str, "CCF") > 0
drop if strpos(bank_str, "CCF") > 0
drop if strpos(bank_str, "Indice") > 0
drop if strpos(bank_str, "Índice") > 0 
drop if strpos(bank_str, "INSTITU") > 0
drop if strpos(bank_str, "Instituc") > 0
drop if strpos(bank_str, "omisi") > 0
drop if strpos(bank_str, "Cifras") > 0
drop if strpos(bank_str, "CIFRAS") > 0
 
label variable ccf_be "CCF -- Boletines Estadísticos"
label variable ccb_be "CCB -- Boletines Estadísticos"
label variable icap_be "CCI -- Boletines Estadísticos"
compress
drop if bank_str == ""

save "${dataBE}\ICAP_info.dta", replace
}


*=====================================
* Activos y resultados netos
*======================================
quietly{
forvalues y = $y0 / $y1  {
	forvalues m = $m0 / $m1{
		
	local 0m : di %02.0f `m'
	local ym `y'`0m'
	scalar errorin = `y'`0m'
	clear
	//Loading datasets
		capture {
		if ym(`y',`m') <= ym(2019, 6) import excel "${dataBE}/`y'/BE_BM_`ym'.xls", sheet("Pm2") cellrange(B6:AL58)  clear allstring
		if ym(`y',`m') == ym(2019, 7) | ym(`y',`m') == ym(2019, 8) import excel "${dataBE}/`y'/BE_BM_`ym'.xlsx", sheet("Pm2") cellrange(B6:AL58)  clear  allstring
		if ym(`y',`m') >= ym(2019, 9) & ym(`y',`m') <= ym(2020, 3) import excel "${dataBE}/`y'/BE_BM_`ym'.xlsm", sheet("Pm2") cellrange(B6:AL58)  clear  allstring
		if ym(`y',`m') >= ym(2020, 4) & ym(`y',`m') <= ym(2020, 8) import excel "${dataBE}/`y'/BE_BM_`ym'.xlsx", sheet("Pm2") cellrange(B6:AL58)  clear allstring
		if ym(`y',`m') >= ym(2020, 9) & ym(`y',`m') <= ym(2020, 10) import excel "${dataBE}/`y'/BE_BM_`ym'.xlsm", sheet("Pm2") cellrange(B6:AL58)  clear allstring
		if ym(`y',`m') >= ym(2020, 11) & ym(`y',`m') <= ym(2021, 2) import excel "${dataBE}/`y'/BE_BM_`ym'.xlsx", sheet("Pm2") cellrange(B6:AL58)  clear allstring
		if ym(`y',`m') >= ym(2021, 3) & ym(`y',`m') <= ym(2021, 11) import excel "${dataBE}/`y'/BE_BM_`ym'.xlsm", sheet("Pm2") cellrange(B6:AL58)  clear allstring
		if ym(`y',`m') >= ym(2021, 12) import excel "${dataBE}/`y'/BE_BM_`ym'.xlsx", sheet("Pm2") cellrange(B6:AL58) clear allstring
		}
		if _rc != 0 {
			continue
		}
		
		*Renaming variables
		keep (B G I M S Y AE AK)
			rename (B G I M S Y AE AK) (bank_str activo inv_val inv_instrfin cartera captn cap_cont res_net)
			
		*Adding labels
		label variable activo "Total activos (mdp)  -- Boletines Estadísticos"
		label variable inv_val "Inversión en valores(mdp) -- Boletines Estadísticos"
		label variable inv_instrfin "Inversión en instrumentos financieros (mdp) -- Boletines Estadísticos"
		label variable cartera "Total cartera (mdp) -- Boletines Estadísticos"
		label variable captn "Captación total (mdp) -- Boletines Estadísticos"
		label variable cap_cont "Capital contable (mdp) -- Boletines Estadísticos"
		label variable res_net "Resultado neto (mdp) -- Boletines Estadísticos"
		destring activo inv_val inv_instrfin cartera captn cap_cont res_net, replace force
			gen monthly_date = ym(`y',`m')
		compress
		
		save "${dataBE}\[rm]BE_BM_`y'_`m'.dta", replace
			noisily di "." _cont

	} // End month loop
} // End year loop

*Appending and cleaning datasets
clear
forvalues y = $y0 / $y1  {
	forvalues m = $m0 / $m1{
		capture: append using "${dataBE}\[rm]BE_BM_`y'_`m'.dta"
		capture: rm "${dataBE}\[rm]BE_BM_`y'_`m'.dta"
	}
}

*Renaming banks
replace bank_str = "Banca Múltiple" if strpos(bank_str, "Sistema") > 0
replace bank_str = subinstr(bank_str, " *", "", .)
replace bank_str = subinstr(bank_str, "*", "", .)
replace bank_str = "Banco Covalto" if strpos(bank_str, "Finterra") > 0
replace bank_str = "BNP Paribas México" if strpos(bank_str, "BNP") > 0
replace bank_str = "Ve por Más" if strpos(bank_str, "Ve por Más") > 0
replace bank_str = "BBVA México" if strpos(bank_str, "BBVA") > 0
replace bank_str = "Bancrea" if strpos(bank_str, "Bancrea") > 0
replace bank_str = "KEB Hana México" if strpos(bank_str, "Hana") > 0
replace bank_str = "J.P. Morgan" if strpos(bank_str, "Morgan") > 0
replace bank_str = "Accendo Banco" if strpos(bank_str, "Accendo") > 0
replace bank_str = "ABC Capital" if strpos(bank_str, "ABC") > 0
replace bank_str = "Famsa" if strpos(bank_str, "Famsa") > 0
replace bank_str = "Bancoppel" if strpos(bank_str, "BanCoppel") > 0
replace bank_str = "Intercam Banco" if strpos(bank_str, "Inter Banco") > 0 
replace bank_str = "Credit Suisse" if strpos(bank_str, "Suisse") > 0 
replace bank_str = "UBS" if strpos(bank_str, "UBS") > 0 

*Renaming variables
rename (activo inv_val inv_instrfin cartera captn cap_cont res_net) ///
	(activo_be inv_val_be inv_instrfin_be cartera_be captn_be cap_cont_be res_net_be)
compress
drop if bank_str == ""

save "${dataBE}\ActivosInfo.dta", replace
}



*=====================================
* ROA / ROE (flujos)
*======================================
quietly{
*Time loop
forvalues y = $y0 / $y1  {
	forvalues m = $m0 / $m1{
	clear
	local 0m : di %02.0f `m'
	local ym `y'`0m'
	scalar errorin = `y'`0m'
	//Loading datasets
		capture {
		if ym(`y',`m') <= ym(2019, 6) import excel "${dataBE}/`y'/BE_BM_`ym'.xls", sheet("Indicadores") cellrange(B6:H58) clear allstring
		if ym(`y',`m') == ym(2019, 7) | ym(`y',`m') == ym(2019, 8) import excel "${dataBE}/`y'/BE_BM_`ym'.xlsx", sheet("Indicadores") cellrange(B6:H58)  clear  allstring
		if ym(`y',`m') >= ym(2019, 9) & ym(`y',`m') <= ym(2020, 3) import excel "${dataBE}/`y'/BE_BM_`ym'.xlsm", sheet("Indicadores") cellrange(B6:H58)  clear  allstring
		if ym(`y',`m') >= ym(2020, 4) & ym(`y',`m') <= ym(2020, 8) import excel "${dataBE}/`y'/BE_BM_`ym'.xlsx", sheet("Indicadores") cellrange(B6:H58)  clear allstring
		if ym(`y',`m') >= ym(2020, 9) & ym(`y',`m') <= ym(2020, 10) import excel "${dataBE}/`y'/BE_BM_`ym'.xlsm", sheet("Indicadores") cellrange(B6:H58)  clear allstring
		if ym(`y',`m') >= ym(2020, 11) & ym(`y',`m') <= ym(2021, 2) import excel "${dataBE}/`y'/BE_BM_`ym'.xlsx", sheet("Indicadores") cellrange(B6:H58)  clear allstring
		if ym(`y',`m') >= ym(2021, 3) & ym(`y',`m') <= ym(2021, 11) import excel "${dataBE}/`y'/BE_BM_`ym'.xlsm", sheet("Indicadores") cellrange(B6:H58)  clear allstring
		if ym(`y',`m') >= ym(2021, 12) import excel "${dataBE}/`y'/BE_BM_`ym'.xlsx", sheet("Indicadores") cellrange(B6:H58)clear allstring
		}
		if _rc != 0 {
			continue
		}
		keep (B E H)
			rename (B E H) (bank_str roa_flujo roe_flujo)
			destring roa_flujo roe_flujo, replace force
			gen monthly_date = ym(`y',`m')
		compress
		save "${dataBE}\[rm]BE_BM_`y'_`m'.dta", replace
		noisily di "." _cont
	} // End month loop
} // End year loop

*Appending and cleaning datasets
clear
forvalues y = $y0 / $y1  {
	forvalues m = $m0 / $m1{
		capture: append using "${dataBE}\[rm]BE_BM_`y'_`m'.dta"
		capture: rm "${dataBE}\[rm]BE_BM_`y'_`m'.dta"
	}
}

*Renaming banks
replace bank_str = "Banca Múltiple" if strpos(bank_str, "Sistema") > 0
replace bank_str = subinstr(bank_str, " *", "", .)
replace bank_str = subinstr(bank_str, "*", "", .)
replace bank_str = "Banco Covalto" if strpos(bank_str, "Finterra") > 0
replace bank_str = "BNP Paribas México" if strpos(bank_str, "BNP") > 0
replace bank_str = "Ve por Más" if strpos(bank_str, "Ve por Más") > 0
replace bank_str = "BBVA México" if strpos(bank_str, "BBVA") > 0
replace bank_str = "Bancrea" if strpos(bank_str, "Bancrea") > 0
replace bank_str = "KEB Hana México" if strpos(bank_str, "Hana") > 0
replace bank_str = "J.P. Morgan" if strpos(bank_str, "Morgan") > 0
replace bank_str = "Accendo Banco" if strpos(bank_str, "Accendo") > 0
replace bank_str = "ABC Capital" if strpos(bank_str, "ABC") > 0
replace bank_str = "Famsa" if strpos(bank_str, "Famsa") > 0
replace bank_str = "Bancoppel" if strpos(bank_str, "BanCoppel") > 0
replace bank_str = "Intercam Banco" if strpos(bank_str, "Inter Banco") > 0 
replace bank_str = "Credit Suisse" if strpos(bank_str, "Suisse") > 0 
replace bank_str = "UBS" if strpos(bank_str, "UBS") > 0 

*Collapsing
collapse (firstnm) roa_flujo roe_flujo, by(bank_str monthly_date)
	compress
	label variable roa_flujo "ROA flujo -- Boletines Estadísticos"
	label variable roe_flujo "ROA flujo -- Boletines Estadísticos"
	compress
	drop if bank_str == ""
save "${dataBE}\ROAflujo_info.dta", replace
}



*=====================================
* CARTERAS (SALDOS, IMOR, P.E.)
*======================================
quietly{
local c_files "CCT" "CCE" "CCEF" "CCGT" "CCCT" ///
			  "CCCTC" "CCCN" "CCCnrP" "CCCAut" ///
			  "CCCAdq BiMu" "CCOAC"  "CCCnrO" "CCV" "CCCMicro"
	
*Loop over credit types
foreach sheet in `c_files' {
	local V : di "`sheet'"  // Use local macro to hold the current element
	local v = strlower("`V'")
	local v = subinstr("`v'", " ", "", .)
		noisily di "`V' -> `v'" _cont
	
*Loop Over Years
forvalues y = $y0 / $y1  {
	forvalues m = $m0 / $m1 {
	clear
	local 0m : di %02.0f `m'
	local ym `y'`0m'
	scalar errorin = `y'`0m'
	capture {
	if ym(`y',`m') <= ym(2019, 6) import excel "${dataBE}/`y'/BE_BM_`ym'.xls", sheet("`V'") cellrange(B6:N58) clear
	if ym(`y',`m') == ym(2019, 7) | ym(`y',`m') == ym(2019, 8) import excel "${dataBE}/`y'/BE_BM_`ym'.xlsx", sheet("`V'") cellrange(B6:N58) clear  allstring
	if ym(`y',`m') >= ym(2019, 9) & ym(`y',`m') <= ym(2020, 3) import excel "${dataBE}/`y'/BE_BM_`ym'.xlsm", sheet("`V'") cellrange(B6:N58) clear  allstring
	if ym(`y',`m') >= ym(2020, 4) & ym(`y',`m') <= ym(2020, 8) import excel "${dataBE}/`y'/BE_BM_`ym'.xlsx", sheet("`V'") cellrange(B6:N58) clear allstring
	if ym(`y',`m') >= ym(2020, 9) & ym(`y',`m') <= ym(2020, 10) import excel "${dataBE}/`y'/BE_BM_`ym'.xlsm", sheet("`V'") cellrange(B6:N58) clear allstring
	if ym(`y',`m') >= ym(2020, 11) & ym(`y',`m') <= ym(2021, 2) import excel "${dataBE}/`y'/BE_BM_`ym'.xlsx", sheet("`V'") cellrange(B6:N58) clear allstring
	if ym(`y',`m') >= ym(2021, 3) & ym(`y',`m') <= ym(2021, 11) import excel "${dataBE}/`y'/BE_BM_`ym'.xlsm", sheet("`V'") cellrange(B6:N58) clear allstring
	if ym(`y',`m') >= ym(2021, 12) import excel "${dataBE}/`y'/BE_BM_`ym'.xlsx", sheet("`V'") cellrange(B6:N58) clear allstring
	}
	if _rc != 0 {
		continue
	} 	
	keep (B E H K N)
		rename (B E H K N) (bank_str cre_`v' imor_`v' icor_`v' pe_`v')
		gen monthly_date = ym(`y',`m')
		destring cre_`v' imor_`v' icor_`v' pe_`v', replace force
	compress
	save "${dataBE}\[rm]BE_BM_`y'_`m'.dta", replace
	noisily: di "." _cont
	} // Fin del ciclo de meses
} // Fin del ciclo de años

*Appending variables
clear
forvalues y = $y0 / $y1  {
	forvalues m = $m0 / $m1{
		capture: append using "${dataBE}\[rm]BE_BM_`y'_`m'.dta", force
		if _rc != 0 {
			continue
		}
		capture: rm "${dataBE}\[rm]BE_BM_`y'_`m'.dta"
	*	if _rc != 0 {
	*		continue
	*	}

	}
}

keep bank_str monthly_date cre_`v' imor_`v' icor_`v' pe_`v'

*Renaming banks
replace bank_str = "Banca Múltiple" if strpos(bank_str, "Sistema") > 0
replace bank_str = subinstr(bank_str, " *", "", .)
replace bank_str = subinstr(bank_str, "*", "", .)
replace bank_str = "Banco Covalto" if strpos(bank_str, "Finterra") > 0
replace bank_str = "BNP Paribas México" if strpos(bank_str, "BNP") > 0
replace bank_str = "Ve por Más" if strpos(bank_str, "Ve por Más") > 0
replace bank_str = "BBVA México" if strpos(bank_str, "BBVA") > 0
replace bank_str = "Bancrea" if strpos(bank_str, "Bancrea") > 0
replace bank_str = "KEB Hana México" if strpos(bank_str, "Hana") > 0
replace bank_str = "J.P. Morgan" if strpos(bank_str, "Morgan") > 0
replace bank_str = "Accendo Banco" if strpos(bank_str, "Accendo") > 0
replace bank_str = "ABC Capital" if strpos(bank_str, "ABC") > 0
replace bank_str = "Famsa" if strpos(bank_str, "Famsa") > 0
replace bank_str = "Bancoppel" if strpos(bank_str, "BanCoppel") > 0
replace bank_str = "Intercam Banco" if strpos(bank_str, "Inter Banco") > 0 
replace bank_str = "Credit Suisse" if strpos(bank_str, "Suisse") > 0 
replace bank_str = "UBS" if strpos(bank_str, "UBS") > 0 


destring cre_`v' imor_`v' icor_`v' pe_`v', replace force
compress
drop if bank_str == ""
save "${dataBE}\Cartera`v'_info.dta", replace
noisily: di "SUCCESS"
}
}



*=====================================
* FINAL. INTEGRACIÓN
*======================================
quietly{
use "${dataBE}\ICAP_info.dta", clear
	drop if bank_str == ""
	
*Merge with other datasets
merge 1:1 bank_str monthly_date using "${dataBE}\ActivosInfo.dta", nogenerate
	drop if bank_str == ""
	
merge 1:1 bank_str monthly_date using "${dataBE}\ROAflujo_info.dta", nogenerate

noisily: di as error "A continuación, revisa si hay algún banco."
noisily: di as error "Si es vacío es que todo está bien"
noisily: di as error "Se muestran aquellos bancos sin código CNBV"
*Appending datasets
*Loop over credit types
local c_files "CCT" "CCE" "CCEF" "CCGT" "CCCT" ///
			  "CCCTC" "CCCN" "CCCnrP" "CCCAut" ///
			  "CCCAdq BiMu" "CCOAC"  "CCCnrO" "CCV" "CCCMicro"
			  
foreach c_file in `c_files' {
	local V : di "`c_file'"  // Use local macro to hold the current element
	local v = strlower("`V'")
	local v = subinstr("`v'", " ", "", .)
	
		merge 1:1 bank_str monthly_date using "${dataBE}\Cartera`v'_info.dta"
			*rm "${dataBE}\Cartera`v'_info.dta"  // Cleaning
		rename _merge merge_`v'
		drop if bank_str == ""
}  // END credit_type loop

drop merge_*

*Now saving labels
foreach c_file in `c_files' {
		local c_file : di "`c_file'"  // Use local macro to hold the current element
		local v = strlower("`c_file'")
		local v = subinstr("`v'", " ", "", .)
		if "`c_file'" == "CCT" local w "Total"  
		if "`c_file'" == "CCE" local w "Empresas"  
		if "`c_file'" == "CCEF" local w "Ent. Financieras"  
		if "`c_file'" == "CCGT" local w "Ent. Gubernamentales"  
		if "`c_file'" == "CCCT" local w "Consumo"  
		if "`c_file'" == "CCCTC" local w "Tarjetas"  
		if "`c_file'" == "CCCN" local w "Nómina"  
		if "`c_file'" == "CCCnrP" local w "Personales"  
		if "`c_file'" == "CCCAut" local w "Automotriz"  
		if "`c_file'" == "CCCAdq BiMu" local w "Bienes Muebles"  
		if "`c_file'" == "CCOAC" local w "Arrendamiento capitalizable"  
		if "`c_file'" == "CCCMicro" local w "Micro" 
		if "`c_file'" == "CCCnrO" local w "Otros" 
		if "`c_file'" == "CCV" local w "Vivienda" 

		label variable cre_`v' "Crédito `w' (mdp) -- Bal mensuales (2021); Boletines estadísticos (2022+)"
		label variable imor_`v' "IMOR `w' (%) -- Bal mensuales (2021); Boletines estadísticos (2022+)"
		label variable icor_`v' "Cobertura `w' (%) -- Bal mensuales (2021); Boletines estadísticos (2022+)"
		label variable pe_`v' "Pérdidas Esperadas `w' (%) -- Boletines estadísticos"
}

rename bank_str bank_labels
	replace bank_labels = "Finterra" if bank_labels == "Banco Covalto"
	replace bank_labels = "Famsa" if bank_labels == "Banco Ahorro Famsa"

*Adding bank codes
merge m:1 bank_labels using "$root\Osvaldo\Otros_DTA\Covars\Banks_ID.dta", keepusing(bank_id)
	replace bank_id = 0 if strpos(bank_labels, "Banca Múltiple") > 0 
		replace _merge = 3 if bank_id == 0
	replace bank_id = 40164 if bank_labels == "BNP Paribas México"
		replace _merge = 3 if bank_labels == "BNP Paribas México"
	replace bank_id = 40124 if bank_labels == "Deutsche Bank"
		replace _merge = 3 if bank_labels == "Deutsche Bank"
	replace bank_id = 40160 if bank_labels == "Banco S3"
		replace _merge = 3 if bank_labels == "Banco S3"
	replace bank_id = 40137 if bank_labels == "Bancoppel"
		replace _merge = 3 if bank_labels == "Bancoppel"
	replace bank_id = 40037 if bank_labels == "Interacciones"
		replace _merge = 3 if bank_labels == "Interacciones"
		replace bank_id = 40131 if bank_labels == "Famsa"
		replace _merge = 3 if bank_labels == "Famsa"
	replace bank_id = 40108 if strpos(bank_labels, "Tokyo") > 0 
		replace _merge = 3 if bank_id == 40108
	replace bank_id = 40134 if strpos(bank_labels, "Mart") > 0 
		replace _merge = 3 if bank_id == 40134
	replace bank_id = 40146 if strpos(bank_labels, "Bicentenario") > 0 
		replace _merge = 3 if bank_id == 40146
		
	noisily: tab bank_labels if _merge == 1  // Bancos sin código
	keep if _merge == 3
	drop _merge
	
*Applying last labs
$run_tags
order bank_id monthly_date cre_* imor_* icor_* pe_*
sort bank_id monthly_date
	format %tm monthly_date
compress

encode icap_info, gen(icap_be_notes)
	label variable icap_be_notes "Fecha del dato de icap_be"
drop bank_labels icap_info

//Charging last date
noisily di "Aplicando formatos para mejor lectura"
preserve
	gen year = year(dofm(monthly_date))
		su year
		global ymax = `r(max)'
	gen month = month(dofm(monthly_date))
		su month if year == ${ymax}
		global mmax = `r(max)'	
restore

ds, has(type numeric)
foreach var of varlist `r(varlist)' {
    summarize `var' if bank_id == 0, meanonly
    if r(mean) > 1000 {
        format `var' %12.1fc
    }
	else {
		format `var' %9.4f
	}
}
format %tm monthly_date

label data "Inf. de Boletines al ${ymax}m${mmax}. Saldos en mdp. Last update: `c(current_date)' by `c(username)'"
save "$dataS\[12]Indicadores_Bancarios_BE.dta", replace
compress
noisily: di as result "Correctamente actualizada al ${ymax}m${mmax}"


	rm "${dataBE}\ICAP_info.dta"
	rm "${dataBE}\ActivosInfo.dta"
	rm "${dataBE}\ROAflujo_info.dta"
	
}


