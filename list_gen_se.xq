xquery version "3.0";
declare variable $file external := 'humord.xml';

(: Warning: This query will be slow ( >~ 1 min on my computer)
   unless you add indexes on 'term-id' and 'hovedemnefrase' :)

declare function local:term($posts as element()*, $token as xs:string)
as element()*
{
    let $splitted := tokenize($token, ' \(')
	let $tlp := if (count($splitted) = 2) then
	    $posts/post[hovedemnefrase = $splitted[0] and kvalifikator = $splitted[1]]
	else
	    $posts/post[hovedemnefrase = $splitted[0] and not(exists(kvalifikator))]
    return if ($rlp/se-id) then
        $posts/post[term-id = $rlp/se-id][1]
    else
        $rlp[1]
};

declare function local:toppterm($posts as element()*, $token as xs:string)
as xs:string*
{
    let $ttid := local:term($posts, $token)/toppterm-id/text()[1]
    let $ttpost := $posts/post[term-id = $ttid]
    return 
        if (count($ttpost) = 0) then "(ikke funnet)"
        else $ttpost[1]/hovedemnefrase/text()
};


<posts>
{
    let $posts := doc($file)/*/ .
	for $post in $posts/post[gen-se-henvisning]
	return <post>
		{ $post/hovedemnefrase }
		{
		    let $parts := tokenize($post/gen-se-henvisning/text(), ' \* ')
		    return (
		        <part1>{ $parts[1] }</part1>,
		        <toppterm1>{ local:toppterm($posts, $parts[1]) }</toppterm1>,
		        
		            if (count($parts) > 1) then
		                (
		                    		        <part2>{ $parts[2] }</part2>,
		        <toppterm2>{ local:toppterm($posts, $parts[2]) }</toppterm2>) else ()
		        

		        )
		}
	</post>
}
</posts>