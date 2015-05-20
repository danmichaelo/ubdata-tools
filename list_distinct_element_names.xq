(: Return all distinct element names :)
declare variable $file external := 'humord.xml';

<nodes>
{
	for $x in distinct-values(doc( $ file )//*/name())
	return element {$x} {''}
}
</nodes>
