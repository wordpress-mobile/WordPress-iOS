<?xml version = "1.0" encoding = "UTF-8"?>
<xsl:stylesheet version = "1.0" xmlns:xsl = "http://www.w3.org/1999/XSL/Transform">
    <xsl:output omit-xml-declaration="yes" />
    <xsl:template match = "/">
        <xsl:for-each select="//testcase[failure]">
            <table><tr>
                <td><xsl:value-of select="@classname" /></td>
                <td><xsl:value-of select="@name" /></td>
            </tr><tr>
                <td colspan="2"><xsl:value-of select="failure/@message" /></td>
            </tr></table>
        </xsl:for-each>
    </xsl:template>
</xsl:stylesheet>
