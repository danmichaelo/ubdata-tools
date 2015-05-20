(: Return all posts with <underemnefrase> :)

declare variable $file external := 'usvd.xml';

{
    for $post in doc( $file )/*/post[descendant::underemnefrase]
    return <post>
              {$post/term-id}
              {$post/hovedemnefrase}
              {$post/underemnefrase}
           </post>
}
