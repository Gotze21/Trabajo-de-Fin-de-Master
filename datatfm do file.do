//ruta

global root "D:\!!UHA Master\TFM\Articulos para TFM\Energy poverty articles\Imagenes y datos\ENAHO\data tfm"

      global data "$root\data"
	  
	  global output "$root\output"
	  
	 
//importar datos

//Modulo 2 Caracteristicas miembros del hogar

use "$data\enaho01-2022-200.dta", clear


// sexo jefe del hogar 1 mujer 0 hombre
* p203 parentezco p207 sexo

gen sexo_jefe=1 if p207 == 2 & p203==1
replace sexo_jefe=0 if p207 == 1 & p203 == 1
//label define sexo_jefe 0 "Hombre" 1 "Mujer"
//label val sexo_jefe sexo_jefe
label var sexo_jefe "Sexo del cabeza de familia"


// edad jefe del hogar 1 mayor o  igual a 50 0 menor o igual a 49 
// p208a edad en años cumplidos

gen edad_jefe=1 if p208a>=50 & p203==1
replace edad_jefe=0 if p208a <=49 & p203 == 1
//label define edad_jefe 0 "Menor o igual a 49" 1 "Mayor o igual a 50"
//label val edad_jefe edad_jefe
label var edad_jefe "Edad del cabeza de familia"

keep conglome vivienda hogar codperso ubigeo dominio estrato sexo_jefe edad_jefe

save "$output\edadsexohogar.dta", replace

//Modulo 3 Educacion

use "$data\enaho01a-2022-300", clear


*p301a ultimo año o grado de estudios y nivel que aprobó 

gen escol_jefe=1 if p301a <= 9 & p203==1
replace escol_jefe=0 if p301a >= 10 & p203 == 1

//label define escol_jefe 0 "Educacion Superior" 1 "No Educación Superior"
//label val escol_jefe escol_jefe
label var escol_jefe "Escolaridad del cabeza de familia"

keep conglome vivienda hogar codperso ubigeo dominio estrato escol_jefe

save "$output\educación.dta", replace

//Modulo 4 Salud

use "$data\enaho01a-2022-400.dta", clear


*POBLACION CON SEGURO DE SALUD
*Existen 8 variables que indican si una persona esta afiliado a un seguro
sum  p4191-p4198

*La codificacion de las variables es 1 & 2, lo quiero cambiar a 1 & 0
recode p4191-p4198 (2=0)

gen seguro= p4191 + p4192 + p4193 + p4194 + p4195 + p4196 + p4197 + p4198
tab seguro
gen aseg_jefe=1 if seguro == 0 & p203==1
replace aseg_jefe=0 if seguro > 0 & p203 == 1
//label define aseg_jefe 0 "Está asegurado" 1 "No está asegurado"
//label val aseg_jefe aseg_jefe
label var aseg_jefe "Tiene seguro de salud el cabeza de famila"

keep conglome vivienda hogar codperso ubigeo dominio estrato aseg_jefe

save "$output\seguromedico.dta", replace



//Modulo 5 Ocupacion e Ingresos

use "$data\enaho01a-2022-500.dta", clear

**ocu500 variable que indica si una persona esta económicamente activa o no.

tab ocu500

drop if ocu500==0
recode ocu500 (1=1) (2=1) (3=4) (4=4), generate(ocu500_agrupada)
tab ocu500_agrupada

gen ocup_jefe=1 if ocu500_agrupada == 4 & p203==1
replace ocup_jefe=0 if ocu500_agrupada == 1 & p203 == 1

//label define ocup_jefe 0 "Ocupado" 1 "Desocupado o Inactivo"
//label val ocup_jefe ocup_jefe
label var ocup_jefe "Situación Laboral"

keep conglome vivienda hogar codperso ubigeo dominio estrato ocup_jefe

save "$output\ocupacionlaboral.dta", replace

// fusion BBDD de individuos

merge 1:1 conglome vivienda hogar codperso using "$output\edadsexohogar"

drop if _merge!=3
drop _merge


merge 1:1 conglome vivienda hogar codperso using "$output\seguromedico"

drop if _merge!=3
drop _merge


merge 1:1 conglome vivienda hogar codperso using "$output\educación"

drop if _merge!=3
drop _merge


use "$output\fusion_individuos.dta", clear

drop if missing(ocup_jefe) & missing(sexo_jefe) & missing(edad_jefe) & missing(aseg_jefe) & missing(escol_jefe)


save "$output\fusion_individuos.dta", replace

// Modulo 6 Equipamientos del hogar

use "$data\enaho01-2022-612.dta", clear

duplicates report conglome vivienda hogar

tab p612n
tab p612

//Dimension Educación/Entretenimiento

//Privación de Televisor 1 = Verdadero 0 = Falso
//Privación de Radio 1 = Verdadero 0 = Falso
 
gen priv_radio = 0
replace priv_radio = 1 if p612n == 1 & p612 == 2
 
//label define priv_radio 0 "Si" 1 "No"
//label val priv_radio priv_radio
label var priv_radio "El hogar posee radio?"
tab priv_radio


gen priv_tvcolor = 0
replace priv_tvcolor = 1 if p612n == 2 & p612 == 2
 
//label define priv_tvcolor 0 "Si" 1 "No"
//label val priv_tvcolor priv_tvcolor
label var priv_tvcolor "El hogar posee TV a color?"
tab priv_tvcolor
 
 
gen priv_tvblanco = 0 
replace priv_tvblanco = 1 if p612n == 3 & p612 == 2
//label define priv_tvblanco 0 "Si" 1 "No"
label val priv_tvblanco priv_tvblanco
label var priv_tvblanco "El hogar posee TV en blanco y negro?"


// Dimension Servicios provistos por electrodomésticos
 
//Privación de Refrigerador 1 = Verdadero 0 = Falso

gen priv_refri = 0
replace priv_refri = 1 if p612n == 12 & p612 == 2
//label define priv_refri 0 "Si" 1 "No"
//label val priv_refri priv_refri
label var priv_refri "El hogar posee refrigerador?"
tab priv_refri


collapse (max) priv_radio priv_tvcolor priv_tvblanco priv_refri, by(conglome vivienda hogar)

// unificar ambas var de tv 

gen priv_tv = 0
replace priv_tv = 1 if priv_tvblanco == 1 & priv_tvcolor == 1
tab priv_tv

label var priv_radio "El hogar posee radio?"
label var priv_tv "El hogar posee TV?"
label var priv_refri "El hogar posee refrigerador?"



save "$output\equipamientos_hogar.dta", replace

//Modulo 1 Caracteristicas de la vivienda y Hogar

use "$data\enaho01-2022-100.dta", clear


//Tipo de combustible 1  electricidad 2  gas (balon glp) 3 gas natural (sistema de tuberias) 5 carbon 6 leña

codebook p113a

drop if missing(p113a)
// missing es que no cocinan.


gen tipo_combustible_cat = .
replace tipo_combustible_cat = 1 if p113a == 1
replace tipo_combustible_cat = 2 if p113a == 2
replace tipo_combustible_cat = 3 if p113a == 3
replace tipo_combustible_cat = 4 if p113a == 5
replace tipo_combustible_cat = 5 if p113a == 6
replace tipo_combustible_cat = 6 if p113a >= 7 


label define tipo_combustible_cat 1 "Electricidad" 2 "Gas (balon glp)" 3 "Gas natural (tuberías)" 4 "Carbon" 5 "Leña" 6 "Estiercol o Residuos agricolas"
label values tipo_combustible_cat tipo_combustible_cat


// Variables para el calculo del MEPI
// 1 Representa privación por tanto el individuo u hogar es pobre energeticamente.

  //Dimension Cocina
  // Tipo de Combustible para cocinar.
  
tab p113a 
//replace comb_coc = . if comb_coc==. missing values

gen     priv_comb_coc=0
replace priv_comb_coc=1 if p113a>=5
//label define priv_comb_coc 0 "Usa combustible moderno" 1 "Usa combustible sólido"
//label val priv_comb_coc priv_comb_coc
label var priv_comb_coc "Tipo de combustible para cocinar"


  //Dimension Iluminación
  //Acceso a electricidad 
  
tab p1121  
gen     priv_electricidad=0
replace priv_electricidad=1 if p1121!=1
//label define priv_electricidad 0 "Posee electricidad" 1 "No posee electricidad"
//label val priv_electricidad priv_electricidad
label var priv_electricidad "Acceso a electricidad"


  //Dimension Comunicación
codebook p1141 p1142

gen priv_telefono = 1
replace priv_telefono = 0 if p1141 ==1  | p1142 == 1
  //Privación de movil y teléfono fijo
  
//label define priv_telefono 0 "Posee movil o tel. fijo" 1 "No posee ninguno"
//label val priv_telefono priv_telefono
label var priv_telefono "Posee telefono fijo o movil"


// Otras variables dummies para la caracterizaciín de los hogares

rename p102 paredes
rename p103 suelo
rename p103a techos
rename p110 agua
rename p111a desagüe

//
codebook paredes

drop if missing(paredes)
gen dparedes= 0
replace dparedes = 1 if paredes != 1
//label define dparedes 0 "Ladrillo o bloque de cemento" 1 "Otro material menos resistente"
//label val dparedes dparedes
label var dparedes "Material predominante en las paredes exteriores"
tab dparedes

codebook suelo

gen dsuelo = 0
replace dsuelo = 1 if suelo >= 4
//label define dsuelo 0 "Material más moderno y costoso" 1 "Otros materiales "
//label val dsuelo dsuelo
label var dsuelo "Material predominante en los suelos"
tab dsuelo


codebook techos

gen dtechos = 0
replace dtechos = 1 if techos != 1
//label define dtechos 0 "Concreto armado" 1 "Otros materiales menos resistentes "
//label val dtechos dtechos
label var dtechos "Material predominante en los techos"
tab dtechos


codebook agua 

gen dagua = 0
replace dagua = 1 if agua >= 3
//label define dagua 0 "Red Pública" 1 "Pozos, manantiales, otros"
//label val dagua dagua
label var dagua "Procedencia del agua utilizada en los hogares"
tab dagua

codebook desagüe
gen ddesagüe = 0
replace ddesagüe = 1 if desagüe >= 3
//label define ddesagüe 0 "Red Pública de desagüe" 1 "Letrina, pozo, otros"
//label val ddesagüe ddesagüe
label var ddesagüe "Servicio higíenico de los hogares conectado a"
tab ddesagüe


// Tipo de viviendas
//1 = casa independiente 2 = apartamento en edificio 3 en adelante condiciones precarias.
codebook p101
gen tip_viviendas = 0 

replace tip_viviendas = 1 if p101 >= 3 
//label define tviviendas 0 "Casa o apartamento" 1 "Viviendas en condiciones precarias"
//label val tviviendas tviviendas
label var tip_viviendas "Tipo de Viviendas"
tab tip_viviendas


// vivienda alquilada o propia

codebook p105a
gen propvivienda = 0

replace propvivienda = 1 if p105a != 2 & p105a != 3  & p105a != 4
//label define propvivienda 0 "Vivienda Propia" 1 "Vivienda Alquilada"
//label val propvivienda propvivienda
label var propvivienda "La Vivienda es propia o alquilada"
tab propvivienda

// si las viviendas han recibido un credito en lso ultimos 12 meses para construir o reparar la vivienda


gen préstamo_recibido = 0

//Reemplazar el valor de préstamo_recibido a 1 si han recibido un préstamo 
replace préstamo_recibido = 1 if p107b3 == 1 | p107b4 == 1
//label define préstamo_recibido 0 "No" 1 "Si"
//label val préstamo_recibido préstamo_recibido
label var préstamo_recibido "Se ha recibido algún crédito para reparar o construir la Vivienda?"
tab préstamo_recibido

// Numero de habitaciones de las viviendas sin contar con el baño, cocina, ni garage

codebook p104

rename p104 num_habit
gen nume_habit = 1
replace nume_habit = 0 if num_habit > 4
label define nume_habit 0 "5 o más habitaciones" 1 "1 a 4 habitaciones"
label var nume_habit  "Número de habitaciones de la vivienda sin contar baño, cocina y garage?"
tab nume_habit

// Dividor el estrato (area) entre urbano y rural viviendas con menos de 2000 habitantes es rural.
tab estrato

gen area = 0
replace area = 1 if estrato > 5 
label define area 0 "Urbana" 1 "Rural"
label val area area
label var area "'Area"
tab area

destring ubigeo, generate(dpto)

* Extraer el código del departamento
replace dpto = dpto / 10000
replace dpto = round(dpto)

label variable dpto "Departamento"
label define dpto 1 "Amazonas"
label define dpto 2 "Ancash", add
label define dpto 3 "Apurimac", add
label define dpto 4 "Arequipa", add
label define dpto 5 "Ayacucho", add
label define dpto 6 "Cajamarca", add
label define dpto 7 "Callao", add
label define dpto 8 "Cusco", add
label define dpto 9 "Huancavelica", add
label define dpto 10 "Huanuco", add
label define dpto 11 "Ica", add
label define dpto 12 "Junin", add
label define dpto 13 "La_Libertad", add
label define dpto 14 "Lambayeque", add
label define dpto 15 "Lima", add
label define dpto 16 "Loreto", add
label define dpto 17 "Madre_de_Dios", add
label define dpto 18 "Moquegua", add
label define dpto 19 "Pasco", add
label define dpto 20 "Piura", add
label define dpto 21 "Puno", add
label define dpto 22 "San_Martin", add
label define dpto 23 "Tacna", add
label define dpto 24 "Tumbes", add
label define dpto 25 "Ucayali", add
label values dpto dpto
tab dpto

//agrupar los dominios en costa, sierra, selva y lima 
//Crear variables dummy para los dominios?

tab dominio

gen dominio2 = 0 if inrange(dominio,1,3)
replace dominio2 = 1 if inrange(dominio,4,6)
replace dominio2 = 2 if dominio == 7
replace dominio2 = 3 if dominio == 8

label define dominio2 0 "Costa" 1 "Sierra" 2 "Selva" 3 "Lima" 
label values dominio2 dominio2
tab dominio2


save "$output\Caract_hogar.dta", replace 


merge 1:1 conglome vivienda hogar using "$output\equipamientos_hogar.dta"
drop if _merge!=3
drop _merge

save "$output\fusion_equipamientos_caract.vivienda.dta", replace

keep conglome vivienda hogar ubigeo dpto dominio dominio2 estrato factor07 tipo_combustible_cat priv_comb_coc priv_electricidad priv_telefono dparedes dsuelo dtechos dagua ddesagüe tip_viviendas propvivienda préstamo_recibido priv_radio priv_tv priv_refri area nume_habit 

save "$output\fusion_equipamientos_caract.vivienda.dta", replace

merge 1:m conglome vivienda hogar using "$output\fusion_individuos.dta"
drop if _merge!=3
drop _merge

// gen id = conglome + vivienda + hogar + codperso 
// gen año 2022

save "$output\DatasetTFM.dta", replace

use "$data\sumaria-2022.dta", clear

//ingmo2hd // ingrso monetario neto


rename ingmo2hd ingmon_net
kdensity ingmon_net

sum ingmon_net, d
sum ingmon_net

keep conglome vivienda hogar mieperho ingmon_net

save "$output\sumatoria.dta", replace

// FUsion entre DatasetTFM y Sumatoria

use "$output\DatasetTFM.dta", clear

merge 1:1 conglome vivienda hogar using "$output\sumatoria.dta"
drop if _merge!=3
drop _merge

order  conglome vivienda hogar mieperho ubigeo dpto dominio dominio2 estrato area factor07 dparedes dsuelo dtechos dagua ddesagüe tip_viviendas nume_habit ingmon_net propvivienda préstamo_recibido ingmon_net ocup_jefe sexo_jefe edad_jefe aseg_jefe escol_jefe tipo_combustible_cat priv_comb_coc priv_electricidad priv_telefono priv_radio priv_tv priv_refri  


//  Indicadores a utilizar para calcular el indice de pobre energetica multidimencional

//Dimension: Cocina 
//Variable: Tipo de combustible para cocinar
tab priv_comb_coc

//Dimension: Iluminacion 
//Variable: Tiene acceso a electricidad
tab priv_electricidad

//Dimension: Servicios prestados por electrodomesticos 
//Variable: Posee un refrigerador

tab priv_refri

//Dimension: Entretenimiento/Educacion 
//Variable: Posee un tv
//Variable: Posee un radio
tab priv_tv
tab priv_radio

//Dimension: Comunicación 
//Variable: Posee un telefono fijo o movil
tab priv_telefono


//Asignar pesos
local w_comb 0.40
local w_ilum 0.20
local w_comunicacion 0.13
local w_entretenimiento 0.065
local w_electrodomesticos 0.13

//Crear variables ponderadas
gen w_priv_comb_coc = priv_comb_coc * `w_comb'
gen w_priv_electricidad = priv_electricidad * `w_ilum'
gen w_priv_telefono = priv_telefono * `w_comunicacion'
gen w_priv_tv = priv_tv * `w_entretenimiento'
gen w_priv_radio = priv_radio * `w_entretenimiento'
gen w_priv_refri = priv_refri * `w_electrodomesticos'


//Crear la matriz de privación ponderada
egen c_vector = rowtotal(w_priv_comb_coc w_priv_electricidad w_priv_telefono w_priv_tv w_priv_radio w_priv_refri)
//Genera el vector de conteo de la suma de privaciones ponderadas, 'c'
//Cantidad de privaciones ponderada que tiene cada hogar
label var c_vector "Vector de conteo"

//Identificación de la pobreza multidimensional

gen multid_pobre_26 = (c_vector >= 26/100)
label var multid_pobre_26 "Identificación de pobre con k=26%"

//Vector de conteo censurado
//Genera el vector censurado de la suma de privaciones individuales ponderadas, 'c(k)'
//Proporciona un valor de cero si el hogar no es pobre multidimensional

gen cens_c_vector_26 = c_vector
replace cens_c_vector_26 = 0 if multid_pobre_26 == 0
label var cens_c_vector_26 "Vector de conteo censurado para pobres con k=26%"

//Tasa de Incidencia de Pobreza Multidimensional (H), la Intensidad de la pobreza entre los pobres (A), y la Tasa de Incidencia Ajustada (Mo).

//Incidencia de la Pobreza Energética (H): Proporción de hogares que son pobres energéticamente (hogares cuya suma ponderada de privaciones supera un umbral predefinido)

sum multid_pobre_26 [iw = factor07]
gen H = r(mean) * 100
lab var H "Incidencia de la Pobreza Energética (H)"

//Intensidad de la Pobreza Energética (A): Promedio de la suma ponderada de privaciones entre los hogares pobres energéticamente.
sum cens_c_vector_26 if multid_pobre_26 == 1 [iw = factor07]
gen A = r(mean) * 100
lab var A "Intensidad de la Pobreza Energética (A)"

// Incidencia ajustada (Mo) MEPI
sum cens_c_vector_26 [iw = factor07]
gen MEPI = r(mean) * 100

lab var MEPI "Indice de Pobreza Energetica Multidimensional."

tab multid_pobre_26 [iw = factor07]

svyset [pweight=factor07], psu(conglome) strata(estrato)
svy: mean multid_pobre_26

svy: mean cens_c_vector_26 if multid_pobre_26 == 1
svy: mean cens_c_vector_26

**H, A Y M0 por area, para k=26
**Calculo de H por dpto
set dp comma
tab dpto [w=factor07], sum(multid_pobre_26)
**Calculo de A por dpto
tab dpto [w=factor07] if multid_pobre_26==1, sum(cens_c_vector_26)
**Calculamos la M0 por dpto
tab dpto [w=factor07], sum(cens_c_vector_26)
svy: mean multid_pobre_26, over(dpto)  
svy: mean cens_c_vector_26 if multid_pobre_26==1, over(dpto)
svy: mean cens_c_vector_26, over(dpto)

save "$output\DatasetTFM.dta", replace

use "$output\DatasetTFM.dta", clear


tabstat ingmon_net, by( tipo_combustible_cat ) statistics(mean)


xtile quintil=ingmon_net, n(5)
tab quintil, gen (Q)

//xtile quartil=ingmon_net, n(4)
//tab quartil, gen (q)

//xtile decil=ingmon_net, n(10)
//tab decil, gen (d)

table (quintil tipo_combustible_cat ), statistic(mean ingmon_net)

* Crear logarítmo de ingresos
gen log_ingmon_net = log(ingmon_net + 1)



//Crear variables dummy para los departamentos
tabulate dpto, generate(dpto_dummy)

//Verificar algunas de las variables dummy generadas
list dpto dpto_dummy* in 1/10

//Crear variables dummy para los departamentos
tabulate dominio2, generate(dpto_dominio2)

//Verificar algunas de las variables dummy generadas
list dpto dominio2* in 1/10



// probit multinomial no ordenado

//mprobit tipo_combustible_cat multid_pobre_26 sexo_jefe edad_jefe escol_jefe aseg_jefe ocup_jefe propvivienda préstamo_recibido, baseoutcome(1) 

// Pasos para detectar si hay endogeneidad
// Estimación el modelo sin instrumentos
//reg tipo_combustible_cat cens_c_vector_26 sexo_jefe edad_jefe escol_jefe aseg_jefe ocup_jefe propvivienda préstamo_recibido
//estimates store ols_model

//Estimación del modelo IV utilizando variables instrumentales (En este caso usé ddesagüe dparedes dagua):
//ivregress 2sls tipo_combustible_cat (cens_c_vector_26 = ddesagüe area) sexo_jefe edad_jefe escol_jefe aseg_jefe ocup_jefe propvivienda préstamo_recibido
//estimates store iv_model

// Ultimo paso prueba de Hausman
//hausman iv_model ols_model, sigmamore

//Si P ≤ 0.05, se rechaza la hipótesis nula, lo que indica que los coeficientes son sistemáticamente diferentes y por tanto multid_pobre_26 es endógena


// Prueba de Sargan verificacion de instrumentos
//estat overid
*** no se utiliza porque solo utilizo un instrumento.


// Primera etapa: estimar la variable endógena usando el instrumento
//probit multid_pobre_26 ddesagüe sexo_jefe edad_jefe escol_jefe aseg_jefe ocup_jefe propvivienda préstamo_recibido

// Predecir los valores ajustados de la variable endógena
//predict multid_pobre_26_hat, xb


// Estimar el modelo multinomial probit usando los valores ajustados
//mprobit tipo_combustible_cat multid_pobre_26_hat sexo_jefe edad_jefe escol_jefe aseg_jefe ocup_jefe propvivienda préstamo_recibido, baseoutcome(1)

// Prueba de heterocedasticidad
//estat hettest

//para tabla numero 2
table tipo_combustible_cat if sexo_jefe == 0, statistic(percent) nformat(%5.2f)

svyset [pweight=factor07]
svy: tabulate tipo_combustible_cat if sexo_jefe == 0, percent format(%5.2f)

log using "D:\!!UHA Master\TFM\Articulos para TFM\Energy poverty articles\Imagenes y datos\ENAHO\data tfm\dofile\output\stata_new25.07.log", text replace

correlate log_ingmon_net sexo_jefe edad_jefe escol_jefe dparedes dtechos dagua ddesagüe area nume_habit ocup_jefe propvivienda tip_viviendas préstamo_recibido dpto_dominio21 dpto_dominio22 dpto_dominio23 

// Ajustar el modelo con errores estándar robustos
mprobit tipo_combustible_cat log_ingmon_net sexo_jefe edad_jefe escol_jefe dparedes dtechos dagua ddesagüe area nume_habit ocup_jefe propvivienda tip_viviendas préstamo_recibido dpto_dominio21 dpto_dominio22 dpto_dominio23 [pweight= factor07], baseoutcome(1)

// Calcular efectos marginales 
margins, dydx(*) 

marginsplot

//mprobit tipo_combustible_cat multid_pobre_26_hat sexo_jefe edad_jefe escol_jefe aseg_jefe ocup_jefe propvivienda préstamo_recibido, vce(robust)

//Precision del modelo
predict prob1 prob2 prob3 prob4 prob5 prob6

gen choice_pred = 1 if prob1 > prob2 & prob1> prob3 & prob1 > prob4 & prob1 > prob5 & prob1 > prob6

replace choice_pred = 2 if prob2 > prob1 & prob2> prob3 & prob2 > prob4 & prob2 > prob5 &prob2 > prob6
replace choice_pred = 3 if prob3 > prob1 & prob3> prob2 & prob3 > prob4 & prob3 > prob5 & prob3 > prob6
replace choice_pred = 4 if prob4 > prob1 & prob4> prob2 & prob4 > prob3 & prob4 > prob5 & prob4 > prob6
replace choice_pred = 5 if prob5 > prob1 & prob5> prob2 & prob5 > prob3 & prob5 > prob4 & prob5 > prob6
replace choice_pred = 6 if prob6 > prob1 & prob6> prob2 & prob6 > prob3 & prob6 > prob4 & prob6 > prob5

tab tipo_combustible_cat choice_pred

//ver los aciertos del modelo

gen acierto = (tipo_combustible_cat == choice_pred)
summarize acierto

log close



