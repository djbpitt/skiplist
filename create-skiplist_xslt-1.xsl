<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:math="http://exslt.org/math"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:djb="http://www.obdurodon.org"
    xmlns:djb-f="http://www.obdurodon.org/function-variables"
    exclude-result-prefixes="xs djb djb-f math" xmlns="http://www.w3.org/2000/svg"
    xmlns:svg="http://www.w3.org/2000/svg" version="1.0">
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
        Outsource computation of static function values to helper function
            with @cache set to yes; this keeps the computation of the
            variable value sort of local to the function that uses it 
            (that is, it avoids using a global stylesheet variable),
            and the caching avoids repeating the computation
        More graceful arrowheads, with less finicky positioning

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
    <xsl:param name="boxSize" select="100"/>

    <!-- ========================================================== -->
    <!-- Stylesheet variables                                       -->
    <!-- $boxSpacing: horizontal distance between left edges of     -->
    <!--   consecutive boxes                                        -->
    <!-- $boxCenterOffset: amount to add to box edge to find center -->
    <!-- $textShift: amount to shift to center text in box          -->
    <!-- ========================================================== -->
    <xsl:variable name="root" select="/"/>
    <xsl:variable name="boxSpacing" select="$boxSize * 2"/>
    <xsl:variable name="boxCenterOffset" select="$boxSize div 2"/>
    <xsl:variable name="textShift" select="3"/>
    <xsl:variable name="textSize" select="'400%'"/>
    <xsl:variable name="maxLevels" select="math:max(//Node[not(@name)]/@level)"/>
    <xsl:variable name="allLevels">
        <xsl:for-each select="(//node())[not(position() > $maxLevels)]">
            <xsl:value-of select="position()"/>
        </xsl:for-each>
    </xsl:variable>
    <xsl:variable name="nodeCount" select="count(//Node[not(@name)])"/>
    <xsl:variable name="circleRadius" select="$boxSize * .10"/>
    <xsl:variable name="nilColor" select="'#E8E8E8'"/>

    <!-- ========================================================== -->
    <!-- Callable templates                                         -->
    <!-- ========================================================== -->
    <xsl:template name="djb:drawRectangle">
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
        <xsl:param name="djb-f:nodeOffset"/>
        <xsl:param name="djb-f:level"/>
        <xsl:param name="djb-f:boxSize"/>
        <xsl:param name="djb-f:boxSpacing"/>
        <xsl:param name="djb-f:boxShading"/>
        <rect x="{$djb-f:nodeOffset * $djb-f:boxSpacing}" y="-{$djb-f:level * $djb-f:boxSize}"
            height="{$djb-f:boxSize}" width="{$djb-f:boxSize}" stroke="black" stroke-width="2"
            fill="{$djb-f:boxShading}"/>
    </xsl:template>
    <xsl:template name="djb:centerText">
        <xsl:param name="djb-f:nodeOffset"/>
        <xsl:param name="djb-f:level"/>
        <xsl:param name="djb-f:boxSize"/>
        <xsl:param name="djb-f:boxCenterOffset"/>
        <xsl:param name="djb-f:boxSpacing"/>
        <xsl:param name="djb-f:text"/>
        <xsl:param name="djb-f:textShift"/>
        <xsl:param name="djb-f:textSize"/>
        <text x="{$djb-f:nodeOffset * $djb-f:boxSpacing + $djb-f:boxCenterOffset}"
            y="{$djb-f:level + $djb-f:boxCenterOffset}" dy="{$djb-f:textShift}"
            dominant-baseline="middle" text-anchor="middle" fill="black"
            font-size="{$djb-f:textSize}">
            <xsl:value-of select="$djb-f:text"/>
        </text>
    </xsl:template>
    <xsl:template name="djb:centerDot">
        <xsl:param name="djb-f:nodeOffset"/>
        <xsl:param name="djb-f:level"/>
        <xsl:param name="djb-f:boxSize"/>
        <xsl:param name="djb-f:boxCenterOffset"/>
        <xsl:param name="djb-f:boxSpacing"/>
        <xsl:param name="djb-f:circleRadius"/>
        <circle cx="{$djb-f:nodeOffset * $djb-f:boxSpacing + $djb-f:boxCenterOffset}"
            cy="-{($djb-f:level - 1) * $djb-f:boxSize + $djb-f:boxCenterOffset}"
            r="{$djb-f:circleRadius}" fill="black"/>
    </xsl:template>
    <xsl:template name="djb:nodesAtLevel">
        <xsl:param name="djb-f:level"/>
        <xsl:param name="djb-f:allNodes"/>
        <xsl:value-of
            select="count($djb-f:allNodes[@level &gt;= $djb-f:level]/preceding-sibling::Node)"/>
    </xsl:template>
    <xsl:template name="djb:drawArrow">
        <!-- ====================================================== -->
        <!-- Draw arrow                                             -->
        <!--                                                        -->
        <!-- Parameters:                                            -->
        <!--   djb-f:start-node: node offset of left end of arrow   -->
        <!--   djb-f:end-node: node offset of right end of arrow    -->
        <!-- Returns:                                               -->
        <!--   svg:line                                             -->
        <!-- ====================================================== -->
        <xsl:param name="djb-f:startNode"/>
        <xsl:param name="djb-f:endNode"/>
        <xsl:param name="djb-f:level"/>
        <xsl:param name="djb-f:boxSpacing"/>
        <xsl:param name="djb-f:boxSize"/>
        <xsl:param name="djb-f:boxCenterOffset"/>
        <xsl:variable name="djb-f:height"
            select="-1 * (($djb-f:level - 1) * $djb-f:boxSize + $djb-f:boxCenterOffset)"/>
        <line x1="{($djb-f:startNode + 1) * $djb-f:boxSpacing + $djb-f:boxCenterOffset}"
            y1="{$djb-f:height}" x2="{($djb-f:endNode + 1) * $boxSpacing}" y2="{$djb-f:height}"
            stroke="black" stroke-width="2" marker-end="url(#arrowend)"/>
    </xsl:template>

    <!-- ========================================================== -->
    <!-- Main                                                       -->
    <!-- ========================================================== -->
    <xsl:template match="/">
        <svg
            viewBox="-{$boxSpacing} -{($maxLevels + 1) * $boxSize} {$boxSpacing * ($nodeCount + 5)} {($maxLevels + 2) * $boxSize}">
            <defs>
                <!-- view-source:https://upload.wikimedia.org/wikipedia/commons/5/59/SVG_double_arrow_with_marker-start_and_marker-end.svg -->
                <!--<marker id="arrowend" viewBox="0 0 13 10" refX="2" refY="5" markerWidth="3.5"
                    markerHeight="3.5" orient="auto">
                    <path d="M 0 0  C 0 0, 3 5, 0 10   L 0 10  L 13 5" fill="black"
                        transform="scale(100)"/>
                </marker>-->
                <marker id="arrowend" viewBox="-30 -8 30 16" markerWidth="30" markerHeight="8">
                    <path d="M -30 0  L -30 8  L 0 0  L -30 -8  Z" fill="black"/>
                </marker>
            </defs>

            <!-- ================================================== -->
            <!-- Draw nodes, including levels                       -->
            <!-- ================================================== -->
            <xsl:apply-templates select="//Node"/>
            <!-- ================================================== -->
            <!-- Draw skip lines for each level                     -->
            <!-- Compute nodes at level, pass into drawing function -->
            <!-- ================================================== -->
            <xsl:for-each select="$allLevels">
                <xsl:variable name="currentLevel" select="."/>
                <xsl:variable name="nodesToLink" select="djb:nodesAtLevel(., $root//Node)"/>
                <xsl:for-each select="$nodesToLink[position() > 1]">
                    <xsl:variable name="beforeCurrentPosition" select="position() - 1"/>
                    <xsl:call-template name="djb:drawArrow">
                        <xsl:with-param name="djb-f:startNode"
                            select="$nodesToLink[$beforeCurrentPosition]"/>
                        <xsl:with-param name="djb-f:endNode" select="$nodesToLink[current()]"/>
                        <xsl:with-param name="djb-f:level" select="$currentLevel"/>
                        <xsl:with-param name="djb-f:boxSpacing" select="$boxSpacing"/>
                        <xsl:with-param name="djb-f:boxSize" select="$boxSize"/>
                        <xsl:with-param name="djb-f:boxCenterOffset" select="$boxCenterOffset"/>
                    </xsl:call-template>
                </xsl:for-each>
            </xsl:for-each>
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
        <xsl:variable name="localLevels">
            <xsl:for-each select="(//node())[not(position() > xs:integer(@level))]">
                <xsl:value-of select="position()"/>
            </xsl:for-each>
        </xsl:variable>

        <xsl:for-each select="$localLevels">
            <xsl:sequence select="djb:drawRectangle($nodeOffset, ., $boxSize, $boxSpacing)"/>
            <xsl:sequence
                select="djb:centerDot($nodeOffset, ., $boxSize, $boxCenterOffset, $boxSpacing, $circleRadius)"
            />
        </xsl:for-each>
    </xsl:template>
    <xsl:template match="Node[@name]">
        <xsl:choose>
            <xsl:when test="@name = 'head'">
                <!-- ============================================== -->
                <!-- Create boxes and labels for head               -->
                <!-- ============================================== -->
                <xsl:for-each select="$allLevels">
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
                <xsl:variable name="xPos" select="$nodeCount + 2"/>
                <xsl:for-each select="$allLevels">
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
