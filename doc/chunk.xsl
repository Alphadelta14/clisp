<!-- CLISP Implementation Notes multi-piece driver -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:import href="/usr/share/docbook-xsl/xhtml/chunk.xsl"/>
<xsl:import href="common.xsl"/>
<xsl:param name="generate.legalnotice.link" select="1"/>
<!-- this must be the same as the ID of the top-level BOOK element -->
<xsl:param name="root.filename" select="'impnotes-top'"/>
<xsl:param name="chunk.first.sections" select="1"/>
</xsl:stylesheet>
