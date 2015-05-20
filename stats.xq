import module namespace emneregister="http://ub.uio.no/emneregister"
  at "emneregister.xq";

declare variable $file external := 'humord.xml';
declare variable $base external := 'hume';

emneregister:stats( doc( $file )/*[name()=$base]/post )
