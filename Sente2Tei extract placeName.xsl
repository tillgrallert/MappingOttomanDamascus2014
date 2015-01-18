<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet  
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:tss="http://www.thirdstreetsoftware.com/SenteXML-1.0"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:html="http://www.w3.org/1999/xhtml"
    xmlns="http://www.thirdstreetsoftware.com/SenteXML-1.0"
    xpath-default-namespace="http://www.tei-c.org/ns/1.0"
    version="2.0"
    >
    <xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes" omit-xml-declaration="no"/>
    
    <!-- this stylesheet produces a TEI XML file containig a listPlace with all strings marked in a Sente XML as <placeName> -->
    
    <!-- this variable specifies the sort order according to the IJMES transliteration of Arabic -->
    <!-- it is called as collation="http://saxon.sf.net/collation?rules={encode-for-uri($sortIjmes)}" -->
    <xsl:variable name="sortIjmes"
        select="'&lt; ʾ,ʿ &lt; a,A &lt; ā, Ā &lt; b,B &lt; c,C &lt; d,D &lt; ḍ, Ḍ &lt; e,é,è,E,É,È &lt; f,F &lt; g,G &lt; ġ, Ġ &lt; h,H &lt; ḥ, Ḥ &lt; ḫ, Ḫ &lt; i,I &lt; ī, Ī  &lt; j,J &lt; k,K &lt; ḳ, Ḳ &lt; l,L &lt; m,M &lt; n,N &lt; o,O &lt; p,P &lt; q,Q &lt; r,R &lt; s,S &lt; ṣ, Ṣ &lt; t,T &lt; ṭ, Ṭ &lt; ṯ, Ṯ &lt; u,U &lt; ū, Ū &lt; v,V &lt; w,W &lt; x,X &lt; y,Y &lt; z, Z &lt; ẓ, Ẓ'"/>
    
    <!-- templates dealing with Sente XML files -->
    <xsl:template match="tss:senteContainer">
        <xsl:result-document href="output/placeNamesTempTEI {format-date(current-date(),'[Y01][M01][D01]')}.xml">
            <tei:TEI>
                <tei:teiHeader>
                    <tei:fileDesc>
                        <tei:titleStmt>
                            <tei:title>placeName nodes extracted from Sente XML</tei:title>
                            <tei:respStmt>
                                <tei:resp>Prepared by</tei:resp>
                                <tei:persName>Till Grallert</tei:persName>
                            </tei:respStmt>
                        </tei:titleStmt>
                        <tei:publicationStmt>
                            <xsl:element name="tei:p">Version of <xsl:value-of select="format-date(current-date(),'[D01] [MNn] [Y0001]')"/></xsl:element>
                        </tei:publicationStmt>
                        <tei:sourceDesc>
                            <xsl:apply-templates mode="mPlace"/>
                        </tei:sourceDesc>
                    </tei:fileDesc>
                    <tei:revisionDesc>
                        <xsl:element name="tei:change">
                            <xsl:attribute name="when" select="format-date(current-date(),'[Y0001]-[M01]-[D01]')"/>
                            <xsl:text>File created from mark-up inside the Sente XML file "</xsl:text>
                            <xsl:value-of select="base-uri()"/>
                            <xsl:text>" through an XSLT conversion.</xsl:text>
                        </xsl:element>
                    </tei:revisionDesc>
                </tei:teiHeader>
                <tei:text>
                    <tei:body>
                        <tei:p>empty</tei:p>
                    </tei:body>
                </tei:text>
            </tei:TEI> 
        </xsl:result-document>
    </xsl:template>
    
    <xsl:template match="tss:library" mode="mPlace">
        <!-- list of tagged placeName -->
        <xsl:element name="tei:listPlace">
            <xsl:for-each-group select="$vPlaceNames/tei:placeName" group-by=".">
                <xsl:sort select="." collation="http://saxon.sf.net/collation?rules={encode-for-uri($sortIjmes)}"/>
                <xsl:element name="tei:place">
                    <xsl:copy-of select="."/>
                </xsl:element>
            </xsl:for-each-group>
        </xsl:element>
    </xsl:template>
    
    <xsl:variable name="vPlaceNames">
        <!-- deals with plain text mark-up -->
        <xsl:for-each select="if(contains(.,'&lt;/placeName&gt;')) then(tokenize(., '&lt;/placeName&gt;')) else()">
            <xsl:element name="tei:placeName">
                <xsl:value-of select="if(substring(substring-after(., '&lt;placeName&gt;'),1,1)=' ') then(substring(substring-after(., '&lt;placeName&gt;'),2)) else(substring-after(., '&lt;placeName&gt;'))"/>
            </xsl:element>
        </xsl:for-each>
        
        <!-- deals with proper xml -->
        <xsl:for-each select=".//tei:placeName">
            <xsl:apply-templates select="." mode="mPlace"/>
        </xsl:for-each>
        <xsl:for-each select=".//tss:placeName">
            <xsl:apply-templates select="." mode="mPlace"/>
        </xsl:for-each>
    </xsl:variable>
    
    <xsl:template match="@*" mode="mPlace">
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="mPlace"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="tei:placeName" mode="mPlace">
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="mPlace"/>
            <xsl:value-of select="normalize-space(.)"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="tss:placeName" mode="mPlace">
        <tei:placeName>
            <xsl:apply-templates select="@*" mode="mPlace"/>
            <xsl:value-of select="normalize-space(.)"/>
        </tei:placeName>
    </xsl:template>
 
</xsl:stylesheet>