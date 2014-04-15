#!/usr/bin/env ruby

require 'csv'

require './budget'

year = ARGV[0]
output_path = File.join(".", "output", year)

# Retrieve entities
Budget.new(year).entity_breakdowns.each do |bkdown|
  puts "#{bkdown.section},#{bkdown.name}" if bkdown.is_state_entity?
  bkdown.children.each do |child|
    key = "#{bkdown.section}.#{bkdown.entity_type}.#{child[:id]}"
    puts "#{key},#{child[:name]}"
  end
end

# Output data spread across a number of files
CSV.open(File.join(output_path, "estructura_economica.csv"), "w", col_sep: ';') do |csv|
  csv << ["EJERCICIO", "GASTO/INGRESO", "CAPITULO", "ARTICULO", "CONCEPTO", "SUBCONCEPTO", "DESCRIPCION CORTA", "DESCRIPCION LARGA"]
  csv << [year, "G", "1", nil, nil, nil, nil, "Gastos de personal"]
  csv << [year, "G", "1", "10", nil, nil, nil, "Salarios"]
  csv << [year, "G", "1", "10", "100", nil, nil, "Whatever"]
  csv << [year, "G", "1", "10", "100", "100000", nil, "Retribuciones básicas de Altos Cargos"]
end

CSV.open(File.join(output_path, "estructura_financiacion.csv"), "w", col_sep: ';') do |csv|
  csv << ["EJERCICIO", "GASTO/INGRESO", "ORIGEN", "FONDO", "FINANCIACION", "DESCRIPCION CORTA", "DESCRIPCION LARGA"]
  csv << [year, "G", "X", "XX", "XXX", "Gastos", ""]
end

CSV.open(File.join(output_path, "estructura_funcional.csv"), "w", col_sep: ';') do |csv|
  csv << ["EJERCICIO","GRUPO","FUNCION","SUBFUNCION","PROGRAMA","DESCRIPCION CORTA","DESCRIPCION LARGA"]
  csv << [year,"0","01","011","0111","Amortiz. y gastos Deuda","Amortización y Gastos Financieros de la Deuda"]
end

CSV.open(File.join(output_path, "estructura_organica.csv"), "w", col_sep: ';') do |csv|
  csv << ["EJERCICIO","CENTRO GESTOR","DESCRIPCION CORTA","DESCRIPCION LARGA"]
  csv << [year,"01","Cortes de Aragón","Cortes de Aragón"]
  csv << [year,"0100","Ingresos de las Cortes de Aragón","Ingresos de las Cortes de Aragón"]
  csv << [year,"01000","Ingresos de las Cortes de Aragón","Ingresos de las Cortes de Aragón"]
end

CSV.open(File.join(output_path, "gastos.csv"), "w", col_sep: ';') do |csv|
  csv << ["EJERCICIO","CENTRO GESTOR","FUNCIONAL","ECONOMICA","FINANCIACION","DESCRIPCION","IMPORTE"]
  csv << [year,"01000","0111","100000","XXX","Retribuciones básicas de Altos Cargos","2.414.299,58"]
end

CSV.open(File.join(output_path, "ingresos.csv"), "w", col_sep: ';') do |csv|
  csv << ["EJERCICIO","CENTRO GESTOR","ECONOMICA","FINANCIACION","DESCRIPCION","IMPORTE"]
  # csv << [year,"01000","100000","11099","Tarifa Autonómica del I.R.P.F.","1.138.992.000,00"]
end

