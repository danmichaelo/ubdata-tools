import module namespace emneregister="http://ub.uio.no/emneregister"
  at "emneregister.xq";

declare variable $file external := 'humord.xml';
declare variable $base external := 'hume';
declare variable $scheme external := 'http://data.ub.uio.no/humord';
declare variable $uri_base external := concat($scheme, '/c');
declare variable $signature_handler external := 'ddc';

emneregister:toRdf( doc( $file )/*[name()=$base]/post, $base, $scheme, $uri_base, $signature_handler)

(: To test a specific post: :)
(: emneregister:post(doc('humord.xml')/hume/post[descendant::term-id/text()="HUME18920"]) :)
