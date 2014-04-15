#!/usr/bin/env ruby

require 'csv'

year = ARGV[0]
output_path = File.join(".", "output", year)

CSV.open(File.join(output_path, "estructura_economica.csv"), "w", col_sep: ';') do |csv|
  csv << ["EJERCICIO", "GASTO/INGRESO", "CAPITULO", "ARTICULO", "CONCEPTO", "SUBCONCEPTO", "DESCRIPCION CORTA", "DESCRIPCION LARGA"]
  csv << ["2013", "G", "1", "10", "100", "100000", "Retr.básicas de Alt.Cargo", "Retribuciones básicas de Altos Cargos"]
  csv << ["2013", "I", "1", "10", "100", "100000", "Retr.básicas de Alt.Cargo", "Retribuciones básicas de Altos Cargos"]
end

CSV.open(File.join(output_path, "estructura_financiacion.csv"), "w", col_sep: ';') do |csv|
  csv << ["EJERCICIO", "GASTO/INGRESO", "ORIGEN", "FONDO", "FINANCIACION", "DESCRIPCION CORTA", "DESCRIPCION LARGA"]
  csv << ["2013", "G", "1", "11", "11099", "FSE P. OPERAT. ANTER 2007", ""]
  csv << ["2013", "I", "1", "11", "11099", "FSE P. OPERAT. ANTER 2007", ""]
end

CSV.open(File.join(output_path, "estructura_funcional.csv"), "w", col_sep: ';') do |csv|
  csv << ["EJERCICIO","GRUPO","FUNCION","SUBFUNCION","PROGRAMA","DESCRIPCION CORTA","DESCRIPCION LARGA"]
  csv << ["2013","0","01","011","0111","Amortiz. y gastos Deuda","Amortización y Gastos Financieros de la Deuda"]
end

CSV.open(File.join(output_path, "estructura_organica.csv"), "w", col_sep: ';') do |csv|
  csv << ["EJERCICIO","CENTRO GESTOR","DESCRIPCION CORTA","DESCRIPCION LARGA"]
  csv << ["2013","01","Cortes de Aragón","Cortes de Aragón"]
  csv << ["2013","0100","Ingresos de las Cortes de Aragón","Ingresos de las Cortes de Aragón"]
  csv << ["2013","01000","Ingresos de las Cortes de Aragón","Ingresos de las Cortes de Aragón"]
end

CSV.open(File.join(output_path, "gastos.csv"), "w", col_sep: ';') do |csv|
  csv << ["EJERCICIO","CENTRO GESTOR","FUNCIONAL","ECONOMICA","FINANCIACION","DESCRIPCION","IMPORTE"]
  csv << ["2013","01000","0111","100000","11099","Retribuciones básicas de Altos Cargos","2.414.299,58"]
end

CSV.open(File.join(output_path, "ingresos.csv"), "w", col_sep: ';') do |csv|
  csv << ["EJERCICIO","CENTRO GESTOR","ECONOMICA","FINANCIACION","DESCRIPCION","IMPORTE"]
  csv << ["2013","01000","100000","11099","Tarifa Autonómica del I.R.P.F.","1.138.992.000,00"]
end

