Tools used by `humord-data`, `usvd-data`, `tekord-data`


## emneregister2rdf.xq

XQuery-script for å konvertere en XML-fil fra Bibsys Emneregister til RDF/XML. Eks:

	$ zorba -i ./tools/emneregister2rdf.xq -e "base:=hume" \
		-e "scheme:=http://data.ub.uio.no/humord" \
		-e "file:=../data/humord.xml" >| ./data/humord.rdf.xml

## stats.xq

Skriver ut litt statistikk om en XML-fil fra Bibsys Emneregister

	$ zorba -i ./tools/stats.xq -e "base:=hume" -e "file:=../data/humord.xml"
	
	<?xml version="1.0" encoding="UTF-8"?>
	<stats>
	  <count desc="Termer">27048</count>
	  <count desc="Har kvalifikator">2148</count>
	  <count desc="Har definisjon">3620</count>
	  <count desc="Har noter">1057</count>
	  <count desc="Knutetermer (type=K)">134</count>
	  <count desc="Fasettindikatorer">180</count>
	  <count desc="Indekstermer">18115</count>
	  <count desc="Se-henvisninger">8569</count>
	  <count desc="Generelle se-henvisninger">364</count>
	  <count desc="Underemnefraser">0</count>
	</stats>
