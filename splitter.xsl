<!DOCTYPE xsl:stylesheet>
<!--

    Stylesheet to split the result document into pieces, to be included
    into tei2html.xsl.

    We need to split a TEI document into pieces, and in addition, also
    need to be able to consistently generate various types of lists
    of generated files, and cross-references both internal to a part
    and to other parts.

    To accomplish this, we use the "splitter" mode to obtain the parts,
    and hand through an "action" parameter to select the appropriate
    action once we land in the part to be handled. Once arrived at the
    level we wish to split at, we call the appropriate template to
    handle the content.

    The following actions are supported:

    [empty]     Generate the (named) files with the content. [TODO]

    filename    Generate the name of the file that contains the
                (transformed) element represented in $node.

    manifest    Generate a manifest (ODF) for ePub.
               
    spine       Generate the spine (ODF) for ePub.

    navMap      Generate the navMap (NXC) for ePub. [TODO]

-->

<xsl:stylesheet
    xmlns="http://www.w3.org/1999/xhtml"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    version="2.0"
    >


    <xsl:template match="text" mode="splitter">
        <xsl:param name="action"/>
        <xsl:param name="node"/>

        <xsl:apply-templates select="front" mode="splitter">
            <xsl:with-param name="action" select="$action"/>
            <xsl:with-param name="node" select="$node"/>
        </xsl:apply-templates>

        <xsl:apply-templates select="body" mode="splitter">
            <xsl:with-param name="action" select="$action"/>
            <xsl:with-param name="node" select="$node"/>
        </xsl:apply-templates>

        <xsl:apply-templates select="back" mode="splitter">
            <xsl:with-param name="action" select="$action"/>
            <xsl:with-param name="node" select="$node"/>
        </xsl:apply-templates>

    </xsl:template>


    <xsl:template match="body[div0]" mode="splitter">
        <xsl:param name="action"/>
        <xsl:param name="node"/>

        <xsl:apply-templates select="div0" mode="splitter">
            <xsl:with-param name="action" select="$action"/>
            <xsl:with-param name="node" select="$node"/>
        </xsl:apply-templates>
    </xsl:template>


    <xsl:template match="div0 | front | back | body[div1]" mode="splitter">
        <xsl:param name="action"/>
        <xsl:param name="node"/>

        <xsl:for-each-group select="node()" group-adjacent="not(self::div1)">
            <xsl:choose>
                <xsl:when test="current-grouping-key()">
                    <!-- Sequence of non-div1 elements -->
                    <xsl:call-template name="div0fragment">
                        <xsl:with-param name="action" select="$action"/>
                        <xsl:with-param name="node" select="$node"/>
                        <xsl:with-param name="nodes" select="current-group()"/>
                    </xsl:call-template>
                </xsl:when>
                <xsl:otherwise>
                    <!-- Sequence of div1 elements -->
                    <xsl:apply-templates select="current-group()" mode="splitter">
                        <xsl:with-param name="action" select="$action"/>
                        <xsl:with-param name="node" select="$node"/>
                    </xsl:apply-templates>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each-group>
    </xsl:template>


    <xsl:template name="div0fragment">
        <xsl:param name="action"/>
        <xsl:param name="node"/>
        <xsl:param name="nodes"/>

        <xsl:choose>
            <xsl:when test="$action = 'filename'">
                <xsl:call-template name="filename.div0fragment">
                    <xsl:with-param name="node" select="$node"/>
                    <xsl:with-param name="nodes" select="$nodes"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="$action = 'navMap'">
                <xsl:call-template name="navMap.div0fragment">
                    <xsl:with-param name="nodes" select="$nodes"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="$action = 'manifest'">
                <xsl:call-template name="manifest.div0fragment">
                    <xsl:with-param name="nodes" select="$nodes"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="$action = 'spine'">
                <xsl:call-template name="spine.div0fragment">
                    <xsl:with-param name="nodes" select="$nodes"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="content.div0fragment">
                    <xsl:with-param name="nodes" select="$nodes"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>

    </xsl:template>


    <xsl:template match="div1" mode="splitter">
        <xsl:param name="action"/>
        <xsl:param name="node"/>

        <xsl:choose>
            <xsl:when test="$action = 'filename'">
                <xsl:call-template name="filename.div1">
                    <xsl:with-param name="node" select="$node"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="$action = 'navMap'">
                <xsl:call-template name="navMap.div1"/>
            </xsl:when>
            <xsl:when test="$action = 'manifest'">
                <xsl:call-template name="manifest.div1"/>
            </xsl:when>
            <xsl:when test="$action = 'spine'">
                <xsl:call-template name="spine.div1"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="content.div1"/>
            </xsl:otherwise>
        </xsl:choose>

    </xsl:template>


    <!-- filename -->

    <xsl:template name="filename.div0fragment">
        <xsl:param name="node"/>
        <xsl:param name="nodes"/>

        <xsl:param name="position" select="position()"/> <!-- that is, position of context group -->

        <!-- Does any of the nodes contains the node sought after? -->
        <xsl:for-each select="$nodes">
            <xsl:if test="descendant-or-self::*[generate-id() = generate-id($node)]">
                <xsl:call-template name="generate-filename-for">
                    <xsl:with-param name="node" select=".."/>
                    <xsl:with-param name="position" select="$position"/>
                </xsl:call-template>
            </xsl:if>
        </xsl:for-each>

        <!-- Handle the case where we are referring to the div0 element itself (our parent) -->
        <xsl:if test="(generate-id(..) = generate-id($node)) and position() = 1">
            <xsl:call-template name="generate-filename-for">
                <xsl:with-param name="node" select=".."/>
                <xsl:with-param name="position" select="$position"/>
            </xsl:call-template>
        </xsl:if>

    </xsl:template>

    <xsl:template name="filename.div1">
        <xsl:param name="node"/>

        <!-- Does this div1 contain the node sought after? -->
        <xsl:if test="descendant-or-self::*[generate-id() = generate-id($node)]">
            <xsl:call-template name="generate-filename"/>
        </xsl:if>
    </xsl:template>


    <!-- navMap -->

    <xsl:template name="navMap.div0fragment">
        <xsl:param name="nodes"/>
    </xsl:template>

    <xsl:template name="navMap.div1">
    </xsl:template>


    <!-- manifest -->

    <xsl:template name="manifest.div0fragment">
        <xsl:param name="nodes"/>

        <item xmlns="http://www.idpf.org/2007/opf">
            <xsl:variable name="id"><xsl:call-template name="generate-id"/></xsl:variable>
            <xsl:attribute name="id">                
                <xsl:call-template name="generate-id-for">
                    <xsl:with-param name="node" select=".."/>
                    <xsl:with-param name="position" select="position()"/>
                </xsl:call-template>
            </xsl:attribute>
            <xsl:attribute name="href">
                <xsl:call-template name="generate-filename-for">
                    <xsl:with-param name="node" select=".."/>
                    <xsl:with-param name="position" select="position()"/>
                </xsl:call-template>
            </xsl:attribute>
            <xsl:attribute name="media-type">application/xhtml+xml</xsl:attribute>
        </item>
    </xsl:template>

    <xsl:template name="manifest.div1">
        <item xmlns="http://www.idpf.org/2007/opf">
            <xsl:variable name="id"><xsl:call-template name="generate-id"/></xsl:variable>
            <xsl:attribute name="id"><xsl:value-of select="$id"/></xsl:attribute>
            <xsl:attribute name="href"><xsl:call-template name="generate-filename"/></xsl:attribute>
            <xsl:attribute name="media-type">application/xhtml+xml</xsl:attribute>
        </item>
    </xsl:template>


    <!-- spine -->

    <xsl:template name="spine.div0fragment">
        <xsl:param name="nodes"/>

        <itemref xmlns="http://www.idpf.org/2007/opf" linear="yes">
            <xsl:attribute name="idref">
                <xsl:call-template name="generate-id-for">
                    <xsl:with-param name="node" select=".."/>
                    <xsl:with-param name="position" select="position()"/>
                </xsl:call-template>
            </xsl:attribute>
        </itemref>
    </xsl:template>

    <xsl:template name="spine.div1">
        <itemref xmlns="http://www.idpf.org/2007/opf" linear="yes">
            <xsl:attribute name="idref"><xsl:call-template name="generate-id"/></xsl:attribute>
        </itemref>
    </xsl:template>


    <!-- content -->

    <xsl:template name="content.div0fragment">
        <xsl:param name="nodes"/>
        
        <xsl:variable name="filename">
            <xsl:call-template name="generate-filename-for">
                <xsl:with-param name="node" select=".."/>
                <xsl:with-param name="position" select="position()"/>
            </xsl:call-template>
        </xsl:variable>

        <xsl:result-document href="{$path}/{$filename}">
            <xsl:message terminate="no">Info: generated file: <xsl:value-of select="$path"/>/<xsl:value-of select="$filename"/>.</xsl:message>
            <html>
                <xsl:call-template name="generate-html-header"/>

                <body>
                    <xsl:apply-templates select="$nodes"/>
                </body>
            </html>
        </xsl:result-document>

    </xsl:template>


    <xsl:template name="content.div1">

        <xsl:variable name="filename"><xsl:call-template name="generate-filename"/></xsl:variable>

        <xsl:result-document href="{$path}/{$filename}">
            <xsl:message terminate="no">Info: generated file: <xsl:value-of select="$path"/>/<xsl:value-of select="$filename"/>.</xsl:message>
            <html>
                <xsl:call-template name="generate-html-header"/>

                <body>
                    <xsl:apply-templates select="."/>
                </body>
            </html>
        </xsl:result-document>

    </xsl:template>


    <!-- Support functions -->

    <xsl:template name="splitter-generate-filename-for">
        <xsl:param name="node" select="."/>

        <xsl:apply-templates select="/TEI.2/text" mode="splitter">
            <xsl:with-param name="node" select="$node"/>
            <xsl:with-param name="action" select="'filename'"/>
        </xsl:apply-templates>
    </xsl:template>

    <xsl:template name="splitter-generate-url-for">
        <xsl:param name="node" select="."/>

        <xsl:call-template name="splitter-generate-filename-for"><xsl:with-param name="node" select="$node"/></xsl:call-template>#<xsl:call-template name="splitter-generate-id"/>
    </xsl:template>

    <xsl:template name="splitter-generate-id">
        <xsl:choose>
            <xsl:when test="@id"><xsl:value-of select="@id"/></xsl:when>
            <xsl:otherwise>x<xsl:value-of select="generate-id(.)"/><xsl:message terminate="no">Warning: generated ID [x<xsl:value-of select="generate-id(.)"/>] is not stable between runs of XSLT.</xsl:message></xsl:otherwise>
        </xsl:choose>
    </xsl:template>


</xsl:stylesheet>