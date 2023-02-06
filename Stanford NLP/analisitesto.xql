xquery version 3.1

declare namespace tei = 'http://www.tei-c.org/ns/1.0';

import module namespace nlp = "http://exist-db.org/xquery/stanford-nlp";

let $properties := json-doc("/db/apps/stanford-nlp/data/StanfordCoreNLP-italian.json")

let $text := doc("db/apps/postille/filexml/postille.xml")//tei:body[position()=2]

return nlp:parse($text, $properties)
