<!DOCTYPE xsl:stylesheet [

    <!ENTITY nbsp       "&#160;">

]>

<xsl:stylesheet version="3.0"
    xmlns="http://www.w3.org/1999/xhtml"
    xmlns:f="urn:stylesheet-functions"
    xmlns:img="http://www.gutenberg.ph/2006/schemas/imageinfo"
    xmlns:xd="http://www.pnp-software.com/XSLTdoc"
    xmlns:xhtml="http://www.w3.org/1999/xhtml"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    exclude-result-prefixes="f img xd xhtml xs">

    <xd:doc type="stylesheet">
        <xd:short>TEI stylesheet to handle figures.</xd:short>
        <xd:detail>This stylesheet handles TEI figure elements; part of tei2html.xsl.</xd:detail>
        <xd:author>Jeroen Hellingman</xd:author>
        <xd:copyright>2016, Jeroen Hellingman</xd:copyright>
    </xd:doc>


    <xd:doc type="string">
        The imageInfoFile is an XML file that contains information on the dimensions of images.
        This file is generated by an external tool, and the name of this file will be provided
        to the XSLT processor as a parameter.
    </xd:doc>

    <xsl:param name="imageInfoFile" as="xs:string?"/>

    <xsl:variable name="imageInfo" select="document(normalize-space($imageInfoFile), .)" as="node()?"/>

    <xd:doc>
        <xd:short>Determine the file name for an image.</xd:short>
        <xd:detail>
            <p>Derive a file name from the <code>@id</code> attribute, and assume that the extension
            is <code>.jpg</code>, unless an alternative name is given in the <code>@rend</code> attribute, using
            the rendition-ladder notation <code>image()</code>.</p>
        </xd:detail>
        <xd:param name="node" type="node()">The figure or graphic element for which the file name needs to be determined.</xd:param>
        <xd:param name="defaultformat" type="string">The default file-extension of the image file.</xd:param>
    </xd:doc>

    <xsl:function name="f:determine-image-filename" as="xs:string">
        <xsl:param name="node" as="element()"/>
        <xsl:param name="defaultformat" as="xs:string"/>
        <xsl:choose>
            <xsl:when test="f:has-rend-value($node/@rend, 'image')">
                <xsl:value-of select="f:rend-value($node/@rend, 'image')"/>
            </xsl:when>
            <xsl:when test="$node/@url">
                <xsl:value-of select="$node/@url"/>
                <xsl:copy-of select="f:log-warning('Using non-standard attribute url {1} on {2}.', ($node/@url, local-name($node)))"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="'images/' || $node/@id || $defaultformat"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>


    <xd:doc>
        <xd:short>Determine the alternate text for an image.</xd:short>
        <xd:param name="node" type="node()">The figure or graphic element for which the alternate text needs to be determined.</xd:param>
        <xd:param name="default" type="string">The default alternate text.</xd:param>
    </xd:doc>

    <xsl:function name="f:determine-image-alt-text" as="xs:string">
        <xsl:param name="node" as="element()"/>
        <xsl:param name="default" as="xs:string"/>

        <xsl:sequence select="if ($node/figDesc) then $node/figDesc else (if ($node/head) then $node/head else $default)"/>
    </xsl:function>


    <xd:doc>
        <xd:short>Determine whether an image should be included in the output.</xd:short>
    </xd:doc>

    <xsl:function name="f:is-image-included" as="xs:boolean">
        <xsl:param name="url" as="xs:string"/>

        <xsl:variable name="is-image-included" select="f:is-set('images.include') and (f:is-image-present($url) or not(f:is-set('images.requireInfo')))"/>
        <xsl:if test="not($is-image-included)">
            <xsl:copy-of select="f:log-warning('Image {1} will not be included in output file!', ($url))"/>
        </xsl:if>
        <xsl:sequence select="$is-image-included"/>
    </xsl:function>


    <xd:doc>
        <xd:short>Verify an image is present in the imageinfo file.</xd:short>
    </xd:doc>

    <xsl:function name="f:is-image-present" as="xs:boolean">
        <xsl:param name="file" as="xs:string"/>

        <xsl:sequence select="boolean($imageInfo/img:images/img:image[@path=$file])"/>
    </xsl:function>


    <xd:doc>
        <xd:short>Warn if an image linked to is not present in the imageinfo file.</xd:short>
    </xd:doc>

    <xsl:function name="f:warn-missing-linked-image">
        <xsl:param name="url" as="xs:string"/>

        <xsl:if test="not(f:is-image-present($url))">
            <xsl:copy-of select="f:log-warning('Linked image {1} not in image-info file {2}.', ($url, normalize-space($imageInfoFile)))"/>
        </xsl:if>
    </xsl:function>


    <xd:doc>
        <xd:short>Insert an image in the output (step 1).</xd:short>
        <xd:detail>
            <p>Insert all the required output for an inline image in HTML.</p>

            <p>This template generates the elements surrounding the actual image tag in the output.</p>
        </xd:detail>
        <xd:param name="alt" type="string">The text to be placed on the HTML alt attribute.</xd:param>
        <xd:param name="defaultformat" type="string">The default file-extension of the image file.</xd:param>
    </xd:doc>


    <xsl:template name="output-image-with-optional-link">
        <xsl:context-item as="element()" use="required"/>
        <xsl:param name="alt" as="xs:string"/>
        <xsl:param name="filename" as="xs:string"/>

        <!-- Should we link to an external image? -->
        <xsl:choose>
            <xsl:when test="f:has-rend-value(@rend, 'link')">
                <xsl:variable name="url" select="f:rend-value(@rend, 'link')"/>
                <xsl:copy-of select="f:warn-missing-linked-image($url)"/>
                <a>
                    <xsl:choose>
                        <xsl:when test="f:is-epub() and matches($url, '^[^:]+\.(jpg|png|gif|svg)$')">
                            <!-- cannot directly link to image file in ePub, so generate wrapper html and link to that. -->
                            <xsl:call-template name="generate-image-wrapper">
                                <xsl:with-param name="imagefile" select="$url"/>
                            </xsl:call-template>
                            <xsl:attribute name="href"><xsl:value-of select="$basename"/>-<xsl:value-of select="f:generate-id(.)"/>.xhtml</xsl:attribute>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:attribute name="href"><xsl:value-of select="$url"/></xsl:attribute>
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:copy-of select="f:output-image($filename, $alt)"/>
                </a>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy-of select="f:output-image($filename, $alt)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>


    <xd:doc>
        <xd:short>Generate an image tag.</xd:short>
        <xd:detail>
            <p>Generate the actual <code>img</code>-element for the output HTML. This will look-up the height and
            width of the image in the imageinfo, and set the <code>height</code> and <code>width</code> attributes
            if found. The <code>alt</code> attribute is filled if present.</p>
        </xd:detail>
        <xd:param name="file" type="string">The name of the image file.</xd:param>
        <xd:param name="alt" type="string">The text to be placed on the HTML alt attribute.</xd:param>
    </xd:doc>

    <xsl:function name="f:output-image">
        <xsl:param name="file" as="xs:string"/>
        <xsl:param name="alt" as="xs:string"/>

        <xsl:variable name="width" select="substring-before(f:image-width($file), 'px')"/>
        <xsl:variable name="height" select="substring-before(f:image-height($file), 'px')"/>
        <xsl:variable name="fileSize" select="f:image-file-size($file)"/>

        <xsl:if test="$width = ''">
            <xsl:copy-of select="f:log-warning('Image {1} not in image-info file {2}.', ($file, normalize-space($imageInfoFile)))"/>
        </xsl:if>
        <xsl:if test="$width != '' and number($width) > 720">
            <xsl:copy-of select="f:log-warning('Image {1} width more than 720 pixels ({2} px).', ($file, $width))"/>
        </xsl:if>
        <xsl:if test="$height != '' and number($height) > 720">
            <xsl:copy-of select="f:log-warning('Image {1} height more than 720 pixels ({2} px).', ($file, $height))"/>
        </xsl:if>
        <xsl:if test="$fileSize != '' and number($fileSize) > 102400">
            <xsl:copy-of select="f:log-warning('Image {1} file-size more than 100 kilobytes ({2} kB).', ($file, xs:string(ceiling(number($fileSize) div 1024))))"/>
        </xsl:if>
        <xsl:if test="$alt = ''">
            <xsl:copy-of select="f:log-warning('Image {1} has no alt-text defined.', ($file))"/>
        </xsl:if>

        <img src="{$file}">
            <xsl:attribute name="alt"><xsl:value-of select="$alt"/></xsl:attribute>
            <xsl:if test="$width != ''"><xsl:attribute name="width"><xsl:value-of select="$width"/></xsl:attribute></xsl:if>
            <xsl:if test="$height != ''"><xsl:attribute name="height"><xsl:value-of select="$height"/></xsl:attribute></xsl:if>
        </img>
    </xsl:function>


    <xd:doc>
        <xd:short>Generate an image wrapper for ePub.</xd:short>
        <xd:detail>
            <p>Since images may not appear stand-alone in an ePub file, this generates
            an HTML wrapper for (mostly large) images linked to from a smaller image using
            <code>link()</code> in the <code>@rend</code> attribute.</p>
        </xd:detail>
        <xd:param name="imagefile" type="string">The name of the image file (may be left empty).</xd:param>
    </xd:doc>

    <xsl:template name="generate-image-wrapper">
        <xsl:context-item as="element()" use="required"/>
        <xsl:param name="imagefile" as="xs:string"/>

        <xsl:variable name="filename"><xsl:value-of select="$basename"/>-<xsl:value-of select="f:generate-id(.)"/>.xhtml</xsl:variable>
        <xsl:variable name="alt" select="f:determine-image-alt-text(., '')"/>

        <xsl:result-document href="{$path}/{$filename}">
            <xsl:copy-of select="f:log-info('Generated image wrapper file: {1}/{2}.', ($path, $filename))"/>
            <html>
                <xsl:call-template name="generate-html-header"/>
                <body>
                    <div class="figure">
                        <img src="{$imagefile}" alt="{$alt}"/>
                        <xsl:apply-templates/>
                    </div>
                </body>
            </html>
        </xsl:result-document>
    </xsl:template>


    <xd:doc>
        <xd:short>Handle an in-line image.</xd:short>
        <xd:detail>
            <p>Special handling of figures marked as inline using the rend attribute.</p>
        </xd:detail>
    </xd:doc>

    <xsl:template match="figure[f:is-inline(.)]">
        <xsl:copy-of select="f:show-debug-tags(.)"/>

        <xsl:variable name="alt" select="f:determine-image-alt-text(., '')" as="xs:string"/>
        <xsl:variable name="filename" select="f:determine-image-filename(., '.png')" as="xs:string"/>

        <xsl:if test="f:is-image-included($filename)">
            <span>
                <xsl:copy-of select="f:set-class-attribute(.)"/>
                <xsl:call-template name="output-image-with-optional-link">
                    <xsl:with-param name="filename" select="$filename"/>
                    <xsl:with-param name="alt" select="$alt"/>
                </xsl:call-template>
            </span>
        </xsl:if>
    </xsl:template>


    <xd:doc>
        <xd:short>Generate CSS code related to images.</xd:short>
        <xd:detail>
            <p>In the CSS for each image, we register its length and width, to help HTML rendering.</p>
        </xd:detail>
    </xd:doc>

    <xsl:template match="figure" mode="css">
        <xsl:variable name="filename" select="f:determine-image-filename(., '.jpg')" as="xs:string"/>

        <xsl:if test="f:is-image-included($filename)">
            <xsl:call-template name="generate-css-rule"/>
            <xsl:copy-of select="f:output-image-width-css(., $filename)"/>
            <xsl:apply-templates mode="css"/>
        </xsl:if>
    </xsl:template>


    <xsl:template match="figure[f:is-inline(.)]" mode="css">
        <xsl:variable name="filename" select="f:determine-image-filename(., '.png')" as="xs:string"/>

        <xsl:if test="f:is-image-included($filename)">
            <xsl:call-template name="generate-css-rule"/>
            <xsl:copy-of select="f:output-image-width-css(., $filename)"/>
            <xsl:apply-templates mode="css"/>
        </xsl:if>
    </xsl:template>


    <xsl:function name="f:output-image-width-css">
        <xsl:param name="node" as="node()"/>
        <xsl:param name="file" as="xs:string"/>
        <xsl:variable name="width" select="f:image-width($file)" as="xs:string?"/>
        <xsl:variable name="selector" select="f:escape-css-selector(f:generate-id($node) || 'width')"/>

        <xsl:if test="$width != ''"><xsl:text expand-text="yes">
.{$selector} {{
width:{$width};
}}
</xsl:text></xsl:if>
    </xsl:function>


    <xsl:function name="f:image-width" as="xs:string?">
        <xsl:param name="file" as="xs:string"/>
        <xsl:variable name="width" select="$imageInfo/img:images/img:image[@path=$file]/@width" as="xs:string?"/>
        <xsl:sequence select="f:adjust-dimension($width, number(f:get-setting('images.scale')))"/>
    </xsl:function>

    <xsl:function name="f:image-height" as="xs:string?">
        <xsl:param name="file" as="xs:string"/>
        <xsl:variable name="height" select="$imageInfo/img:images/img:image[@path=$file]/@height" as="xs:string?"/>
        <xsl:sequence select="f:adjust-dimension($height, number(f:get-setting('images.scale')))"/>
    </xsl:function>

    <xsl:function name="f:image-file-size" as="xs:string?">
        <xsl:param name="file" as="xs:string"/>
        <xsl:variable name="fileSize" select="$imageInfo/img:images/img:image[@path=$file]/@filesize"/>
        <xsl:sequence select="$fileSize"/>
    </xsl:function>


    <xd:doc>
        <xd:short>Handle a figure element.</xd:short>
        <xd:detail>
            <p>This template handles the figure element. It takes care of positioning figure annotations (title, legend, etc.)
            and in-line loading of the image in HTML.</p>
        </xd:detail>
    </xd:doc>

    <xsl:template match="figure">
        <xsl:copy-of select="f:show-debug-tags(.)"/>

        <xsl:variable name="alt" select="f:determine-image-alt-text(., '')" as="xs:string"/>
        <xsl:variable name="filename" select="f:determine-image-filename(., '.jpg')" as="xs:string"/>

        <xsl:if test="f:is-image-included($filename)">
            <xsl:if test="not(f:rend-value(@rend, 'position') = 'abovehead')">
                <!-- figure will be rendered outside a paragraph context if position is abovehead. -->
                <xsl:call-template name="closepar"/>
            </xsl:if>
            <div class="figure">
                <xsl:copy-of select="f:set-lang-id-attributes(.)"/>

                <xsl:variable name="file" select="f:determine-image-filename(., '.jpg')" as="xs:string"/>
                <xsl:variable name="width" select="f:image-width($file)" as="xs:string?"/>

                <xsl:variable name="class">
                    <xsl:text>figure </xsl:text>
                    <xsl:if test="f:rend-value(@rend, 'float') = 'left'">floatLeft </xsl:if>
                    <xsl:if test="f:rend-value(@rend, 'float') = 'right'">floatRight </xsl:if>

                    <!-- Add the class that sets the width, if the width is known. -->
                    <xsl:if test="$width != ''"><xsl:value-of select="f:generate-id(.)"/><xsl:text>width</xsl:text></xsl:if>
                </xsl:variable>
                <xsl:copy-of select="f:set-class-attribute-with(., $class)"/>

                <xsl:call-template name="figure-head-top"/>
                <xsl:call-template name="figure-annotations-top"/>

                <xsl:call-template name="output-image-with-optional-link">
                    <xsl:with-param name="filename" select="$filename"/>
                    <xsl:with-param name="alt" select="$alt"/>
                </xsl:call-template>

                <xsl:call-template name="figure-annotations-bottom"/>
                <xsl:apply-templates/>
            </div>
            <xsl:if test="not(f:rend-value(@rend, 'position') = 'abovehead')">
                <xsl:call-template name="reopenpar"/>
            </xsl:if>
        </xsl:if>
    </xsl:template>


    <xd:doc>
        <xd:short>Handle a figure head that should be placed above the figure.</xd:short>
    </xd:doc>

    <xsl:template name="figure-head-top">
        <xsl:context-item as="element()" use="required"/>

        <xsl:if test="head[f:position-annotation(@rend) = 'figTop']">
            <xsl:apply-templates select="head[f:position-annotation(@rend) = 'figTop']" mode="figAnnotation"/>
        </xsl:if>
    </xsl:template>


    <xd:doc>
        <xd:short>Handle figure annotations that should be placed directly above the figure.</xd:short>
    </xd:doc>

    <xsl:template name="figure-annotations-top">
        <xsl:context-item as="element()" use="required"/>

        <xsl:if test="p[f:has-top-position-annotation(@rend)]">

            <xsl:variable name="file" select="f:determine-image-filename(., '.jpg')" as="xs:string"/>
            <xsl:variable name="width" select="f:image-width($file)" as="xs:string?"/>

            <div>
                <xsl:attribute name="class">
                    <xsl:text>figAnnotation </xsl:text>
                    <xsl:if test="$width != ''"><xsl:value-of select="f:generate-id(.)"/><xsl:text>width</xsl:text></xsl:if>
                </xsl:attribute>

                <xsl:if test="p[f:position-annotation(@rend) = 'figTopLeft']">
                    <span class="figTopLeft"><xsl:apply-templates select="p[@type='figTopLeft' or f:rend-value(@rend, 'position') = 'figTopLeft']" mode="figAnnotation"/></span>
                </xsl:if>
                <xsl:if test="p[f:position-annotation(@rend) = 'figTop']">
                    <span class="figTop"><xsl:apply-templates select="p[@type='figTop' or f:rend-value(@rend, 'position') = 'figTop']" mode="figAnnotation"/></span>
                </xsl:if>
                <xsl:if test="not(p[f:position-annotation(@rend) = 'figTop'])">
                    <span class="figTop"><xsl:text>&nbsp;</xsl:text></span>
                </xsl:if>
                <xsl:if test="p[f:position-annotation(@rend) = 'figTopRight']">
                    <span class="figTopRight"><xsl:apply-templates select="p[@type='figTopRight' or f:rend-value(@rend, 'position') = 'figTopRight']" mode="figAnnotation"/></span>
                </xsl:if>
            </div>
        </xsl:if>
    </xsl:template>


    <xd:doc>
        <xd:short>Handle figure annotations that should be placed directly below the figure.</xd:short>
    </xd:doc>

    <xsl:template name="figure-annotations-bottom">
        <xsl:context-item as="element()" use="required"/>

        <xsl:if test="p[f:has-bottom-position-annotation(@rend)]">

            <xsl:variable name="file" select="f:determine-image-filename(., '.jpg')" as="xs:string"/>
            <xsl:variable name="width" select="f:image-width($file)" as="xs:string?"/>

            <div>
                <xsl:attribute name="class">
                    <xsl:text>figAnnotation </xsl:text>
                    <xsl:if test="$width != ''"><xsl:value-of select="f:generate-id(.)"/><xsl:text>width</xsl:text></xsl:if>
                </xsl:attribute>

                <xsl:if test="p[f:position-annotation(@rend) = 'figBottomLeft']">
                    <span class="figBottomLeft"><xsl:apply-templates select="p[@type='figBottomLeft' or f:rend-value(@rend, 'position') = 'figBottomLeft']" mode="figAnnotation"/></span>
                </xsl:if>
                <xsl:if test="p[f:position-annotation(@rend) = 'figBottom']">
                    <span class="figBottom"><xsl:apply-templates select="p[@type='figBottom' or f:rend-value(@rend, 'position') = 'figBottom']" mode="figAnnotation"/></span>
                </xsl:if>
                <xsl:if test="not(p[f:position-annotation(@rend) = 'figBottom'])">
                    <span class="figTop"><xsl:text>&nbsp;</xsl:text></span>
                </xsl:if>
                <xsl:if test="p[f:position-annotation(@rend) = 'figBottomRight']">
                    <span class="figBottomRight"><xsl:apply-templates select="p[@type='figBottomRight' or f:rend-value(@rend, 'position') = 'figBottomRight']" mode="figAnnotation"/></span>
                </xsl:if>
            </div>
        </xsl:if>
    </xsl:template>


    <xsl:function name="f:has-position-annotation" as="xs:boolean">
        <xsl:param name="rend" as="xs:string?"/>
        <xsl:sequence select="f:position-annotation($rend) != ''"/>
    </xsl:function>

    <xsl:function name="f:has-top-position-annotation" as="xs:boolean">
        <xsl:param name="rend" as="xs:string?"/>
        <xsl:sequence select="f:top-position-annotation($rend) != ''"/>
    </xsl:function>

    <xsl:function name="f:has-bottom-position-annotation" as="xs:boolean">
        <xsl:param name="rend" as="xs:string?"/>
        <xsl:sequence select="f:bottom-position-annotation($rend) != ''"/>
    </xsl:function>

    <xsl:function name="f:position-annotation" as="xs:string">
        <xsl:param name="rend" as="xs:string?"/>
        <xsl:variable name="position" select="f:rend-value($rend, 'position')"/>
        <xsl:value-of select="if ($position = ('figTopLeft', 'figTop', 'figTopRight', 'figBottomLeft', 'figBottom', 'figBottomRight')) then $position else ''"/>
    </xsl:function>

    <xsl:function name="f:top-position-annotation" as="xs:string">
        <xsl:param name="rend" as="xs:string?"/>
        <xsl:variable name="position" select="f:rend-value($rend, 'position')"/>
        <xsl:value-of select="if ($position = ('figTopLeft', 'figTop', 'figTopRight')) then $position else ''"/>
    </xsl:function>

    <xsl:function name="f:bottom-position-annotation" as="xs:string">
        <xsl:param name="rend" as="xs:string?"/>
        <xsl:variable name="position" select="f:rend-value($rend, 'position')"/>
        <xsl:value-of select="if ($position = ('figBottomLeft', 'figBottom', 'figBottomRight')) then $position else ''"/>
    </xsl:function>

    <xsl:template match="figure/head[not(f:has-position-annotation(@rend))]">
        <p class="figureHead"><xsl:apply-templates/></p>
    </xsl:template>


    <xd:doc>
        <xd:short>Figure heads that should go above are handled elsewhere.</xd:short>
    </xd:doc>

    <xsl:template match="figure/head[f:has-position-annotation(@rend)]"/>


    <xd:doc>
        <xd:short>Paragraphs that are placed around a picture with an explicit position are handled elsewhere.</xd:short>
    </xd:doc>

    <xsl:template match="p[f:has-position-annotation(@rend)]"/>


    <xsl:template match="figure/head[f:has-position-annotation(@rend)]" mode="figAnnotation">
        <p class="figureHead"><xsl:apply-templates/></p>
    </xsl:template>


    <xsl:template match="p[f:has-position-annotation(@rend)]" mode="figAnnotation">
        <xsl:apply-templates/>
    </xsl:template>


    <xd:doc>
        <xd:short>The figDesc element is not rendered (but used as an attribute value).</xd:short>
    </xd:doc>

    <xsl:template match="figDesc"/>


    <xd:doc>
        <xd:short>Handle a TEI P5 graphic element. (UNDER DEVELOPMENT)</xd:short>
        <xd:detail>
            <p>The TEI P5 specification uses an alternative model for including figures; allowing more
            than one graphic element to be encoded in a figure.</p>

            <p>To co-exist with the TEI P3 specification, the code only assumes the P5 model when a
            figure element contains a graphic element.</p>
        </xd:detail>
    </xd:doc>


    <xsl:template match="figure[figure]">
        <div>
            <xsl:copy-of select="f:set-class-attribute-with(., 'compositeFigure')"/>
            <xsl:copy-of select="f:set-lang-id-attributes(.)"/>
            <xsl:apply-templates/>
        </div>
    </xsl:template>


    <xsl:template match="figure[graphic]">
        <div>
            <xsl:copy-of select="f:set-class-attribute-with(., 'compositeFigure')"/>
            <xsl:copy-of select="f:set-lang-id-attributes(.)"/>
            <xsl:variable name="class">
                <xsl:text>figure </xsl:text>
                <xsl:variable name="widestImage" select="f:widest-image(graphic/@url)"/>
                <xsl:if test="f:image-width($widestImage) != ''">
                    <xsl:value-of select="f:generate-id(graphic[@url = $widestImage][1])"/><xsl:text>width</xsl:text>
                </xsl:if>
            </xsl:variable>
            <xsl:copy-of select="f:set-class-attribute-with(., $class)"/>
            <xsl:apply-templates/>
        </div>
    </xsl:template>


    <xsl:function name="f:widest-image" as="xs:string?">
        <xsl:param name="files" as="xs:string*"/>
        <xsl:variable name="maxWidth" select="f:max-width($imageInfo/img:images/img:image[@path=$files]/@width)" as="xs:string?"/>
        <xsl:value-of select="$imageInfo/img:images/img:image[@path=$files and @width=$maxWidth][1]/@path"/>
    </xsl:function>


    <xsl:function name="f:max-width" as="xs:string">
        <xsl:param name="widths" as="xs:string*"/>
        <xsl:value-of select="max(for $width in $widths return translate($width, 'px', '')) || 'px'"/>
     </xsl:function>


    <xsl:template match="graphic">
        <!-- handle both P3 @url and P5 @target convention -->
        <xsl:variable name="url" select="if (@url) then @url else @target"/>
        
        <xsl:if test="f:is-image-included($url)">
            <xsl:copy-of select="f:output-image($url, if (../figDesc) then ../figDesc else '')"/>
        </xsl:if>
    </xsl:template>


    <xsl:template match="figure[figure]" mode="css">
        <!-- outer figure typically has no image attached to it -->
        <xsl:if test="@rend">
            <xsl:call-template name="generate-css-rule"/>
        </xsl:if>
        <xsl:apply-templates mode="css"/>
    </xsl:template>


    <xsl:template match="graphic" mode="css">
        <xsl:variable name="url" select="if (@url) then @url else @target"/>
        <xsl:if test="f:is-image-included($url)">
            <xsl:copy-of select="f:output-image-width-css(., $url)"/>
        </xsl:if>
    </xsl:template>


    <xsl:function name="f:count-graphics" as="xs:integer">
        <xsl:param name="node" as="node()"/>

        <xsl:sequence select="count($node//graphic) - count($node//note[@place='foot' or not(@place)]//graphic)"/>
    </xsl:function>


    <xsl:function name="f:contains-figure" as="xs:boolean">
        <xsl:param name="node" as="node()"/>
        <!-- $node contains a figure element (either directly or within some other element, but excluding
             elements that get lifted out of the context of this node (for example: footnotes) -->
        <xsl:sequence select="count($node//figure) - count($node//note[not(@place) or @place='foot']//figure) > 0"/>
    </xsl:function>



</xsl:stylesheet>
