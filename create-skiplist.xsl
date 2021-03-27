<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:djb="http://www.obdurodon.org"
    xmlns:djb-f="http://www.obdurodon.org/function-variables"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math" exclude-result-prefixes="#all"
    xmlns="http://www.w3.org/2000/svg" xmlns:svg="http://www.w3.org/2000/svg" version="3.0">
    <!-- ========================================================== -->
    <!-- Naming conventions                                         -->
    <!-- ========================================================== -->
    <!-- stylesheet variable names:                                 -->
    <!--   lower camelCase, e.g., $maxLevels                        -->
    <!-- function names:                                            -->
    <!--   lower camelCase, djb namespace, e.g., djb:centerDot()    -->
    <!-- function variable names:                                   -->
    <!--   lower camelCases, djb-f namespace, e.g., djb-f:startNode -->
    <!-- ========================================================== -->
    <!-- TODO:
        Render value
            Modify for CollateX, where value is a variant graph node
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
    <!--                                                            -->
    <!-- TODO: Declaring this as static raises a Java NPE when      -->
    <!--   placing circles inside head boxes; Saxon issue?          -->
    <!-- ========================================================== -->
    <xsl:param name="boxSize" as="xs:double" select="100"/>

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
    <xsl:variable name="textSize" as="xs:string" select="'400%'"/>
    <xsl:variable name="maxLevels" as="xs:double" select="max(//Node[not(@name)]/@level)"/>
    <xsl:variable name="nodeCount" as="xs:integer" select="count(//Node[not(@name)])"/>
    <xsl:variable name="circleRadius" as="xs:double" select="$boxSize * .10"/>
    <xsl:variable name="nilColor" as="xs:string" select="'#E8E8E8'"/>

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
    <xsl:function name="djb:nodesAtLevel" as="xs:integer+">
        <xsl:param name="allNodes" as="element(Node)"/>
    </xsl:function>
    <xsl:function name="djb:drawArrow" as="element(svg:line)">
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
            <!-- Draw skip lines for each level                     -->
            <!-- Compute nodes at level, pass into drawing function -->
            <!-- ================================================== -->
            <!--<xsl:for-each select="1 to xs:integer($maxLevels)">
                <xsl:sequence select="djb:nodesAtLevel() => djb:drawArros()"/>
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
            dominant-baseline="middle" fill="black" font-size="{$textSize}">
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
        <xsl:choose>
            <xsl:when test="@name eq 'head'">
                <!-- ============================================== -->
                <!-- Create boxes and labels for head               -->
                <!-- ============================================== -->
                <xsl:for-each select="1 to xs:integer($maxLevels)">
                    <!-- create box -->
                    <xsl:sequence select="djb:drawRectangle(1, ., $boxSize, $boxSpacing)"/>
                    <!-- create dot -->
                    <xsl:sequence
                        select="djb:centerDot(1, ., $boxSize, $boxCenterOffset, $boxSpacing, $circleRadius)"
                    />
                </xsl:for-each>
                <!-- label head -->
                <text x="{$boxSpacing + $boxCenterOffset}" y="150" fill="gray"
                    font-size="{$textSize}" dominant-baseline="middle" text-anchor="middle"
                    >[head]</text>
            </xsl:when>
            <xsl:otherwise>
                <!-- ============================================== -->
                <!-- Create boxes and labels for tail               -->
                <!-- ============================================== -->
                <xsl:variable name="xPos" as="xs:integer" select="$nodeCount + 2"/>
                <xsl:for-each select="1 to xs:integer($maxLevels)">
                    <!-- create box -->
                    <xsl:sequence
                        select="djb:drawRectangle($xPos, ., $boxSize, $boxSpacing, $nilColor)"/>
                    <!--write NIL into box-->
                    <text x="{$xPos * $boxSpacing + $boxCenterOffset}"
                        y="-{. * $boxSize - $boxCenterOffset}" dominant-baseline="middle"
                        text-anchor="middle" fill="black" font-size="300%">NIL</text>
                    <!-- label tail -->
                    <text x="{$xPos * $boxSpacing + $boxCenterOffset}" y="150" fill="gray"
                        font-size="{$textSize}" dominant-baseline="middle" text-anchor="middle"
                        >[tail]</text>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>

    </xsl:template>
</xsl:stylesheet>
