<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:djb="http://www.obdurodon.org"
    xmlns:djb-f="http://www.obdurodon.org/function-variables"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math" exclude-result-prefixes="#all"
    xmlns="http://www.w3.org/2000/svg" xmlns:svg="http://www.w3.org/2000/svg" version="3.0">
    <!-- ========================================================== -->
    <!-- About this file                                            -->
    <!-- ========================================================== -->
    <!-- stylesheet variable names are in lower camelCase,          -->
    <!--   e.g. $maxLevels                                          -->
    <!-- function names are hyphenated and in the djb namespace,    -->
    <!--   e.g., djb:draw-arrow()                                   -->
    <!-- function variables are in lower camelCases in the djb-f    -->
    <!--   namespace, e.g., djb-f:startNode                         -->
    <!-- ========================================================== -->
    <!-- TODO:
        Render value
            Modify for CollateX, where value is a variant graph node
        General function to draw rectangle, used by
            Function to create rectangle with NIL for tail
        Function to draw all arrows for level at a time, where higher level
            implies all lower levels
        Outsource computation of static function values to helper function
            with @cache set to yes; this keeps the computation of the
            variable value sort of local to the function that uses it 
            (that is, it avoids using a global stylesheet variable),
            and the caching avoids repeating the computation
        Arrowhead SVG: view-source:https://upload.wikimedia.org/wikipedia/commons/5/59/SVG_double_arrow_with_marker-start_and_marker-end.svg
        
        Create dumpAsXML function in PySkipList
    -->
    <xsl:output method="xml" indent="yes"/>

    <!-- ========================================================== -->
    <!-- Stylesheet parameters                                      -->
    <!--                                                            -->
    <!-- $boxSize: height and width of boxes                        -->
    <!-- ========================================================== -->
    <xsl:param name="boxSize" as="xs:double" static="yes" select="100"/>

    <!-- ========================================================== -->
    <!-- Stylesheet variables                                       -->
    <!-- $boxSpacing: horizontal distance between left edges of     -->
    <!--   consecutive boxes                                        -->
    <!-- $boxCenterOffset: amount to add to box edge to find center -->
    <!-- $textShift: amount to shift to center text in box          -->
    <!-- ========================================================== -->
    <xsl:variable name="root" as="document-node()" select="/"/>
    <xsl:variable name="boxSpacing" as="xs:double" select="$boxSize * 2"/>
    <xsl:variable name="boxCenterOffset" as="xs:double" select="$boxSize div 2"/>
    <xsl:variable name="textShift" as="xs:double" select="3"/>
    <xsl:variable name="maxLevels" as="xs:double" select="max(//Node[not(@name)]/@level)"/>
    <xsl:variable name="nodeCount" as="xs:integer" select="count(//Node[not(@name)])"/>
    <xsl:variable name="circleRadius" as="xs:double" select="$boxSize * .15"/>

    <!-- ========================================================== -->
    <!-- Stylesheet functions                                       -->
    <!-- ========================================================== -->
    <xsl:function name="djb:drawRectangle" as="element(svg:rect)">
        <!-- ====================================================== -->
        <!-- Draw rectangle#5                                       -->
        <!--                                                        -->
        <!-- Parameters:                                            -->
        <!--   djb-f:nodeOffset: node offset                        -->
        <!--   djb-f:nodeLevel: level at which to draw rectangle    -->
        <!--   djb-f:boxSize: height and width of rectangle         -->
        <!--   djb-f:boxSpacing: incremental offset distance        -->
        <!--     between rectangles                                 -->
        <!--   djb-f:boxShading: fill color (defaults to none)      -->
        <!-- Returns:                                               -->
        <!--   svg:rect                                             -->
        <!-- ====================================================== -->
        <xsl:param name="djb-f:nodeOffset" as="xs:integer"/>
        <xsl:param name="djb-f:level" as="xs:integer"/>
        <xsl:param name="djb-f:boxSize" as="xs:double"/>
        <xsl:param name="djb-f:boxSpacing" as="xs:double"/>
        <xsl:param name="djb-f:boxShading" as="xs:string"/>
        <rect x="{$djb-f:nodeOffset * $djb-f:boxSpacing}" y="-{$djb-f:level * $djb-f:boxSize}"
            height="{$djb-f:boxSize}" width="{$djb-f:boxSize}" stroke="black" stroke-width="2"
            fill="{$djb-f:boxShading}"/>
    </xsl:function>
    <xsl:function name="djb:drawRectangle" as="element(svg:rect)">
        <!-- ====================================================== -->
        <!-- Draw rectangle#3                                       -->
        <!--                                                        -->
        <!-- Parameters:                                            -->
        <!--   djb-f:nodeOffset: node offset                        -->
        <!--   djb-f:nodeLevel: level at which to draw rectangle    -->
        <!--   djb-f:boxSize: height and width of rectangle         -->
        <!--   djb-f:boxSpacing: incremental offset distance        -->
        <!--     between rectangles                                 -->
        <!--                                                        -->
        <!-- Returns:                                               -->
        <!--   svg:rect                                             -->
        <!--                                                        -->
        <!-- Note: calls rectangle#4 with rectShading = none        -->
        <!-- ====================================================== -->
        <xsl:param name="djb-f:nodeOffset" as="xs:integer"/>
        <xsl:param name="djb-f:level" as="xs:integer"/>
        <xsl:param name="djb-f:boxSize" as="xs:double"/>
        <xsl:param name="djb-f:boxSpacing" as="xs:double"/>
        <xsl:sequence
            select="djb:drawRectangle($djb-f:nodeOffset, $djb-f:level, $djb-f:boxSize, $djb-f:boxSpacing, 'none')"
        />
    </xsl:function>
    <xsl:function name="djb:centerText" as="element(svg:text)">
        <xsl:param name="djb-f:nodeOffset" as="xs:integer"/>
        <xsl:param name="djb-f:level" as="xs:integer"/>
        <xsl:param name="djb-f:boxSize" as="xs:double"/>
        <xsl:param name="djb-f:boxCenterOffset" as="xs:double"/>
        <xsl:param name="djb-f:boxSpacing" as="xs:double"/>
        <xsl:param name="djb-f:text" as="xs:string"/>
        <xsl:param name="djb-f:textShift"/>
        <xsl:param name="djb-f:textSize" as="xs:string"/>
        <text x="{$djb-f:nodeOffset * $djb-f:boxSpacing + $djb-f:boxCenterOffset}"
            y="{$djb-f:level + $djb-f:boxCenterOffset}" dy="{$djb-f:textShift}"
            dominant-baseline="middle" text-anchor="middle" fill="black"
            font-size="{$djb-f:textSize}">
            <xsl:value-of select="$djb-f:text"/>
        </text>
    </xsl:function>
    <xsl:function name="djb:centerDot" as="element(svg:circle)">
        <xsl:param name="djb-f:nodeOffset" as="xs:integer"/>
        <xsl:param name="djb-f:level" as="xs:integer"/>
        <xsl:param name="djb-f:boxSize" as="xs:double"/>
        <xsl:param name="djb-f:boxCenterOffset" as="xs:double"/>
        <xsl:param name="djb-f:boxSpacing" as="xs:double"/>
        <xsl:param name="djb-f:circleRadius" as="xs:double"/>
        <circle cx="{$djb-f:nodeOffset * $djb-f:boxSpacing + $djb-f:boxCenterOffset}"
            cy="-{($djb-f:level - 1) * $djb-f:boxSize + $djb-f:boxCenterOffset}"
            r="{$djb-f:circleRadius}" fill="black"/>
    </xsl:function>
    <xsl:function name="djb:draw-arrow" as="element(svg:line)">
        <!-- ====================================================== -->
        <!-- Draw arrow                                             -->
        <!--                                                        -->
        <!-- Parameters:                                            -->
        <!--   djb-f:start-node: node offset of left end of arrow   -->
        <!--   djb-f:end-node: node offset of right end of arrow    -->
        <!-- Returns:                                               -->
        <!--   svg:line                                             -->
        <!-- ====================================================== -->
        <xsl:param name="djb-f:start-node" as="xs:integer"/>
        <xsl:param name="djb-f:end-node" as="xs:integer"/>
        <xsl:param name="djb-f:level" as="xs:integer"/>
        <line x1="{$djb-f:start-node * $boxSize}" y1="-{$djb-f:level + 0.5 * $boxSize}"
            x2="{$djb-f:start-node * $boxSize}" y2="{$djb-f:level + 0.5 * $boxSize}" stroke="black"
        />
    </xsl:function>

    <!-- ========================================================== -->
    <!-- Main                                                       -->
    <!-- ========================================================== -->
    <xsl:template match="/">
        <svg
            viewBox="-{$boxSpacing} -{($maxLevels + 1) * $boxSize} {$boxSpacing * ($nodeCount + 5)} {($maxLevels + 2) * $boxSize}">
            <!-- ================================================== -->
            <!-- Draw nodes, including levels                       -->
            <!-- ================================================== -->
            <xsl:apply-templates select="//Node"/>
            <!-- ================================================== -->
            <!-- Draw skips                                         -->
            <!-- ================================================== -->
            <!--            <xsl:for-each select="2 to xs:integer($maxLevels)">
                <xsl:variable name="node-keys-at-height" as="xs:double+"
                    select="-1, $root//Node[@level = current()]/@key, count($root//Node[not(@name)]) + 1"/>
                <xsl:message select="$node-keys-at-height => string-join(', ')"/>
            </xsl:for-each>-->
        </svg>
    </xsl:template>
    <xsl:template match="Node">
        <!-- ================================================== -->
        <!-- Process all nodes except head and tail             -->
        <!-- ================================================== -->
        <xsl:variable name="nodeOffset" select="position()"/>
        <!-- ================================================== -->
        <!-- Create numbered yellow box for node (not a level)  -->
        <!--   Write value under box                            -->
        <!-- ================================================== -->
        <xsl:sequence select="djb:drawRectangle(position(), 0, $boxSize, $boxSpacing, 'yellow')"/>
        <xsl:sequence
            select="djb:centerText(position(), 0, $boxSize, $boxCenterOffset, $boxSpacing, xs:string(position() - 2), $textShift, '500%')"/>
        <text x="{position() * $boxSpacing + $boxCenterOffset}" y="150" text-anchor="middle"
            dominant-baseline="middle" fill="black" font-size="400%">
            <xsl:value-of select="@value"/>
        </text>
        <!-- ================================================== -->
        <!-- Create dotted boxes for all levels                 -->
        <!-- ================================================== -->
        <xsl:for-each select="1 to @level">
            <xsl:sequence select="djb:drawRectangle($nodeOffset, ., $boxSize, $boxSpacing)"/>
            <xsl:sequence
                select="djb:centerDot($nodeOffset, ., $boxSize, $boxCenterOffset, $boxSpacing, $circleRadius)"
            />
        </xsl:for-each>
    </xsl:template>
    <xsl:template match="Node[@name]">
        <!--       <xsl:choose>
            <xsl:when test="@name eq 'head'">
                <!-\- ============================================== -\->
                <!-\- Create boxes and labels for head               -\->
                <!-\- ============================================== -\->
                <xsl:for-each select="2 to xs:integer($maxLevels)">
                    <rect x="-{$boxSize}" y="-{$boxSize div 2 * (current() - 1)}"
                        width="{$boxSize div 2}" height="{$boxSize div 2}" stroke="black"
                        fill="none"/>
                    <circle cx="{-$boxSize + ($boxSize div 4)}"
                        cy="-{$boxSize * (current() - 1.5) div 2}" r="3" fill="black"/>
                </xsl:for-each>
                <text x="{-$boxSize + ($boxSize div 4)}" y="{$boxSize div 4}" dy="{$textShift}"
                    fill="black" text-anchor="middle" dominant-baseline="middle" font-size="x-small"
                    >head</text>
            </xsl:when>
            <xsl:otherwise>
                <!-\- ============================================== -\->
                <!-\- Create boxes and labels for tail               -\->
                <!-\- Write NIL in separate loop because of z-index  -\->
                <!-\- ============================================== -\->
                <xsl:variable name="xPos" as="xs:double"
                    select="count(//Node[not(@name)]) * $boxSize"/>
                <xsl:for-each select="2 to xs:integer($maxLevels)">
                    <rect x="{$xPos}" y="-{$boxSize div 2 * (current() - 1)}"
                        width="{$boxSize div 2}" height="{$boxSize div 2}" stroke="black"
                        fill="#E8E8E8"/>
                </xsl:for-each>
                <xsl:for-each select="2 to xs:integer($maxLevels)">
                    <text x="{$xPos + ($boxSize div 4)}"
                        y="-{$boxSize div 2 * (current() - 1) - ($boxSize div 4)}" fill="black"
                        text-anchor="middle" dominant-baseline="middle" font-size="xx-small"
                        >NIL</text>
                </xsl:for-each>
                <text x="{$xPos + ($boxSize div 4)}" y="{$boxSize div 4}" dy="3{$textShift}"
                    fill="black" text-anchor="middle" dominant-baseline="middle" font-size="x-small"
                    >tail</text>
            </xsl:otherwise>
        </xsl:choose>
 -->
    </xsl:template>
</xsl:stylesheet>
