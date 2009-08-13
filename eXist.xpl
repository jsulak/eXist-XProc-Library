<?xml version="1.0" encoding="iso-8859-1"?>
<p:library xmlns:p="http://www.w3.org/ns/xproc" xmlns:c="http://www.w3.org/ns/xproc-step"
  xmlns:cx="http://xmlcalabash.com/ns/extensions" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:saxon="http://saxon.sf.net/" xmlns:exist="http://exist.sourceforge.net/NS/exist"
  xmlns:wxp="http://www.wordsinboxes.com/xproc" xmlns:ex="http://www.wordsinboxes.com/xproc/exist">

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
    <h3>ex:extract</h3>
    <p>The <code>ex:extract</code> step extracts resources from an eXist database.  
       If <code>resource</code> is specified, then it extracts a single resource from
       the collection specified by the <code>uri</code> option.  If <code>resource</code> is not specified,
       then it extracts all the resources contained in the collection specified by <code>uri</code>.
       If <code>subcollections</code> is set to 'true', then it recurses through all the subcollections 
       and extracts those resources as well.</p>
    <p>The step fails if the resource is inaccessible or does not exist.</p>
  </p:documentation>

  <!-- TODO: add xml base attributes -->
  <p:declare-step type="ex:extract">
    <p:output port="result" sequence="true"/>

    <p:option name="uri" required="true"/>
    <p:option name="user" select="''"/>
    <p:option name="password" select="''"/>
    <p:option name="resource" select="''" />
    <p:option name="subcollections" select="'false'"/>
    
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


  <!-- TODO: Make this handle a sequence of documents -->
  <!-- TODO: Make it conditionally create collections -->

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

    <p:option name="uri" required="true"/>
    <p:option name="resource" required="true"/>
    <p:option name="user" required="true"/>
    <p:option name="password" required="true"/>

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
    <!-- TODO:  Error checking to make sure that the slash, etc. actually work out -->
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

    <wxp:safe-http-request/>

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

    <p:option name="uri"/>
    <p:option name="collection" select="''"/>
    <p:option name="resource" select="''"/>
    <p:option name="user"/>
    <p:option name="password"/>    

    <p:variable name="path" select="replace(substring-after($uri, 'rest/'), '/$', '')">
      <p:empty/>
    </p:variable>
    
    <!-- Create a uri without the trailing slash -->
    <p:variable name="clean-uri" select="replace($uri, '(.*)/$', '$1')" >
      <p:empty />
    </p:variable>

    <p:identity name="initial-request">
      <p:input port="source">
        <p:inline>         
           <c:query xmlns="http://exist.sourceforge.net/NS/exist" start="1" max="20" cache="no">
             <c:text> 
               let $resource := "${resource}" 
               let $collection := "${collection}" 
               let $login := xmldb:login("xmldb:exist:///db", "${user}", "${password}") 
               let $response := if ($resource != '' and $collection = '') 
                                   then xmldb:remove("/${path}/", "${resource}") 
                                   else if ($collection != '') 
                                           then xmldb:remove("/${path}/${collection}") 
                                           else () 
               return $response                         
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

    <!-- Fill in the needed parameters -->
    <!-- NOTE: Or maybe even a generic construct-request that can take the specific function you want to complete as a parameter -->
    <wxp:resolve-placeholder placeholder="user">
      <p:with-option name="value" select="$user"/>
    </wxp:resolve-placeholder>
    <wxp:resolve-placeholder placeholder="password">
      <p:with-option name="value" select="$password"/>
    </wxp:resolve-placeholder>  
    <wxp:resolve-placeholder placeholder="path">
      <p:with-option name="value" select="$path"/>
    </wxp:resolve-placeholder>
    <wxp:resolve-placeholder placeholder="resource">
      <p:with-option name="value" select="$resource"/>
    </wxp:resolve-placeholder>
    <wxp:resolve-placeholder placeholder="collection">
      <p:with-option name="value" select="$collection"/>
    </wxp:resolve-placeholder>

    <ex:xquery>
      <p:with-option name="user" select="$user"/>
      <p:with-option name="password" select="$password"/>
      <p:with-option name="uri" select="$clean-uri"/>
    </ex:xquery>

    <wxp:check-status success-status="200">
      <p:with-option name="failonerror" select="'true'"/>
      <p:with-option name="return-string" select="concat($clean-uri, '/', $resource, $collection)"/>
    </wxp:check-status>
    
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

    <p:option name="uri" required="true"/>
    <p:option name="user" required="true"/>
    <p:option name="password" required="true"/>

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

    <wxp:safe-http-request/>

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
    
    <p:option name="uri" required="true"/>
    <p:option name="user" required="true"/>
    <p:option name="password" required="true"/>    
    <p:option name="collection" required="true"/>
    
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
              import module namespace xdb="http://exist-db.org/xquery/xmldb";   
              declare namespace c="http://www.w3.org/ns/xproc-step";
              let $login := xdb:login("xmldb:exist:///db", "${user}", "${password}") 
              let $response := xdb:create-collection("${parent-collection}", "${collection}")
              return (element c:result { concat(request:get-url(), $response) })
            </c:text>
          </c:query>
        </p:inline>
      </p:input>
    </p:identity>
    
    <wxp:resolve-placeholder placeholder="user">
      <p:with-option name="value" select="$user"/>
    </wxp:resolve-placeholder>
    <wxp:resolve-placeholder placeholder="password">
      <p:with-option name="value" select="$password"/>
    </wxp:resolve-placeholder>
    <wxp:resolve-placeholder placeholder="parent-collection">
      <p:with-option name="value" select="$parent-collection"/>
    </wxp:resolve-placeholder>
    <wxp:resolve-placeholder placeholder="collection">
      <p:with-option name="value" select="$collection"/>
    </wxp:resolve-placeholder>
    
    <ex:xquery>
      <p:with-option name="user" select="$user"/>
      <p:with-option name="password" select="$password"/>
      <p:with-option name="uri" select="$base-uri"/>
    </ex:xquery>
    
    <p:choose>
      <p:when test="//c:result = concat($clean-uri, '/', $collection)">
        <p:filter select="//c:result" />
      </p:when>
      <p:otherwise>
        <p:error code="creation-failed" />        
      </p:otherwise>
    </p:choose>
    
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

    <p:option name="uri"/>
    <p:option name="user" select="''" />
    <p:option name="password" select="''" />
    
    <p:option name="resources" select="'true'"/>
    <p:option name="collections" select="'true'"/>
    
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


  <!-- TODO:  Make the failure messages actually valid -->

  <p:declare-step type="wxp:safe-http-request">
    <p:input port="source"/>
    <p:output port="result"/>

    <p:try name="request-block">
      <p:group>
        <p:http-request name="request"/>
      </p:group>
      <p:catch>
        <p:identity>
          <p:input port="source">
            <p:inline>
              <c:result>Fail: No response from server</c:result>
            </p:inline>
          </p:input>
        </p:identity>
      </p:catch>
    </p:try>
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
