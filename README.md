Los Presupuestos
================

Los Presupuestos Generales del Estado del año 2010 se encuentran disponibles en la web del [Ministerio de Hacienda y Administraciones Públicas][1]. Antes de comenzar a trabajar con los Presupuestos es muy recomendable leer el [Libro Azul][2], que da una visión general de la estructura de los mismos.

Ejecutando los scripts
======================

Preparación: descargando los Presupuestos
-----------------------------------------

Los Presupuestos Generales del Estado están disponibles en la web del Ministerio tanto en su versión aprobada (la que nos interesa por ahora) como en la versión del proyecto de ley. Cada una de estas versiones se puede visualizar en línea o se puede descargar. En nuestro caso, estamos interesados en descargar la información para trabajar localmente, mucho más cómoda y rápidamente.

Las descargas se pueden hacer "por tomos", donde un fichero PDF representa cada uno de los tomos que componen la versión física del Presupuesto, pero para procesar la información automáticamente es mucho mejor la versión "normal", que incluye una versión HTML de cada uno de los artículos del Presupuesto.

[1]: http://www.sepg.pap.hacienda.gob.es/sitios/sepg/es-ES/Presupuestos/Paginas/MenuSitio.aspx
[2]: http://www.sepg.pap.hacienda.gob.es/sitios/sepg/es-ES/Presupuestos/PresupuestosEjerciciosAnteriores/Documents/EJERCICIO%202018/LIBRO%20AZUL%202018%20%28con%20marcadores%29.pdf

Entendiendo la estructura de ficheros
-------------------------------------

La versión de los Presupuestos que nos hemos descargado consiste en un enorme conjunto de ficheros .HTM con nombres aparentemente crípticos. Una pequeña explicación del significado de los nombres de los ficheros se encuentra en [`budget.rb`][3].

[3]: https://github.com/civio/pge-parser/blob/master/lib/budget.rb

Extracción de gastos presupuestados
-----------------------------------

Existen tareas Rake para ejecutar las tareas relacionadas con los presupuestos:

    $ rake -T
    rake "budget:parse[year]"    # Extract all information from budget files
    rake "budget:summary[year]"  # Generate a summary with budget key figures

Para extraer los datos de gastos de los Presupuestos, ejecutar por ejemplo:

    $ mkdir output/2014
    $ rake "budget:parse[2014]"

Los datos extraídos se redirigen a ficheros en la carpeta `output/[año]/`.

Para generar un resumen con las principales cifras del presupuesto, así como verificar su validez comparándolas con las cifras oficiales, ejecutar:

    $ rake "budget:summary[2014]"
