<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:djb="http://www.obdurodon.org"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math" exclude-result-prefixes="#all"
    xmlns="http://www.w3.org/2000/svg" version="3.0">
    <!-- TODO:
        Add first tier
        Keys may not be numeric, but will be sorted
        Function to create numbered yellow rectangle
        Function to create rectangle with dot
        Function to create rectangle with NIL for tail
        Function to draw all arrow for level at a time, where higher level
            implies all lower levels
    -->
    <xsl:output method="xml" indent="yes"/>
    <xsl:variable name="root" as="document-node()" select="/"/>
    <xsl:variable name="xScale" as="xs:double" select="40"/>
    <xsl:variable name="maxHeight" as="xs:double" select="max(//Node[not(@name)]/@level)"/>
    <xsl:function name="djb:draw-arrow" as="item()+">
        <xsl:param name="start-node" as="xs:integer"/>
        <xsl:param name="end-node" as="xs:integer"/>
        <xsl:param name="level" as="xs:integer"/>
        <line x1="{$start-node * $xScale}" y1="-{$level + 0.5 * $xScale}"
            x2="{$start-node * $xScale}" y2="{$level + 0.5 * $xScale}" stroke="black"/>
    </xsl:function>
    <xsl:template match="/">
        <svg viewBox="-50 -300 500 350" width="90%">
            <!-- ================================================== -->
            <!-- Draw nodes, including levels                       -->
            <!-- ================================================== -->
            <xsl:apply-templates select="//Node"/>
            <!-- ================================================== -->
            <!-- Draw skips                                         -->
            <!-- ================================================== -->
            <xsl:for-each select="2 to xs:integer($maxHeight)">
                <xsl:variable name="node-keys-at-height" as="xs:double+"
                    select="-1, $root//Node[@level = current()]/@key, count($root//Node[not(@name)]) + 1"/>
                <xsl:message select="$node-keys-at-height => string-join(', ')"/>
            </xsl:for-each>
        </svg>
    </xsl:template>
    <xsl:template match="Node">
        <xsl:variable name="xPos" as="xs:double" select="@key * $xScale"/>
        <xsl:if test="not(@name)">
            <!-- ================================================== -->
            <!-- Create numbered yellow box for level 1             -->
            <!-- ================================================== -->
            <rect x="{$xPos}" y="0" width="{$xScale div 2}" height="{$xScale div 2}" stroke="black"
                fill="yellow"/>
            <text x="{$xPos + ($xScale div 4)}" y="{$xScale div 4}" dy="2" fill="black"
                font-size="large" text-anchor="middle" dominant-baseline="middle">
                <xsl:value-of select="@key"/>
            </text>
            <!-- ================================================== -->
            <!-- Create boxes for all levels (level 1 is done)      -->
            <!-- ================================================== -->
            <xsl:for-each select="2 to @level">
                <xsl:variable name="yPos" as="xs:double"
                    select="-1 * $xScale div 2 * (current() - 1)"/>
                <rect x="{$xPos}" y="{$yPos}" width="{$xScale div 2}" height="{$xScale div 2}"
                    stroke="black" fill="none"/>
                <circle cx="{$xPos + ($xScale div 4)}" cy="{$yPos + ($xScale div 4)}" r="3"
                    fill="black"/>
            </xsl:for-each>
        </xsl:if>
    </xsl:template>
    <xsl:template match="Node[@name]">
        <xsl:choose>
            <xsl:when test="@name eq 'head'">
                <!-- ============================================== -->
                <!-- Create boxes and labels for head               -->
                <!-- ============================================== -->
                <xsl:for-each select="2 to xs:integer($maxHeight)">
                    <rect x="-{$xScale}" y="-{$xScale div 2 * (current() - 1)}"
                        width="{$xScale div 2}" height="{$xScale div 2}" stroke="black" fill="none"/>
                    <circle cx="{-$xScale + ($xScale div 4)}"
                        cy="-{$xScale * (current() - 1.5) div 2}" r="3" fill="black"/>
                </xsl:for-each>
                <text x="{-$xScale + ($xScale div 4)}" y="{$xScale div 4}" dy="3" fill="black"
                    text-anchor="middle" dominant-baseline="middle" font-size="x-small">head</text>
            </xsl:when>
            <xsl:otherwise>
                <!-- ============================================== -->
                <!-- Create boxes and labels for tail               -->
                <!-- Write NIL in separate loop because of z-index  -->
                <!-- ============================================== -->
                <xsl:variable name="xPos" as="xs:double"
                    select="count(//Node[not(@name)]) * $xScale"/>
                <xsl:for-each select="2 to xs:integer($maxHeight)">
                    <rect x="{$xPos}" y="-{$xScale div 2 * (current() - 1)}" width="{$xScale div 2}"
                        height="{$xScale div 2}" stroke="black" fill="#E8E8E8"/>
                </xsl:for-each>
                <xsl:for-each select="2 to xs:integer($maxHeight)">
                    <text x="{$xPos + ($xScale div 4)}"
                        y="-{$xScale div 2 * (current() - 1) - ($xScale div 4)}" fill="black"
                        text-anchor="middle" dominant-baseline="middle" font-size="xx-small"
                        >NIL</text>
                </xsl:for-each>
                <text x="{$xPos + ($xScale div 4)}" y="{$xScale div 4}" dy="3" fill="black"
                    text-anchor="middle" dominant-baseline="middle" font-size="x-small">tail</text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
</xsl:stylesheet>
