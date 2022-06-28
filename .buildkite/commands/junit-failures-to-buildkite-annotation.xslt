<?xml version = "1.0" encoding = "UTF-8"?>
<xsl:stylesheet version = "1.0" xmlns:xsl = "http://www.w3.org/1999/XSL/Transform">
    <xsl:output method="xml" omit-xml-declaration="yes" />
    <xsl:template match = "/">
        <xsl:text>### </xsl:text><xsl:value-of select="$step_title" /><xsl:text>&#xA;&#xA;</xsl:text>
        <xsl:value-of select="count(//testcase[failure])" /><xsl:text> failures.&#xA;</xsl:text>
        <xsl:for-each select="//testcase[failure]">
            <details><summary><tt><xsl:value-of select="@name" /></tt> in <tt><xsl:value-of select="@classname" /></tt></summary>
            <xsl:text>&#xA;</xsl:text>
            <xsl:value-of select="failure/@message" />
            <xsl:text>&#xA;&#xA;```&#xA;</xsl:text>
            <xsl:value-of select="failure" />
            <xsl:text>&#xA;```&#xA;</xsl:text>
            </details><xsl:text>&#xA;</xsl:text>
        </xsl:for-each>
    </xsl:template>
</xsl:stylesheet>
