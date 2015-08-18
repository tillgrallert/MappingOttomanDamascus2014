<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" xmlns:ex="http://api.simile-widgets.org/exhibit/3.0.0/"
    xmlns:functx="http://www.functx.com" xmlns:html="http://www.w3.org/1999/xhtml"
    xmlns:kml="http://earth.google.com/kml/2.0" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:tss="http://www.thirdstreetsoftware.com/SenteXML-1.0"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    
    <xsl:output encoding="UTF-8" indent="yes" method="html" omit-xml-declaration="yes"/>

    <!-- this styleshee produces a structured JSON file to be used for visualisation through MIT's Simile Exhibit widget as well as the HTML with the Exhibit -->
    <!-- It uses geo-data from a reference file ($pgLocs) and checks a given XML for occurences of these locations -->
    
    <!--  to prevent the mentioning of Damascus, dimashq etc. in titles, places of publication etc. blurring the results, I limited the search focus to the abstractText and the notes -->


    <xsl:strip-space elements="*"/>
    

    <!-- $pgLocs links to a master file with an ontology of geocoded places / toponyms. It follows the TEI with nested <place> nodes inside <listPlace> in the <sourceDesc>. For convenience, pgLocs links to an authority file hosted in a GitHub repository and served through rawgit. -->
    <xsl:param name="pgLocs"
        select="document('https://cdn.rawgit.com/tillgrallert/OttomanDamascus/master/LocationsMasterTEI.xml')"/>
    
    <!-- $pgRefs holds all <tss:reference> nodes in the input document -->
    <xsl:param name="pgRefs" select="tss:senteContainer/tss:library/tss:references"/>
    
    <!-- This parameter selects the elements of the Sente XML to be searched for the location terms. Values are "abstract", "notes", "all", and "*"; if another string is provided abstracts, notes AND keywords will be searched -->
    <xsl:param name="pgSearchField" select="'all'"/>
    
    <!-- This paramter provides the label of the eventType. It is used for the file names, the eventType in the JSON data source, the <head> and the <body> of the HTML output -->
    <xsl:param name="pgType" select="'type'"/>
    
    <!-- these variables can be used to down-mark transliterations -->
    <xsl:variable name="vIjmesDiac">
        <xsl:text>ĀāĪīŪūḌḍḤḥḪḫḲḳṢṣṬṭṮṯẒẓʾʿ</xsl:text>
    </xsl:variable>
    <xsl:variable name="vIjmesNormal">
        <xsl:text>AaIiUuDdHhHhQqSsTtTtZz''</xsl:text>
    </xsl:variable>
    <!-- this variable specifies the sort order according to the IJMES transliteration of Arabic -->
    <!-- it is called as collation="http://saxon.sf.net/collation?rules={encode-for-uri($sortIjmes)}" -->
    <xsl:variable name="sortIjmes"
        select="'&lt; ʾ,ʿ &lt; a,A &lt; ā, Ā &lt; b,B &lt; c,C &lt; d,D &lt; ḍ, Ḍ &lt; e,é,è,E,É,È &lt; f,F &lt; g,G &lt; ġ, Ġ &lt; h,H &lt; ḥ, Ḥ &lt; ḫ, Ḫ &lt; i,I &lt; ī, Ī  &lt; j,J &lt; k,K &lt; ḳ, Ḳ &lt; l,L &lt; m,M &lt; n,N &lt; o,O &lt; p,P &lt; q,Q &lt; r,R &lt; s,S &lt; ṣ, Ṣ &lt; t,T &lt; ṭ, Ṭ &lt; ṯ, Ṯ &lt; u,U &lt; ū, Ū &lt; v,V &lt; w,W &lt; x,X &lt; y,Y &lt; z, Z &lt; ẓ, Ẓ'"/>
    
    <!-- place holder for the title in the websites title and for file names -->
    <xsl:variable name="vgName">
        <xsl:value-of select="translate($pgType,$vIjmesDiac,$vIjmesNormal)"/>
    </xsl:variable>

    <xsl:param name="pgDateCurrent" select="format-date(current-date(),'[Y01][M01][D01]')"/>


    <xsl:template match="tss:senteContainer">
        <xsl:apply-templates mode="mJson"/>
        <xsl:apply-templates mode="mHtml"/>
    </xsl:template>

    <!-- mJSON: creates the JSON file -->
    <xsl:template match="tss:library" mode="mJson">
        <!--<xsl:variable name="vRefs">
            <xsl:copy-of select="./tss:references"/>
        </xsl:variable>-->
        <xsl:result-document href="simileData-{$vgName}-{$pgDateCurrent}.js">
            <xsl:text>{
    "items":[
            </xsl:text>
            <xsl:call-template name="templItemsJson"/>
            <xsl:text>],
                </xsl:text>
            <xsl:call-template name="templTypes"/>
            <xsl:text>,</xsl:text>
            <xsl:call-template name="templProperties"/>
            <xsl:text>}
}</xsl:text>
        </xsl:result-document>
    </xsl:template>
   
    <!-- employed in mJson -->
    <xsl:template name="templItemsJson">
        <xsl:for-each select="$pgLocs//tei:place">
            <xsl:sort collation="http://saxon.sf.net/collation?rules={encode-for-uri($sortIjmes)}"
                select="."/>
            <xsl:variable name="vPlace">
                <xsl:variable name="vId" select="@xml:id"/>
                <xsl:choose>
                    <!-- this conditions includes all subordinated topographical units in the search for place names of quarters and neighbourhoods; i.e. Qanawāt, will also return Marja Square -->
                    <xsl:when
                        test="ancestor::tei:listPlace[@corresp=concat('#',$vId)][@type='quarter' or 'neighbourhood' or 'town' or 'village' or 'county']">
                        <xsl:copy-of select="parent::tei:listPlace"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:copy-of select="."/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <xsl:variable name="vLoc"
                select="if (./tei:placeName[@xml:lang='ar-Latn-x-ijmes']!='') then (./tei:placeName[@xml:lang='ar-Latn-x-ijmes'][1]) else (./tei:placeName[@type='simple'])"/>
           
            <xsl:variable name="vPlaceNamesMentioned1">
                <xsl:for-each select="$vPlace//tei:placeName[not(.='')]">
                    <xsl:variable name="vPName" select="."/>
                    
                    <!-- this searches the reference nodes in the input XML for occurrences to the placeNames -->
                    <xsl:for-each select="$pgRefs/tss:reference">
                        <xsl:choose>
                            <xsl:when test="$pgSearchField='abstract'">
                                <xsl:if
                                    test=".//tss:characteristic[@name='abstractText']                 [contains(lower-case(.),lower-case(concat('',$vPName,'')))]">
                                    <tss:reference>
                                        <tss:characteristics>
                                            <xsl:element name="tss:characteristic">
                                                <xsl:attribute name="name" select="'UUID'"/>
                                                <xsl:value-of
                                                  select="ancestor-or-self::tss:reference//tss:characteristic[@name='UUID']"
                                                />
                                            </xsl:element>
                                        </tss:characteristics>
                                    </tss:reference>
                                </xsl:if>
                            </xsl:when>
                            <xsl:when test="$pgSearchField='notes'">
                                <xsl:if
                                    test=".//tss:notes [contains(lower-case(.),lower-case(concat('',$vPName,'')))]">
                                    <tss:reference>
                                        <tss:characteristics>
                                            <xsl:element name="tss:characteristic">
                                                <xsl:attribute name="name" select="'UUID'"/>
                                                <xsl:value-of
                                                  select="ancestor-or-self::tss:reference//tss:characteristic[@name='UUID']"
                                                />
                                            </xsl:element>
                                        </tss:characteristics>
                                    </tss:reference>
                                </xsl:if>
                            </xsl:when>
                            <xsl:when test="$pgSearchField='tags'">
                                <xsl:if
                                    test=".//tss:keywords                [contains(lower-case(.),lower-case(concat('',$vPName,'')))]">
                                    <tss:reference>
                                        <tss:characteristics>
                                            <xsl:element name="tss:characteristic">
                                                <xsl:attribute name="name" select="'UUID'"/>
                                                <xsl:value-of
                                                  select="ancestor-or-self::tss:reference//tss:characteristic[@name='UUID']"
                                                />
                                            </xsl:element>
                                        </tss:characteristics>
                                    </tss:reference>
                                </xsl:if>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:if
                                    test=".               [contains(lower-case(.),lower-case(concat('',$vPName,'')))]">
                                    <tss:reference>
                                        <tss:characteristics>
                                            <xsl:element name="tss:characteristic">
                                                <xsl:attribute name="name" select="'UUID'"/>
                                                <xsl:value-of
                                                  select="ancestor-or-self::tss:reference//tss:characteristic[@name='UUID']"
                                                />
                                            </xsl:element>
                                        </tss:characteristics>
                                    </tss:reference>
                                </xsl:if>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:for-each>
                </xsl:for-each>
            </xsl:variable>
            <!-- the previous variable might contained duplicates, which can be omitted by grouping by UUID -->
            <xsl:variable name="vPlaceNamesMentioned2">
                <xsl:for-each-group group-by=".//tss:characteristic[@name='UUID']"
                    select="$vPlaceNamesMentioned1//tss:reference">
                    <tss:reference/>
                </xsl:for-each-group>
            </xsl:variable>

            <!-- this counts the total number of unique tss:reference nodes per place mentioned  -->
            <xsl:variable name="vCount">
                <xsl:value-of select="count($vPlaceNamesMentioned2//tss:reference)"/>
            </xsl:variable>
          

            <xsl:variable name="vType" select="./@type"/>
            <xsl:variable name="vTypeCode">
                <!-- designing a scale of areas:  -->
                <xsl:choose>
                    <xsl:when test="$vType='street'">
                        <xsl:value-of select="'1'"/>
                    </xsl:when>
                    <xsl:when test="$vType='square'">
                        <xsl:value-of select="'1'"/>
                    </xsl:when>
                    <xsl:when test="$vType='building'">
                        <xsl:value-of select="'1'"/>
                    </xsl:when>
                    <xsl:when test="$vType='neighbourhood'">
                        <xsl:value-of select="'2'"/>
                    </xsl:when>
                    <xsl:when test="$vType='quarter'">
                        <xsl:value-of select="'2'"/>
                    </xsl:when>
                    <xsl:when test="$vType='village'">
                        <xsl:value-of select="'2'"/>
                    </xsl:when>
                    <xsl:when test="$vType='town'">
                        <xsl:value-of select="'3'"/>
                    </xsl:when>
                    <xsl:when test="$vType='county'">
                        <xsl:value-of select="'4'"/>
                    </xsl:when>
                    <xsl:when test="$vType='district'">
                        <xsl:value-of select="'5'"/>
                    </xsl:when>
                    <xsl:when test="$vType='province'">
                        <xsl:value-of select="'6'"/>
                    </xsl:when>
                </xsl:choose>
            </xsl:variable>
            <xsl:variable name="vLat" select="substring-before(./tei:location/tei:geo, ',')"/>
            <xsl:variable name="vLong" select="substring-after(./tei:location/tei:geo, ',')"/>

            <xsl:choose>
                <xsl:when test="$vCount!=0">
                    <xsl:text>{
            </xsl:text>
                    <xsl:text>"label":"</xsl:text>
                    <xsl:value-of select="normalize-space($vLoc)"/>
                    <xsl:text>",
            </xsl:text>
                    <xsl:text>"type":"</xsl:text>
                    <xsl:value-of select="$vType"/>
                    <xsl:text>",
            </xsl:text>
                    <xsl:text>"typeCode":"</xsl:text>
                    <xsl:value-of select="$vTypeCode"/>
                    <xsl:text>",
            </xsl:text>
                    <xsl:text>"latlng":"</xsl:text>
                    <xsl:value-of select="$vLat"/>
                    <xsl:text>, </xsl:text>
                    <xsl:value-of select="$vLong"/>
                    <xsl:text>",
            </xsl:text>
                    <xsl:text>"events":"</xsl:text>
                    <xsl:value-of select="$vCount"/>
                    <xsl:text>",
                </xsl:text>
                    <xsl:text>"eventDetails":"dates should go here",
                </xsl:text>
                    <xsl:text>"eventType":"</xsl:text>
                    <xsl:value-of select="$pgType"/>
                    <xsl:text>"</xsl:text>
                    <xsl:text>}</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <!-- at the moment, this is an inelegant, but feasible solution. Exhibit will output one value it could not map, no matter how many of these values are present. -->
                    <xsl:text>{"label":"empty value"}</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:if test="position()!=last()">
                <xsl:text>,
                        </xsl:text>
            </xsl:if>
            
        </xsl:for-each>
    </xsl:template>

    <xsl:template name="templTypes">
        <xsl:text>"types": {
		"City": {
			"pluralLabel": "Cities"
		}
	}</xsl:text>
    </xsl:template>

    <xsl:template name="templProperties">
        <xsl:text>"properties": {
		"rank": {
			"valueType": "number"
		},
		"events": {
			"valueType": "number"
		},
        "eventDetails":{
            "valueType": "string"
        }</xsl:text>
    </xsl:template>

    <!-- the following set of templates and parameters is used to provide the maximum of references that return "true" for the search criteria. This maximum is then used for setting the maximum size of dots in the mapping exhibit.  -->
    <xsl:template name="templCount">
        <xsl:param name="pString1" select="./tei:placeName[@type='simple']"/>
        <xsl:param name="pString2"
            select="if (./tei:placeName[@type='IJMES']!='') then (./tei:placeName[@type='IJMES']) else ('fyrg2369')"/>
        <xsl:param name="pString3"
            select="if (./tei:placeName[@type='alt'][ @n='1']!='') then (./tei:placeName[@type='alt'][ @n='1']) else ('fyrg2369')"/>
        <xsl:param name="pString4"
            select="if (./tei:placeName[@type='alt'][ @n='2']!='') then (./tei:placeName[@type='alt'][ @n='1']) else ('fyrg2369')"/>
        <xsl:param name="pLang1"
            select="if (./tei:placeName[@xml:lang='ar']!='') then (./tei:placeName[@xml:lang='ar']) else ('fyrg2369')"/>
        <xsl:choose>
            <xsl:when test="$pgSearchField='abstract'">
                <xsl:value-of
                    select="count($pgRefs/tss:reference[functx:contains-any-of(.//tss:characteristic[@name='abstractText'],($pString1,$pString2,$pString3, $pString4, $pLang1))])"
                />
            </xsl:when>
            <xsl:when test="$pgSearchField='notes'">
                <xsl:value-of
                    select="count($pgRefs/tss:reference[functx:contains-any-of(.//tss:notes,($pString1,$pString2, $pString3, $pString4, $pLang1))])"
                />
            </xsl:when>
            <xsl:when test="$pgSearchField='tags'">
                <xsl:value-of
                    select="count($pgRefs/tss:reference[functx:contains-any-of(.//tss:keywords,($pString1,$pString2, $pString3, $pString4, $pLang1))])"
                />
            </xsl:when>
            <xsl:when test="$pgSearchField='*'">
                <xsl:value-of
                    select="count($pgRefs/tss:reference[functx:contains-any-of(.,($pString1,$pString2, $pString3, $pString4, $pLang1))])"
                />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of
                    select="count($pgRefs/tss:reference[functx:contains-any-of(concat(.//tss:characteristic[@name='abstractText'], ./tss:notes, ./tss:keywords),($pString1,$pString2, $pString3, $pString4, $pLang1))])"
                />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:param name="pgCount">
        <xsl:element name="places">
            <xsl:for-each-group group-by="." select="$pgLocs//tei:place">
                <xsl:variable name="vCount">
                    <xsl:call-template name="templCount"/>
                </xsl:variable>
                <xsl:element name="place">
                    <xsl:element name="placeName">
                        <xsl:value-of select="current-grouping-key()"/>
                    </xsl:element>
                    <xsl:element name="count">
                        <xsl:value-of select="$vCount"/>
                    </xsl:element>
                </xsl:element>
            </xsl:for-each-group>
        </xsl:element>
    </xsl:param>
    <xsl:param name="pgMax" select="max($pgCount//count)"/>
    

    <xsl:function as="xs:boolean" name="functx:contains-any-of" xmlns:functx="http://www.functx.com">
        <xsl:param as="xs:string?" name="arg"/>
        <xsl:param as="xs:string*" name="searchStrings"/>

        <xsl:sequence
            select=" 
            some $searchString in $searchStrings
            satisfies contains($arg,$searchString)
            "
        />
    </xsl:function>

    

    <!-- mHtml creates the html page with the SIMILE exhibits -->
    <xsl:template match="tss:library" mode="mHtml">
        <xsl:variable name="vRefs" select="./tss:references"/>
        <xsl:result-document href="simileMapTableV-{$vgName}-{$pgDateCurrent}.html">
            <html>
                <xsl:call-template name="tHtmlHead"/>
                <body>
                    <!-- <ul id="path">
                            <li><a href="/">SIMILE Widgets</a></li>
                            <li><a href="/exhibit3/">Exhibit 3.0</a></li>
                            <li><span>Density of Reports</span></li> 
                        </ul>-->
                    <div id="header">
                        <h1>Spatial distribution of <xsl:value-of select="count($vRefs/tss:reference)"/> reports on <xsl:value-of select="$pgType"/>
                            <xsl:call-template name="templRange"/></h1>
                        <p> Using <a href="http://simile-widgets.org/exhibit3/">SIMILE Widgets:
                                Exhibit 3.0</a>. </p>
                    </div>
                    <div id="content">
                        <!-- the mpgMax must be computed separately -->
                        <div ex:coderClass="ColorGradient"
                            ex:gradientPoints="1, #FF0000; 30, #FF0000; {$pgMax}, #610B0B"
                            ex:role="coder" id="events-color"/>
                        <div ex:coderClass="ColorGradient"
                            ex:gradientPoints="1, #FF0000; 2, #FFA500; 3, #FFFF00; 4, #008000; 5, #0000FF; 6, #800080"
                            ex:role="coder" id="type-color"/>
                        <div ex:coderClass="SizeGradient"
                            ex:gradientPoints="1, 10; 5,30; 30,60; {$pgMax}, 100" ex:role="coder"
                            id="events-size"/>
                        <!-- <div ex:role="coder" ex:coderClass="SizeGradient" id="events-size"
                                ex:gradientPoints="1, 10; 5,30; {$pgMax},60"></div> size could depend on pgMax and fractions thereof -->
                        <div ex:coderClass="Icon" ex:role="coder" id="events-icon"/>

                        <table width="100%">
                            <tr valign="top">
                                <td style="width:15%">
                                    <div ex:facetClass="TextSearch" ex:facetLabel="Search"
                                        ex:role="facet"/>
                                    <div ex:expression=".type" ex:facetLabel="Location type"
                                        ex:role="facet"/>
                                    <div ex:expression=".label" ex:facetLabel="Location"
                                        ex:role="facet"/>
                                    <div ex:expression=".eventType" ex:facetLabel="Event type"
                                        ex:role="facet"/>
                                </td>
                                <td ex:role="viewPanel" style="width:69%">
                                    <div ex:center="33.509166, 36.310154"
                                        ex:colorCoder="type-color" 
                                        ex:colorKey=".typeCode" 
                                        ex:colorLegendLabel="Location type" 
                                        ex:label="events"
                                        ex:latlng=".latlng" 
                                        ex:mapHeight="580" 
                                        ex:role="view"
                                        ex:shape="circle" 
                                        ex:showHeader="false"
                                        ex:sizeCoder="events-size" 
                                        ex:sizeKey=".events"
                                        ex:sizeLegendLabel="Events" 
                                        ex:viewClass="Map" 
                                        ex:zoom="15">
                                        <div class="map-lens" ex:role="lens" style="display: none;">
                                            <div><b ex:content=".label"/>, <span ex:content=".type"/></div>
                                            <div><span ex:content=".events"/> reports on "<span
                                                  ex:content=".eventType"/>".</div>
                                        </div>
                                    </div>
                                </td>
                                <td style="width:15%">
                                    <div ex:border="1" 
                                        ex:cellPadding="0" 
                                        ex:cellSpacing="0"
                                        ex:columns=".label, .events" 
                                        ex:role="view"
                                        ex:showToolbox="true" 
                                        ex:sortAscending="false"
                                        ex:sortColumn="1" 
                                        ex:viewClass="Tabular"
                                        style="max-width:200px;"/>
                                </td>
                            </tr>
                        </table>

                    </div>

                </body>
            </html>

        </xsl:result-document>
        
        <!-- The following HTML arranges the results differently: the search bar is atop the map and the browser columns underneath -->
        <xsl:result-document href="simileMapTableH-{$vgName}-{$pgDateCurrent}.html">
            <html>
                <xsl:call-template name="tHtmlHead"/>
                <body>
                    <!-- <ul id="path">
                            <li><a href="/">SIMILE Widgets</a></li>
                            <li><a href="/exhibit3/">Exhibit 3.0</a></li>
                            <li><span>Density of Reports</span></li> 
                        </ul>-->
                    <div id="header">
                        <h1>Spatial distribution of <xsl:value-of select="count($vRefs/tss:reference)"/> reports on <xsl:value-of select="$pgType"/>
                            <xsl:call-template name="templRange"/></h1>
                        <p> Using <a href="http://simile-widgets.org/exhibit3/">SIMILE Widgets:
                            Exhibit 3.0</a>. </p>
                    </div>
                    <div id="content">
                        <!-- the mpgMax must be computed separately -->
                        <div ex:coderClass="ColorGradient"
                            ex:gradientPoints="1, #FF0000; 30, #FF0000; {$pgMax}, #610B0B"
                            ex:role="coder" id="events-color"/>
                        <div ex:coderClass="ColorGradient"
                            ex:gradientPoints="1, #FF0000; 2, #FFA500; 3, #FFFF00; 4, #008000; 5, #0000FF; 6, #800080"
                            ex:role="coder" id="type-color"/>
                        <div ex:coderClass="SizeGradient"
                            ex:gradientPoints="1, 10; 5,30; 30,60; {$pgMax}, 100" ex:role="coder"
                            id="events-size"/>
                        <!-- <div ex:role="coder" ex:coderClass="SizeGradient" id="events-size"
                                ex:gradientPoints="1, 10; 5,30; {$pgMax},60"></div> size could depend on pgMax and fractions thereof -->
                        <div ex:coderClass="Icon" ex:role="coder" id="events-icon"/>
                        
                        <div style="width:15%;position:relative;float:right;" ex:border="1" ex:cellPadding="0" ex:cellSpacing="0" ex:columns=".label, .events" ex:role="view" ex:showToolbox="true" ex:sortAscending="false" ex:sortColumn="1" ex:viewClass="Tabular"></div>
                        
                        <div width="80%">
                            <div style="width:80%;position:relative;float:left" ex:facetClass="TextSearch" ex:facetLabel="Search" ex:role="facet"></div>
                            <div ex:role="viewPanel" style="width:80%;position:relative;float:left">
                                <div ex:center="33.509166, 36.310154" ex:colorCoder="type-color" ex:colorKey=".typeCode" ex:colorLegendLabel="Location type" ex:label="events" ex:latlng=".latlng" ex:mapHeight="580" ex:role="view" ex:shape="circle" ex:showHeader="false" ex:sizeCoder="events-size" ex:sizeKey=".events" ex:sizeLegendLabel="Events" ex:viewClass="Map" ex:zoom="15">
                                    <div class="map-lens" ex:role="lens" style="display: none;">
                                        <div><b ex:content=".label"></b>, <span ex:content=".type"></span></div>
                                        <div><span ex:content=".events"></span> reports on "<span ex:content=".eventType"></span>".
                                        </div>
                                    </div>
                                </div>
                            </div>
                            <div style="width:80%;position:relative;float:left">
                                <div style="width:33%;position:relative;float:left" ex:expression=".type" ex:facetLabel="Location type" ex:role="facet"></div>
                                <div style="width:33%;position:relative;float:left" ex:expression=".label" ex:facetLabel="Location" ex:role="facet"></div>
                                <div style="width:33%;position:relative;float:left" ex:expression=".eventType" ex:facetLabel="Event type" ex:role="facet"></div>
                            </div>
                        </div>  
                        
                    </div>
                    
                </body>
            </html>
            
        </xsl:result-document>
    </xsl:template>
    
    <xsl:template name="tHtmlHead">
        <head>
            <title>
                <xsl:value-of select="$pgType"/>
                <xsl:call-template name="templRange"/>
            </title>
            <link href="http://www.simile-widgets.org/styles/common.css" rel="stylesheet"
                type="text/css"/>
            
            <link href="simileData-{$vgName}-{$pgDateCurrent}.js" rel="exhibit-data"
                type="application/json"/>
            
            <link
                href="http://api.simile-widgets.org/exhibit/3.0.0/extensions/map/map-extension.js"
                rel="exhibit-extension" type="text/javascript"/>
            
            <script src="http://api.simile-widgets.org/exhibit/3.0.0/exhibit-api.js"/>
        </head>
    </xsl:template>
    
    <xsl:template name="templRange">
        <xsl:param name="pDate" select="$pgRefs/tss:reference/tss:dates/tss:date[if(@type='Original') then(@type='Original') else(@type='Publication')]/@year"/>
        <xsl:text> between </xsl:text>
        <xsl:value-of select="min($pDate)"/>
        <xsl:text> and </xsl:text>
        <xsl:value-of select="max($pDate)"/>
        <xsl:text>.</xsl:text>
    </xsl:template>

</xsl:stylesheet>
