<?xml version = "1.0" encoding = "UTF-8"?>
<xsl:stylesheet version = "1.0" xmlns:xsl = "http://www.w3.org/1999/XSL/Transform">
<xsl:output method="text" />
<xsl:template match = "/">
#### <xsl:value-of select="$step_title" />: <xsl:value-of select="count(//testcase[failure])" /> failures.
<xsl:for-each select="//testcase[failure]">
&lt;details&gt;&lt;summary&gt;&lt;tt&gt;<xsl:value-of select="@name" />&lt;/tt&gt; in &lt;tt&gt;<xsl:value-of select="@classname" />&lt;/tt&gt;&lt;/summary&gt;
    
<xsl:value-of select="failure/@message" />
    
```
<xsl:value-of select="failure" />
```
&lt;/details&gt;
</xsl:for-each>
</xsl:template>
</xsl:stylesheet>
