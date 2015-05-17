# encoding=utf8

from rdflib.graph import Graph, Literal
from rdflib.namespace import Namespace, URIRef, OWL, RDF, DC, DCTERMS, FOAF, XSD, SKOS, RDFS
import json
import argparse
import logging
import logging.handlers

logger = logging.getLogger()
logger.setLevel(logging.DEBUG)
formatter = logging.Formatter('[%(asctime)s %(levelname)s] %(message)s')

console_handler = logging.StreamHandler()
console_handler.setFormatter(formatter)
logger.addHandler(console_handler)

WD = Namespace('http://data.ub.uio.no/webdewey-terms#')


def convert(infile, outfile):
    logger.debug('Loading %s', infile)
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

    # Build parent lookup hash
    logger.debug('Building parent lookup hash')
    parents = {}
    for c, p in g.subject_objects(SKOS.broader):
        c = c.format()  # to string
        p = p.format()  # to string
        if c not in parents:
            parents[c] = set()
        parents[c].add(p)

    # Build labels lookup hash using two fast passes
    logger.debug('Building labels lookup hash')
    labels = {}
    for c, p in g.subject_objects(SKOS.altLabel):
        labels[c.format()] = p.value
    for c, p in g.subject_objects(SKOS.prefLabel):
        labels[c.format()] = p.value  # overwrite altLabel with prefLabel if found

    logger.debug('Building documents')
    docs = []
    for uriref in g.subjects(RDF.type, SKOS.Concept):
        doc = {'id': uriref.format()}

        for pred, obj in g.predicate_objects(uriref):
            if pred not in schema:
                logger.error('Encountered unknown predicate with no mapping to JSON: %s', pred)
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
            # logger.debug(level, items)
            doc['parentsLevel{}'.format(level)] = [labels[x] for x in items if x in labels]  # Vi mangler labels for enkelt toppetiketter, som f.eks. 'http://data.ub.uio.no/ddc/19'

        docs.append(doc)
    logger.debug('Generated %d documents', len(docs))

    logger.debug('Saving %s', outfile)
    json.dump(docs, open(outfile, 'w'), indent=2)


def main():

    parser = argparse.ArgumentParser(description='Convert Turtle to SOLR JSON')
    parser.add_argument('infile', nargs=1, help='Input Turtle file')
    parser.add_argument('outfile', nargs=1, help='Output SOLR JSON')
    parser.add_argument('-v', '--verbose', dest='verbose', action='store_true', help='More verbose output')

    args = parser.parse_args()

    if args.verbose:
        console_handler.setLevel(logging.DEBUG)
    else:
        console_handler.setLevel(logging.INFO)

    in_file = args.infile[0]
    out_file = args.outfile[0]

    convert(in_file, out_file)


if __name__ == '__main__':
    main()
