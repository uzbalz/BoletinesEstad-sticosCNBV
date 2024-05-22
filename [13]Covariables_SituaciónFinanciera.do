			
************************** INSTRUCCIONES *******************************
*Ir a la sección de <<Nuevas ediciones||Zona de juegos>> y añadir los nuevos indicadores
	*Añadir esos indicadores al último collapse
	*Añadir una etiqueta, estos indicadores deberían terminar con <<_own>>
	*Correr todo el do-file
	
*Para más información: https://www.cnbv.gob.mx/Anexos/Anexo%2034%20CUB.pdf

*Nota el código está listo para que todo quede en miles de millon es de pesos
*Todo está en términos nominales, pero se integra el INPC para futuras estimaciones

*Previamente debiste correr las versiones 11. y 12.

***Carga de ubicación
macro drop all
clear all
local usuario substr( "`c(username)'",1,5) //Para funcionar con cualquier usuario en servidor
if `usuario'== "Usuar" global root "F:\DARMACRO" 
else if `usuario' != "Usuar" global root "\\Statadgef\darmacro"
	global mun_char "$root\Data\Municipalities Characteristics"
		global main "$root\Data\Bank Data"
			global dataS "$main\data\Stata"
			global dataR "$main\data\Raw"
			global results "$main\results"
			global graphs "$main\graphs"
			global temp "$main\temp"
			global logs "$main\log"	
global run_tags do "$root\Osvaldo\Otros_DTA\etiquetas.do"

quietly{			
* =========================== PARTE 1 =================================
*************** IMPORTANDO BASES DE DATOS DE CNBV **********************
		*Y SE CONVIERTE A UN ARCHIVO DTA PARA MEJOR INTERPRETACIÓN
noisily di "P1. Descargando y guardando base de datos"

*Descargando directamente de CNBV
local cnbv_web "https://portafolioinfdoctos.cnbv.gob.mx/Documentacion/minfo/CSV/BM/040_R12A_1219_133.csv"

//Because there is no security in CNBV ssl
set sslrelax on  
	capture: import delimited using `cnbv_web', clear
	if _rc != 0 {
		noisily: di "Error detectado en CNBV. Si no necesita actualizar, omita, en otro caso, recurra a `cnbv_web'"
		use "${dataS}\[13a]040_R12A_1219_133.dta", clear
	} 
	else {
		noisily di "   Convirtiendo a millones de pesos"
		replace importe_pesos = importe_pesos / 1e6
		label data "Información de la CNBV. De la situación financiera."
		save "${dataS}\[13a]040_R12A_1219_133.dta", replace
	}
set sslrelax off


	su periodo //Detectando el valor a la fecha de hoy
	compress
save "${dataS}\Backups\SITUACIONFINANCIERA_`r(max)'", replace


*Fusionando con el catálogo de indicadores
import delimited "${dataR}\(11-OB)catalogo_R12A_1219_BM.csv", clear 
	compress
save "${dataS}\[11-OB]catalogo_R12A_1219_BM.dta", replace

*Mixing <<CONCEPTOS>>
use "${dataS}\[13a]040_R12A_1219_133.dta", clear
	merge m:1 concepto using "${dataS}\[11-OB]catalogo_R12A_1219_BM.dta"
	
*Creando variable de mes (monthly_date)
	gen year = floor(periodo/100)
	gen month = periodo - year*100
	gen time_monthly = ym(year, month)
		format time_monthly %tm
		gen monthly_date = time_monthly
	
*Creating system ID	
	rename institucion bank_id
	replace bank_id = 0 if bank_id == 5

*Determinanndo el mes máximo
	su monthly_date
		global yy = year(dofm(`r(max)'))
		global mm = month(dofm(`r(max)'))
		
	
	
* =========================== PARTE 2 =================================
***************    CONSTRUYENDO LOS INDICADORES  **********************
do "${root}\Data\Bank Data\Codes\Data Construction\[11A]Diccionario.do"

* Cargando los saldos
noisily: di "P2. Trabajando en la construcción de indicadores"

local x = 1
forvalues ce1 = 7/14{  // C. Etapa 1, créditos no restringidos
	if `ce1' < 10 {
	local c1r = `ce1' + 8   // 7 + 8 = 15 // C. Etapa 1, créditos restringidos
	local ce2 = `ce1' + 3   // 7+3 =10    // C. Etapa 2
	local ce3 = `ce1' + 19  // 7+19=26    // C. Etapa 3
	local cvr = `ce1' + 35  // 7 + 35 = 42 //Cartera valuada razonable
		egen cre_`x'_tot = total(importe_pesos) if ///
		concepto == 10180030700`ce1' | concepto == 1018004070`c1r' | ///
		concepto == 1018006060`ce2' | concepto == 1018009060`ce3'  | ///
		concepto == 1018012060`cvr', by(bank_id time_monthly)
			ereplace cre_`x'_tot = min(cre_`x'_tot), by(bank_id time_monthly)
			
		egen cre_`x' = total(importe_pesos) if ///
		concepto == 10180030700`ce1' | concepto == 1018004070`c1r' | ///
		concepto == 1018006060`ce2'  | ///
		concepto == 1018012060`cvr', by(bank_id time_monthly)
			ereplace cre_`x' = min(cre_`x'), by(bank_id time_monthly)
			
		egen cre_`x'_r = total(importe_pesos) if concepto == 1018012060`cvr', ///
		by(bank_id time_monthly)
			ereplace cre_`x'_r = min(cre_`x'_r), by(bank_id time_monthly)
			
		egen cre_ven_`x' = total(importe_pesos) if concepto == 1018009060`ce3', ///
		by(bank_id time_monthly)
			ereplace cre_ven_`x' = min(cre_ven_`x'), by(bank_id time_monthly)
		gen imor_`x' = cre_ven_`x' / cre_`x'_tot *100	
	}  //Fin primer if <10
	
	if `ce1' >= 10 {
	local c1r = `ce1' + 8
	local ce2 = `ce1' + 3
	local ce3 = `ce1' + 19
		egen cre_`x'_tot = total(importe_pesos) if ///
			concepto == 1018003070`ce1' | concepto == 1018004070`c1r' | ///
			concepto == 1018006060`ce2' | concepto == 101800906026`ce3' | ///
			concepto == 1018012060`cvr', by(bank_id time_monthly)
			ereplace cre_`x'_tot = min(cre_`x'_tot), by(bank_id time_monthly)
		
		egen cre_`x' = total(importe_pesos) if ///
			concepto == 1018003070`ce1' | concepto == 1018004070`c1r' | ///
			concepto == 1018006060`ce2' | concepto == 101800906026`ce3' ///
			, by(bank_id time_monthly)
			ereplace cre_`x' = min(cre_`x'), by(bank_id time_monthly)
		
		egen cre_`x'_r = total(importe_pesos) if ///
			concepto == 1018004070`c1r', by(bank_id time_monthly)
			ereplace cre_`x'_r = min(cre_`x'_r), by(bank_id time_monthly)
			
		egen cre_ven_`x' = total(importe_pesos) if concepto == 1018009060`ce3', ///
		by(bank_id time_monthly)
		ereplace cre_ven_`x' = min(cre_ven_`x'), by(bank_id time_monthly)
		gen imor_`x' = cre_ven_`x' / cre_`x'_tot *100
	}
	local x = `x' + 1
}
rename (*1*) (*tdc*)
rename (*2*) (*per*)
rename (*3*) (*nom*)
rename (*4*) (*aut*)
rename (*5*) (*abc*)
rename (*6*) (*arr*)
rename (*7*) (*mic*)
rename (*8*) (*otr*)

*Crédito empresarial
/*
Cartera de crédito con riesgo de crédito etapa 1	101800107001.-Actividad empresarial o comercial
Cartera de crédito con riesgo de crédito etapa 1r	101800207004.-Actividad empresarial o comercial
Cartera de crédito con riesgo de crédito etapa 2	101800506007.-Actividad empresarial o comercial
Cartera de crédito con riesgo de crédito etapa 3	101800806023.-Actividad empresarial o comercial
Cartera de crédito valuada a valor razonable	    101801106039.-Actividad empresarial o comercial
*/
*EMPRESAS
egen cre_emp_tot = total(importe_pesos) if  ///
		inlist(concepto, 101800107001, 101800207004, 101800506007, ///
						 101800806023, 101801106039), by(bank_id time_monthly)
		ereplace cre_emp_tot = min(cre_emp_tot), by(bank_id time_monthly)
		
	egen cre_emp = total(importe_pesos) if ///
		concepto == 101800107001 | concepto == 101800207004 | ///
		concepto == 101800506007 | ///
		concepto == 101801106039, by(bank_id time_monthly)
		ereplace cre_emp = min(cre_emp), by(bank_id time_monthly)
		
	egen cre_emp_r = total(importe_pesos) if ///
		concepto == 101800207004 , by(bank_id time_monthly)
		ereplace cre_emp_r = min(cre_emp_r), by(bank_id time_monthly)
		
	egen cre_ven_emp = total(importe_pesos) if concepto == 101800806023, ///
		by(bank_id time_monthly)
		ereplace cre_ven_emp = min(cre_ven_emp), by(bank_id time_monthly)
	gen imor_emp = cre_ven_emp / cre_emp_tot *100
	
*CRÉDITO a la vivienda
egen cre_viv_tot = total(importe_pesos) if inlist(concepto, 101800105003, ///
										101800205007, 101800305010, 101800405013), ///
										by(bank_id time_monthly)
egen cre_viv = total(importe_pesos) if inlist(concepto, 101800105003, ///
										101800205007, 101800405013), ///
										by(bank_id time_monthly)
egen cre_ven_viv = total(importe_pesos) if concepto == 101800305010, ///
										by(bank_id time_monthly)

gen imor_viv = cre_ven_viv / cre_viv_tot *100	

egen cre_tot_neta = total(importe_pesos) if concepto == 131800102001, by(bank_id time_monthly)

/*
egen cre_tot = total(importe_pesos) if ///
		concepto == 101800105001 | concepto == 101800105002 | concepto == 101800105003 ///
		| concepto == 101800205005 | concepto == 101800205006 | concepto == 101800205007 ///
		| concepto == 101800305008 | concepto == 101800305009 | concepto == 101800305010 ///
		| concepto == 101800405011 | concepto == 101800405012 |  concepto == 101800405013, ///
		by(bank_id time_monthly)
		*/
egen cre_tot = total(importe_pesos) if inlist(concepto, 101800105001, 101800105002, 101800105003, ///
                                          101800205005, 101800205006, 101800205007, ///
                                          101800305008, 101800305009, 101800305010, ///
                                          101800405011, 101800405012, 101800405013), ///
                          by(bank_id time_monthly)
	
egen cre_tot_ven = total(importe_pesos) if inlist(concepto, 101800305008, 101800305010), ///
                           by(bank_id time_monthly)
/*
Cartera de crédito con riesgo de crédito etapa 1	101800105001.-Créditos comerciales
Cartera de crédito con riesgo de crédito etapa 1	101800105002.-Créditos de consumo
Cartera de crédito con riesgo de crédito etapa 1	101800105003.-Créditos a la vivienda
Cartera de crédito con riesgo de crédito etapa 2	101800205005.-Créditos comerciales
Cartera de crédito con riesgo de crédito etapa 2	101800205006.-Créditos de consumo
Cartera de crédito con riesgo de crédito etapa 2	101800205007.-Créditos a la vivienda
Cartera de crédito con riesgo de crédito etapa 3	101800305008.-Créditos comerciales
Cartera de crédito con riesgo de crédito etapa 3	101800305009.-Créditos de consumo
Cartera de crédito con riesgo de crédito etapa 3	101800305010.-Créditos a la vivienda
Cartera de crédito valuada a valor razonable	    101800405011.-Créditos comerciales
Cartera de crédito valuada a valor razonable	    101800405012.-Créditos de consumo
Cartera de crédito valuada a valor razonable	    101800405013.-Créditos a la vivienda
*/

	
	
* ========================
* ZONA DE JUEGOS
* Aquí se pueden <<diseñar>> nuevos indicadores
*
**** Nuevas ediciones
* egen NEW_VAR = total(importe_pesos) if concepto == {CONCEPTO DEL CATÁLOGO}, by(bank_id time_monthly)

egen cap_trad = total(importe_pesos) if concepto == 200200001001, by(bank_id time_monthly)
egen cap_trad_exiginm = total(importe_pesos) if concepto == 200200102001, by(bank_id time_monthly)
egen cap_trad_deppzo = total(importe_pesos) if concepto == 200200102002, by(bank_id time_monthly)
egen cap_trad_titcre = total(importe_pesos) if concepto == 200200102003, by(bank_id time_monthly)
egen cap_trad_nomovs = total(importe_pesos) if concepto == 200200102004, by(bank_id time_monthly)


/*
Liquidez
*Activos líquidos = Activo líquido / Pasido líquido
	Activo Circulante = Efectivo y Equivalentes de Efectivo + Instrumentos Financieros Negociables sin restricción + Instrumentos Financieros para cobrar o vender sin restricción.
	
	Pasivo Circulante = Depósitos de exigibilidad inmediata + Préstamos interbancarios y de otros  organismos de exigibilidad inmediata + Préstamos interbancarios y de otros organismos de corto plazo.
	
*/
egen intrs_finan = total(importe_pesos) if inlist(concepto, 100600001001), ///
	by(bank_id time_monthly)

egen efectivo = total(importe_pesos) if inlist(concepto, 100200001001) , ///
	by(bank_id time_monthly)

egen capital_part_controlad = total(importe_pesos) if inlist(concepto, 440200001001), ///
	by(bank_id time_monthly)
egen capital_part_nocontrolad = total(importe_pesos) if inlist(concepto, 440400001001), ///
	by(bank_id time_monthly)

egen act_liq_own = total(importe_pesos) if ///
	concepto == 100200001001 | ///  // 100200001001.-Efectivo y equivalentes de efectivo
	concepto == 100400001001 | ///  // 100400001001.-Cuentas de margen (instrumentos financieros derivados)
	concepto == 100600103001 | ///  // 100600103001.-Instrumentos financieros negociables sin restricción
	 concepto == 100600203005, ///  // 100600203005.-Instrumentos financieros para cobrar o vender sin restricción
	by(bank_id time_monthly)

egen pas_liq_own = total(importe_pesos) if ///
	concepto == 200200102001 | ///  // 200200102001.-Depósitos de exigibilidad inmediata
	concepto == 200400102001 | ///  // 200400102001.-De exigibilidad inmediata
	concepto == 200400102002, ///   // 200400102002.-De corto plazo
	by(bank_id time_monthly)

	
/*
DEFINICIÓN:
ROA = Resultado neto del trimestre anualizado / Activo total promedio.
*/
egen resultado_neto = total(importe_pesos) if concepto == 430201204005, ///
	by(bank_id time_monthly)

egen activo = total(importe_pesos) if concepto == 100000000000, ///
	by(bank_id time_monthly)
	
/*
PARTE FINAL
Colapsar al nivel Banco-Tiempo
*/
collapse (mean) *own resultado_neto activo cre* imor* cap_trad* intrs_finan efectivo capital_part_controlad capital_part_nocontrolad, by(bank_id time_monthly)

*Generando variables adicionales y etiquetando
gen liq_own = act_liq_own / pas_liq_own * 100
	label variable liq_own "Ratio activo/pasivo --Anexo 34 SF"
	
gen roa_own = resultado_neto * 12 * 100 / activo 
	label variable roa_own "ROA (Resultado neto anualizado entre activos) --Anexo 34 SF"

	label variable pas_liq_own "Pasivos líquidos (mdp) --Anexo 34 SF"
	label variable act_liq_own "Activos líquidos (mdp) --Anexo 34 SF"
	label variable resultado_neto "R.N. (mdp) -- S.F."
	label variable activo "R.N. (mdp) -- S.F."
	
	label variable cap_trad "Captación Tradicional(mdp) -- S.F."
	label variable cap_trad_exiginm "Depósitos de exigibilidad inmediata (mdp)-- S.F."
	label variable cap_trad_deppzo "Depósitos a plazo (mdp)-- S.F."
	label variable cap_trad_titcre "Títulos de crédito emitidos (mdp)-- S.F."
	label variable cap_trad_nomovs "Cuenta global de captación sin movimientos (mdp)-- S.F."
	
	label variable intrs_finan "Inversiones en instrumentos financieros"
	label variable efectivo "Efectivo y equivalentes de efectivo"
	label variable capital_part_controlad "Capital contable: Participación Controladora"
	label variable capital_part_nocontrolad "Capital contable: Participación No Controladora"
	

rename (liq_own pas_liq_own act_liq_own) (liq act_liq pas_liq)

compress
label data "Indicadores de Situación Financiera (a partir de 2022)"
*save "${dataS}\[13]aux_indicators_R12A_1219_BM.dta", replace
	gen monthly_date = time_monthly
save "${dataS}\[13a]Indicadores_Bancarios2022.dta", replace

*
* FIN ZONA DE JUEGOS
*



* =========================== PARTE 3 =================================
* 						FUSIONANDO LAS BASES
noisily: di "Fusionando con bases pre-2022"

*
***Integrar las estadísticas de razones financieras hasta 2021
use "${dataS}\[13a]Indicadores_Bancarios2022.dta", clear
	*append using "${dataS}\[11-OB]Indicadores_Bancarios2021.dta"  //Adding 2021 info
format monthly_date time_monthly %tm

sort bank_id monthly_date 
	
	
* ~~~~~~~~~~~~~ Añadiendo etiquetas
label data "Situación Financiera al ${yy}m${mm}. Last update: `c(current_date)' by `c(username)'"

*Vigente
label variable activo "Activos (mdp)"
label variable cre_tdc "Crédito vigente Tarjetas de Crédito (mdp)"
label variable cre_per "Crédito vigente personales (mdp)"
label variable cre_nom "Crédito vigente de nómina (mdp)"
label variable cre_aut "Crédito vigente automotriz (mdp)"
label variable cre_abc "Crédito vigente ABCD (mdp)"
label variable cre_mic "Microcréditos vigente (mdp)"
label variable cre_arr "Créditos vigente arrendamientos (mdp)"
label variable cre_emp "Créditos vigente empresariales (mdp)"
label variable cre_otr "Créditos vigente otros (mdp)"
label variable cre_viv "Cartera vigente de vivienda (mdp)"

*Renaming to indicate they are outstanding loans
foreach v of varlist cre_tdc cre_per cre_nom cre_aut cre_abc cre_mic cre_arr cre_otr cre_emp cre_viv{
    rename `v' `v'_vig
}

*total
label variable cre_tdc_tot "Crédito total Tarjetas de Crédito (mdp)"
label variable cre_per_tot "Crédito total personales (mdp)"
label variable cre_nom_tot "Crédito total de nómina (mdp)"
label variable cre_aut_tot "Crédito total automotriz (mdp)"
label variable cre_abc_tot "Crédito total ABCD (mdp)"
label variable cre_mic_tot "Microcréditos total (mdp)"
label variable cre_arr_tot "Créditos total arrendamientos (mdp)"
label variable cre_emp_tot "Créditos total empresariales (mdp)"
label variable cre_viv_tot "Cartera total de vivienda (mdp)"
label variable cre_tot "Total cartera (mdp)"

*Vencidas
label variable cre_ven_tdc "Crédito vencido en Tarjetas de Crédito (mdp)"
label variable cre_ven_per "Créditos vencidos personales (mdp)"
label variable cre_ven_nom "Créditos vencidos de nómina (mdp)"
label variable cre_ven_aut "Crédito vencidoautomotriz (mdp)"
label variable cre_ven_abc "Crédito vencidoABCD (mdp)"
label variable cre_ven_mic "Microcréditos (mdp)"
label variable cre_ven_arr "Créditos vencidos de arrendamientos (mdp)"
label variable cre_ven_emp "Créditos vencidos empresariales (mdp)"
label variable cre_ven_viv "Cartera vencida de vivienda (mdp)"

rename (cre_ven_*) (cre_*_ven)

label variable cre_tot_ven "Cartera total vencida (mdp)"

*Construyendo morosidades
foreach v in tdc per nom aut abc arr mic otr emp viv{
    label variable imor_`v' "IMOR (%) en `v' -- Situación Financiera"
}

save "${dataS}\[13a]Indicadores_Bancarios_SF.dta", replace


* =========================== PARTE 4 =================================
***Fusionando con información de los Boletines Estadísticos.
noisily: di "P4. Integrando información de Boletines Estadísticos y Alertas Tempranas"
use "${dataS}\[13a]Indicadores_Bancarios_SF.dta", clear

***Integrar ICAP  °°Alertas tempranas históricas
	merge 1:1 bank_id monthly_date using "${dataS}\[11]Capitalización.dta", update replace
		drop _merge
		label variable icap "ICAP -- Alertas Tempranas"
		label variable capital_neto "Capital Neto (mdp) --Alertas Tempranas"
	xtset bank_id monthly_date
	gen icap_lag = l1.icap
	gen capital_neto_lag = l1.capital_neto

	
	
* =========================== PARTE 5 =================================
noisily: di "P5. Limpiando y organizando variables"
***Renombrar los índices de cobertura y de morosidad para hacer la analogía con los BE previo
foreach varl of varlist cre*{
	replace `varl' = 0 if `varl' == .
}


	*Saving vars and renaming to sf*
	
	*Fusionando ÍNDICES DE COBERTURA	
	*rename (icor_tot icor_emp icor_con icor_tdc icor_per icor_nom icor_aut icor_adbm  icor_otr icor_viv)	(icor_cct icor_cce icor_ccct icor_ccctc icor_cccnrp icor_cccn icor_cccaut icor_cccadqbimu  icor_cccnro icor_ccv)
	
	*Fusionando ÍNDICES DE MOROSIDAD
	*rename (imor_tot imor_emp imor_cons imor_tdc imor_per imor_nom imor_aut imor_abm imor_arr imor_otr imor_viv)	(imor_cct imor_cce imor_ccct imor_ccctc imor_cccnrp imor_cccn imor_cccaut imor_cccadqbimu imor_arr imor_cccnro imor_ccv)
		
merge 1:1 bank_id monthly_date using "${dataS}\[12]Indicadores_Bancarios_BE.dta", update

*Recoding labels
// Create a dictionary to map values of dta_file to corresponding labels var_label
local dta_labels "CCT Total" "CCE Empresas" "CCEF Ent.Financieras" "CCGT Ent.Gubernamentales" ///
                 "CCCT Consumo" "CCCTC Tarjetas" "CCCN Nómina" "CCCnrP Personales" ///
                 "CCCAut Automotriz" "CCCAdqBiMu BienesMuebles" "CCOAC ArrendamientoCapitalizable" ///
                 "CCCMicro Micro" "CCCnrO Otros" "CCV Vivienda"

foreach dta_f_label in "`dta_labels'" {
	tokenize `dta_f_label'
		local dta_f `1'
		local vlab `2'
		
		// Convert variable names to lowercase and remove spaces
		local varl = subinstr(strlower("`dta_f'"), " ", "", .)
		
		// Add labels
		label variable cre_`varl' "Crédito `vlab' (mdp) -- `new_info'"
		label variable imor_`varl' "IMOR `vlab' (%) -- `new_info'"
		label variable icor_`varl' "Cobertura `vlab' (%) -- `new_info'"
	}


*Renaming aditional variables

		
*Cleaning the resulting dataset
label data "Sit. Financiera, Boletines y Alertas al ${yy}m${mm}. Updated:`c(current_date)' by `c(username)'"


*Correr etiquetas
$run_tags
	sort bank_id monthly_date
	replace time_monthly = monthly_date
	label values bank_id bank_id
	
order bank_id monthly_date cre_c* imor_c* icor_* roa* roe* liq* 



* =========================== PARTE 6 =================================
noisily: di "P6. Identificando últimas variables adicionales"
*Identificar el principal negocio del banco
local tc cce ccctc cccnrp cccn cccaut cccnro ///
			ccv ccef ccgt cccadqbimu ccoac cccmicro
			
foreach cred in `tc' {
	*Porcentaje de crédito del banco en ese tipo de crédito
	gen shb_`cred' = cre_`cred' / cre_cct * 100
	format shb_`cred' %9.2f
}

	egen aux = rowmax(shb_*)  //Contiene el valor máximo de concentración
		format aux %9.2f
	gen b_buss = ""
	
foreach cred in `tc'{
	*Indicando el tipo de crédito mmás importante
	replace b_buss = "`cred'" if aux == shb_`cred'
}

replace b_buss = "Automotriz" if b_buss == "cccaut"
replace b_buss = "Microcréditos" if b_buss == "cccmicro"
replace b_buss = "Personales" if b_buss == "cccnrp"
replace b_buss = "Empresariales" if b_buss == "cce"
replace b_buss = "Gubernamentales" if b_buss == "ccgt"

	
tostring aux, gen(aux2) force
replace aux2 = substr(aux2, 1, 5)
gen b_buss_info = b_buss + " (" + aux2 + "%)"

*Identificar el segundo negocio del banco
foreach cred in `tc'{
	replace shb_`cred' = 0 if shb_`cred' == aux
}
gen b_buss2 = ""
drop aux*
egen aux = rowmax(shb_*)
	format aux %9.2f
	
foreach cred in `tc'{
	replace b_buss2 = "`cred'" if aux == shb_`cred'
}
replace b_buss2 = "Automotriz" if b_buss2 == "cccaut"
replace b_buss2 = "Hipotecario" if b_buss2 == "ccv"
replace b_buss2 = "Cred ABCD" if b_buss2 ==  "cccadqbimu"
replace b_buss2 = "Tarjetas" if b_buss2 ==  "ccctc"
replace b_buss2 = "Ent. Financieras" if b_buss2 ==  "ccef"
replace b_buss2 = "Microcréditos" if b_buss2 == "cccmicro"
replace b_buss2 = "Personales" if b_buss2 == "cccnrp"
replace b_buss2 = "Empresariales" if b_buss2 == "cce"
replace b_buss2 = "Gubernamentales" if b_buss2 == "ccgt"

	
tostring aux, gen(aux2) force
replace aux2 = substr(aux2, 1, 5)
gen b_buss2_info = b_buss2 + " (" + aux2 + "%)"

drop aux* shb*

*Etiquetas finales
foreach cred in `tc'{
if "`cred'" == "cct" local w "total"  
if "`cred'" == "cce" local w "empresas"  
if "`cred'" == "ccef" local w "ent. financieras"  
if "`cred'" == "cc" local w "ent. gubernamentales"  
if "`cred'" == "ccct" local w "consumo"  
if "`cred'" == "ccctc" local w "tarjetas"  
if "`cred'" == "cccn" local w "nómina"  
if "`cred'" == "cccnrp" local w "personales"  
if "`cred'" == "cccaut" local w "automotriz"  
if "`cred'" == "cccadq bimu" local w "bienes muebles"  
if "`cred'" == "ccoac" local w "arrendamiento capitalizable"  
if "`cred'" == "cccmicro" local w "micro" 
if "`cred'" == "cccnro" local w "otros" 
if "`cred'" == "ccv" local w "vivienda"

	*Generando la proporción de crédito en cada cartera
	gen shb_`cred' = cre_`cred' / cre_cct * 100
	label variable shb_`cred' "% de la cartera del banco en `w'"
}

label variable b_buss_info "Negocio principal del banco"
label variable b_buss2_info "Negocio secundario del banco"


foreach varl of varlist cre_cct - cre_ccv  activo - cre_tot_ven {
	*replace `varl' = `varl' / 1000 if monthly_date <= tm(2021m12)
}
compress

*Modifiyng labels on browser
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
format %tm time_monthly monthly_date

*Size in bank_id browser
char bank_id[_de_col_width_] 32

capture: drop _merge

***Integrar el INPC
merge m:1 time_monthly using "${root}\Data\INPC\Data\Stata\[1-DC] INPC.dta", keepusing(inpc)
	keep if _merge == 3
	drop _merge
	
decode bank_id, gen(bank_aux)
	drop if bank_aux == ""
	drop if monthly_date < tm(2017m1)
	drop bank_aux
	

	save "${dataS}\[13]Indicadores_Bancarios_Agr.dta", replace
	label data "Datos de créditos. Información al ${yy}m${mm}}"
	*save "${dataS}\[13_OB]Indicadores_Bancarios_Agr.dta", replace
noisily: display `"{browse "${dataS}": Archivo guardado exitosamente. Información al ${yy}m${mm}}"'


*=======================================================
* Printing diccionary
preserve
	describe, replace clear
	keep name varlab
	outfile using "$root\Data\Bank Data\Diccionario.txt", replace wide
restore

quietly: su monthly_date
list monthly_date icap imor_cce liq roa_flujo if bank_id == 0 & monthly_date == `r(max)'
xtset bank_id monthly_date
-
	*
****** Limpiando
capture: rm "${dataS}\[11-OB]catalogo_R12A_1219_BM.dta"
capture: rm "${dataS}\[13]aux_indicators_R12A_1219_BM.dta" 
capture: rm "${dataS}\[13a]Indicadores_Bancarios2022.dta"
*capture: rm "${dataS}\[13a]Indicadores_Bancarios_SF.dta"
}