/*
*Instrucciones
	*Descargar las covariables de los links de abajo
	*Copiar todas las variables a otra hoja de excel
	*Trasponerlas en valores para dejar el nombre de los bancos en las filas
	*Copiarlas a formato de STATA usando <<edit>>

*Links
*http://portafoliodeinformacion.cnbv.gob.mx/bm1/Paginas/infosituacion.aspx
*http://portafoliodeinformacion.cnbv.gob.mx/bm1/Paginas/alertas.aspx

*Actualización
	*logsV2: Incorporación directa de los links y mejora en etiquetas

*/

***Carga de ubicación
local usuario substr( "`c(username)'",1,5) //Para funcionar con cualquier usuario en servidor
if `usuario'== "Usuar" global root "F:\DARMACRO\" 
else if `usuario' != "Usuar" global root "\\Statadgef\darmacro\"
	global home "$root\Osvaldo\"
	global source "$home\Data_CNBV_updated\"
	global mun_char "$root\Data\Municipalities Characteristics\"
		global main "$root\Data\Bank Data\"
			global dataS "$main\data\Stata"
			global dataR "$main\data\Raw"
			global results "$main\results"
			global graphs "$main\graphs"
			global temp "$main\temp"
			global logs "$main\log"	
			
*============================= BALANCES MENSUALES ================================
import excel "$dataR\(11-OB)CNBV_data_2021_R0.xlsx", sheet("Hoja1") firstrow clear

rename Concepto bank_labels
	replace bank_labels = bank_labels[_n-1] if bank_labels == ""
rename B periodo
	gen year = floor(periodo/100)
	gen month = periodo - year * 100
	gen monthly_date = ym(year, month)
		format monthly_date %tm
rename ACTIVO activo
rename CarteradeCréditoNeta cre_tot
rename (Actividadempresa AL TarjetadeCrédit Personales Nómina Automotriz AdquisicióndeBi OperacionesdeArr OtrosCréditosde) (cre_emp cre_emp_r cre_tdc cre_per cre_nom cre_aut cre_abc cre_arr cre_otr)
rename (AY AZ BA BB BC BD BE) (cre_tdc_r cre_per_r cre_nom_r cre_aut_r cre_abc_r cre_arr_r cre_otr_r)
rename CréditosalaVivienda cre_viv
rename (Actividadempresarial BS BT BU BV BW BX BY Créditosalavivienda) (cre_ven_emp cre_ven_tdc cre_ven_per cre_ven_nom cre_ven_aut cre_ven_abc cre_ven_arr cre_ven_otr cre_ven_viv)

keep bank_labels activo year month monthly_date periodo cre_*
gen  time_monthly = monthly_date

foreach v of varlist activo- cre_ven_viv{
	replace `v' = 0 if `v' == .
}
foreach v in emp per nom aut abc arr otr{
	gen imor_`v' = cre_ven_`v' / (cre_`v' + cre_`v'_r) * 100
}
gen imor_viv = cre_ven_viv/cre_viv * 100
compress

merge m:1 bank_labels using "$root\Osvaldo\Otros_DTA\Covars\Banks_ID.dta", keepusing(bank_id)
	replace bank_id = 0 if bank_labels == "Total Banca Múltiple"
	keep if _merge == 3 | bank_id == 0
	drop _merge
order bank_id monthly_date
sort bank_id monthly_date

compress
label data "Contiene valores de activos, cartera y morosidad de 2021"
save "$dataS\[11-OB]R0_BalancesMensuales2021.dta", replace


*============================= RAZONES MENSUALES ================================
*Parche del ICAP porque no se actualizaron las últimas razones mensuales
import excel "$dataR\(11-OB)parche_icap21m12.xlsx", sheet("Hoja1") firstrow clear 
	gen monthly_date = tm(2021m12)
	rename ICAP icap
	save "$dataR\[11-OB]parche_icap21m12.dta", replace
import excel "$dataR\(11-OB)CNBV_data_2021_R6.xlsx", sheet("Hoja1") firstrow clear
rename Indicador bank_labels
rename B periodo
	gen year = floor(periodo/100)
	gen month = periodo - year * 100
	gen monthly_date = ym(year, month)
		format monthly_date %tm
		
rename (IMORCarteratotal IMORActividadempresa IMORCarteratotaldeconsu IMORTarjetadeCrédit IMORPersonales IMORNómina IMORABCD IMORAutomotriz IMORAdqdeBienesMu IMOROpsdeArrendami IMOROtrosCréditosde IMORCarteratotaldevivie IMORMediayResidencial IMORDeInterésSocial) (imor_tot imor_emp imor_con imor_tdc imor_per imor_nom imor_abc imor_aut imor_abm imor_arr imor_otr imor_viv imor_viv_res imor_viv_int)
rename (IMORajustadoCarteratotal IMORajustadoActividadempresar AA IMORajustadoTarjetadeCrédito IMORajustadoPersonales IMORajustadoNómina IMORajustadoABCD IMORajustadoAutomotriz IMORajustadoAdqdeBienesMue IMORajustadoOpsdeArrendamie IMORajustadoOtrosCréditosde IMORajustadoCarteratotaldev) (imora_tot imora_emp imora_con imora_tdc imora_per imora_nom imora_abc imora_aut imora_abm imora_arr imora_otr imora_viv)
rename (ICORCarteratotal ICORActividadempresarial ICORCarteratotaldeconsumo ICORTarjetadeCrédito ICORPersonales ICORNómina ICORAutomotriz ICORAdqdeBienesMuebles ICOROpsdeArrendamientoCapit ICOROtrosCréditosdeConsumo ICORCarteratotaldevivienda ICORMediayResidencial ICORDeInterésSocial) (icor_tot icor_emp icor_con icor_tdc icor_per icor_nom icor_aut icor_abm icor_arr icor_otr icor_viv icor_viv_res icor_viv_int)
rename (LIQUIDEZactivosliquidospasiv ROA ROE ROAFlujo12Meses ROEFlujo12Meses ICAP EFICIENCIAOPERATIVA) (liq roa roe roa_flujo roe_flujo icap eficiencia)

keep bank_labels monthly_date year month periodo imor* imora* icor* liq roa roe roa_flujo roe_flujo icap eficiencia

compress
merge 1:1 bank_labels monthly_date using "$dataR\[11-OB]parche_icap21m12.dta", replace update nogenerate

merge m:1 bank_labels using "$root\Osvaldo\Otros_DTA\Covars\Banks_ID.dta", keepusing(bank_id)
	replace bank_id = 0 if bank_labels == "Total Banca Múltiple"
	keep if _merge == 3 | bank_id == 0
	drop _merge
order bank_id monthly_date
sort bank_id monthly_date

compress
label data "Contiene valores de morosidad, eficiencia y otras variables de 2021"
save "$dataS\[11-OB]R6_RazonesFinMensuales2021.dta", replace


*======================== NUEVAS RAZONES MENSUALES ================================
destring cve_institucion, replace
rename cve_institucion bank_id
rename cve_periodo monthly_date
replace monthly_date = monthly_date[_n -1] if monthly_date == .

gen year = floor(monthly_date/100)
gen month =  monthly_date - year*100
replace monthly_date = ym(year, month)

replace bank_id = 0 if bank_id == 5
keep bank_id monthly_date year month imor* imora* icor* liq roa roe roa_flujo roe_flujo ef_oper
save "$dataS\[11-OB]R6_RazonesFinMensuales2021.dta", replace


*============================= CAPITALIZACIÓN ================================
import excel "$dataR\(11-OB)CNBV_data_2021_R6b.xlsx", sheet("Hoja1") firstrow clear

rename Conceptos  bank_labels
rename B periodo 
	gen year = floor(periodo/100)
	gen month = periodo - year * 100
	gen monthly_date = ym(year, month)
		format monthly_date %tm
rename CapitalNeto capital_neto
	replace capital_neto = capital_neto / 1000000

keep bank_labels monthly_date year month capital_neto 

merge m:1 bank_labels using "$root\Osvaldo\Otros_DTA\Covars\Banks_ID.dta", keepusing(bank_id)
	replace bank_id = 0 if bank_labels == "Total Banca Múltiple"
	keep if _merge == 3 | bank_id == 0
	drop _merge
order bank_id monthly_date
sort bank_id monthly_date

compress
label data "Contiene valores de capital neto de 2021"
save "$dataS\[11-OB]R6b_AlertasTempranas2021.dta", replace

*INTEGRACIÓN DE TODAS LAS BASES
use "$dataS\[11-OB]R0_BalancesMensuales2021.dta", clear
	drop imor*  //porque existen en Razones financieras.
	merge 1:1 bank_id monthly_date using "$dataS\[11-OB]R6_RazonesFinMensuales2021.dta",  nogenerate nol noreport
	merge 1:1 bank_id monthly_date using "$dataS\[11-OB]R6b_AlertasTempranas2021.dta",  nogenerate nol noreport
	
global data_temp "\\Statadgef\darmacro\Data\Bank Data\Data\Temp"
copy "${dataS}\[11-OB]R0_BalancesMensuales2021.dta" "${data_temp}\[11-OB]R0_BalancesMensuales2021.dta", replace
copy "$dataS\[11-OB]R6_RazonesFinMensuales2021.dta" "${data_temp}\[11-OB]R6_RazonesFinMensuales2021.dta", replace
copy "$dataS\[11-OB]R6b_AlertasTempranas2021.dta" "${data_temp}\[11-OB]R6b_AlertasTempranas2021.dta", replace
	capture: rm "${dataS}\[11-OB]R0_BalancesMensuales2021.dta"
	capture: rm "$dataS\[11-OB]R6_RazonesFinMensuales2021.dta"
	capture: rm "$dataS\[11-OB]R6b_AlertasTempranas2021.dta"
compress
save "$dataS\[11-OB]Indicadores_Bancarios2021.dta", replace
