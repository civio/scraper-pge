=begin
Parte general del nombre
   N_10[Año]_E[A=proyecto,E=aprobado?]_V[Color]_1[Serie]_
más parte específica, como:
   102[O Autonomos]_2_2[Gastos]_2[Detalle]_115[Seccion MEH]_1_2[Detalle]_1105[INE]_1

N_10_E_A_3_    Memorias: variación respecto a ejercicio anterior
               Presupuesto consolidado (debería ser A.4)
N_10_E_G_5_    Consorcios con participación no mayoritaria del Sector Público
N_10_E_R_2_    Ingresos
N_10_E_R_31_   Gastos. Presupuestos por programas (R.3) 
            1[Sección]_1_  Organismos del estado (Casa Real, Ministerios, Fondos de compensación CCAA...)
            .            1_  Presupuesto de gastos
            .            . 1_   Por programa
            .            . . 1[Programa]_
            .            . . .           2  Presupuesto gastos (Detalle)
            .            . . .           3  Presupuesto gastos (Resumen orgánico/económico)
            .            . . T_
            .            . .   1  Transferencias internas (Detalle)
            .            . .   2  Transferencias internas (Resumen orgánico/económico)
            .            . 2 Presupuesto agregado organismo
            .            2 Anexo inversiones/personal (por programa)
            2_1_  Seguridad Social
                G_1_  Gastos
                .   1_
                .   . 1[Programa]_
                .   . .           O   Presupuesto gastos (Resumen orgánico/económico)
                .   . .           P   Presupuesto gastos (Detalle)
                .   . T_
                .   . . 1  Transferencias internas (Detalle)
                .   . . 2  Transferencias internas (Resumen orgánico/económico)
                .   2   Resumen orgánico por programas y capítulos
                .   7   Resumen económico por programas
                I_  Ingresos
N_10_E_R_4_    Estados financieros y cuentas de Organismos Autónomos (debería ser R.5/6/7?)
N_10_E_R_5_    Estados financieros y cuentas de Organismos Autónomos (debería ser R.6/7?)
N_10_E_R_6_    Resúmenes Ingresos y Gastos (debería ser R.8)
N_10_E_R_7_    Cuentas fondos y consorcios? (R.6?)
N_10_E_V_1_    Ingresos y gastos. Anexos de desarrollo orgánico y económico
           1[Ámbito]_2_
             01  Estado
             02  Organismos Autónomos
             03  Agencias Estatales
             04  Otros Organismos Públicos
                       1_  Ingresos
                       . 1   Resumen general por organismos y capítulos (agregado)
                       . 2_1[Sección]_1_  Desglose por sección
                       .                1[Organismo]_1  Detalle por organismo
                       .                3  Resumen por artículos
                       .                4  Resumen por capítulos
                       . 3   Resumen general por artículos y secciones (agregado)
                       . 5_1 Resumen general por artículos
                       2_  Gastos
                       . 1   Resumen general por organismos y capítulos (agregado)
                       . 2_1[Sección]_1_  Desglose por sección
                       .                1_1  Detalle por seccion
                       .                2_1[Organismo]_1  Detalle por organismo
                       .                3  Resumen por artículos
                       .                4  Resumen por capítulos
                       3_  Cuentas de explotación y balances (no para todos?)
N_10_E_V_2_    Anexos de inversiones reales y programación plurianual (estructura por CCAA y organismo)
N_10_E_V_3_    Anexos de personal
           1  Estructura orgánica
           2  Por programa

=end

require_relative 'entity_breakdown'
require_relative 'programme_breakdown'

class Budget
  def initialize(path)
    @path = path || ''
  end
  
  def entity_breakdowns
    Dir[@path+'/doc/HTM/*.HTM'].
        select {|f| EntityBreakdown.entity_breakdown? f }.
        map {|f| EntityBreakdown.new(f) }
  end

  def programme_breakdowns
    Dir[@path+'/doc/HTM/*.HTM'].
        select {|f| ProgrammeBreakdown.programme_breakdown? f }.
        map {|f| ProgrammeBreakdown.new(f) }
  end
end
