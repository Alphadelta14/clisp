<?xml version="1.0">
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:import href="fo/docbook.xsl"/>
<xsl:param name="paper.type" select="'letter'"/>

<xsl:template match="epigraph">
 <fo:block text-align="right" margin-left="50%">
  <xsl:call-template name="anchor"/>
  <xsl:apply-templates select="para|simpara|formalpara|literallayout"/>
  <xsl:if test="attribution">
   <fo:inline>
    <xsl:text>--</xsl:text>
    <xsl:apply-templates select="attribution"/>
   </fo:inline>
  </xsl:if>
 </fo:block>
</xsl:template>

<xsl:template match="comment()">  <!-- pass through comments -->
 <xsl:text>&#10;</xsl:text>
 <xsl:comment><xsl:value-of select="normalize-space(.)"/></xsl:comment>
 <xsl:if test="not(following-sibling::comment())">
  <xsl:text>&#10;</xsl:text></xsl:if>
</xsl:template>

<xsl:template match="isbn" mode="bibliography.mode">
 <fo:inline>
  <xsl:text>ISBN&#160;</xsl:text>
  <xsl:apply-templates mode="bibliography.mode"/>
  <xsl:value-of select="$biblioentry.item.separator"/>
 </fo:inline>
</xsl:template>

<xsl:template match="emphasis[@role = 'plat-dep']">
 <fo:inline>
  <xsl:text>Platform Dependent: </xsl:text>
  <xsl:apply-imports/>
 </fo:inline>
</xsl:template>

<xsl:param name="title.margin.left" select="'1pc'"/>
<xsl:param name="ulink.footnotes" select="1"/>
<xsl:param name="ulink.show" select="1"/>

</xsl:stylesheet>
