<?xml version='1.0' encoding='UTF-8'?>
<!-- Xtra validation of ParlaMint affiliations and organizations -->
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:tei="http://www.tei-c.org/ns/1.0"
  xmlns="http://www.tei-c.org/ns/1.0"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xi="http://www.w3.org/2001/XInclude"
  xmlns:mk="http://ufal.mff.cuni.cz/matyas-kopp"
  exclude-result-prefixes="tei xi">

  <xsl:output method="text"/>

  <xsl:template match="tei:affiliation">
    <xsl:variable name="personId" select="./parent::tei:person/@xml:id"/>
    <xsl:variable name="ref" select="@ref"/>
    <xsl:variable name="from" select="@from"/>
    <xsl:variable name="to" select="@to"/>
    <xsl:variable name="ana" select="@ana"/>
    <xsl:variable name="text" select="./text()"/>

    <xsl:if test="$text">
      <xsl:call-template name="affiliation-error">
        <xsl:with-param name="ident">02</xsl:with-param>
        <xsl:with-param name="msg">
          <xsl:text>Contains text value</xsl:text>
        </xsl:with-param>
      </xsl:call-template>
    </xsl:if>

    <xsl:choose>
      <xsl:when test="$ref">
        <xsl:variable name="affWith" select="./ancestor::tei:teiCorpus//*[@xml:id = substring-after($ref,'#')]"/>
        <xsl:choose>
          <xsl:when test="$affWith/local-name()='org'"> <!-- affiliation with organization -->
            <xsl:variable name="orgFrom" select="mk:get_org_from($affWith)"/>
            <xsl:variable name="orgTo" select="mk:get_org_to($affWith)"/>
            <xsl:variable name="affFrom" select="mk:fix_date(mk:get_from(.),'-01-01','T00:00:00')"/>
            <xsl:variable name="affTo" select="mk:fix_date(mk:get_to(.),'-12-31','T23:59:59')"/>

            <xsl:if test="following-sibling::tei:affiliation
                            [@role='member'][not(@from or @to)][@ref = $ref]">
              <xsl:call-template name="error">
                <xsl:with-param name="ident">01</xsl:with-param>
                <xsl:with-param name="msg">
                  <xsl:text>Duplicate party affiliation for </xsl:text>
                  <xsl:value-of select="@ref"/>
                </xsl:with-param>
              </xsl:call-template>
            </xsl:if>

    <!-- WARN ana correspond to organization event - it is not necesary in case of commisions -->
    <!-- test overlapping affiliation with same role and organization -->
    <!-- ministry and government affiliations -->

            <xsl:call-template name="check-in-event">
              <xsl:with-param name="refs"><xsl:value-of select="@ana"/></xsl:with-param>
              <xsl:with-param name="date"><xsl:value-of select="$affFrom"/></xsl:with-param>
            </xsl:call-template>
            <xsl:call-template name="check-in-event">
              <xsl:with-param name="refs"><xsl:value-of select="@ana"/></xsl:with-param>
              <xsl:with-param name="date"><xsl:value-of select="$affTo"/></xsl:with-param>
            </xsl:call-template>

            <!-- test if affiliation correspond to organization existence -->
            <xsl:if test="$orgFrom > $affFrom ">
              <xsl:call-template name="error">
                <xsl:with-param name="ident">08</xsl:with-param>
                <xsl:with-param name="severity">WARN</xsl:with-param>
                <xsl:with-param name="msg">
                  <xsl:text>Affiliate from date (</xsl:text>
                  <xsl:value-of select="$affFrom"/>
                  <xsl:text>) is </xsl:text>
                  <xsl:value-of select="xs:duration(xs:dateTime($orgFrom) - xs:dateTime($affFrom))"/>
                  <xsl:text> before </xsl:text>
                  <xsl:value-of select="$affWith/@xml:id"/>
                  <xsl:text> organization beginning (</xsl:text>
                  <xsl:value-of select="$orgFrom"/>
                  <xsl:text>) </xsl:text>
                </xsl:with-param>
              </xsl:call-template>
            </xsl:if>
            <xsl:if test="affTo > $orgTo ">
              <xsl:call-template name="error">
                <xsl:with-param name="ident">07</xsl:with-param>
                <xsl:with-param name="severity">WARN</xsl:with-param>
                <xsl:with-param name="msg">
                  <xsl:text>Affiliate to date (</xsl:text>
                  <xsl:value-of select="$affTo"/>
                  <xsl:text>) is </xsl:text>
                  <xsl:value-of select="xs:duration(xs:dateTime($affTo) - xs:dateTime($orgTo))"/>
                  <xsl:text>after </xsl:text>
                  <xsl:value-of select="$affWith/@xml:id"/>
                  <xsl:text> organization ending (</xsl:text>
                  <xsl:value-of select="$orgTo"/>
                  <xsl:text>) </xsl:text>
                </xsl:with-param>
              </xsl:call-template>
            </xsl:if>

            <!-- MP affiliation to organizations with roles: parliament,   -->
            <xsl:if test="./@role = 'MP' and not(contains(' parliament ', concat(' ',$affWith/@role,' ')))">
              <xsl:call-template name="error">
                <xsl:with-param name="ident">06</xsl:with-param>
                <xsl:with-param name="msg">
                  <xsl:text>Wrong affiliation role (MP) with </xsl:text>
                  <xsl:value-of select="$affWith/@xml:id"/>
                  <xsl:text> organization</xsl:text>
                </xsl:with-param>
              </xsl:call-template>
            </xsl:if>

          </xsl:when>
          <xsl:when test="not($affWith)"> <!-- ref contain reference inside current corpus file -->
            <xsl:call-template name="error">
              <xsl:with-param name="ident">03</xsl:with-param>
              <xsl:with-param name="msg">
                <xsl:text>Wrong affiliation ref=</xsl:text>
                <xsl:value-of select="@ref"/>
              </xsl:with-param>
            </xsl:call-template>
          </xsl:when>
          <xsl:otherwise> <!-- affiliation is not with organization -->
            <xsl:call-template name="affiliation-error">
              <xsl:with-param name="ident">04</xsl:with-param>
              <xsl:with-param name="msg">
                <xsl:text>Affiliation with </xsl:text>
                <xsl:value-of select="$affWith/local-name()" />
                <xsl:text> element</xsl:text>
              </xsl:with-param>
            </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="affiliation-error">
          <xsl:with-param name="ident">05</xsl:with-param>
          <xsl:with-param name="msg">
            <xsl:text>Missing reference</xsl:text>
          </xsl:with-param>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>

  </xsl:template>

  <xsl:template match="tei:org">
    <xsl:if test="not(@role)">
      <xsl:call-template name="error">
        <xsl:with-param name="ident">09</xsl:with-param>
        <xsl:with-param name="msg">
          <xsl:text>Organisation without role for </xsl:text>
          <xsl:value-of select="."/>
        </xsl:with-param>
      </xsl:call-template>
    </xsl:if>
    <xsl:choose>
      <xsl:when test="@xml:id">
        <!-- organization without affiliation -->
        <xsl:variable name="orgId" select="@xml:id"/>
        <xsl:variable name="affCnt" select="count(./ancestor::tei:teiCorpus//tei:affiliation[@ref = concat('#',$orgId)])"/>

        <xsl:call-template name="error">
          <xsl:with-param name="ident">10</xsl:with-param>
          <xsl:with-param name="severity">INFO</xsl:with-param>
          <xsl:with-param name="msg">
            <xsl:text>Total number of affiliations with </xsl:text>
            <xsl:value-of select="$orgId"/>
            <xsl:text>: </xsl:text>
            <xsl:value-of select="$affCnt"/>
          </xsl:with-param>
        </xsl:call-template>
        <xsl:if test="$affCnt = 0">
          <xsl:call-template name="error">
            <xsl:with-param name="ident">10</xsl:with-param>
            <xsl:with-param name="severity">WARN</xsl:with-param>
            <xsl:with-param name="msg">
              <xsl:text>Organisation without affiliation: #</xsl:text>
              <xsl:value-of select="@xml:id"/>
            </xsl:with-param>
          </xsl:call-template>
        </xsl:if>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="error">
          <xsl:with-param name="ident">11</xsl:with-param>
          <xsl:with-param name="msg">
            <xsl:text>Organisation has not id </xsl:text>
            <xsl:apply-templates select="." mode="serialize"/>
          </xsl:with-param>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>

    <!-- government and parliament has "terms" events -->
    <!-- parliament has ana -->
    <!-- events in organization match its existence ??? -->
  </xsl:template>


  <xsl:template match="tei:particDesc">
    <xsl:apply-templates/>
    <!-- test parliament existence -->
    <xsl:call-template name="org-role-cnt">
      <xsl:with-param name="role">parliament</xsl:with-param>
    </xsl:call-template>
    <!-- test government existence -->
    <xsl:call-template name="org-role-cnt">
      <xsl:with-param name="role">government</xsl:with-param>
    </xsl:call-template>
    <!-- test ministry existence -->
    <xsl:call-template name="org-role-cnt">
      <xsl:with-param name="role">ministry</xsl:with-param>
    </xsl:call-template>
  </xsl:template>



  <xsl:template name="check-in-event">
    <xsl:param name="refs"/>
    <xsl:param name="date"/>
    <xsl:choose>
      <xsl:when test="not($refs) or $refs = ''"/>
      <xsl:when test="not($date)"/>
      <xsl:otherwise>
        <xsl:variable name="newRefs" select="substring-after($refs,' ')"/>
        <xsl:variable name="actRef" select="substring-after(substring-before(concat($refs,' '),' '),'#')"/>
        <xsl:variable name="eventNode" select="./ancestor::tei:teiCorpus//tei:event[@xml:id = $actRef]"/>
        <xsl:if test="$eventNode">
          <xsl:variable name="eventFrom" select="mk:fix_date(mk:get_from($eventNode),'-01-01','T00:00:00')" />
          <xsl:variable name="eventTo" select="mk:fix_date(mk:get_to($eventNode),'-12-31','T23:59:59')" />
          <xsl:if test="$eventFrom > $date or $date > $eventTo">
            <xsl:call-template name="error">
              <xsl:with-param name="ident">13</xsl:with-param>
              <xsl:with-param name="severity">WARN</xsl:with-param>
              <xsl:with-param name="msg">
                <xsl:text>Event #</xsl:text>
                <xsl:value-of select="$actRef"/>
                <xsl:text> (</xsl:text>
                <xsl:value-of select="$eventFrom"/>
                <xsl:text> ...  </xsl:text>
                <xsl:value-of select="$eventTo"/>
                <xsl:text>) corresponding to affiliation don't cover affiliation date </xsl:text>
                <xsl:value-of select="$date"/>
              </xsl:with-param>
            </xsl:call-template>
          </xsl:if>
        </xsl:if>
        <xsl:call-template name="check-in-event">
          <xsl:with-param name="refs"><xsl:value-of select="$newRefs"/></xsl:with-param>
          <xsl:with-param name="date"><xsl:value-of select="$date"/></xsl:with-param>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="org-role-cnt">
    <xsl:param name="min">1</xsl:param>
    <xsl:param name="role"/>
    <xsl:param name="severity">ERROR</xsl:param>
    <xsl:variable name="cnt" select="count(.//tei:org[@role=$role])"/>
    <xsl:call-template name="error">
      <xsl:with-param name="ident">12</xsl:with-param>
      <xsl:with-param name="severity">
        <xsl:choose>
          <xsl:when test="$min > $cnt "><xsl:value-of select="$severity"/></xsl:when>
          <xsl:otherwise>INFO</xsl:otherwise>
        </xsl:choose>
      </xsl:with-param>
      <xsl:with-param name="msg">
        <xsl:text>Total number of organizations with </xsl:text>
        <xsl:value-of select="$role"/>
        <xsl:text> role: </xsl:text>
        <xsl:value-of select="$cnt"/>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>

  <xsl:template match="text()"/>

  <xsl:template name="affiliation-error">
    <xsl:param name="msg">???</xsl:param>
    <xsl:param name="severity">ERROR</xsl:param>
    <xsl:param name="ident">??</xsl:param>
    <xsl:variable name="personId" select="./parent::tei:person/@xml:id"/>
    <xsl:call-template name="error">
      <xsl:with-param name="severity">
        <xsl:value-of select="$severity"/>
      </xsl:with-param>
      <xsl:with-param name="ident">
        <xsl:value-of select="$ident"/>
      </xsl:with-param>
      <xsl:with-param name="msg">
        <xsl:value-of select="$msg"/>
        <xsl:text> in </xsl:text>
        <xsl:value-of select="$personId"/>
        <xsl:text> affiliation </xsl:text>
        <xsl:apply-templates select="." mode="serialize"/>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>


  <xsl:template name="error">
    <xsl:param name="msg">???</xsl:param>
    <xsl:param name="severity">ERROR</xsl:param>
    <xsl:param name="ident">??</xsl:param>
    <xsl:message>
      <xsl:value-of select="$severity"/>
      <xsl:text>[</xsl:text>
      <xsl:value-of select="$ident"/>
      <xsl:text>]&#32;</xsl:text>
      <xsl:value-of select="/tei:*/@xml:id"/>
      <xsl:text>:</xsl:text>
      <xsl:value-of select="./@LINE"/>
      <xsl:text>&#32;</xsl:text>
      <xsl:value-of select="$msg"/>
    </xsl:message>
  </xsl:template>



  <xsl:template match="*" mode="serialize">
    <xsl:text>[</xsl:text>
    <xsl:value-of select="name()"/>
    <xsl:apply-templates select="@*" mode="serialize" />
    <xsl:choose>
        <xsl:when test="node()">
            <xsl:text>]</xsl:text>
            <xsl:apply-templates mode="serialize" />
            <xsl:text>[/</xsl:text>
            <xsl:value-of select="name()"/>
            <xsl:text>]</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text> /]</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="@*[not(name()='LINE')]" mode="serialize">
    <xsl:text> </xsl:text>
    <xsl:value-of select="name()"/>
    <xsl:text>="</xsl:text>
    <xsl:value-of select="."/>
    <xsl:text>"</xsl:text>
</xsl:template>

<xsl:template match="@LINE" mode="serialize"></xsl:template>

<xsl:template match="text()" mode="serialize">
    <xsl:value-of select="."/>
</xsl:template>




  <xsl:function name="mk:get_org_from">
    <xsl:param name="org"/>
    <xsl:choose>
      <xsl:when test="$org//tei:event/@*[contains(' from when ',mk:borders(name()))]"><xsl:value-of select="min($org//tei:event/@*[contains(' from when ',mk:borders(name()))]/xs:dateTime(mk:fix_date(.,'-01-01','T00:00:00')))"/></xsl:when>
      <xsl:otherwise>1500-01-01</xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <xsl:function name="mk:get_org_to">
    <xsl:param name="org"/>
    <xsl:choose>
      <xsl:when test="$org//tei:event/@*[contains(' to when ',mk:borders(name()))]"><xsl:value-of select="min($org//tei:event/@*[contains(' to when ',mk:borders(name()))]/xs:dateTime(mk:fix_date(.,'-12-31','T23:59:59')))"/></xsl:when>
      <xsl:otherwise><xsl:value-of select="$org/ancestor::tei:teiHeader//tei:publicationStmt/tei:date/@when"/></xsl:otherwise>
    </xsl:choose>
  </xsl:function>


  <xsl:function name="mk:get_from">
    <xsl:param name="node"/>
    <xsl:choose>
      <xsl:when test="$node/@from"><xsl:value-of select="$node/@from"/></xsl:when>
      <xsl:when test="$node/@when"><xsl:value-of select="$node/@from"/></xsl:when>
      <xsl:when test="$node and not($node/parent::tei:bibl/parent::tei:sourceDesc/parent::tei:fileDesc)">
        <xsl:value-of select="mk:get_from($node/ancestor::tei:teiHeader//tei:sourceDesc/tei:bibl[1]/tei:date)"/>
      </xsl:when>
      <xsl:otherwise>1500-01-01</xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <xsl:function name="mk:get_to">
    <xsl:param name="node"/>
    <xsl:choose>
      <xsl:when test="$node/@to"><xsl:value-of select="$node/@to"/></xsl:when>
      <xsl:when test="$node/@when"><xsl:value-of select="$node/@to"/></xsl:when>
      <xsl:when test="$node and not($node/parent::tei:bibl/parent::tei:sourceDesc/parent::tei:fileDesc)">
        <xsl:value-of select="mk:get_to($node/ancestor::tei:teiHeader//tei:sourceDesc/tei:bibl[1]/tei:date)"/>
      </xsl:when>
      <xsl:otherwise><xsl:value-of select="$node/ancestor::tei:teiHeader//tei:publicationStmt/tei:date/@when"/></xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  
  <xsl:function name="mk:fix_date">
    <xsl:param name="date"/>
    <xsl:param name="fixDate"/>
    <xsl:param name="fixTime"></xsl:param>
    <xsl:choose>
      <xsl:when test="string-length($date) = 4"><xsl:value-of select="concat($date,$fixDate,$fixTime)"/></xsl:when>
      <xsl:when test="string-length($date) = 10"><xsl:value-of select="concat($date,$fixTime)"/></xsl:when>
      <xsl:otherwise><xsl:value-of select="$date"/></xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <xsl:function name="mk:borders">
    <xsl:param name="str"/>
    <xsl:value-of select="concat(' ',$str,' ')"/>
  </xsl:function>
</xsl:stylesheet>
