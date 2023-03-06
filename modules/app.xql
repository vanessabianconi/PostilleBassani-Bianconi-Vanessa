xquery version "3.1";

(:~ This is the defppult application library module of the postille app.
 :
 : @author Vanessa
 : @version 1.0.0
 : @see http://exist-db.org
 :)

(: Module for app-specific template functions :)
module namespace app="http://exist-db.org/apps/postille/templates";
import module namespace templates="http://exist-db.org/xquery/html-templating";
import module namespace lib="http://exist-db.org/xquery/html-templating/lib";
import module namespace config="http://exist-db.org/apps/postille/config" at "config.xqm";
(: modulo stanford nlp ner :)
import module namespace ner = "http://exist-db.org/xquery/stanford-nlp/ner";
import module namespace nlp="http://exist-db.org/xquery/stanford-nlp";
(: modulo kwic :)
import module namespace kwic= "http://exist-db.org/xquery/kwic";
(: dichiarazione namespace tei :)
declare namespace tei = 'http://www.tei-c.org/ns/1.0';

declare namespace functx = "http://www.functx.com";
(:~
 : This is a sample templating function. It will be called by the templating module if
 : it encounters an HTML element with an attribute: data-template="app:test" or class="app:test" (deprecated).
 : The function has to take 2 default parameters. Additional parameters are automatically mapped to
 : any matching request or function parameter.
 :
 : @param $node the HTML node with the attribute which triggered this call
 : @param $model a map containing arbitrary data - used to pass information between template calls
 :)

declare
    %templates:wrap
function app:foo($node as node(), $model as map(*)) {
    <p>Dummy templating function.</p>
};

declare function app:test($node as node(), $model as map(*)) {
    <p>Dummy template output generated by function app:test at {current-dateTime()}. The templating
        function was triggered by the class attribute <code>class="app:test"</code>.</p>
};
(: funzione che serve per inserire una sottostringa in una posizione specifica (trovata online) :)
declare function functx:insert-string
  ( $originalString as xs:string? ,
    $stringToInsert as xs:string? ,
    $pos as xs:integer )  as xs:string {

   concat(substring($originalString,1,$pos - 1),
             $stringToInsert,
             substring($originalString,$pos))
 } ;
 (: funzione che serve per rendere maiuscolo il primo carattere della stringa (trovata online) :)
 declare function functx:capitalize-first
  ( $arg as xs:string? )  as xs:string? {

   concat(upper-case(substring($arg,1,1)),
             substring($arg,2))
 } ;

(: funzione che stampa il titolo. Uso %templates:wrap per preservare l'elemento h1 che ho definito nell'html :)
declare
%templates:wrap
function app:stampa-titolo($node as node(), $model as map(*)) {
    let $titolo := doc( $config:app-root || "/filexml/postille.xml" )/tei:TEI/tei:teiHeader/tei:fileDesc/tei:titleStmt
    return data($titolo/tei:title)
};

(: funzione che gestisce il titolo del dettaglio immagine. In questo caso ho usato il templates wrap in modo da preservare l'h5 definito nel file HTML :)
declare %templates:wrap  function app:titoloimmagine($node as node(), $model as map(*), $immagine as xs:string?){
    let $titoloimg := functx:insert-string($immagine,'ina ',4)
    let $maiuscolo := functx:capitalize-first($titoloimg)
    return
    if($immagine = "Copertina.jpg")
    then 
        "Copertina libro"
    else if($immagine = "Frontespizio1.jpg" or $immagine = "Frontespizio2.jpg")
    then
        "Frontespizio"
    else if($immagine = "Foglio di guardia anteriore.jpg")
    then 
        "Foglio di guardia anteriore"
    else if($immagine = "Indice.jpg")
    then "Indice"
    else 
        replace($maiuscolo, '.jpg', '')
};

(: funzione che serve per stampare una stringa in base allo strumento usato da Bassani per postillare la pagina :)
declare function app:handverbali($immagine as xs:string?){
    let $nuovo := replace($immagine, '.jpg', '')
    let $line := doc( $config:app-root || "/filexml/postille.xml")/tei:TEI/tei:sourceDoc/tei:surface[@xml:id=$nuovo]//tei:zone
    return
    if($line/@hand = "#m1")
    then
        <div class="strumentousato">
        <h6> Strumento usato:</h6>
        <p>Lapis</p>
        </div>
    else if($line/@hand = "#m2")
    then 
        <div class="strumentousato">
        <h6> Strumento usato:</h6>
        <p style="color:red">Matita rossa</p>
        </div>
    else if($line/@hand = "#m3")
    then 
        <div class="strumentousato">
        <h6> Strumento usato:</h6>
        <p style="color:blue">Matita blu</p>
        </div>
    else ()
        
};

(: funzione che prende la lista delle immagini (dal file json) :)
declare function app:immagini(){
    let $prova := unparsed-text($config:app-root ||"/filejson/images.json") => json-to-xml()
    for $i in $prova//fn:string
    return $i
};

(: funzione che gestisce i titoli delle thumbnails :)
declare function app:titolothumb($url as xs:string){
    let $titoloimg := functx:insert-string($url,'ina ',4)
    let $maiuscolo := functx:capitalize-first($titoloimg)
    return
    if($url = "Copertina.jpg")
    then 
        <strong id="copertina"> Copertina libro </strong>
    else if($url = "Frontespizio1.jpg" or $url = "Frontespizio2.jpg")
    then
        <strong>Frontespizio</strong>
    else if($url = "Foglio di guardia anteriore.jpg")
    then 
        <strong> Foglio di guardia</strong>
    else if($url = "Indice.jpg")
    then <strong> Indice </strong>
    else 
        <strong>{replace($maiuscolo, '.jpg', '')}</strong>
    
};

(: funzione scritta per la creazioni delle thumbnails delle immagini :)
declare function app:thumb($node as node(), $model as map(*), $url){
    let $doc := app:immagini()
    for $url in $doc
        return
            <div id="thumb">
            {app:titolothumb($url)}
            <a class="info" href="riproduzioni/{$url}" title="{$url}">
        <img src="riproduzioni/{$url}" width="100" heigth="100"></img>
        </a>
        <br/>
        <div class="icons">
            <form action="mostra.html" method="GET">
                <input type="hidden" name="immagine" value="{$url}"/>
            <button type="submit">
            <img width="16" heigth="16" title="dettaglio" alt="dettaglio" src="resources/images/iconimg.png"/>
            </button>
            </form>
        </div>
        </div>
};
(: da togliere 
declare function app:mostraimg($node as node(), $model as map(*), $immagine){
    <img src="riproduzioni/{$immagine}" width="300" heigth="300"></img>
        
};:)

(: inizio ricerca :)
(: funzione che gestisce il recupero del testo a stampa legato alle postille nella pagina "Ricerca" :)
declare function app:testoastampa($hit as node()){
    let $correspp := $hit/parent::tei:div/@corresp
    let $correspcorretto := replace($correspp, "#", "")
    let $item := doc($config:app-root || "/filexml/postille.xml")//tei:msItem[@xml:id=$correspcorretto]
    let $locus := $item//tei:locus[position() = 1]/@facs
    let $locusok := replace($locus[1], "#", "")
    let $zone := doc($config:app-root || "/filexml/postille.xml")//tei:zone[@xml:id=$locusok]
    let $zone1 := $zone/@corresp
    let $corresp2 := replace($zone1, "#", "")
    let $zone2 := doc($config:app-root || "/filexml/postille.xml")//tei:zone[@xml:id=$corresp2]
    let $start := replace($zone2/@start, "#", "")
    return 
        if(exists(doc($config:app-root ||"/filexml/postille.xml")//tei:div[@xml:id=$start]/tei:ab))
        then doc($config:app-root ||"/filexml/postille.xml")//tei:div[@xml:id=$start]/tei:ab
        else <p>Questa postilla non si riferisce a nessun testo a stampa</p>
};

(: funzione usata per visualizzare il link all'immagine nella pagina della ricerca :)
declare function app:stringaimmagine($hit as node()){
    let $div := $hit/parent::tei:div/@xml:id
    let $stringa := replace($div,"t", "")
    let $stringadef := functx:insert-string(functx:insert-string($stringa, 'pag', 1), '.jpg', 7)
    let $stringa2 := substring($stringa, 1, string-length($stringa) - 2)
    return 
        if(contains($stringa, '.'))
        then <a href="mostra.html?immagine={functx:insert-string(functx:insert-string($stringa2, 'pag', 1), '.jpg', 7)}">{functx:insert-string($stringa2, 'Pagina ', 1)}</a>
        else <a href="mostra.html?immagine={$stringadef}">{functx:insert-string($stringa, 'Pagina ', 1)}</a>
};

(: funzione che gestisce la ricerca di parole, usando un carattere jolly o wildcard :)
declare function app:cercawildcard($postille as xs:string?){
    let $query := <query>
        <bool><wildcard>{$postille}</wildcard></bool>
    </query>
    for $hit in doc($config:app-root ||"/filexml/postille.xml")//tei:p[ft:query(., $query)]
    let $expanded := kwic:expand($hit)
    order by ft:score($hit) descending
    return
        <tr>
        <td>{app:stringaimmagine($hit)}</td>
        <td>{$expanded}</td>
        <td>{app:testoastampa($hit)}</td>
        </tr>
};


(: funzione che stampa i risultati della ricerca wildcard :)
declare function app:wildcard($node as node(), $model as map(*), $postille as xs:string?){
    let $contaoccorrenze := count(app:cercawildcard($postille))
    return
    if($contaoccorrenze > 0)
    then 
        <div class="cercawild">
        <p><b>Tipo di ricerca:</b> Wildcard </p>
        <p> <b>Parola cercata: </b> {$postille}</p>
        <p><b>Postille trovate: </b> {$contaoccorrenze}</p>
        <div>
        <table>
        <tr>
            <th>Pagina</th>
            <th>Risultato</th>
            <th>Testo a stampa</th>
        </tr>
        {app:cercawildcard($postille)}
        </table>
        </div>
        </div>
    else ""
};

(: funzione che gestisce la ricerca fuzzy, basata sull'edit distance :)
declare function app:fuzzy($fuzzy as xs:string?){
    let $query := 
    <query>
        <bool><fuzzy>{$fuzzy}~</fuzzy></bool>
    </query>
    for $hit in doc($config:app-root ||"/filexml/postille.xml")//tei:p[ft:query(., $query)]
    order by ft:score($hit) descending
    let $expanded := kwic:expand($hit)
    return
        <tr>
        <td>{app:stringaimmagine($hit)}</td>
        <td>{$expanded}</td>
        <td>{app:testoastampa($hit)}</td>
        </tr>
    
};
(: funzione che stampa i risultati della ricerca fuzzy :)
declare function app:ricercafuzzy($node as node(), $model as map(*), $fuzzy as xs:string?){
    let $conta := count(app:fuzzy($fuzzy))
    return
    if($fuzzy != " " and $conta > 0)
    then 
        <div class="cercafuzzy">
        <p><b>Tipo di ricerca:</b> Fuzzy </p>
        <p> <b>Parola cercata: </b> {$fuzzy}</p>
        <p><b>Postille trovate: </b> {$conta}</p>
        <div>
        <table>
        <tr>
            <th>Pagina</th>
            <th>Risultato</th>
            <th>Testo a stampa</th>
        </tr>
        {app:fuzzy($fuzzy)}
        </table>
        </div>
        <hr></hr>
        </div>
    else ""
};

(: funzione che gestisce la ricerca di termini vicini :)
declare function app:input($distanza as xs:string?){
let $termnumero := request:get-parameter("input", "")
        let $query := <near slop="{$distanza}" ordered="no">
    {
        for $n in $termnumero return 
        <term occur="must">{$n}</term>
    }
        
    </near> 
     for $hit in doc($config:app-root ||"/filexml/postille.xml")//tei:p[ft:query(., $query)]
    let $expanded := kwic:expand($hit)
    return
        <tr>
        <td>{app:stringaimmagine($hit)}</td>
        <td>{$expanded}</td>
        <td>{app:testoastampa($hit)}</td>
        </tr>
};

(: funzione che stampa la ricerca di termini vicini :)
declare function app:cercatermini($node as node(), $model as map(*), $distanza as xs:integer?){
    let $termini := request:get-parameter("input", "")
    let $conta := count(app:input($distanza))
    return
    if($conta > 0)
    then
        <div class="cercadoppio">
            <p><b>Tipo di ricerca:</b> termini vicini </p>
            <p><b>Termini cercati: </b>{for $n in $termini return
            $n}</p>
            <p><b>Distanza selezionata: </b>{$distanza} </p>
            <p><b>Occorrenze: </b>{count(app:input($distanza))}</p>
            <div>
                <table>
                    <thead>
                        <tr>
                            <th>Pagina</th>
                            <th>Risultato</th>
                            <th>Testo a stampa</th>
                    </tr>
                    </thead>
            {app:input($distanza)}
            </table>
            </div>
        </div>
        
    else ""
};

(: funzione che gestisce la creazione della select per la ricerca delle entità nominate :)
declare %templates:wrap function app:personecitate($node as node(), $model as map(*)){
let $listapersone := doc($config:app-root ||"/filexml/postille.xml")//tei:listPerson
return
    <span>
        <label for="persone">Persone citate:</label>
        <select name="persona" required="yes">
        <option value="">seleziona...</option>
        {for $i in $listapersone/tei:person
        return
            <option value="{$i/@xml:id}">{$i}</option>
        }
        </select>
        </span>
};

(: funzione che gestisce la ricerca di entità nominate :)
declare function app:cercapersonecitate($persona as xs:string?){
    for $hit in doc($config:app-root ||"/filexml/postille.xml")//tei:p[ft:query(., $persona)]
    let $expanded := kwic:expand($hit)
    order by ft:score($hit) descending
    return
        <tr>
        <td>{app:stringaimmagine($hit)}</td>
        <td>{for $match in $expanded//exist:match 
        return
        kwic:get-summary($expanded, $match, <config width="60"/>)}</td>
        <td>{app:testoastampa($hit)}</td>
        </tr>
};

(: funzione che stampa la ricerca delle entità nominate :)
declare function app:stampapersonecitate($node as node(), $model as map(*), $persona as xs:string?){
    let $conta := count(app:cercapersonecitate($persona))
    return
    if($persona != " " and $conta > 0)
    then 
        <div class="risultato">
        <p> <b>Persona selezionata: </b> {$persona}</p>
        <p><b>Occorrenze: </b> {$conta}</p>
        <div>
        <table>
        <tr>
            <th>Pagina</th>
            <th>Risultato</th>
            <th>Testo a stampa</th>
        </tr>
        {app:cercapersonecitate($persona)}
        </table>
        </div>
        </div>
    else ""
};

(: funzione che crea i bottoni del vocabolario dell'antifascismo, tramite un file json, all'interno del quale ho inserito la lista delle parole selezionate :)
declare function app:parolevoc($node as node(), $model as map(*)){
    let $parole:= unparsed-text($config:app-root ||"/filejson/antifascismo.json") => json-to-xml()
    for $i in $parole//fn:string
    order by $i
    return 
        <form method="GET">
            <input type="hidden" name="parola" value="{$i}"/>
            <button type="submit" class="btn btn-danger">{functx:capitalize-first($i)}</button>
        </form>
};

(: funzione che gestisce la ricerca delle parole del vocabolario dell'antifascismo :)
declare function app:cercaparolevoc($parola as xs:string?){
    for $hit in doc($config:app-root || "/filexml/postille.xml")//tei:p[ft:query(., $parola)]
    let $expanded := kwic:expand($hit)
    return
    <tr>
        <td>{app:stringaimmagine($hit)}</td>
        <td>{$expanded}</td>
        <td>{app:testoastampa($hit)}</td>
    </tr>
};

(: funzione che stampa i risultati del vocabolario dell'antifascismo :)
declare %templates:wrap function app:vocabolario($node as node(), $model as map(*), $parola as xs:string?){
    let $conta := count(app:cercaparolevoc($parola))
    return
    if($parola != " " and $conta > 0)
    then 
        <div class="vocabolario">
        <p> <b>Parola selezionata: </b> {$parola}</p>
        <p><b>Occorrenze: </b> {$conta}</p>
        <div>
        <table class="tablevoc">
        <tr>
            <th>Pagina</th>
            <th>Risultato</th>
            <th>Testo a stampa</th>
        </tr>
        {app:cercaparolevoc($parola)}
        </table>
        </div>
        </div>
    else if(not($parola))
    then ""
    else ""
};



(: fine ricerca :)

declare function app:citazioni($immagine as xs:string){
    let $i := "ciao"
    return
    if($immagine = "pag4.jpg" or $immagine = "pag119.jpg")
    then
        <p><h6>Persone citate:</h6>
            <a href="https://it.wikipedia.org/wiki/Rainer_Maria_Rilke">Rainer Maria Rilke</a>
        </p>
    else if($immagine = "pag13.jpg")
    then
        <p><h6>Persone citate:</h6>
            <a href="https://it.wikipedia.org/wiki/Giovanni_Papini">Giovanni Papini</a>
        </p>
    else if($immagine = "pag29.jpg")
    then
        <p><h6>Persone citate:</h6>
            <a href="https://www.treccani.it/enciclopedia/guido-calogero_(Dizionario-Biografico)">Guido Calogero</a>
        </p>
    else if($immagine = "pag34.jpg" or $immagine = "pag96.jpg")
    then 
        <p><h6>Persone citate:</h6>
            <a href="https://it.wikipedia.org/wiki/Benedetto_Croce">Benedetto Croce</a>
        </p>
    else if($immagine = "pag77.jpg")
    then
        <p>
            <h6>Persone citate:</h6>
            <a href="https://it.wikipedia.org/wiki/Aldo_Capitini">Aldo Capitini</a> <br/>
            <a href="https://it.wikipedia.org/wiki/Mahatma_Gandhi">Mohandas Karamchand Gandhi</a> <br/>
            <a href="https://it.wikipedia.org/wiki/Francesco_d%27Assisi">San Francesco d'Assisi</a>
        </p>
    else if($immagine = "pag103.jpg")
    then 
        <p>
            <h6>Persone citate: </h6>
            <a href="https://it.wikipedia.org/wiki/Francesco_Guicciardini">Francesco Guicciardini</a>
        </p>
    else if($immagine = "pag169.jpg")
    then
        <p>
            <h6>Persone citate:</h6>
            <a href="https://it.wikipedia.org/wiki/Gianfranco_Contini">Gianfranco Contini</a>
        </p>
    else ()
};

(: funzione creata per la pagina 152 che contiene il verso di una poesia di Ungaretti :)
declare function app:ungaretti($immagine as xs:string?){
       if($immagine = "pag152.jpg")
       then <div>
           In questa postilla Bassani cita il verso 15 della poesia <a href="https://www.poeticous.com/giuseppe-ungaretti/auguri-per-il-proprio-compleanno">"Auguri per il proprio compleanno"</a> di Giuseppe Ungaretti.
            </div>
       else ""
    
};

(: funzione per la creazione dei tasti usati per navigare tra le postille di una stessa pagina :)
declare function app:bootstrap($node as node(), $model as map(*), $immagine as xs:string){
    let $immaginestr := replace($immagine, '.jpg', '')
    let $doc := doc($config:app-root ||"/filexml/postille.xml")
let $linea := $doc/tei:TEI/tei:sourceDoc/tei:surface[@xml:id=$immaginestr]//tei:zone
return 
    if($linea/descendant::tei:line)
    then
        <span class="postilleverbalidiv">
    <h4> Postille verbali</h4>
    <ul class="">
    <a class="linkpost" style="display:none"></a>
    {
for $i at $t in $linea
return
if ($i/@corresp and $i/child::tei:line and $linea[position() = 1])then
let $testo := $doc/tei:TEI/tei:text/tei:group/tei:text/tei:body
where data($i/@corresp) = data($testo/tei:div/@facs) and $i/descendant::tei:line
return
	    <li class="btn btn-danger postillamostra"><a href="#{replace($i/@xml:id, '\.', '')}" class="linkpost" data-toggle="tab"></a></li>
	else if(not($i//@corresp) and $i/child::tei:line)
	then <li class="btn btn-danger postillamostra"><a href="#{replace($i/@xml:id, '\.', '')}" class="linkpost" data-toggle="tab"></a></li>
    else ""}
    </ul>
    </span>
    else ""
};

(: funzione per l'analisi automatica delle postille, tramite StanfordNLP :)
declare function app:stanfordNLP($i){
    let $properties := json-doc($config:app-root || "/Stanfordnlp/StanfordCoreNLP-italian.json")
        return <div id="{replace(replace($i/@corresp, "#",""),'\.','')}an" style="display:none; overflow-y:scroll; height:400px;" class="analisix"><textarea readonly="yes" rows="10" style="margin-top:10px">
        {let $funzione := nlp:parse($i, $properties)//token
        for $k in $funzione
        return <StanfordNLP>{$k//word} {$k//POS} {$k//NER}
        </StanfordNLP>
        }</textarea></div>
};

(: funzione che stampa i dettagli delle postille verbali :)
declare function app:noteverbali($i, $immagine as xs:string){
    let $doc := doc($config:app-root ||"/filexml/postille.xml")
    let $immaginestr := replace($immagine, '.jpg', '')
    return
    if($i//@corresp) then
    let $note := $doc/tei:TEI//tei:msContents//tei:msItem/tei:note
        return <div id="{replace(replace($i/@corresp, "#",""),'\.','')}det" style="display: none; clear:both;">
        {
            for $n in $note
            where replace(data($n/preceding-sibling::tei:locus/@facs), '#', '') = data($i/@xml:id) and $i/descendant::tei:line
            return 
            <div>
            <h6> Note:</h6>
            <p>{$n}</p>
            <p><h6>Categorie:</h6>
                {replace(replace(replace(data($n/parent::tei:msItem/@class),"#", ''), " ", ", "),"_", " ")}</p>
                {if($n/preceding-sibling::tei:textLang)
                then <p>
                    <h6>Lingua:</h6>
                    {$n/preceding-sibling::tei:textLang}
                    </p>
                else <p>
                    <h6>Lingua:</h6>italiano</p>
        } 
                {app:handverbali($immagine)}
                {app:citazioni($immagine)}
                {app:ungaretti($immagine)}
            </div>
        }
        
        <hr></hr>
        </div>
        else if(not($i/@corresp))then
            let $note := $doc/tei:TEI//tei:msContents//tei:msItem/tei:note
            return <div id="{replace($i/@xml:id,'\.','')}det" style="display: none;">
            {
            for $n in $note
            where replace(data($n/preceding-sibling::tei:locus/@facs), '#', '') = data($i/@xml:id) and $i/descendant::tei:line
            return 
            <div>
            <h6> Note:</h6>
            <p>{$n}</p>
            <p><h6>Categorie:</h6>
                {replace(replace(replace(data($n/parent::tei:msItem/@class),"#", ''), " ", ", "),"_", " ")}</p>
                {if($n/preceding-sibling::tei:textLang)
                then <p>
                    <h6>Lingua:</h6>
                    {$n/preceding-sibling::tei:textLang}
                    </p>
                else <p>
                    <h6>Lingua:</h6>italiano</p>
            }
            {app:handverbali($immagine)}
                {app:citazioni($immagine)}
                {app:ungaretti($immagine)}
        
        </div>
        }
        </div>
        else ""
};

(: funzione che stampa le postille verbali con il testo a stampa :)
declare function app:postilleverbali($node as node(), $model as map(*), $immagine as xs:string){
let $immaginestr := replace($immagine, '.jpg', '')
let $doc := doc($config:app-root ||"/filexml/postille.xml")
let $linea := $doc/tei:TEI/tei:sourceDoc/tei:surface[@xml:id=$immaginestr]//tei:zone
return 
    if($linea/descendant::tei:line)
    then
<div class="tab-content">
    {
for $i in $linea
return
if ($i/@corresp and $i/child::tei:line) then
let $testo := $doc/tei:TEI/tei:text/tei:group/tei:text/tei:body
where data($i/@corresp) = data($testo/tei:div/@facs) and $i/descendant::tei:line
return
        <div id="{replace($i/@xml:id, '\.', '')}" class="tab-pane">
		<div>
        
        <h6>Postilla:</h6>
        {for $t in $i/tei:line
        return 
        <div id="postillav">{$t}<br></br></div>
        }
        <br></br>
        <h6>Testo:</h6>
        <p style="background-color: powderblue;">"{$testo/tei:div[@facs = $i/@corresp]/tei:ab}"</p>
        <button type="button" class="dettagli1 btn btn-primary" rel="{replace(replace($i/@corresp, "#",""),'\.','')}det"> Dettagli </button> <button type="button" class="analisi btn btn-dark" rel="{replace(replace($i/@corresp, "#",""),'\.','')}an"> Analisi linguistica </button> <button type="button" class="fenomeni btn btn-secondary">Interventi autoriali</button><br></br></div>
        {app:stanfordNLP($i)}
        {app:noteverbali($i, $immagine)}
        </div>
    else if(not($i//@corresp) and $i/child::tei:line) then 
        <div id="{replace($i/@xml:id, '\.', '')}" class="tab-pane">
        <h6>Postilla</h6>
        {for $t in $i/tei:line
        return 
        <div id="postillav">{$t}<br></br></div>
        }
        <button type="button" class="dettagli1 btn btn-primary" rel="{replace($i/@xml:id,'\.','')}det"> Dettagli </button> <button type="button" class="analisi btn btn-dark" rel="{replace(replace($i/@corresp, "#",""),'\.','')}an"> Analisi linguistica </button>
        <button type="button" class="fenomeni btn btn-secondary">Interventi autoriali</button><br></br>
        {app:stanfordNLP($i)}
        {app:noteverbali($i, $immagine)}
        </div>
        
    else ""}
    </div>
    else <p>In questa pagina non sono presenti postille verbali</p>
};

(: funzione che stampa le postille non verbali con il testo a stampa :)
declare function app:postmute($node as node(), $model as map(*), $immagine as xs:string){
    let $immaginestr := replace($immagine, '.jpg', '')
    let $doc := doc($config:app-root || "/filexml/postille.xml")
    let $linea := $doc/tei:TEI/tei:sourceDoc/tei:surface[@xml:id=$immaginestr]//tei:zone
    return 
        if($immagine = "pag157.jpg" or $immagine = "pag39.jpg")
        then <div>Non sono presenti postille non verbali in questa pagina</div>
        else 
        if($linea/descendant::tei:metamark)
        then
            <div class="postillemutediv">
            <h4>Postille non verbali</h4>
            <div>
                {
                    for $i in $linea
                    let $testo := $doc/tei:TEI/tei:text/tei:group/tei:text/tei:body
                    where data($i/@corresp) = data($testo/tei:div/@facs) and $i/descendant::tei:metamark
                    return
                        <div>
                        {if($i/descendant::tei:metamark/@rend = "wavy" and $i/descendant::tei:metamark/@place = "vertical_line" or $i/descendant::tei:metamark/@place = "vertical line")
                        then
                            <div><img src="https://img.icons8.com/material-sharp/24/000000/squiggly-line.png"/>Barra laterale ondulata: <br/> <p style="background-color: powderblue;">"{$testo/tei:div[@facs = $i/@corresp]/tei:ab}"</p></div>
                            else if($i/descendant::tei:metamark/@rend = "underlining" and $i/descendant::tei:metamark/@place = "inline")
                            then 
                            <div><span class="bi bi-type-underline"></span>Testo sottolineato:<br/> <p style="background-color: powderblue;">"{$testo/tei:div[@facs = $i/@corresp]/tei:ab}"</p></div>
                        else if($i/descendant::tei:metamark/@rend = "straight" or $i/descendant::tei:metamark/@rend = "underlining"  and $i/descendant::tei:metamark/@place = "vertical_line" or $i/descendant::tei:metamark/@place = "vertical line")
                            then 
                            <div><img src="https://img.icons8.com/material-rounded/24/000000/vertical-line.png"/>Linea verticale: <br/> <p style="background-color: powderblue;">"{$testo/tei:div[@facs = $i/@corresp]/tei:ab}"</p></div>
                        else if($i/descendant::tei:metamark/@rend = "square_bracket_and_straight_vertical_line")
                        then
                                <div><img src="resources/images/mega-creator-4.png" width="24" height="24"/>Parentesi quadra e linea verticale:<br/> <p style="background-color: powderblue;">"{$testo/tei:div[@facs = $i/@corresp]/tei:ab}"</p></div>
                        else if($i/descendant::tei:metamark/@rend = "double_straight" or $i/descendant::tei:metamark/@rend = "doppia" and $i/descendant::tei:metamark/@place = "vertical_line")
                        then
                            <div><span class="bi bi-pause" width="32" height="32"></span>Doppia barra laterale: <br/> <p style="background-color: powderblue;">"{$testo/tei:div[@facs = $i/@corresp]/tei:ab}"</p></div>
                            else if($i/descendant::tei:metamark/@rend = "wavy" and $i/descendant::tei:metamark/@place = "inline")
                            then
                                <div><img src="https://img.icons8.com/material-two-tone/24/000000/wavy-line.png"/> Sottolineatura ondulata: <br/> <p style="background-color: powderblue;">"{$testo/tei:div[@facs = $i/@corresp]/tei:ab}"</p></div>
                            else if($i/descendant::tei:metamark/@rend = "pound_sign")
                            then <div><img src="https://img.icons8.com/ios/24/000000/hashtag.png"/>Cancelletto: <br/> <p style="background-color: powderblue;">"{$testo/tei:div[@facs = $i/@corresp]/tei:ab}"</p></div>
                            else if($i/descendant::tei:metamark/@rend = "square_bracket" or $i/descendant::tei:metamark/@rend = "parentesi_quadra" or $i/descendant::tei:metamark/@rend ="corner_bracket")
                            then <div><img src="resources/images/pquadra.png" width="24" height="24"/>Parentesi quadra: <br/> <p style="background-color: powderblue;">"{$testo/tei:div[@facs = $i/@corresp]/tei:ab}"</p></div>
                            else if($i/descendant::tei:metamark/@rend = "vertical_wavy_line_and_plus_sign")
                            then <div><img src="resources/images/mega-creator-2.png" width="24" height="24"/>Segno più e linea verticale ondulata: <br/> <p style="background-color: powderblue;">"{$testo/tei:div[@facs = $i/@corresp]/tei:ab}"</p></div>
                            else if($i/descendant::tei:metamark/@rend = "asterisk")
                            then <div><img src="https://img.icons8.com/material-two-tone/24/000000/asterisk.png"/>Asterisco: <br/> <p style="background-color: powderblue;">"{$testo/tei:div[@facs = $i/@corresp]/tei:ab}"</p></div>
                            else if($i/descendant::tei:metamark/@rend = "double_straight_line_and_ics")
                            then <div><img src="resources/images/mega-creator-3.png" width="24" height="24"/>Linea verticale doppia e ics: <br/> <p style="background-color: powderblue;">"{$testo/tei:div[@facs = $i/@corresp]/tei:ab}"</p></div>
                            else if($i/descendant::tei:metamark/@rend = "vertical_wavy_line_and_asterisk")
                            then <div><img src="resources/images/mega-creator-5.png" width="24" height="24"/>Linea verticale ondulata e asterisco: <br/> <p style="background-color: powderblue;">"{$testo/tei:div[@facs = $i/@corresp]/tei:ab}"</p></div>
                            else if($i/descendant::tei:metamark/@rend = "square_barcket_and_ics")
                            then <div><img src="resources/images/mega-creator-6.png" width="24" height="24"/>Parentesi quadra e ics: <br/> <p style="background-color: powderblue;">"{$testo/tei:div[@facs = $i/@corresp]/tei:ab}"</p></div>
                            else if($i/descendant::tei:metamark/@rend = "ics")
                            then <div><img src="https://img.icons8.com/fluency-systems-regular/24/000000/x.png"/>ics: <br/> <p style="background-color: powderblue;">"{$testo/tei:div[@facs = $i/@corresp]/tei:ab}"</p></div>
                            else if($i/descendant::tei:metamark/@rend = "vertical_wavy_line_and_dash")
                            then <div><img src="resources/images/mega-creator-7.png" width="24" height="24"/>Linea verticale ondulata e trattino: <br/> <p style="background-color: powderblue;">"{$testo/tei:div[@facs = $i/@corresp]/tei:ab}"</p></div>
                            else if($i/descendant::tei:metamark/@rend = "double_wavy" and $i/descendant::tei:metamark/@place = "vertical_line")
                            then <div><img src="resources/images/mega-creator-8.png" width="24" height="24"/>Doppia linea ondulata verticale: <br/> <p style="background-color: powderblue;">"{$testo/tei:div[@facs = $i/@corresp]/tei:ab}"</p></div>
                            else if($i/descendant::tei:metamark/@rend = "double_curve")
                            then <div><img src="resources/images/mega-creator-9.png" width="24" height="24"/>Parentesi tonda doppia: <br/> <p style="background-color: powderblue;">"{$testo/tei:div[@facs = $i/@corresp]/tei:ab}"</p></div>
                            else if($i/descendant::tei:metamark/@rend = "triple_straight")
                            then <div><img src="resources/images/mega-creator-10.png" width="24" height="24"/>Linea tripla verticale: <br/> <p style="background-color: powderblue;">"{$testo/tei:div[@facs = $i/@corresp]/tei:ab}"</p></div>
                            else if($i/descendant::tei:metamark/@rend = "vertical_wavy_line_and_pound_sign")
                            then <div><img src="resources/images/mega-creator-11.png" width="24" height="24"/>Linea verticale ondulata e cancelletto: <br/> <p style="background-color: powderblue;">"{$testo/tei:div[@facs = $i/@corresp]/tei:ab}"</p></div>
                            else if($i/descendant::tei:metamark/@rend = "double_slash")
                            then <div><img src="resources/images/mega-creator-12.png" width="24" height="24"/>Doppio slash: <br/> <p style="background-color: powderblue;">"{$testo/tei:div[@facs = $i/@corresp]/tei:ab}"</p></div>
                            else if($i/descendant::tei:metamark/@rend = "oblique_line" and $i/descendant::tei:metamark/@function = "correction_of_misprint")
                            then <div><img src="https://img.icons8.com/external-outline-black-m-oki-orlando/24/000000/external-slash-math-vol-1-outline-outline-black-m-oki-orlando.png"/>Correzione di un errore di stampa (slash): <br/> <p style="background-color: powderblue;">"{$testo/tei:div[@facs = $i/@corresp]/tei:ab}"</p></div>
                            else if($i/descendant::tei:metamark/@rend = "vertical_wavy_line_and_ics")
                            then <div><img src="resources/images/mega-creator-13.png" width="24" height="24"/>Linea verticale ondulata e ics: <br/> <p style="background-color: powderblue;">"{$testo/tei:div[@facs = $i/@corresp]/tei:ab}"</p></div>
                            else if($i/descendant::tei:metamark/@rend = "angle_bracket")
                            then <div><img src="https://img.icons8.com/material-rounded/24/000000/less-than.png"/> Parentesi angolata: <br/> <p style="background-color: powderblue;">"{$testo/tei:div[@facs = $i/@corresp]/tei:ab}"</p></div>
                            else if($i/descendant::tei:metamark/@rend = "double_square_bracket")
                            then <div><img src="https://img.icons8.com/ios-glyphs/24/000000/square-brackets.png"/>Doppia parentesi quadra: <br/> <p style="background-color: powderblue;">"{$testo/tei:div[@facs = $i/@corresp]/tei:ab}"</p></div>
                            else if($i/descendant::tei:metamark/@rend = "curve")
                            then <div><img src="resources/images/parentesitonda.png" width="24" height="24"/>Parentesi tonda: <br/> <p style="background-color: powderblue;">"{$testo/tei:div[@facs = $i/@corresp]/tei:ab}"</p></div>
                            else ""
                        }
                    </div>
                }
                </div>
                </div>
        else <p class="paramute">Non sono presenti postille non verbali in questa pagina</p>
};

(: funzione per la stampa del titolo nella pagina Archivio :)
declare%templates:wrap function app:stampatitolo2($node as node(), $model as map(*)){
    let $doc := doc($config:app-root || "/filexml/postille.xml")
    let $titolo := $doc//tei:biblStruct[@xml:id="Scuola_uomo"]/tei:monogr/tei:title
    return data($titolo)
};
(: metadati volume "La scuola dell'uomo" :)
declare function app:stampaautore($node as node(), $model as map(*)){
    let $doc := doc($config:app-root || "/filexml/postille.xml")
    let $autore := $doc//tei:biblStruct[@xml:id="Scuola_uomo"]//tei:author
    return 
        <p id="autore"><b>Autore:</b>
        <a href="https://www.treccani.it/enciclopedia/guido-calogero_(Dizionario-Biografico)">{data($autore)}</a></p>
};

declare function app:stampaedizione($node as node(), $model as map(*)){
    let $doc := doc($config:app-root || "/filexml/postille.xml")
    let $edizione := $doc//tei:biblStruct[@xml:id="Scuola_uomo"]//tei:edition
    return
        <p id="edizione"><b>Edizione:</b>{data($edizione)}</p>
};

declare function app:stampaeditore($node as node(), $model as map(*)){
    let $doc := doc($config:app-root || "/filexml/postille.xml")
    let $editore := $doc//tei:biblStruct[@xml:id="Scuola_uomo"]//tei:imprint/tei:publisher
    let $luogo := $doc//tei:biblStruct[@xml:id="Scuola_uomo"]//tei:imprint/tei:pubPlace
    return 
        <p id="editore"><b>Casa editrice:</b>
        <a href="https://it.wikipedia.org/wiki/Sansoni">{data($editore)}</a>,{data($luogo)}</p>
};

declare function app:annoedizione($node as node(), $model as map(*)){
    let $doc := doc($config:app-root || "/filexml/postille.xml")
    let $anno := $doc//tei:biblStruct[@xml:id="Scuola_uomo"]//tei:imprint/tei:date
    return 
        <p id="annoedizione"><b>Anno:</b>{data($anno)}</p>
};


declare function app:serie($node as node(), $model as map(*)){
    let $doc := doc($config:app-root || "/filexml/postille.xml")
    let $serietit := $doc//tei:biblStruct[@xml:id="Scuola_uomo"]/tei:series/tei:title
    let $serienum := $doc//tei:biblStruct[@xml:id="Scuola_uomo"]/tei:series/tei:biblScope
    return
        <p id="serie"><b>Collana:</b>{data($serietit)}, {data($serienum)}</p>
};

declare function app:biblioteca($node as node(), $model as map(*)){
    let $doc := doc($config:app-root || "/filexml/postille.xml")
    let $biblioteca := $doc//tei:msDesc//tei:repository
    return
        <p><b>Conservato presso:</b>{data($biblioteca)}</p>
};

declare function app:biblioluogo($node as node(), $model as map(*)){
    let $doc := doc($config:app-root || "/filexml/postille.xml")
    let $biblioluogo := $doc//tei:msDesc//tei:institution
    let $luogobiblio := $doc//tei:msDesc//tei:settlement
    return
        <p><b>Luogo:</b><a href="https://www.fondazionegiorgiobassani.it">{data($biblioluogo)}</a>, {data($luogobiblio)}</p>
};
(: fine metadati :)

(: funzione usata per modificare la stringa durante la digitazione nell'input (cerca pagine) :)
declare
%templates:wrap  function app:titoloselect($immagine as xs:string?){
    let $titoloimg := functx:insert-string($immagine,'ina ',4)
    let $maiuscolo := functx:capitalize-first($titoloimg)
    return
    if($immagine = "Copertina.jpg")
    then 
        "Copertina libro"
    else if($immagine = "Frontespizio1.jpg" or $immagine = "Frontespizio2.jpg")
    then
        "Frontespizio"
    else if($immagine = "Foglio di guardia anteriore.jpg")
    then 
        "Foglio di guardia anteriore"
    else if($immagine = "Indice.jpg")
    then "Indice"
    else 
        replace($maiuscolo, '.jpg', '')
};

(: funzione che crea la select per la ricerca di pagine :)
declare function app:ricercapagine($node as node(), $model as map(*), $url){
    let $immagini := app:immagini()
    return 
        <form class="form-inline mt-2 mt-md-0 ricercaf">
            <select class="js-example-basic-multiple" multiple="multiple">
            {for $url in $immagini
            let $risultato := app:titoloselect($url)
                return
            <option value="mostra.html?immagine={$url}">{$risultato}</option>
            }
            </select>
        </form>
    
};
(: funzione che gestisce la comparsa della codifica xml (surface) :)
declare function app:codificaxml($node as node(), $model as map(*), $immagine as xs:string){
    let $immaginestr := replace($immagine, '.jpg', '')
    let $doc := doc($config:app-root || "/filexml/postille.xml")
    let $codifica := $doc/tei:TEI/tei:sourceDoc/tei:surface[@xml:id=$immaginestr]
    return
        <div class="codificaxml">
        <h5>Codifica</h5>
            <xmp>{$codifica}</xmp>
        </div>
    
};

