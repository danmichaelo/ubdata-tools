module namespace emneregister = "http://ub.uio.no/emneregister";

declare namespace owl     = "http://www.w3.org/2002/07/owl#";
declare namespace marcxml = "http://www.loc.gov/MARC21/slim";
declare namespace rdf     = "http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace rdfs    = "http://www.w3.org/2000/01/rdf-schema#";
declare namespace skos    = "http://www.w3.org/2004/02/skos/core#";
declare namespace dct     = "http://purl.org/dc/terms/";
declare namespace bs      = "http://data.ub.uio.no/onto/bs#";


(: Strip off non-valid characters, return only non-empty values :)
declare function emneregister:signaturesAsDdc( $sigs as element()* )
as element()*
{
	for $sig in $sigs

	(: Remove noise :)
	let $s := replace( $sig/text(), '[^0-9.-]', '' )

	(: Replace dangling dashes by T1--. Per mail from Hilde K. Bjerkholt 2015-05-12 
	  "hvorfor man ikke markerte med T! [i emneregisteret] var kanskje fordi den var den eneste hjelpetabellen som ble lagt inn" :)
	let $s := replace(replace( $sig/text(), '[^0-9.-]', '' ), '^-', 'T1--')

	where $s != ''
	return (
		<skos:exactMatch rdf:resource="http://data.ub.uio.no/ddc/{ $s }"/> ,
		<skos:notation rdf:datatype="http://dewey.info/schema-terms/Notation">{ $s }</skos:notation>
	)
};

(: Return only non-empty values :)
declare function emneregister:signaturesAsUdc( $sigs as element()* )
as element()*
{
	for $sig in $sigs
	return <skos:notation rdf:datatype="http://udcdata.info/UDCnotation">{ $sig/text() }</skos:notation>
};

(: Return the label for a post, including chain and qualifiers :)
declare function emneregister:label( $post as element() )
as xs:string
{
	(: Strip off non-valid characters, return only non-empty elements :)
	concat(
		string-join(( $post/hovedemnefrase/text(), $post/underemnefrase/text(), $post/kjede/text() ), ' : ' ),
		{ 
			for $x in $post/kvalifikator
			return concat(' (', $x/text(), ')')
		}
	)
};

declare function emneregister:uriFromTermId( $uri_base as xs:string, $termId as xs:string )
as xs:string
{
	(: Strip off letter prefix <s>and leading zeros</s> :)
	concat( $uri_base, replace( $termId, '^[^0-9]+', '' ))
};

(: Parse <post> elements, return skos:Concepts :)
declare function emneregister:posts( $posts as element()*, $scheme as xs:string, $uri_base as xs:string, $signature_handler as xs:string)
as element()*
{
	<skos:ConceptScheme rdf:about="{ $scheme }">
	{
		for $post in $posts
		return
		{
			if ($post/toppterm-id/text() = $post/term-id/text()) then
				<skos:hasTopConcept rdf:resource="{ emneregister:uriFromTermId( $uri_base, $post/term-id/text() ) }"/>
			else ()
		}
	}
	</skos:ConceptScheme>,
	for $post in $posts
	return
	{
		if ( $post/se-id or $post/gen-se-henvisning ) then 
		{
			if ($post/gen-se-henvisning) then ()  (: ignore for now :)
			else 
			{
				for $seId in $post/se-id/text()
				return  <skos:Concept rdf:about="{ emneregister:uriFromTermId( $uri_base, $seId ) }">
							<skos:altLabel xml:lang="nb">{ emneregister:label( $post ) }</skos:altLabel>
						</skos:Concept>
			}
		}
		else
			<skos:Concept rdf:about="{ emneregister:uriFromTermId( $uri_base, $post/term-id/text() ) }">
				<skos:prefLabel xml:lang="nb">{
					emneregister:label($post)
				}</skos:prefLabel>
				<dct:identifier>{
					$post/term-id/text()
				}</dct:identifier>
				<dct:modified rdf:datatype="http://www.w3.org/2001/XMLSchema#date">{
					xs:date( $post/dato/text() )
				}</dct:modified>
				{
					if ($post/type/text() = 'K') then
					<rdf:type rdf:resource="http://data.ub.uio.no/onto/bs#KnuteTerm"/>
					else if ($post/type/text() = 'F') then
					(
					<rdf:type rdf:resource="http://purl.org/iso25964/skos-thes#ThesaurusArray"/>,
					<rdf:type rdf:resource="http://www.w3.org/2004/02/skos/core#Collection"/>
					)
					else ()
				}{
					if ($post/toppterm-id/text() = $post/term-id/text()) then
						<skos:topConceptOf rdf:resource="{ $scheme }"/>
					else
						<skos:inScheme rdf:resource="{ $scheme }"/>
				}{
					(: We could add a switch here to support more classification schemes in the future :)
					switch ($signature_handler)
						case "ddc" return emneregister:signaturesAsDdc( $post/signatur )
						case "udc" return emneregister:signaturesAsUdc( $post/signatur )
						default return ()
				}{
					for $x in $post/definisjon/text()
					return <skos:definition xml:lang="nb">{ $x }</skos:definition>
				}{
					for $x in $post/noter/text()
					return <skos:editorialNote xml:lang="nb">{ $x }</skos:editorialNote>
				}{
					for $x in $post/lukket-bemerkning/text()
					return <skos:editorialNote xml:lang="nb">Lukket bemerkning: { $x }</skos:editorialNote>
				}{
					for $x in $post/gen-se-ogsa-henvisning/text()
					return <skos:scopeNote xml:lang="nb">Se også: { $x }</skos:scopeNote>
				}{
					(: Ignore overordnetterm-id if the concept is a top concept! :)
					if ($post/toppterm-id/text() = $post/term-id/text()) then ()
					else for $x in $post/overordnetterm-id/text()
					return <skos:broader rdf:resource="{ emneregister:uriFromTermId( $uri_base, $x ) }"/>
				}{
					for $x in $post/ox-id/text()
					return <skos:broader rdf:resource="{ emneregister:uriFromTermId( $uri_base, $x ) }"/>
				}{
					for $x in $post/se-ogsa-id/text()
					return <skos:related rdf:resource="{ emneregister:uriFromTermId( $uri_base, $x ) }"/>
				}{
					if ($scheme = 'http://data.ub.uio.no/tekord') then
						<owl:sameAs rdf:resource="http://ntnu.no/ub/data/tekord#{ $post/term-id/text() }"/>
					else ()
				}
			</skos:Concept>
	}
};

declare function emneregister:toRdf( $posts as element()*, $scheme as xs:string, $uri_base as xs:string, $signature_handler as xs:string )
as element()*
{
	<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
		xmlns:skos="http://www.w3.org/2004/02/skos/core#"
		xmlns:dct="http://purl.org/dc/terms/">
	{ 
		emneregister:posts($posts, $scheme, $uri_base, $signature_handler)
	}
	</rdf:RDF>
};

declare function emneregister:stats( $posts as element()*)
as element()*{
	<stats>
		<count desc="Termer">{
			count( $posts )
		}</count>
		<count desc="Har kvalifikator">{
			count( $posts[kvalifikator] )
		}</count>
		<count desc="Har definisjon">{
			count( $posts[definisjon] )
		}</count>
		<count desc="Har noter">{
			count( $posts[noter] )
		}</count>
		<count desc="Knutetermer (type=K)">{
			count( $posts[type='K'] )
		}</count>
		<count desc="Fasettindikatorer">{
			count( $posts[type='F'] )
		}</count>
		<count desc="Indekstermer">{
			count( $posts[not(se-id) and not(gen-se-henvisning)] )
		}</count>
		<count desc="Se-henvisninger">{
			count( $posts[se-id] )
		}</count>
		<count desc="Generelle se-henvisninger">{
			count( $posts[gen-se-henvisning] )
		}</count>
		<count desc="Underemnefraser">{
			count( $posts[underemnefrase] )
		}</count>
	</stats>
};

(: To test a specific post: :)
(: emneregister:post(doc('humord.xml')/hume/post[descendant::term-id/text()="HUME18920"]) :)


