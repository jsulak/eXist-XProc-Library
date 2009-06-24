<?xml version="1.0" encoding="iso-8859-1"?>
<p:library xmlns:p="http://www.w3.org/ns/xproc" xmlns:c="http://www.w3.org/ns/xproc-step"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:saxon="http://saxon.sf.net/"
  xmlns:exist="http://www.wordsinboxes.com/xproc/exist">

  <p:documentation xmlns="http://www.w3.org/1999/xhtml">
    <div>
      <h1>eXist Database Extension Library</h1>
      <h2>Version 0.1</h2>
      <p>The steps defined in this library are implemented using the eXist REST interface.</p>
      <p>Contact: James Sulak</p>
      <p>Public repository:  </p>
    </div>
  </p:documentation>


  <p:declare-step type="exist:store" name="store-def">
    <p:documentation>
      <p><b>Input:</b> A single XML document.</p>
      <p><b>Output:</b> A c:result element following the convention of p:store.</p>
    </p:documentation>

    <p:input port="source" primary="true"/>
    <p:output port="result">
      <p:pipe port="result" step="result"/>
    </p:output>

    <p:option name="uri" required="true"/>
    <p:option name="user" />
    <p:option name="password" />
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
    <p:add-attribute attribute-name="href" match="/c:request">
      <p:with-option name="attribute-value" select="$uri"/>
    </p:add-attribute>
    <p:set-attributes match="c:request">
      <p:input port="attributes">
        <p:inline>
          <c:request method="put" auth-method="Basic" send-authorization="true" detailed="true" status-only="true"/>
        </p:inline>
      </p:input>
    </p:set-attributes>

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

    <p:identity name="response"/>

    <p:choose name="determine-result">
      <p:when test="/c:response/@status = '201'">
        <p:identity>
          <p:input port="source">
            <p:inline>
              <c:result>Success</c:result>
            </p:inline>
          </p:input>
        </p:identity>
      </p:when>
      <p:otherwise>
        <p:choose>
          <p:when test="$failonerror = 'true'">
            <p:output port="result">
              <p:inline>
                <nop/>
              </p:inline>
            </p:output>
            <p:error>
              <!-- This doesn't seem to quite work yet. -->
              <!-- Not really sure how to test this. -->
              <p:with-option name="code" select="concat('R', /c:response/@status)"/>
              <p:input port="source">
                <p:pipe step="response" port="result"/>
              </p:input>
            </p:error>
          </p:when>
          <p:otherwise>
            <p:output port="result">
              <p:inline>
                <c:result>Fail</c:result>
              </p:inline>
            </p:output>
            <p:sink/>
          </p:otherwise>
        </p:choose>
      </p:otherwise>
    </p:choose>

    <p:identity name="result"/>

  </p:declare-step>


  <p:declare-step type="exist:remove" name="remove-def">
    <p:output port="result" primary="true"/>

    <p:option name="uri" />
    <p:option name="user" />
    <p:option name="password" />
    <p:option name="failonerror" select="'false'"/>

    <!-- This doesn't work -->
    <p:http-request>
      <p:input port="source">
        <p:inline>
          <c:request method="delete" auth-method="Basic" send-authorization="true" status-only="true" detailed="true"
            username="admin" password="james" href="http://localhost:8080/exist/webdav/db/test/hello.xml"> </c:request>
        </p:inline>
      </p:input>
    </p:http-request>

  </p:declare-step>


  <p:declare-step type="exist:create" name="create-def">
    <p:output port="result" primary="true"/>

    <p:option name="uri" />
    <p:option name="user" />
    <p:option name="password" />
    <p:option name="failonerror" select="'false'"/>

    <p:option name="collection"/>
  </p:declare-step>


  <p:declare-step type="exist:list" name="list-def">
    <p:output port="result" primary="true"/>

    <p:option name="uri" />
    <p:option name="user" />
    <p:option name="password" />
    <p:option name="failonerror" select="'false'"/>

    <p:option name="reources"/>
    <p:option name="collections"/>
  </p:declare-step>


</p:library>
