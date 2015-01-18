<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:html="http://www.w3.org/1999/xhtml"
    xmlns:kml="http://earth.google.com/kml/2.0">
    
    <xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes" omit-xml-declaration="no"/>

    <!-- This stylesheet produces a KML file from a TEI XML master file of locations -->

    <xsl:strip-space elements="tei:placeName tei:geo"/>

    <xsl:template match="tei:TEI">
        <xsl:result-document href="output/loc-{format-date(current-date(),'[Y00][M00][D00]')}.kml">
            <xsl:element name="kml">
                <xsl:element name="Document">
                    <xsl:element name="name">Locations</xsl:element>
                    <xsl:call-template name="tStyles"/>
                    <xsl:apply-templates select=".//tei:place"/>
                </xsl:element>
            </xsl:element>
        </xsl:result-document>
    </xsl:template>

    <!-- This will generate a KML file to be used for visualization with Google Maps -->
    <xsl:template match="tei:place">
        <xsl:variable name="vPlaceName">
            <xsl:choose>
                <xsl:when test="./tei:placeName[@type='IJMES']">
                    <xsl:value-of select="normalize-space(./tei:placeName[@type='IJMES'][1])"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="normalize-space(./tei:placeName[@type='simple'])"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="vID">
            <xsl:if test="@xml:id">
                <xsl:analyze-string select="@xml:id" regex="(\d)">
                    <xsl:matching-substring>
                        <xsl:value-of select="regex-group(1)"/>
                    </xsl:matching-substring>
                </xsl:analyze-string>
            </xsl:if>
        </xsl:variable>
        <xsl:element name="Placemark">
            <xsl:attribute name="xml:id">
                <xsl:value-of select="./@xml:id"/>
            </xsl:attribute>

            <xsl:element name="name">
                <xsl:value-of select="$vPlaceName"/>
            </xsl:element>
            <xsl:element name="description">
                <xsl:value-of select="@type"/>
                <xsl:value-of select="concat(' of ',$vPlaceName)"/>
                <xsl:if test="parent::tei:listPlace/@corresp">
                    <xsl:text> in the </xsl:text>
                    <xsl:value-of select="parent::tei:listPlace/@type"/>
                    <xsl:text> of </xsl:text>
                    <xsl:value-of select="parent::tei:listPlace/tei:place[@xml:id=substring(parent::tei:listPlace/@corresp,2)]/tei:placeName[@type='simple']"/>
                </xsl:if>
                <xsl:if test="@xml:id">
                    <xsl:choose>
                        <xsl:when test="contains(@xml:id,'lgn')">
                            <xsl:element name="br"/>
                            <xsl:element name="a">
                                <xsl:attribute name="href" select="concat('http://geonames.org/',$vID)"/>
                                <xsl:text>Entry at GeoNames.org</xsl:text>
                            </xsl:element>
                        </xsl:when>
                        <xsl:when test="contains(@xml:id,'lwm')">
                            <xsl:element name="br"/>
                            <xsl:element name="a">
                                <xsl:attribute name="href" select="concat('http://wikimapia.org/',$vID)"/>
                                <xsl:text>Entry at WikiMapia.org</xsl:text>
                            </xsl:element>
                        </xsl:when>
                    </xsl:choose>
                </xsl:if>
            </xsl:element>
            <xsl:element name="styleUrl">
                <xsl:choose>
                    <xsl:when test="./@type='city'">
                        <xsl:value-of select="'#m_quarter'"/>
                    </xsl:when>
                    <xsl:when test="./@type='town'">
                        <xsl:value-of select="'#m_quarter'"/>
                    </xsl:when>
                    <xsl:when test="./@type='village'">
                        <xsl:value-of select="'#m_quarter'"/>
                    </xsl:when>
                    <xsl:when test="./@type='quarter'">
                        <xsl:value-of select="'#m_quarter'"/>
                    </xsl:when>
                    <xsl:when test="./@type='neighbourhood'">
                        <xsl:value-of select="'#m_quarter'"/>
                    </xsl:when>
                    <xsl:when test="./@type='street'">
                        <xsl:value-of select="'#m_street'"/>
                    </xsl:when>
                    <xsl:when test="./@type='square'">
                        <xsl:value-of select="'#m_street'"/>
                    </xsl:when>
                    <xsl:when test="./@type='building'">
                        <xsl:value-of select="'#m_building'"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="'#m_generic'"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:element>
            <xsl:element name="Point">
                <xsl:element name="coordinates">
                    <xsl:variable name="vLat"
                        select="normalize-space(substring-before(./tei:location/tei:geo, ','))"/>
                    <xsl:variable name="vLong"
                        select="normalize-space(substring-after(./tei:location/tei:geo, ','))"/>

                    <xsl:value-of select="$vLong"/>
                    <xsl:text>, </xsl:text>
                    <xsl:value-of select="$vLat"/>
                </xsl:element>
            </xsl:element>
        </xsl:element>

    </xsl:template>
    
    <xsl:template name="tStyles">
        <!-- generic -->
        <StyleMap id="m_generic">
            <Pair>
                <key>normal</key>
                <styleUrl>#s_generic</styleUrl>
            </Pair>
            <Pair>
                <key>highlight</key>
                <styleUrl>#s_generic_hl</styleUrl>
            </Pair>
        </StyleMap>
        <Style id="s_generic_hl">
            <IconStyle>
                <!--<color>ffffff</color>-->
                <scale>1.0</scale>
                <Icon>
                    <href>http://maps.google.com/mapfiles/kml/shapes/square.png</href>
                </Icon>
                <hotSpot x="20" y="2" xunits="pixels" yunits="pixels"/>
            </IconStyle>
            <LabelStyle>
                <!--<color>ffffff</color>-->
                <scale>1.4</scale>
            </LabelStyle>
        </Style>
        <Style id="s_generic">
            <IconStyle>
                <!--<color>ffffff</color>-->
                <scale>1.0</scale>
                <Icon>
                    <href>http://maps.google.com/mapfiles/kml/shapes/placemark_square.png</href>
                </Icon>
                <hotSpot x="20" y="2" xunits="pixels" yunits="pixels"/>
            </IconStyle>
            <LabelStyle>
                <!--<color>ffffff</color>-->
                <scale>1.0</scale>
            </LabelStyle>
        </Style>
        <!-- for quarters, neighbourhoods -->
        <StyleMap id="m_quarter">
            <Pair>
                <key>normal</key>
                <styleUrl>#s_quarter</styleUrl>
            </Pair>
            <Pair>
                <key>highlight</key>
                <styleUrl>#s_quarter_hl</styleUrl>
            </Pair>
        </StyleMap>
        <Style id="s_quarter_hl">
            <IconStyle>
                <color>ffb419ed</color>
                <scale>1.0</scale>
                <Icon>
                    <href>http://maps.google.com/mapfiles/kml/shapes/square.png</href>
                </Icon>
                <hotSpot x="20" y="2" xunits="pixels" yunits="pixels"/>
            </IconStyle>
            <LabelStyle>
                <color>ffb419ed</color>
                <scale>1.4</scale>
            </LabelStyle>
        </Style>
        <Style id="s_quarter">
            <IconStyle>
                <color>ffb419ed</color>
                <scale>1.0</scale>
                <Icon>
                    <href>http://maps.google.com/mapfiles/kml/shapes/placemark_square.png</href>
                </Icon>
                <hotSpot x="20" y="2" xunits="pixels" yunits="pixels"/>
            </IconStyle>
            <LabelStyle>
                <color>ffb419ed</color>
                <scale>1.0</scale>
            </LabelStyle>
        </Style>
        <!-- for streets -->
        <StyleMap id="m_street">
            <Pair>
                <key>normal</key>
                <styleUrl>#s_street</styleUrl>
            </Pair>
            <Pair>
                <key>highlight</key>
                <styleUrl>#s_street_hl</styleUrl>
            </Pair>
        </StyleMap>
        <Style id="s_street_hl">
            <IconStyle>
                <color>ff00e179</color>
                <scale>1.0</scale>
                <Icon>
                    <href>http://maps.google.com/mapfiles/kml/shapes/square.png</href>
                </Icon>
                <hotSpot x="20" y="2" xunits="pixels" yunits="pixels"/>
            </IconStyle>
            <LabelStyle>
                <color>ff00e179</color>
                <scale>1.4</scale>
            </LabelStyle>
        </Style>
        <Style id="s_street">
            <IconStyle>
                <color>ff00e179</color>
                <scale>1.0</scale>
                <Icon>
                    <href>http://maps.google.com/mapfiles/kml/shapes/placemark_square.png</href>
                </Icon>
                <hotSpot x="20" y="2" xunits="pixels" yunits="pixels"/>
            </IconStyle>
            <LabelStyle>
                <color>ff00e179</color>
                <scale>1.0</scale>
            </LabelStyle>
        </Style>
        
        <!-- for buildings -->
        <StyleMap id="m_building">
            <Pair>
                <key>normal</key>
                <styleUrl>#s_building</styleUrl>
            </Pair>
            <Pair>
                <key>highlight</key>
                <styleUrl>#s_building_hl</styleUrl>
            </Pair>
        </StyleMap>
        <Style id="s_building_hl">
            <IconStyle>
                <color>ff4a67ff</color>
                <scale>1.0</scale>
                <Icon>
                    <href>http://maps.google.com/mapfiles/kml/shapes/square.png</href>
                </Icon>
                <hotSpot x="20" y="2" xunits="pixels" yunits="pixels"/>
            </IconStyle>
            <LabelStyle>
                <color>ff4a67ff</color>
                <scale>1.4</scale>
            </LabelStyle>
        </Style>
        <Style id="s_building">
            <IconStyle>
                <color>ff4a67ff</color>
                <scale>1.0</scale>
                <Icon>
                    <href>http://maps.google.com/mapfiles/kml/shapes/placemark_square.png</href>
                </Icon>
                <hotSpot x="20" y="2" xunits="pixels" yunits="pixels"/>
            </IconStyle>
            <LabelStyle>
                <color>ff4a67ff</color>
                <scale>1.0</scale>
            </LabelStyle>
        </Style>
    </xsl:template>
   
</xsl:stylesheet>
