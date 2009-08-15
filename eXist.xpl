<?xml version="1.0" encoding="iso-8859-1"?>
<p:library xmlns:p="http://www.w3.org/ns/xproc" xmlns:c="http://www.w3.org/ns/xproc-step"
  xmlns:xs="http://www.w3.org/2001/XMLSchema" 
  xmlns:cx="http://xmlcalabash.com/ns/extensions" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:saxon="http://saxon.sf.net/" xmlns:exist="http://exist.sourceforge.net/NS/exist"
  xmlns:wxp="http://www.wordsinboxes.com/xproc" xmlns:ex="http://www.wordsinboxes.com/xproc/exist" >

  <p:documentation xmlns="http://www.w3.org/1999/xhtml">
    <div>
      <h1>eXist Database Extension Library</h1>
      <h2>Version 0.1</h2>
      <p>The steps defined in this library are implemented using the eXist REST interface.</p>
      <p>Contact: James Sulak</p>
      <p>Public repository: http://bitbucket.org/jasulak/exist-xproc-library/</p>      
    </div>
  </p:documentation>


  <p:import href="library-1.0.xpl"/>


  <p:documentation xmlns="http://www.w3.org/1999/xhtml">
    <h3>ex:copy</h3>
    <p>The <code>ex:copy</code> step copies a resource or collection to a new destination.</p>
    <p>It returns a <code>&lt;c:result/></code> containing the absolute URI of the target.</p>
  </p:documentation>
  
  <p:declare-step type="ex:copy">
    <p:output port="result" primary="true"/>
    
    <p:option name="uri"/>
    <p:option name="collection" select="''"/>
    <p:option name="resource" select="''"/>
    <p:option name="target" required="true" />
    <p:option name="user"/>
    <p:option name="password"/>   
    
    <!-- Create a uri without the trailing slash -->
    <p:variable name="clean-uri" select="replace($uri, '(.*)/$', '$1')" >
      <p:empty />
    </p:variable>
    <p:variable name="base-uri" select="replace($uri, '^(.*)/db/?.*$', '$1')">
      <p:empty />
    </p:variable>
    <p:variable name="parent-collection" select="replace($uri, '.*(/db.*)$', '$1')">
      <p:empty/>
    </p:variable>
    
    <p:identity name="initial-request">
      <p:input port="source">
        <p:inline>         
          <c:query xmlns="http://exist.sourceforge.net/NS/exist" start="1" max="20" cache="no">
            <c:text> 
              declare namespace c="http://www.w3.org/ns/xproc-step";
              let $resource := "${resource}"
              let $collection := "${collection}"
              let $login := xmldb:login("xmldb:exist:///db", "${user}", "${password}")              
              let $response := if ($resource != '')
                               then xmldb:copy("${parent-collection}", "${target}", "${resource}")
                               else xmldb:copy("${parent-collection}/${collection}", "${target}")
              return (element c:result { concat(request:get-url(), "${target}/${resource}${collection}") }) 
            </c:text>
          </c:query>
        </p:inline>
      </p:input>
    </p:identity>
    
    
    <!-- Abort step if wrong options specified -->
    <p:choose>
      <p:when test="($collection = '' and $resource = '') or ($collection != '' and $resource != '')">
        <p:error code="invalid-options"/>
      </p:when>
      <p:otherwise>
        <p:identity />
      </p:otherwise>
    </p:choose>
    
    <wxp:resolve-placeholders>
      <p:input port="parameters">
        <p:empty />
      </p:input>
      <p:with-param name="user" select="$user" />
      <p:with-param name="password" select="$password" />
      <p:with-param name="parent-collection" select="$parent-collection" />
      <p:with-param name="target" select="$target" />
      <p:with-param name="resource" select="$resource" />
      <p:with-param name="collection" select="$collection" />
    </wxp:resolve-placeholders>
    
    <cx:message>
      <p:with-option name="message" select="concat($base-uri, $target, '/', $resource)" />
    </cx:message>
    <cx:message>
      <p:with-option name="message" select="$base-uri" />
    </cx:message>
    
    <ex:xquery>
      <p:with-option name="user" select="$user"/>
      <p:with-option name="password" select="$password"/>
      <p:with-option name="uri" select="$base-uri"/>
    </ex:xquery>
    
    <p:filter select="//c:result" />
    
  </p:declare-step>
  
  
  <p:documentation xmlns="http://www.w3.org/1999/xhtml">
    <h3>ex:move</h3>
    <p>The <code>ex:move</code> step move a resource or collection to a new destination.</p>
    <p>It returns a <code>&lt;c:result/></code> containing the absolute URI of the target.</p>
  </p:documentation>
  
  <p:declare-step type="ex:move">
    <p:output port="result" primary="true"/>
    
    <p:option name="uri"/>
    <p:option name="collection" select="''"/>
    <p:option name="resource" select="''"/>
    <p:option name="target" required="true" />
    <p:option name="user"/>
    <p:option name="password"/>   
    
    <!-- Create a uri without the trailing slash -->
    <p:variable name="clean-uri" select="replace($uri, '(.*)/$', '$1')" >
      <p:empty />
    </p:variable>
    <p:variable name="base-uri" select="replace($uri, '^(.*)/db/?.*$', '$1')">
      <p:empty />
    </p:variable>
    <p:variable name="parent-collection" select="replace($uri, '.*(/db.*)$', '$1')">
      <p:empty/>
    </p:variable>
    
    <p:identity name="initial-request">
      <p:input port="source">
        <p:inline>         
          <c:query xmlns="http://exist.sourceforge.net/NS/exist" start="1" max="20" cache="no">
            <c:text> 
              declare namespace c="http://www.w3.org/ns/xproc-step";
              let $resource := "${resource}"
              let $collection := "${collection}"
              let $login := xmldb:login("xmldb:exist:///db", "${user}", "${password}")              
              let $response := if ($resource != '')
              then xmldb:move("${parent-collection}", "${target}", "${resource}")
              else xmldb:move("${parent-collection}/${collection}", "${target}")
              return (element c:result { concat(request:get-url(), "${target}/${resource}${collection}") }) 
            </c:text>
          </c:query>
        </p:inline>
      </p:input>
    </p:identity>
    
    
    <!-- Abort step if wrong options specified -->
    <p:choose>
      <p:when test="($collection = '' and $resource = '') or ($collection != '' and $resource != '')">
        <p:error code="invalid-options"/>
      </p:when>
      <p:otherwise>
        <p:identity />
      </p:otherwise>
    </p:choose>
    
    <wxp:resolve-placeholders>
      <p:input port="parameters">
        <p:empty />
      </p:input>
      <p:with-param name="user" select="$user" />
      <p:with-param name="password" select="$password" />
      <p:with-param name="parent-collection" select="$parent-collection" />
      <p:with-param name="target" select="$target" />
      <p:with-param name="resource" select="$resource" />
      <p:with-param name="collection" select="$collection" />
    </wxp:resolve-placeholders>
    
    <cx:message>
      <p:with-option name="message" select="concat($base-uri, $target, '/', $resource)" />
    </cx:message>
    <cx:message>
      <p:with-option name="message" select="$base-uri" />
    </cx:message>
    
    <ex:xquery>
      <p:with-option name="user" select="$user"/>
      <p:with-option name="password" select="$password"/>
      <p:with-option name="uri" select="$base-uri"/>
    </ex:xquery>
    
    <p:filter select="//c:result" />
    
  </p:declare-step>
  


  <p:documentation xmlns="http://www.w3.org/1999/xhtml">
    <h3>ex:extract</h3>
    <p>The <code>ex:extract</code> step extracts resources from an eXist database.  
       If <code>resource</code> is specified, then it extracts a single resource from
       the collection specified by the <code>uri</code> option.  If <code>resource</code> is not specified,
       then it extracts all the resources contained in the collection specified by <code>uri</code>.
       If <code>subcollections</code> is set to 'true', then it recurses through all the subcollections 
       and extracts those resources as well.</p>
    <p>The step fails if the resource is inaccessible or does not exist.</p>
  </p:documentation>

  <p:declare-step type="ex:extract">
    <p:output port="result" sequence="true"/>

    <p:option name="uri" required="true"/>             <!-- URI of collection -->
    <p:option name="user" select="''"/>                <!-- eXist username -->
    <p:option name="password" select="''"/>            <!-- eXist password -->
    <p:option name="resource" select="''" />           <!-- resource to extract -->
    <p:option name="subcollections" select="'false'"/> <!-- extract subcollections? (boolean) -->
    
    <!-- Create a uri without the trailing slash -->
    <p:variable name="clean-uri" select="replace($uri, '(.*)/$', '$1')" >
      <p:empty />
    </p:variable>
    
    <!-- First, choose between extracting a single file, and looping through an entire collection -->
    <p:choose>
      <p:xpath-context>
        <p:empty />
      </p:xpath-context>
      <p:when test="$resource != ''">
        <wxp:smart-http-get>
          <p:with-option name="uri" select="concat($clean-uri, '/', $resource)" >
            <p:empty />
          </p:with-option>
          <p:with-option name="password" select="$password">
            <p:empty />
          </p:with-option>
          <p:with-option name="user" select="$user">
            <p:empty />
          </p:with-option>
        </wxp:smart-http-get>        
        <p:add-xml-base />          
      </p:when>
      <p:otherwise>
        
        <!-- Use the list step to get all the items we need.  
             Then loop through them and extract. 
         -->
        
        <ex:list>
          <p:with-option name="uri" select="$clean-uri">
            <p:empty/>
          </p:with-option>
          <p:with-option name="collections" select="$subcollections">
            <p:empty/>
          </p:with-option>
          <p:with-option name="user" select="$user">
            <p:empty />
          </p:with-option>
          <p:with-option name="password" select="$password">
            <p:empty />
          </p:with-option>
        </ex:list>
        
        <p:for-each>
          <p:iteration-source select="/c:collection/*"/>
          <p:output port="result" sequence="true"/>
          
          <p:choose>
            <p:when test="c:resource">
              <!-- TODO: remove messages -->
              <cx:message>
                <p:with-option name="message" select="concat('resource: ', $clean-uri, '/', c:resource/@name)"
                />
              </cx:message>
              <ex:extract>
                <p:with-option name="uri" select="$clean-uri"/>
                <p:with-option name="resource" select="c:resource/@name"/>
                <p:with-option name="user" select="$user" />
                <p:with-option name="password" select="$password" />
              </ex:extract>
            </p:when>
            <p:otherwise>
              <cx:message>
                <p:with-option name="message"
                  select="concat('collection: ', $clean-uri, '/', c:collection/@name)"/>
              </cx:message>
              <ex:extract subcollections="true">
                <p:with-option name="uri" select="concat($clean-uri, '/', c:collection/@name)"/>
                <p:with-option name="user" select="$user" />
                <p:with-option name="password" select="$password" />
              </ex:extract>
            </p:otherwise>
          </p:choose>
        </p:for-each>
      </p:otherwise>
    </p:choose>

  </p:declare-step>


  <!-- TODO: Make it conditionally create collections -->
  <!-- TODO: optional authentication? -->

  <p:documentation xmlns="http://www.w3.org/1999/xhtml">
    <h3>ex:store</h3>
    <p>The <code>ex:store</code> step stores the document provided on the input port in an eXist
      database in the location provided by the <code>uri</code> option.</p>
    <p>It returns a <code>&lt;c:result/></code> containing the absolute URI of the stored file.
       The step fails if the resource cannot be stored.</p>
  </p:documentation>

  <p:declare-step type="ex:store" name="store-def">
    <p:input port="source" primary="true" sequence="false"/>
    <p:output port="result"/>                  
    <p:option name="uri" required="true"/>      <!-- URI of collection -->
    <p:option name="resource" required="true"/> <!-- name of new resource -->
    <p:option name="user" select="''"/>         <!-- eXist username -->
    <p:option name="password" select="''"/>     <!-- eXist password -->

    <!-- Create a uri without the trailing slash -->
    <p:variable name="clean-uri" select="replace($uri, '(.*)/$', '$1')" />    

    <p:wrap wrapper="c:body" match="/"/>
    <p:add-attribute attribute-name="content-type" attribute-value="text/xml" match="/c:body"/>

    <p:wrap wrapper="c:request" match="/"/>

    <p:add-attribute attribute-name="username" match="/c:request">
      <p:with-option name="attribute-value" select="$user"/>
    </p:add-attribute>
    <p:add-attribute attribute-name="password" match="/c:request">
      <p:with-option name="attribute-value" select="$password"/>
    </p:add-attribute>
    <p:add-attribute attribute-name="href" match="/c:request">
      <p:with-option name="attribute-value" select="concat($clean-uri, '/', $resource)"/>
    </p:add-attribute>
    <p:set-attributes match="c:request">
      <p:input port="attributes">
        <p:inline>
          <c:request method="put" auth-method="Basic" send-authorization="true" detailed="true"
            status-only="true"/>
        </p:inline>
      </p:input>
    </p:set-attributes>

    <p:http-request/>

    <wxp:check-status success-status="201">
      <p:with-option name="failonerror" select="'true'"/>
      <p:with-option name="return-string" select="concat($clean-uri, '/', $resource)"/>
    </wxp:check-status>

  </p:declare-step>




  <p:documentation xmlns="http://www.w3.org/1999/xhtml">
    <h3>ex:remove</h3>
    <p>The <code>ex:remove</code> step removes a single resource or collection from the collection
      specified in the <code>uri</code> option.</p>
    <p>It returns a <code>&lt;c:result/></code> containing the absolute URI of the deleted file.
       The step fails if the resource does not exist or cannot be deleted. </p>
  </p:documentation>

  <!-- TODO: Replace POST request with DELETE request once it works in Calabash. -->

  <p:declare-step type="ex:remove" name="remove-def">
    <p:output port="result" primary="true"/>
    <p:option name="uri"/>                    <!-- URI of collection -->  
    <p:option name="collection" select="''"/> <!-- name of subcollection to remove -->
    <p:option name="resource" select="''"/>   <!-- name of resource to remove -->
    <p:option name="user"/>                   <!-- eXist password -->
    <p:option name="password"/>               <!-- eXist username -->

    <p:variable name="parent-collection" select="replace($uri, '.*(/db.*)$', '$1')">
      <p:empty/>
    </p:variable>
    
    <!-- Create a uri without the trailing slash -->
    <p:variable name="clean-uri" select="replace($uri, '(.*)/$', '$1')" >
      <p:empty />
    </p:variable>
    <p:variable name="base-uri" select="replace($clean-uri, '^(.*)/db/?.*$', '$1')">
      <p:empty />
    </p:variable>

    <p:identity name="initial-request">
      <p:input port="source">
        <p:inline>         
           <c:query xmlns="http://exist.sourceforge.net/NS/exist" start="1" max="20" cache="no">
             <c:text> 
               declare namespace c="http://www.w3.org/ns/xproc-step";
               let $resource := "${resource}" 
               let $collection := "${collection}" 
               let $login := xmldb:login("xmldb:exist:///db", "${user}", "${password}") 
               let $response := if ($resource != '') 
                                then xmldb:remove("${parent-collection}", "${resource}") 
                                else xmldb:remove("${parent-collection}/${collection}")
               return (element c:result { concat(request:get-url(), "${parent-collection}/${resource}${collection}") } )
             </c:text>
           </c:query>            
        </p:inline>
      </p:input>
    </p:identity>

    <cx:message>
      <p:with-option name="message" select="$parent-collection" />
    </cx:message>


    <!-- Abort step if wrong options specified -->
    <p:choose>
      <p:when test="($collection = '' and $resource = '') or ($collection != '' and $resource != '')">
        <p:error code="invalid-options"/>
      </p:when>
      <p:otherwise>
        <p:identity />
      </p:otherwise>
    </p:choose>

    <wxp:resolve-placeholders>
      <p:input port="parameters">
        <p:empty />
      </p:input>
      <p:with-param name="user" select="$user" />
      <p:with-param name="password" select="$password" />
      <p:with-param name="parent-collection" select="$parent-collection" />
      <p:with-param name="resource" select="$resource" />
      <p:with-param name="collection" select="$collection" />
    </wxp:resolve-placeholders>
    
    <ex:xquery>
      <p:with-option name="user" select="$user"/>
      <p:with-option name="password" select="$password"/>
      <p:with-option name="uri" select="$base-uri"/>
    </ex:xquery>

    <p:filter select="//c:result" />

  </p:declare-step>


  <p:documentation xmlns="http://www.w3.org/1999/xhtml">
    <h3>ex:xquery</h3>
    <p>The <code>ex:xquery</code> step executes an XQuery expression.</p>
    <p>It expects the query to be wrapped in a <code>&lt;c:query></code>. It returns the result
      of the expression in a <code>&lt;c:result></code>.</p>
  </p:documentation>

  <!-- TODO: handle sequence of documents? -->
  <!-- TODO: check result wrapper element -->
  <!-- TODO: Make authentication optional? -->

  <p:declare-step type="ex:xquery" name="xquery-def">
    <p:input port="source" primary="true"/>
    <p:output port="result" primary="true"/>
    <p:option name="uri" required="true"/>      <!-- URI of eXist database -->
    <p:option name="user" required="true"/>     <!-- eXist username -->
    <p:option name="password" required="true"/> <!-- eXist password -->

    <!-- Change the xproc document namespace to the exist namespace -->
    <p:namespace-rename from="http://www.w3.org/ns/xproc-step"
      to="http://exist.sourceforge.net/NS/exist" name="rename"/>

    <!-- Insert actual query -->
    <p:replace match="exist:query">
      <p:input port="source">
        <p:inline>
          <c:request method="post" auth-method="Basic" send-authorization="true" detailed="true">
            <c:body content-type="text/xml">
              <exist:query/>
            </c:body>
          </c:request>
        </p:inline>
      </p:input>
      <p:input port="replacement">
        <p:pipe port="result" step="rename"/>
      </p:input>
    </p:replace>

    <p:add-attribute match="c:request" attribute-name="password">
      <p:with-option name="attribute-value" select="$password"/>
    </p:add-attribute>
    <p:add-attribute match="c:request" attribute-name="username">
      <p:with-option name="attribute-value" select="$user"/>
    </p:add-attribute>
    <p:add-attribute match="c:request" attribute-name="href">
      <p:with-option name="attribute-value" select="$uri"/>
    </p:add-attribute>

    <p:http-request/>

  </p:declare-step>


  <p:documentation xmlns="http://www.w3.org/1999/xhtml">
    <h3>ex:create</h3>
    <p>The <code>ex:create</code> step creates a single empty collection.  The name is specified in the <code>collection option</code>, and its 
      location is specified in the <code>uri</code> option.</p>
    <p>It returns a <code>&lt;c:result/></code> containing the absolute URI of the created collection.  
      The step fails if the collection cannot be created.</p>
  </p:documentation>
  
  <p:declare-step type="ex:create" name="create-def">
    <p:output port="result" primary="true" sequence="true"/>
    
    <p:option name="uri" required="true"/>        <!-- URI of collection -->
    <p:option name="user" select="''"/>           <!-- eXist username -->
    <p:option name="password" select="''"/>       <!-- eXist password -->
    <p:option name="collection" required="true"/> <!-- subcollection to create -->
    
    <p:variable name="parent-collection" select="replace($uri, '.*(/db.*)$', '$1')">
      <p:empty/>
    </p:variable>
    <p:variable name="base-uri" select="replace($uri, '^(.*)/db/?.*$', '$1')">
      <p:empty />
    </p:variable>
    
    <!-- Create a uri without the trailing slash -->
    <p:variable name="clean-uri" select="replace($uri, '(.*)/$', '$1')" >
      <p:empty />
    </p:variable>
    
    <p:identity>
      <p:input port="source">
        <p:inline>
          <c:query xmlns="http://exist.sourceforge.net/NS/exist" start="1" max="20" cache="no">
            <c:text>   
              declare namespace c="http://www.w3.org/ns/xproc-step";
              let $login := xmldb:login("xmldb:exist:///db", "${user}", "${password}") 
              let $response := xmldb:create-collection("${parent-collection}", "${collection}")
              return (element c:result { concat(request:get-url(), $response) })
            </c:text>
          </c:query>
        </p:inline>
      </p:input>
    </p:identity>
    
    
    <wxp:resolve-placeholders>
      <p:input port="parameters">
        <p:empty />
      </p:input>
      <p:with-param name="user" select="$user" />
      <p:with-param name="password" select="$password" />
      <p:with-param name="parent-collection" select="$parent-collection" />
      <p:with-param name="collection" select="$collection" />
    </wxp:resolve-placeholders>
    
    <ex:xquery>
      <p:with-option name="user" select="$user"/>
      <p:with-option name="password" select="$password"/>
      <p:with-option name="uri" select="$base-uri"/>
    </ex:xquery>
    
    <p:filter select="//c:result" />
    
  </p:declare-step>
  


  <p:documentation xmlns="http://www.w3.org/1999/xhtml">
    <h3>ex:list</h3>
    <p>The <code>ex:list</code> step returns a list of the resources and/or collections contained in
      the collection specified in the <code>uri</code> option.</p>
    <p>It's behavior is modeled after <code>&lt;p:directory-list</code>. It returns a
        <code>&lt;c:collection></code> containing a sequence of <code>&lt;c:resource</code>
      and <code>&lt;c:collection</code>s. The step fails if the resource does not exist or cannot be deleted.</p>
  </p:documentation>

  <p:declare-step type="ex:list" name="list-def">
    <p:output port="result" primary="true"/>        
    <p:option name="uri" required="true"/>          <!-- URI of collection -->
    <p:option name="user" select="''" />            <!-- eXist username  -->
    <p:option name="password" select="''" />        <!-- eXist password  -->
    <p:option name="resources" select="'true'"/>    <!-- list resources? (boolean) -->
    <p:option name="collections" select="'true'"/>  <!-- list subcollections? (boolean) -->
    
    <!-- Create a uri without the trailing slash -->
    <p:variable name="clean-uri" select="replace($uri, '(.*)/$', '$1')" >
      <p:empty />
    </p:variable>
    
    <wxp:smart-http-get>
      <p:with-option name="uri" select="$clean-uri" >
        <p:empty />
      </p:with-option>
      <p:with-option name="password" select="$password">
        <p:empty />
      </p:with-option>
      <p:with-option name="user" select="$user">
        <p:empty />
      </p:with-option>
    </wxp:smart-http-get>    

    <p:filter select="//exist:result" />
    <p:unwrap match="exist:result"/>

    <p:rename match="exist:collection" new-name="c:collection"/>
    <p:rename match="exist:resource" new-name="c:resource"/>

     <p:choose>
      <p:when test="$resources = 'false'">
        <p:delete match="c:resource"/>
      </p:when>
      <p:otherwise>
        <p:identity/>
      </p:otherwise>
    </p:choose>

    <p:choose>
      <p:when test="$collections = 'false'">
        <p:delete match="*/c:collection"/>
      </p:when>
      <p:otherwise>
        <p:identity/>
      </p:otherwise>
    </p:choose>

  </p:declare-step>



  <!-- ================================= -->
  <!-- Utility Steps -->
  <!-- ================================= -->


  <p:declare-step type="wxp:resolve-placeholders" name="resolver">
    <p:input port="source" primary="true" sequence="false"/>
    <p:input port="parameters" kind="parameter"/>
    <p:output port="result" />
    
    <p:parameters name="parameters">
      <p:input port="parameters">
        <p:pipe port="parameters" step="resolver"/>
      </p:input>
    </p:parameters>
    
    <p:xslt>
      <p:input port="source">
        <p:pipe port="source" step="resolver"/>
        <p:pipe port="result" step="parameters"/>
      </p:input>
      <p:input port="stylesheet">
        <p:inline>
          <xsl:stylesheet version="2.0">
            
            <xsl:variable name="values" select="collection()[2]/c:param-set/c:param" as="element()*" />
            
            <xsl:template match="text()" name="text" priority="1">
              <xsl:variable name="regex" as="xs:string">
                <xsl:text>\$\{([a-zA-Z0-9-]{1,20})\}</xsl:text>
              </xsl:variable>
              <xsl:analyze-string select="." regex="{$regex}">
                <xsl:matching-substring>
                  <xsl:variable name="placeholder" select="regex-group(1)" />
                  <xsl:value-of select="$values[@name = $placeholder]/@value" />
                </xsl:matching-substring>
                <xsl:non-matching-substring>
                  <xsl:value-of select="." />
                </xsl:non-matching-substring>
              </xsl:analyze-string>
            </xsl:template>
            
            <xsl:template match="@*">
              <xsl:attribute name="{name(.)}">
                <xsl:call-template name="text" />
              </xsl:attribute>
            </xsl:template>
            
            <xsl:template match="node()">
              <xsl:copy>
                <xsl:apply-templates select="@*|node()"/>
              </xsl:copy>
            </xsl:template>
            
          </xsl:stylesheet>
        </p:inline>
      </p:input>
    </p:xslt>
    
  </p:declare-step>


  <!-- Shorthand for a common http-get.  
       Intelligently chooses whether to use authentication, based on 
       the presence or absense of $user and $password.  
       (That may not be actually necessary) -->
  
  <p:declare-step type="wxp:smart-http-get">
    <p:output port="result" sequence="true" />
    
    <p:option name="uri" required="true"/>
    <p:option name="user" select="''"/>
    <p:option name="password" select="''"/>
    
    <p:identity name="initial-request">
      <p:input port="source">
        <p:inline>
          <c:request method="get" detailed="true" />          
        </p:inline>
      </p:input>
    </p:identity>
    
    <p:add-attribute attribute-name="href" match="/c:request">
      <p:with-option name="attribute-value" select="$uri"  />
    </p:add-attribute>
    
    <p:choose>
      <!-- Catch invalid option definitions -->
      <p:when test="($user != '' and $password = '') or ($user = '' and $password != '')">
        <p:error code="invalid-options"/>
      </p:when>      
      <p:when test="$user != '' and $password != ''">
        <p:add-attribute attribute-name="auth-method" match="/c:request" attribute-value="Basic" />
        <p:add-attribute attribute-name="send-authorization" match="/c:request" attribute-value="true" />
        <p:add-attribute attribute-name="username" match="/c:request">
          <p:with-option name="attribute-value" select="$user"/>
        </p:add-attribute>
        <p:add-attribute attribute-name="password" match="/c:request">
          <p:with-option name="attribute-value" select="$password"/>
        </p:add-attribute>    
      </p:when>
      <p:otherwise>
        <p:identity />
      </p:otherwise>
    </p:choose>
    
    <p:http-request />
    
  </p:declare-step>



  <!-- Utility step for resolving inline placeholding variables -->
  <p:declare-step type="wxp:resolve-placeholder">
    <p:input port="source" primary="true"/>
    <p:output port="result" primary="true"/>
    <p:option name="placeholder" required="true"/>
    <p:option name="value" required="true"/>

    <p:string-replace match="text() | attribute()">
      <p:with-option name="replace"
        select="concat('replace(., &quot;\$\{', $placeholder, '\}&quot;,&quot;', $value, '&quot;)')"
      />
    </p:string-replace>
  </p:declare-step>


  <!-- Utility step for checking an http-response status -->
  <p:declare-step type="wxp:check-status" name="check-status">
    <p:input port="source"/>
    <p:output port="result"/>

    <p:option name="success-status" required="true"/>
    <p:option name="return-string" select="'Success'"/>
    <p:option name="failonerror" required="true"/>

    <p:choose name="determine-result">
      <!-- First, check if it worked -->
      <p:when test="/c:response/@status = $success-status">
        <p:string-replace match="c:result/text()">
          <p:with-option name="replace" select="concat('&quot;', $return-string, '&quot;')"/>
          <p:input port="source">
            <p:inline>
              <c:result>REPLACE</c:result>
            </p:inline>
          </p:input>
        </p:string-replace>
      </p:when>
      <!-- If not, then determine if we need to fail loudly or quietly -->
      <p:otherwise>
        <p:choose>
          <p:when test="$failonerror = 'true'">
            <p:error>
              <!-- I think this is correct, but Calabash always reports "No outputs allowed" -->
              <!-- Not really sure how to test this. -->
              <p:with-option name="code" select="concat('R', /c:response/@status)"/>
            </p:error>
          </p:when>
          <p:otherwise>
            <p:replace match="/*">
              <p:input port="replacement">
                <p:inline>
                  <c:result>Fail</c:result>
                </p:inline>
              </p:input>
            </p:replace>
          </p:otherwise>
        </p:choose>
      </p:otherwise>
    </p:choose>
  </p:declare-step>


</p:library>
