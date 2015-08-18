<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" 
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns="http://www.tei-c.org/ns/1.0">
    
    <xsl:output encoding="UTF-8" indent="yes" method="xml" omit-xml-declaration="no" version="1.0"/>

    <!-- This xslt takes a list of place/placeName inside the sourceDesc of a TEI xml as source. 
        @mode='m2' queries the Api of geonames.org and produces an output file "georeference.xml"
        @mode='m3' uses this output file and converts it into a valid TEI listPlace element. result is saved to "georeferences-tei.xml" -->
    
    <!-- this param defines the XML returned from geonames.org -->
    <xsl:param name="pGeonames"
        select="'/BachUni/projekte/XML/Sente Georeference/output/georeferences.xml'"/>
    <!-- these variables are used to transpose transliterations from GeoNames to Ijmes -->
    <xsl:variable name="vGeoNamesDiac" select="'’‘áḨḨḩŞşŢţz̧'"/>
    <xsl:variable name="vGeoNamesIjmes" select="'ʾʿāḤḤḥṢṣṬṭẓ'"/>

    <xsl:template match="tei:TEI">
        <xsl:apply-templates mode="m2" select=".//tei:sourceDesc/tei:listPlace"/>
        <xsl:result-document href="output/georeferences-tei.xml">
            <xsl:copy>
                <xsl:apply-templates select="@* | node()" mode="m3"/>
            </xsl:copy>
        </xsl:result-document>
    </xsl:template>

    <xsl:template match="@* | node()" mode="m3">
        <xsl:copy>
            <xsl:apply-templates mode="m3" select="@* | node()"/>
        </xsl:copy>
    </xsl:template>


    <!-- calls the geonames.org api for every distinct value  -->
    <xsl:template match="tei:listPlace" mode="m2">
        <xsl:result-document href="output/georeferences.xml">
            <xsl:element name="geonames">
                <!-- add a translate function for the geonames transliteration -->
                <xsl:for-each-group group-by="lower-case(.)" select=".//tei:placeName">
                    <xsl:element name="tei:place">
                        <xsl:element name="tei:placeName">
                            <xsl:attribute name="type">simple</xsl:attribute>
                            <xsl:value-of select="."/>
                        </xsl:element>
                        <xsl:call-template name="templGeoNames">
                            <xsl:with-param name="pSearchString" select="current-grouping-key()"/>
                        </xsl:call-template>
                    </xsl:element>
                </xsl:for-each-group>
            </xsl:element>
        </xsl:result-document>
    </xsl:template>

    <!-- use the file produced in m2 -->
    <xsl:template match="tei:listPlace" mode="m3">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="m3"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="tei:place" mode="m3">
        <!-- check whether GeoNames returned some data -->
        <xsl:variable name="vPlName" select="./tei:placeName"/>
        <xsl:variable name="vPlace">
            <xsl:copy-of select="document($pGeonames)//place[./tei:placeName=$vPlName]"/>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="$vPlace//geoname">
                <xsl:element name="tei:place">
                    <xsl:attribute name="type">
                        <xsl:choose>
                            <xsl:when test="$vPlace//fcode='MSQE'">
                                <xsl:text>building</xsl:text>
                            </xsl:when>
                            <xsl:when test="starts-with($vPlace//fcode,'PPL')">
                                <xsl:text>town</xsl:text>
                            </xsl:when>
                            <xsl:when test="starts-with($vPlace//fcode,'ADM')">
                                <xsl:text>county</xsl:text>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="./fcode"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:attribute>
                    <xsl:choose>
                        <xsl:when test="$vPlace//fcode='MSQE'">
                            <xsl:attribute name="subtype" select="'mosque'"/>
                        </xsl:when>
                    </xsl:choose>
                    <xsl:attribute name="xml:id">
                        <xsl:text>lgn</xsl:text>
                        <xsl:value-of select="$vPlace//geonameId"/>
                    </xsl:attribute>
                    <xsl:element name="tei:placeName">
                        <xsl:attribute name="type">simple</xsl:attribute>
                        <xsl:value-of select="$vPlName"/>
                    </xsl:element>
                    <xsl:element name="tei:placeName">
                        <xsl:attribute name="type">toponym</xsl:attribute>
                        <xsl:value-of select="$vPlace//toponymName"/>
                    </xsl:element>
                    <xsl:element name="tei:placeName">
                        <xsl:attribute name="xml:lang">ar-Latn-x-ijmes</xsl:attribute>
                        <xsl:value-of
                            select="translate($vPlace//toponymName,$vGeoNamesDiac,$vGeoNamesIjmes)"/>
                    </xsl:element>
                    <xsl:element name="tei:placeName">
                        <xsl:attribute name="xml:lang">en</xsl:attribute>
                        <xsl:value-of select="$vPlace//name"/>
                    </xsl:element>
                    <xsl:element name="tei:placeName">
                        <xsl:attribute name="xml:lang">ar</xsl:attribute>
                        <xsl:value-of select="$vPlace//alternateName[@lang='ar']"/>
                    </xsl:element>
                    <xsl:element name="tei:placeName">
                        <xsl:attribute name="xml:lang">tr</xsl:attribute>
                        <xsl:value-of select="$vPlace//alternateName[@lang='tr']"/>
                    </xsl:element>
                    <xsl:for-each select="tokenize($vPlace//alternateNames,',')">
                        <xsl:element name="tei:placeName">
                            <xsl:attribute name="type" select="'alt'"/>
                            <xsl:attribute name="n" select="position()"/>
                            <xsl:value-of select="."/>
                        </xsl:element>
                    </xsl:for-each>
                    <xsl:element name="tei:location">
                        <xsl:element name="tei:geo">
                            <xsl:value-of select="$vPlace//lat"/>
                            <xsl:text>, </xsl:text>
                            <xsl:value-of select="$vPlace//lng"/>
                        </xsl:element>
                    </xsl:element>
                </xsl:element>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy>
                    <xsl:apply-templates select="@* | node()" mode="m3"/>
                </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="tei:revisionDesc" mode="m3">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="m3"/>
            <xsl:element name="tei:change">
                <xsl:attribute name="when" select="format-date(current-date(),'[Y0001]-[M01]-[D01]')"/>
                <xsl:text>Added location data from GeoNames.org through an XSLT conversion.</xsl:text>
            </xsl:element>
        </xsl:copy>
    </xsl:template>


    <xsl:template name="templGeoNames">
        <xsl:param name="pApiUrl" select="'http://api.geonames.org/search?name='"/>
        <xsl:param name="pApiOptions"
            select="'&amp;maxRows=1&amp;style=FULL&amp;lang=en&amp;username=tardigradae'"/>
        <xsl:param name="pSearchString"/>
        <xsl:variable name="vDocName">
            <xsl:value-of select="$pApiUrl"/>
            <xsl:value-of select="translate($pSearchString,$vGeoNamesIjmes,$vGeoNamesDiac)"/>
            <xsl:value-of select="$pApiOptions"/>
        </xsl:variable>
        <xsl:copy-of select="document($vDocName)/geonames/geoname[1]"/>
    </xsl:template>

</xsl:stylesheet>
