<?xml version="1.0" encoding="iso-8859-1"?>
<p:library xmlns:p="http://www.w3.org/ns/xproc" xmlns:c="http://www.w3.org/ns/xproc-step"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:saxon="http://saxon.sf.net/"
  xmlns:exist="http://exist.sourceforge.net/NS/exist" xmlns:wxp="http://www.wordsinboxes.com/xproc"
  xmlns:ex="http://www.wordsinboxes.com/xproc/exist">

  <p:documentation xmlns="http://www.w3.org/1999/xhtml">
    <div>
      <h1>eXist Database Extension Library</h1>
      <h2>Version 0.1</h2>
      <p>The steps defined in this library are implemented using the eXist REST interface.</p>
      <p>Contact: James Sulak</p>
      <p>Public repository:  http://bitbucket.org/jasulak/exist-xproc-library/</p>
    </div>
  </p:documentation>

  <!-- TODO: Make this handle a sequence of documents -->

  <p:declare-step type="ex:store" name="store-def">
    <p:documentation>
      <p><b>Input:</b> A single XML document.</p>
      <p><b>Output:</b> A c:result element following the convention of p:store.</p>
    </p:documentation>

    <p:input port="source" primary="true"/>
    <p:output port="result">
      <p:pipe port="result" step="result"/>
    </p:output>

    <p:option name="uri" required="true"/>
    <p:option name="resource" required="true" />
    <p:option name="user" required="true"/>
    <p:option name="password" required="true"/>
    <p:option name="failonerror" select="'false'"/>

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
      <p:with-option name="attribute-value" select="concat($uri, '/', $resource)"/>
    </p:add-attribute>
    <p:set-attributes match="c:request">
      <p:input port="attributes">
        <p:inline>
          <c:request method="put" auth-method="Basic" send-authorization="true" detailed="true" status-only="true"/>
        </p:inline>
      </p:input>
    </p:set-attributes>

    <wxp:safe-http-request/>

    <wxp:check-status success-status="201">
      <p:with-option name="failonerror" select="$failonerror"/>
    </wxp:check-status>

    <p:identity name="result"/>

  </p:declare-step>


  <!-- TODO: Replace POST request with DELETE request once it works in Calabash. -->

  <p:declare-step type="ex:remove" name="remove-def">
    <p:output port="result" primary="true"/>

    <p:option name="uri" required="true"/>
    <p:option name="collection" select="''"/>
    <p:option name="resource" select="''"/>
    <p:option name="user" required="true"/>
    <p:option name="password" required="true"/>
    <p:option name="failonerror" select="'false'"/>

    <p:variable name="path" select="replace(substring-after($uri, 'rest/'), '/$', '')">
      <p:empty/>
    </p:variable>


    <!-- TODO: Check to make sure that one of collection or resource is defined -->

    <p:identity>
      <p:input port="source">
        <p:inline>
          <c:request method="post" auth-method="Basic" send-authorization="true" detailed="true" username="${user}"
            password="${password}" href="${uri}">
            <c:body content-type="text/xml">
              <query xmlns="http://exist.sourceforge.net/NS/exist" start="1" max="20" cache="no">
                <text>
                  import module namespace xdb="http://exist-db.org/xquery/xmldb";                
                  let $resource := "${resource}"
                  let $collection := "${collection}"                                            
                  let $response := if ($resource != '') 
                                   then xdb:remove("/${path}/", "${resource}")
                                   else xdb:remove("/${path}/${collection}")
                  return $response
                </text>
              </query>
            </c:body>
          </c:request>
        </p:inline>
      </p:input>
    </p:identity>

    <!-- Fill in the needed parameters -->
    <!-- NOTE: Or maybe even a generic construct-request that can take the specific function you want to complete as a parameter -->
    <wxp:resolve-placeholder placeholder="user">
      <p:with-option name="value" select="$user"/>
    </wxp:resolve-placeholder>
    <wxp:resolve-placeholder placeholder="password">
      <p:with-option name="value" select="$password"/>
    </wxp:resolve-placeholder>
    <wxp:resolve-placeholder placeholder="uri">
      <p:with-option name="value" select="$uri"/>
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

    <wxp:safe-http-request/>

    <wxp:check-status success-status="200">
      <p:with-option name="failonerror" select="$failonerror"/>
    </wxp:check-status>

  </p:declare-step>


  <!-- TODO: handle sequence of documents? -->

  <p:declare-step type="ex:xquery" name="xquery-def">
    <p:input port="source" primary="true"/>
    <p:output port="result" primary="true"/>

    <p:option name="uri" required="true"/>
    <p:option name="user" required="true"/>
    <p:option name="password" required="true"/>
    <p:option name="failonerror" select="'false'"/>

    <!-- Change the xproc document namespace to the exist namespace -->
    <p:namespace-rename from="http://www.w3.org/ns/xproc-step" to="http://exist.sourceforge.net/NS/exist" name="rename"/>

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
      <p:with-option name="attribute-value" select="$password" />
    </p:add-attribute>
    <p:add-attribute match="c:request" attribute-name="username">
      <p:with-option name="attribute-value" select="$user" />
    </p:add-attribute>
    <p:add-attribute match="c:request" attribute-name="href">
      <p:with-option name="attribute-value" select="$uri" />
    </p:add-attribute>

    <wxp:safe-http-request/>

  </p:declare-step>


  <p:declare-step type="ex:create" name="create-def">
    <p:output port="result" primary="true"/>

    <p:option name="uri" required="true"/>
    <p:option name="user" required="true"/>
    <p:option name="password" required="true"/>
    <p:option name="failonerror" select="'false'"/>    
    <p:option name="collection" required="true"/>

    <p:variable name="parent-collection" select="replace($uri, '.*(/db.*)$', '$1')">
      <p:empty />      
    </p:variable>

    <p:identity>
      <p:input port="source">
        <p:inline>
          <c:query xmlns="http://exist.sourceforge.net/NS/exist" start="1" max="20" cache="no">
            <c:text>
                  import module namespace xdb="http://exist-db.org/xquery/xmldb";               
                  let $parent-collection := "${parent-collection}"
                  let $collection := "${collection}"                                               
                  let $response := xdb:create-collection($parent-collection, $collection)
                  return $response
            </c:text>
          </c:query>
        </p:inline>
      </p:input>
    </p:identity>

    <wxp:resolve-placeholder placeholder="parent-collection">
      <p:with-option name="value" select="$parent-collection"/>
    </wxp:resolve-placeholder>
    <wxp:resolve-placeholder placeholder="collection">
      <p:with-option name="value" select="$collection"/>
    </wxp:resolve-placeholder>

    <ex:xquery>
      <p:with-option name="user" select="$user"/>
      <p:with-option name="password" select="$password"/>
      <p:with-option name="uri" select="$uri"/>
    </ex:xquery>

  </p:declare-step>


  <p:declare-step type="ex:list" name="list-def">
    <p:output port="result" primary="true"/>

    <p:option name="uri"/>
    <p:option name="user"/>
    <p:option name="password"/>
    <p:option name="failonerror" select="'false'"/>

    <p:option name="reources"/>
    <p:option name="collections"/>
  </p:declare-step>



  <!-- ================================= -->
  <!-- Utility Steps -->
  <!-- ================================= -->

  <!-- Utility step for resolving inline placeholding variables -->
  <p:declare-step type="wxp:resolve-placeholder">
    <p:input port="source" primary="true"/>
    <p:output port="result" primary="true"/>
    <p:option name="placeholder" required="true"/>
    <p:option name="value" required="true"/>

    <p:string-replace match="text() | attribute()">
      <p:with-option name="replace"
        select="concat('replace(., &quot;\$\{', $placeholder, '\}&quot;,&quot;', $value, '&quot;)')"/>
    </p:string-replace>
  </p:declare-step>


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
    <p:option name="failonerror" required="true"/>

    <p:choose name="determine-result">
      <!-- First, check if it worked -->
      <p:when test="/c:response/@status = $success-status">
        <p:identity>
          <p:input port="source">
            <p:inline>
              <c:result>Success</c:result>
            </p:inline>
          </p:input>
        </p:identity>
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
