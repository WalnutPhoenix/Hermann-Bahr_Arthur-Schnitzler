xquery version "3.1";

module namespace app="http://hbas.at/templates";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace hbas="http://hbas.at/ns";


import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace config="http://hbas.at/config" at "config.xqm";
import module namespace format="http://hbas.at/format" at "format.xqm";
import module namespace kwic="http://exist-db.org/xquery/kwic";



(:~
 : This is a sample templating function. It will be called by the templating module if
 : it encounters an HTML element with an attribute data-template="app:test" 
 : or class="app:test" (deprecated). The function has to take at least 2 default
 : parameters. Additional parameters will be mapped to matching request or session parameters.
 : 
 : @param $node the HTML node with the attribute which triggered this call
 : @param $model a map containing arbitrary data - used to pass information between template calls
 :)
declare function app:test($node as node(), $model as map(*)) {
    <p>Dummy template output generated by function app:test at {current-dateTime()}. The templating
        function was triggered by the data-template attribute <code>data-template="app:test"</code>.</p>
};

(: --------------------------- Test für die Startseite - später löschen  ----------------------------------------- :)
(: Filtert die Ausgegeben Files nach Dokumenttypen :)

declare
    %templates:wrap
function app:list-files($node as node(), $model as map(*), $type, $id) {
    let $data-path := 
    switch($type)
    case "T" return $config:data-root || "/texts"
    case "D" return $config:data-root || "/diaries"
    case "L" return $config:data-root || "/letters"
    default return $config:data-root
    let $data := collection($data-path)
    for $doc in $data//tei:TEI
return 
    $doc/@xml:id/string()
};


(: ---------------------- correspDesc-Metadaten ---------------------------- :)
(: deprecated :)
declare function app:corresp-meta($id) {
    let $corresp-data := collection($config:data-root)/id($id)//tei:correspDesc
    return
        <div class="correspMeta">
            <span class="sender">{$corresp-data/tei:sender}</span>
            <span class="addressee">{$corresp-data/tei:addressee}</span>
            <span class="placeSender">{$corresp-data/tei:placeSender}</span>
            <span class="placeAddressee">{$corresp-data/tei:placeAddressee}</span>
            <span class="dateSender">{$corresp-data/tei:dateSender}</span>
        </div>
    
};

(: --------------------------- view.html - Seite  ----------------------------------------- :)

declare
 %templates:wrap
 %templates:default("type", "")
 function app:page_view($node as node(), $model as map(*),$id,$type,$date,$author,$show,$view-mode,$q) {
 (: 
  : Seite zeigt ein einzelnes Dokument an. Welches angezeigt werden soll, wird per $id übergeben.
  : $id xml:id des Dokuments
  : $type für Listenansicht: T texts, D diaries, L letters
  : $show steuert die Ansicht
 :)

let $output := if ($id!="") then
        app:view_single($id,$type,$show, $view-mode,$q)
    else
        app:view_list($type,$date,$author,$id,$q)
 return $output
 };

declare function app:view_list($type,$date,$author,$id,$q) {
    (:Gibt eine Liste mit allen verfügbaren Dokumenten aus:)
    if ($date!='' or $author!='') then 
        (:$date oder author gesetzt, weiter filtern:)
        if ($date!='') then
            (:"Datum gesetzt, Autor?":)
            if ($author!='') then  "Datum und Autor gesetzt" 
            
            else "Nur Datum gesetzt"
        else
            if ($type!='') then (: "Nur Autor gesetzt, Filter auf Typ":)
                if ($type="L") then "Briefe von einem Autor"
                else
            
            <div class="col-sm-9">
                <div class="title-box">
                <h2 class="doc-title">Nur Autor gesetzt, Filter auf Typ(aber nicht Brief)</h2>
            </div>
            </div>
            else
        <div class="col-sm-9">
            <div class="title-box">
                <h2 class="doc-title">Verfügbare Dokumente von {collection($config:data-root)/id($author)//tei:forename || " " || collection($config:data-root)/id($author)//tei:surname}</h2>
            </div>
            
            {
            
            for $doc in collection($config:data-root)//tei:fileDesc//tei:author[contains(@key,$author)]/ancestor::tei:TEI
        let $date := 
            switch (substring($doc/@xml:id/string(),1,1))
            case "T" return $doc//tei:origDate/@when/string()
            case "D" return $doc//tei:text//tei:date[@when][1]/@when/string()
            case "L" return $doc//tei:dateSender/tei:date/@when/string()
            default return $doc//tei:date[@when][1]/@when/string()
        order by $date ascending
            
    (:
    sortieren nach @when, @n:; bei Briefen sortieren nach senderDater > date ; bei Tagebuch body > date[1]
    bei Texten origDate
    :)
return
    <div class="docListItem">
        <span class="autor">{$doc//tei:titleStmt/tei:author/string()}</span>
        <a href="{concat('view.html?id=',$doc/@xml:id/string())}" class="title-link">{$doc//tei:titleStmt/tei:title[@level='a']/string()}</a>
    </div>
            
            }    
            
            
        </div>
    else (:$date oder $author nicht gesetzt:) 
    <div class="col-sm-9">
    <div class="title-box">
    <h2 class="doc-title">{
        switch($type)
                case "T" return "Texte"
                case "D" return "Tagebucheinträge"
                case "L" return "Briefe"
        default return "Dokumente"}
            
            </h2>
        </div>
    {
       let $data-path :=
       if ($type) then
            switch($type)
                case "T" return $config:data-root || "/texts"
                case "D" return $config:data-root || "/diaries"
                case "L" return $config:data-root || "/letters"
            default return $config:data-root
        else $config:data-root
    let $data := collection($data-path)
    for $doc in $data//tei:TEI[@xml:id]
        let $date := 
            switch (substring($doc/@xml:id/string(),1,1))
            case "T" return $doc//tei:origDate/@when/string()
            case "D" return $doc//tei:text//tei:date[@when][1]/@when/string()
            case "L" return $doc//tei:dateSender/tei:date/@when/string()
            default return $doc//tei:date[@when][1]/@when/string()
        order by $date ascending
            
    (:
    sortieren nach @when, @n:; bei Briefen sortieren nach senderDater > date ; bei Tagebuch body > date[1]
    bei Texten origDate
    :)
return
    <div class="docListItem doctype_{substring($doc/@xml:id/string(),1,1)}">
        <span class="autor">{$doc//tei:titleStmt/tei:author/string()}</span>
        <a href="{concat('view.html?id=',$doc/@xml:id/string())}" class="title-link">{$doc//tei:titleStmt/tei:title[@level='a']/string()}</a>
    </div>
    }
    </div>
};

declare function app:view_single($id,$type,$show, $view-mode,$q) {
    (:Gibt eine Einzelansicht eines Dokuments aus:)
    
    <div id="content-box" class="col-sm-9">
        <div class="title-box">
            <nav>
                <ul class="pager">
                    <li class="previous"><a id="prev" href="view.html?id={app:prev-doc-id($id,$type)}&amp;type={$type}&amp;show={$show}&amp;view-mode={$view-mode}">&lt;</a></li>
                    <li class="next"><a id="next" href="view.html?id={app:next-doc-id($id,$type)}&amp;type={$type}&amp;show={$show}&amp;view-mode={$view-mode}">&gt;</a></li>
                </ul>
             </nav>
            <h2 class="doc-title">{collection($config:data-root)/id($id)//tei:titleStmt//tei:title[@level='a']/text()}</h2>
        </div> <!-- /title-box -->
        <div class="text-box leseansicht">
            {format:tei2html(collection($config:data-root)/id($id)//tei:text)}
        </div>
        <div id="anhang" class="anhang-box collapse">
            {
                if (substring($id,1,1)="L") then
                    <div class="correspDesc">
                        <span class="glyphicon glyphicon-envelope"></span>
                        <div class="sender-box">
                            <span class="sender">
                                {format:tei2html(collection($config:data-root)/id($id)//tei:sender//tei:persName)}
                            </span>
                            {format:tei2html(collection($config:data-root)/id($id)//tei:placeSender)}
                            {
                                if (collection($config:data-root)/id($id)//tei:dateSender) then
                                format:tei2html(collection($config:data-root)/id($id)//tei:dateSender)
                                else ()
                            }
                            
                        </div>
                        <div class="addressee-box">
                            {format:tei2html(collection($config:data-root)/id($id)//tei:addressee)}
                            {format:tei2html(collection($config:data-root)/id($id)//tei:placeAddressee)}
                            {format:tei2html(collection($config:data-root)/id($id)//tei:dateAddressee)}
                        </div>
                    </div>
                    
                else ()
            }
            {
                if (collection($config:data-root)/id($id)//tei:listWit) then
            <div class="witnessBox">
                <span class="glyphicon glyphicon-map-marker"></span>
                {format:tei2html(collection($config:data-root)/id($id)//tei:listWit)}
            </div>
                else ()
            }
            {
            if (collection($config:data-root)/id($id)//tei:listBibl) then
            <div class="biblBox">
            <span class="glyphicon glyphicon-book"></span>
                {format:tei2html(collection($config:data-root)/id($id)//tei:listBibl)}
            </div>
            else ()
            }
            {
            if (collection($config:data-root)/id($id)//tei:anchor[@type='commentary']) then
        <div id="kommentar" class="kommentar-box">
            {
                for $kommentar in collection($config:data-root)/id($id)//tei:anchor[@type='commentary']
                return 
                    <div class="commentary-fn">
                        <sup class="fn-marker"><a id="FN_{$kommentar/@xml:id}"
                        href="#FN-ref_{$kommentar/@xml:id}"
                        >
                            {count($kommentar/preceding::tei:anchor[@type='commentary'])+1}
                        </a></sup>
                        <span class="lemma">{$kommentar}</span>
                        <span class="kommentar-txt">
                        {format:tei2html(collection($config:data-root||"/meta")/id($kommentar/@xml:id)//tei:p/node())}
                        </span>
                    </div>
            }
        </div>
        else ()
        }
            
        </div> <!-- /anhang-box -->
        
    </div>
    
    (: 
    <div class="row">
        <h2>{collection($config:data-root)/id($id)//tei:titleStmt/tei:title[@level='a']/text()}</h2>
        {
            if (substring($id,1,1)='L') then
                app:corresp-meta($id)
            else ()
        }
        
        {format:tei2html(collection($config:data-root)/id($id))}
    </div>
    :)
    
};



(: register.html :)

declare
 %templates:wrap
 function app:register_view($node as node(), $model as map(*),$key, $type) {
 (: 
  Seite zeigt einen Registereintrag an: 
  entweder einen Einzeleintrag, wenn $key gesetzt ist,
  oder eine Liste, wenn $type gesetzt ist: 
  Werte für $type: p(persName), o(placeName), w(workName)
  
 :)

let $output := if ($key!="") then
        app:register_single($key,$type)
    else
        app:register_liste($type)
 return $output
 };



(: --------------------------- register-Liste  ----------------------------------------- :)

declare
function app:register_liste($type) {
    (: Werte für $type: p(persName), o(placeName), w(workName) :)
    if ($type != '') then
    (:Alter Code, der die Liste filterbar gemacht hat...deprecated:)
    let $liste :=
    for $key in
    switch ($type)
        case "p" return distinct-values(collection($config:data-root)//tei:persName/tokenize(@key,' '))
        case "o" return distinct-values(collection($config:data-root)//tei:placeName/@key)
        case "w" return distinct-values(collection($config:data-root)//tei:workName/tokenize(@key,' '))
        case "org" return distinct-values(collection($config:data-root)//tei:orgName/tokenize(@key,' '))
        default return ()
        return
            switch ($type)
                case "p" return 
                    <li>
                        <a href="{concat('register.html?key=',$key,'&amp;type=',$type)}">{(collection($config:data-root)/id($key)//tei:forename/string(), collection($config:data-root)/id($key)//tei:surname/string())}</a>
                    </li>
                case "o" return 
                    <li>
                        <a href="{concat('register.html?key=',$key,'&amp;type=',$type)}">{collection($config:data-root)/id($key)//tei:placeName}</a>
                    </li>
                case "w" return 
                    <li>
                        <a href="{concat('register.html?key=',$key,'&amp;type=',$type)}">{collection($config:data-root)/id($key)//tei:title/text()}</a>
                    </li>
                    (:Wenn nichts übergeben, dann alles retour:)
                case "org" return 
                    <li><a href="{concat('register.html?key=',$key,'&amp;type=',$type)}">
                    
                    {collection($config:data-root)/id($key)//tei:orgName/text()}</a></li>
                default return <li><a href="{concat('register.html?key=',$key,'&amp;type=',$type)}">{$key}</a></li>
            
        return 
            <div class="col-sm-9">
                <div class="title-box">
                <h2 class="doc-title">Register{
                    switch($type)
                    case "p" return ": Personen"
                    case "o" return ": Orte"
                    case "w" return ": Werke"
                    case "org" return ": Organisationen"
                    default return ()
                }</h2>
            </div>
            <ul class="register">
                {$liste}
            </ul>
            </div>
        (:else zu $type != '':)
        else 
            <div class="col-sm-9">
                <div class="title-box">
                <h2 class="doc-title">Register</h2>
            </div>
            <ul class="register">
                {
                    ()
                }
            </ul>
            </div>
};

declare function app:register_single($key,$type) {
        
    
        <div class="col-sm-9">
            <div class="title-box">
                <h2>
                    {
                        switch($type)
                        case "p" return 
                            (
                            if (collection($config:data-root)/id($key)//tei:forename and collection($config:data-root)/id($key)//tei:surname) then
                            collection($config:data-root)/id($key)//tei:forename || " " || collection($config:data-root)/id($key)//tei:surname
                            else collection($config:data-root)/id($key)//tei:persName/text(),
                            
                            if (collection($config:data-root)/id($key)//tei:birth and collection($config:data-root)/id($key)//tei:death) then
                                "(" || collection($config:data-root)/id($key)//tei:birth/@when || "–" || collection($config:data-root)/id($key)//tei:death/@when || ")"
                                else
                                    (),
                                    
                            if (collection($config:data-root)/id($key)//tei:occupation) then
                                (
                                <br/>,collection($config:data-root)/id($key)//tei:occupation/text()
                                )
                                else ()
                            
                            
                            )
                        case "o" return 
                            (
                            if (collection($config:data-root)/id($key)//tei:district) then
                                if (contains(collection($config:data-root)/id($key)//tei:placeName,"Wien")) then collection($config:data-root)/id($key)//tei:settlement || " " || collection($config:data-root)/id($key)//tei:district
                                else collection($config:data-root)/id($key)//tei:placeName
                            else
                                 collection($config:data-root)/id($key)//tei:placeName 
                                
                            )
                        case "w" return 
                            (
                            if (collection($config:data-root)/id($key)//tei:title and collection($config:data-root)/id($key)//tei:author) then 
                                if (collection($config:data-root)/id($key)//tei:author//tei:surname) then
                                    collection($config:data-root)/id($key)//tei:author//tei:surname/text() || ": " || collection($config:data-root)/id($key)//tei:title/text()
                                else
                                    collection($config:data-root)/id($key)//tei:title/text() 
                            else "Werk " || $key
                            )
                        case "org" return 
                            (
                                if (collection($config:data-root)/id($key)//tei:orgName) then 
                                    (
                                    collection($config:data-root)/id($key)//tei:orgName,
                                    if (collection($config:data-root)/id($key)//tei:desc) then
                                        
                                        (
                                        <br/>,
                                        collection($config:data-root)/id($key)//tei:desc
                                        )
                                        else ()
                                    
                                    )
                                    else "Organisation " || $key
                            )
                            
                        default return $key
                    }
                </h2>
                
            </div>
            <div class="ergebnisliste">
            {
                let $liste :=
    for $doc in
    switch ($type)
        case "p" return collection($config:data-root)//tei:persName[@key=$key]/ancestor::tei:TEI
        case "o" return collection($config:data-root)//tei:placeName[@key=$key]/ancestor::tei:TEI
        case "w" return collection($config:data-root)//tei:workName[@key=$key]/ancestor::tei:TEI
        case "org" return collection($config:data-root)//tei:orgName[@key=$key]/ancestor::tei:TEI
        default return ()
        return
            <li><a href="{concat('view.html?id=',$doc/@xml:id)}">{$doc//tei:titleStmt/tei:title[@level="a"]/text()}</a></li>
        return 
            <ul class="register">{$liste}</ul>        
            }
        </div>    
        </div>
        
        (:collection($config:data-root)//tei:persName)[@key=$key]/ancestor::tei:TEI:)
        
        
};


declare
    %templates:wrap
function app:nav($node as node(), $model as map(*)) {
    (:Navigation:)
    <nav class="navbar navbar-default" role="navigation">
                        <div class="navbar-header">
                            <button type="button" class="navbar-toggle" data-toggle="collapse" data-target="#menu">
                                <span class="sr-only">Toggle navigation</span>
                                <span class="icon-bar"/>
                                <span class="icon-bar"/>
                                <span class="icon-bar"/>
                            </button>
                            <span class="visible-xs navbar-brand">Menü</span>
                        </div> <!-- /.navbar-header -->
                        <div id="menu" class="navbar-collapse collapse">
                            <ul class="nav navbar-nav">
                                <li class="dropdown visible-xs" id="nav_home">
                                    <a href="index.html">Home</a>
                                </li>
                                <li class="dropdown hidden-md hidden-lg" id="nav_dokumente">
                                    <a href="#" class="dropdown-toggle" data-toggle="dropdown">Dokumente</a>
                                    <ul class="dropdown-menu">
                                        <li>
                                            <a href="view.html?type=L">Briefe</a>
                                        </li>
                                        <li>
                                            <a href="view.html?type=D">Tagebucheinträge</a>
                                        </li>
                                        <li>
                                            <a href="view.html?type=T">Texte</a>
                                        </li>
                                    </ul>
                                </li> 
                                <li class="hidden-xs hidden-sm">
                                    <a href="view.html">Dokumente</a>
                                </li>
                                <!-- /Dokumente -->
                                
                                <li class="dropdown" id="nav_suche">
                                    <a href="search.html">Suche</a>
                                </li> <!-- /Suche -->
                                
                                <li class="dropdown hidden-md hidden-lg" id="nav_register">
                                    <a href="#" class="dropdown-toggle" data-toggle="dropdown">Register</a>
                                    <ul class="dropdown-menu">
                                        <li>
                                            <a href="register.html?type=p">Personen</a>
                                        </li>
                                        <li>
                                            <a href="register.html?type=org">Organisationen</a>
                                        </li>
                                        <li>
                                            <a href="register.html?type=o">Orte</a>
                                        </li>
                                        <li>
                                            <a href="register.html?type=w">Werke</a>
                                        </li>
                                    </ul>
                                </li> 
                                <li class="hidden-xs hidden-sm">
                                    <a href="register.html">Register</a>
                                </li>
                                <!-- /Register -->


                                <li class="dropdown" id="nav_ueber">
                                    <a href="#" class="dropdown-toggle" data-toggle="dropdown">Zur Edition / Impressum</a>
                                    <ul class="dropdown-menu">
                                        <li>
                                                <a href="#">Zur Ausgabe</a>
                                            </li>
                                        <li>
                                                <a href="#">Editionsbericht</a>
                                            </li>
                                        <li>
                                                <a href="#">Nachwort</a>
                                            </li>
                                        <li>
                                                <a href="#">Kontakt</a>
                                            </li>
                                            <li>
                                                <a href="#">Impressum</a>
                                            </li>
                                    </ul>
                                </li> <!-- /About -->


                            </ul> <!-- /Navigations-Liste -->
                        </div> <!--/.nav-collapse -->
        </nav>
};

declare
    %templates:wrap
function app:inhalt-liste($node as node(), $model as map(*)) {
    (:Funktioniert nicht, wegen der Session:)
    for $doc in app:meta-docs(1,100) return
        <li>{$doc/title/text()}</li>
};

declare function app:meta-docs($start,$n) {
    
    let $docs := for $doc in collection($config:data-root)/tei:TEI
        let $id := $doc/@xml:id/string()
        let $type := substring($id,1,1)
        let $title := $doc//tei:titleStmt/tei:title[@level="a"]/text()
        let $author := $doc//tei:titleStmt/tei:title/tei:author/text()
        let $date := 
            switch (substring($id,1,1))
            case "L" return $doc//tei:dateSender/tei:date/@when/string()
            case "D" return $doc//tei:text//tei:date[@when][1]/@when/string()
            case "T" return $doc//tei:origDate/@when/string()
            default return "none"
        order by $date ascending
        return 
            <doc>
                <id>{$id}</id>
                <type>{$type}</type>
                <author>{$title}</author>
                <title>{$title}</title>
                <date>{$date}</date>
            </doc>
    let $session := session:set-attribute("docs", $docs) (: store result into session :)
    (: only return $n nodes starting at $start nodes :)
    
    for $doc in subsequence($docs, $start, $n)
    return 
        $doc
    
};

declare function app:order-ids() {
    let $ids :=
    for $doc in collection($config:data-root)/tei:TEI
    let $id := $doc/@xml:id/string()
    let $date := 
            switch (substring($id,1,1))
            case "L" return $doc//tei:dateSender/tei:date/@when/string()
            case "D" return $doc//tei:text//tei:date[@when][1]/@when/string()
            case "T" return $doc//tei:origDate/@when/string()
            default return "none"
        order by $date ascending
    return 
        <id type="{substring($id,1,1)}">{$id}</id>
    return
        <ids>{$ids}</ids>
};

declare function app:next-doc-id($id,$type) {
    (:Liefert das folgende Dokument;nutzt die Session wahrscheinlich nicht:)
    let $ordered-ids :=
        if (session:get-attribute("ids")) then
            session:get-attribute("ids")
        else 
            session:set-attribute("ids", app:order-ids())
    return
        if ($type!='') then
            $ordered-ids//id[text()=$id]/following-sibling::id[@type=$type][1]
            else
        $ordered-ids//id[text()=$id]/following-sibling::id[1]
    (: 
    app:order-ids()//id[text()=$id]/following-sibling::id[1]
    :)
    
};

declare function app:prev-doc-id($id,$type) {
    (:Liefert das folgende Dokument;nutzt die Session wahrscheinlich nicht:)
    let $ordered-ids :=
        if (session:get-attribute("ids")) then
            session:get-attribute("ids")
        else 
            session:set-attribute("ids", app:order-ids())
    return
        if ($type!='') then
            $ordered-ids//id[text()=$id]/preceding-sibling::id[@type=$type][1]
            else
        $ordered-ids//id[text()=$id]/preceding-sibling::id[1]
    (: 
    app:order-ids()//id[text()=$id]/following-sibling::id[1]
    :)
    
};

declare
    %templates:wrap
function app:settings($node as node(), $model as map(*),$show, $view-mode, $id) {
    if ($id != "") then
    <form>
        Ansicht:
        <select id="select-view-mode" class="custom-select">
            <option>Leseansicht</option>
            <option>Erweiterte Ansicht</option>
        </select>

        <div class="checkbox">
            <label>
                <input type="checkbox" id="check_anhang" data-toggle="collapse" data-target="#anhang"> Anhang</input>
            </label>
        </div>
        
    </form>
    else 
        (: Listenansicht :)
        <form class="hidden-xs hidden-sm">
            Zeige Dokumente:
        <div class="checkbox">
            <label>
                <input type="checkbox" id="toggle_doctype_L" checked="checked"> Briefe</input>
            </label>
        </div>
        <div class="checkbox">
            <label>
                <input type="checkbox" id="toggle_doctype_D" checked="checked"> Tagebucheinträge</input>
            </label>
        </div>
        <div class="checkbox">
            <label>
                <input type="checkbox" id="toggle_doctype_T" checked="checked"> Texte</input>
            </label>
        </div>
        </form>
        
};

(: --------------------------- search.html - Seite  ----------------------------------------- :)
(: Suche :)
declare
    %templates:wrap
function app:searchbox($node as node(), $model as map(*),$q) {
   <form class="form-inline" action="search.html">
            <div class="form-group col-sm-7">
                <label class="sr-only" for="Suche_Suchfeld">Volltextsuche im Datenbestand</label>
                <div class="input-group input-group-lg">
                    <input type="text" class="form-control" id="Suche_Suchfeld" name="q" 
                placeholder="{if ($q!='') then $q else "Suche..."}"/>
                <span class="input-group-btn">
                    <button class="btn btn-default" type="submit"><span class="glyphicon glyphicon-search"></span></button>
                </span>
                </div>
                
            </div>
            
        </form>,
        <div>
        <!--
        <a href="">Erweiterte Suche</a>
        -->
        </div>
};

declare
    %templates:wrap
    %templates:default("orderby", "date")
function app:search_results($node as node(), $model as map(*),$q,$type,$orderby) {
    app:format_searchresults(app:search($q, $type), $q, $type, $orderby)
};

declare
function app:search($q,$type) {
    (: --------------- Die Suchfunktion -------------------------- :)
    (:
     : $q Suchstring
     : $type
     
     Die Funktion liefert XML-Elemente zurück <hit ft-score="">TEI-item-Element</hit>
     
     :)
    let $ergebnisse :=
    (:Überprüfen, ob ein Suchstring gesetzt ist:)
    if ($q!="") then 
        (:Suchstring ist vorhanden, Suche starten:)
        (:Überprüfen, ob Filter gesetzt sind, wenn ja, dann anpassen, wo gesucht wird:)
        (:Optionen überprüfen, entsprechend den Ergebnissen Suchkontext $kontext setzen. Kontext enthält die entsprechenden Daten, in denen gesucht wird:)
            (:Überprüfen, ob nur innerhalb von bestimmten Einträgen gesucht werden soll, dann entfällt nämlich die weitere Kontext-Einschränkung, nicht aber die $w-switches:)
            
                                    (:überall, kein Filter:)
                                    for $hit in collection($config:data-root)//tei:div[ft:query(.,$q)]
                                    let $ft-score := ft:score($hit)
                                    let $docid := $hit/ancestor::tei:TEI/@xml:id
                                    let $docdate := 
                                        switch (substring($docid,1,1))
                                        case "L" return collection($config:data-root)/id($docid)//tei:dateSender/tei:date/@when/string()
                                        case "D" return collection($config:data-root)/id($docid)//tei:text//tei:date[@when][1]/@when/string()
                                        case "T" return collection($config:data-root)/id($docid)//tei:origDate/@when/string()
                                        default return "0000-00-00"
                                    let $doctitle := $hit/ancestor::tei:TEI//tei:titleStmt//tei:title[@level='a']/text()
                                    return 
                                        <hit docid="{$docid}" doctitle="{$doctitle}" docdate="{$docdate}" ft-score="{$ft-score}">
                                            {kwic:expand($hit)}
                                        </hit>
                                        
    else ()
    (:Kein Suchstring angegeben, deswegen wird das Suchfeld angezeig:)
    return
        $ergebnisse

};

declare function app:format_searchresults($ergebnisse, $q, $type, $orderby) {
    (:Funktion, die eine Ergebnisliste für die Suchergebnisse aus app:suche erstellt. Übernimmt alle Suchfilterparameter + die Ergebnisse der Suche $ergebnisse:)
    (:momentan gibt das Zeugs eine Tabelle aus, aber man könnte wahrscheinlich noch mehr machen, wenn man weitere Parameter, z.B. einen $stil, $zielformat oder so etwas übergibt:)
     if ($q !='') then
     <div>
     <h3>Ergebnisse:</h3>
     <div id="Ergebnisuebersicht">
        <strong>{count($ergebnisse)} Treffer für "{$q}"</strong>
    </div>
        <div class="search-hits">
        {
         for $hit in $ergebnisse
         order by $hit/@docdate
         return 
            <div class="search-hit" data-docdate="{$hit/@docdate}" data-ftScore="{$hit/@ft-score}">
                <span class="hit-title">
                <a href="view.html?id={$hit/@docid/string()}&amp;q={$q}">{$hit/@doctitle/string()}</a>
                </span>
                {kwic:summarize($hit, <config width="60"/>)}
            </div>
        }
     
     </div>
     </div>
     else ()
};

