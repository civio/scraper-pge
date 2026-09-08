Los Presupuestos
================

Los Presupuestos Generales del Estado se publican en la web del [Ministerio de Hacienda][1].
Antes de comenzar a trabajar con ellos es muy recomendable leer el Libro Azul, que da una
visión general de su estructura.

Este repositorio contiene los scripts que extraen los datos de gastos e ingresos de esos
ficheros, y el resultado de haberlos ejecutado, en [`output/`](output/).

[1]: https://www.sepg.pap.hacienda.gob.es/sitios/sepg/es-ES/Presupuestos/Paginas/Presupuestos.aspx


Requisitos
==========

Ruby 3.2 o posterior (ver `.ruby-version`) y las gemas del `Gemfile`:

    $ bundle install


Preparación: descargando los Presupuestos
=========================================

El Ministerio publica cada presupuesto como un único fichero .zip de entre 100 MB y 900 MB,
que contiene una versión HTML de todos los documentos. Las URLs siguen este patrón:

    https://www.sepg.pap.hacienda.gob.es/Presup/PGE<AÑO>Ley/MaestroDocumentos.zip
    https://www.sepg.pap.hacienda.gob.es/Presup/PGE<AÑO>Proyecto/MaestroDocumentos.zip

Los ficheros se guardan en `raw/`, que no está en el repositorio (son unos 10 GB), con el
nombre del presupuesto al que corresponden: `2023.zip` para el presupuesto aprobado de 2023
y `2023P.zip` para el Proyecto enviado por el Gobierno al Congreso.

**No hace falta descomprimirlos**: los scripts leen directamente del .zip, y sólo extraen
las páginas que necesitan (unos cientos de las casi 5.000 que contiene un presupuesto). Si
prefieres trabajar con una copia ya descomprimida, también vale: basta con pasar la carpeta
en lugar del .zip.

Dos avisos sobre los ficheros de `raw/`:

  * `2018-prorroga.zip` y `2019-prorroga.zip` son los presupuestos prorrogados (contienen
    páginas `N_18P_...` y `N_19P_...`, no `N_18_...`). El parser **no** los entiende: no hubo
    Presupuestos aprobados para 2019 ni para 2020.
  * El Proyecto de 2019 fue rechazado por el Congreso y el Ministerio retiró la
    documentación, así que `output/2019P/` ya no se puede regenerar.


Entendiendo la estructura de ficheros
=====================================

Cada presupuesto consiste en un enorme conjunto de ficheros .HTM con nombres aparentemente
crípticos, bajo `PGE-ROM/doc/HTM/`. Una explicación del significado de esos nombres está al
principio de [`lib/budget.rb`](lib/budget.rb).


Ejecutando los scripts
======================

Todo se hace con `bin/pge`:

    $ bin/pge parse 2023      # extrae los datos a output/2023/*.csv
    $ bin/pge summary 2023    # genera output/2023/README.md con las cifras principales
    $ bin/pge all 2023        # las dos cosas, en orden

Por defecto lee `raw/<presupuesto>.zip` y escribe en `output/<presupuesto>/`. Ambas rutas se
pueden cambiar:

    $ bin/pge all 2023 --input /otra/ruta/2023.zip --output /tmp/2023

El resumen incluye una comprobación de las cifras agregadas contra los totales oficiales
publicados en el propio presupuesto, que es la mejor verificación de que la extracción ha
ido bien.


Correcciones
============

Algunos programas de la Seguridad Social se publican con las páginas de desglose vacías,
aunque los totales del resto del presupuesto sí los incluyen. Las líneas que faltan se
localizaron a mano y están en [`corrections/`](corrections/), un fichero por presupuesto,
con los importes en miles de euros igual que en las páginas originales. El parser las añade
al resto de líneas, de forma que una nueva ejecución reproduce las cifras publicadas en
lugar de perderlas.


Tests
=====

    $ bundle exec ruby test/all.rb

Hay dos niveles. Los tests rápidos usan un puñado de páginas reales guardadas en
`test/fixtures/budget_pages.zip`, y cubren los tres formatos HTML que ha usado el Ministerio
a lo largo de los años: tablas hasta 2013, CSS autogenerado entre 2014 y 2018, y divs sin
estructura semántica desde 2019.

Además, `test/golden_output_test.rb` vuelve a procesar cada presupuesto y comprueba que
sigue generando exactamente los ficheros de `output/`. Como los .zip no están en el
repositorio, los presupuestos cuyo fichero no esté en `raw/` se saltan en lugar de fallar.
Para comprobar sólo algunos:

    $ PGE_BUDGETS=2013,2023 bundle exec ruby test/golden_output_test.rb
