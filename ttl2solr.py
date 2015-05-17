from rdflib.graph import Graph, Literal
from rdflib.namespace import Namespace, URIRef, OWL, RDF, DC, DCTERMS, FOAF, XSD, SKOS, RDFS
import json

WD = Namespace('http://data.ub.uio.no/webdewey-terms#')


def convert(infile, outfile):
    g = Graph()
    g.load(infile, format='turtle')

    schema = {
        SKOS.prefLabel: 'prefLabel_t',  # _t for type:text, se Solr schema.xml
        SKOS.altLabel: 'altLabel_t',
        SKOS.definition: 'definition_t',
        SKOS.scopeNote: 'scopeNote_t',
        SKOS.notation: 'notation_s',  # string, right?
        WD.including: 'including_t',
        WD.classHere: 'classhere_t',
        WD.variantName: 'variantname_t',

        # Ignore:
        SKOS.editorialNote: None,  # eller bør vi ha den med så vi kan veksle den?? 'editorialNote_t',
        RDF.type: None,
        SKOS.inScheme: None,
        SKOS.topConceptOf: None,
        SKOS.broader: None,
        SKOS.related: None,
        SKOS.historyNote: None,
        OWL.sameAs: None,
        DCTERMS.identifier: None,
        DCTERMS.modified: None,
        WD.synthesized: None,
        WD.component: None
    }

    vocabs = {
        URIRef('http://data.ub.uio.no/ddc'): 'ddc23no',
        URIRef('http://data.ub.uio.no/humord'): 'humord'
    }

    docs = []

    # Build parent lookup hash
    parents = {}
    labels = {}
    for res in g.query("""
                       PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
                       PREFIX : <http://data.ub.uio.no/humord/>

                       SELECT ?concept ?parent ?label ?altlabel
                       WHERE {
                         ?parent ^skos:broader ?concept .
                         OPTIONAL { ?parent skos:prefLabel ?label . }
                         OPTIONAL { ?parent skos:altLabel ?altlabel . }
                       }
                       """):

        c = res[0].format()  # to string
        p = res[1].format()  # to string
        if c not in parents:
            parents[c] = set()
        parents[c].add(p)
        if res[2] is not None:
            labels[p] = res[2].value
        elif res[3] is not None:
            labels[p] = res[3].value

    for uriref in g.subjects(RDF.type, SKOS.Concept):
        doc = {'id': uriref.format()}

        for pred, obj in g.predicate_objects(uriref):
            if pred not in schema:
                print 'Encountered unknown predicate with no mapping to JSON: ', pred
                continue
            if pred == SKOS.inScheme and schema[pred] in vocabs:
                doc['vocab'] = vocabs[schema[pred]]
                continue
            if schema[pred] is None:
                continue
            if schema[pred] not in doc:
                doc[schema[pred]] = []

            doc[schema[pred]].append(obj.value)

        # Add labels from broader concepts

        byLevel = [[uriref.format()]]  # Level 0
        level = 0
        while True:
            byLevel.append([])
            for x in byLevel[level]:
                byLevel[level + 1].extend(parents.get(x, set()))
            if len(byLevel[level + 1]) == 0:
                break
            level += 1

        for level, items in enumerate(byLevel[1:-1]):
            # print level, items
            doc['parentsLevel{}'.format(level)] = [labels[x] for x in items if x in labels]  # Vi mangler labels for enkelt toppetiketter, som f.eks. 'http://data.ub.uio.no/ddc/19'

        docs.append(doc)

    json.dump(docs, open(outfile, 'w'), indent=2)


# convert('humord.ttl', 'humord_docs.json')
convert('ddc100-ddc199.999.ttl', 'ddc100-ddc199.999_docs.json')
