eXist XProc Extension Library
=============================

*A set of XProc extension steps for interacting with an eXist XML database from a client.*

Using these steps, you can conduct common eXist management tasks from XProc - loading resources, extracting resources, querying data, etc.  They fill much the same role as the [eXist Ant tasks](http://exist-db.org/ant-tasks.html).  They are run from a *client*, and so fill a different (smaller) role than James Fuller's [xprocxq](http://code.google.com/p/xprocxq) project, which is an entire XProc implementation within eXist.

This library should be considered *alpha quality*.  It mostly works, but there are several known bugs (and probably a few design flaws), and I'm not responsible for anything bad that happens to your data.  Option names, etc. are subject to change at any time. 

That said, I hope you find it useful.  Any feedback is welcome.

Download it [here](http://bitbucket.org/jasulak/exist-xproc-library/downloads/). 

## Background

This library is an experiment in writing a non-trivial reusable library in pure XProc.  I avoided all extension steps, so in theory it will work in any XPath-2.0-capable XProc processor, but in practice the only one available is [XML Calabash](http://www.xmlcalabash.com).  This library requires Calabash 0.9.15.

Many steps are implemented by POSTing an XQuery containing eXist database manipulation extension functions.  So most steps requiring authentication *will transmit your username and password as plain text in the request body*.  This of course is a security risk, so be advised. 

I've done my best to mirror the conventions in the [eXist Ant tasks](http://exist-db.org/ant-tasks.html), the [XProc Standard Step Library](http://www.w3.org/TR/xproc/#std-components) and Norm Walsh's [proposed fileutils package](http://markmail.org/message/syhodx5ytz2pjx4g).  Where these conflict, I've gone with the XProc conventions.

## Using the Library

To use the library, import it into your pipeline, using `<p:import/>`:

```
<p:import href="eXist.xpl" />
```

These steps are in the namespace "http://www.wordsinboxes.com/xproc/exist," identified below by the prefix "ex."

Every step takes three common options:

- **href.** An URI specifying the REST location of a database collection.  By default, it will be a address such as "http://localhost:8080/exist/rest/.  For more information about eXist's REST interface, see its [documentation](http://exist-db.org/devguide_rest.html#rest).

- **user.** The user to connect with.  Blank by default.

- **password.** Password for the user.  Blank by default.

## Examples

You can easily extract an entire collection and save it to disk:

```
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc"
    xmlns:ex="http://www.wordsinboxes.com/xproc/exist">
    <p:import href="eXist.xpl"/>
    <p:variable name="exist-base" select="'http://localhost:8080/exist/rest/db'" >
       <p:empty />
    </p:variable>
  
    <ex:extract subcollections="false">
       <p:with-option name="href" select="concat($exist-base, '/books')" >
          <p:empty />
       </p:with-option>
    </ex:extract>

     <p:for-each>        
        <p:store>
           <p:with-option name="href" select="concat('out/', replace(/*/@xml:base, $exist-base, ''))" />
        </p:store>
     </p:for-each>
</p:declare-step>
```

Or load an entire directory into eXist:

```
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc"
    xmlns:c="http://www.w3.org/ns/xproc-step"
    xmlns:ex="http://www.wordsinboxes.com/xproc/exist">
    <p:output port="result" primary="true" sequence="true" />
    <p:import href="eXist.xpl"/>
    <p:directory-list path="."  include-filter=".*\.xml$"/>
    <p:for-each>
        <p:iteration-source select="//c:file"/>
        <p:variable name="name" select="c:file/@name"/>

        <p:load>
            <p:with-option name="href" select="$name"/>
        </p:load>

        <ex:store href="http://localhost:8080/exist/rest/db/book" user="user" password="pass">
            <p:with-option name="resource" select="$name"/>
        </ex:store>
    </p:for-each>
</p:declare-step>
```
  
Or query a collection:

```
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc"
    xmlns:c="http://www.w3.org/ns/xproc-step"
    xmlns:ex="http://www.wordsinboxes.com/xproc/exist">
    <p:output port="result" primary="true" />
    <p:import href="eXist.xpl"/>

    <ex:xquery href="http://localhost:8080/exist/rest/" >
      <p:input port="source">
        <p:inline>
          <c:query>
            <c:text>
               let $plays := collection("/db/shakespeare/plays")/*
               let $people := distinct-values($plays/PERSONAE//PERSONA)
               return element people { 
                         for $person in $people 
                         order by $person
                         return element person { $person }
                      }
            </c:text>
          </c:query>
        </p:inline>
      </p:input>
    </ex:xquery>
</p:declare-step>

```

## Steps

The library contains the following steps:

- ex:store
- ex:remove
- ex:create
- ex:list
- ex:copy
- ex:move
- ex:xquery
- ex:extract

### ex:store

Stores the document provided on its input port in the location provided by the **href** option.

```
<p:declare-step type="ex:store">
    <p:input port="source" primary="true" sequence="false"/>
    <p:output port="result"/>                  
    <p:option name="href" required="true"/>             <!-- URI of collection -->
    <p:option name="user" select="''"/>                 <!-- eXist username -->
    <p:option name="password" select="''"/>             <!-- eXist password -->
    <p:option name="resource" required="true"/>         <!-- name of new resource -->
<p:declare-step>
```

It returns a `<c:result/>` containing the absolute URI of the stored resource.  The step fails if the resource cannot be stored.

For an example of `<c:ex:store/>`, see "Examples," above.

### ex:remove 

Removes a single resource or collection from the collection specified by **href**.

```
<p:declare-step type="ex:remove">
    <p:output port="result" primary="true"/>
    <p:option name="href" required="true"/>             <!-- URI of collection -->  
    <p:option name="user" select="''"/>                 <!-- eXist password -->
    <p:option name="password" select="''"/>             <!-- eXist username -->
    <p:option name="collection" select="''"/>           <!-- name of subcollection to remove -->
    <p:option name="resource" select="''"/>             <!-- name of resource to remove -->
</p:declare-step>
```

If **resource** is specified, it removes that resource from the collection specified by **href**.  If **collection** is specified, then that subcollection is removed.  It is an error to specify both **collection** and **resource**.  The step fails if the resource or collection does not exist or cannot be deleted.

For example, to remove the resource "all_well.xml:"

```
<ex:remove href="http://localhost:8080/exist/rest/db/shakespeare/plays" resource="all_well.xml"
   user="user" password="pass" />
```

which returns:

```
<c:result>http://localhost:8080/exist/rest/db/shakespeare/plays/all_well.xml</c:result>
```

### ex:create 

Creates a single, empty collection.

```
<p:declare-step type="ex:create" name="create-def">
    <p:output port="result" primary="true" sequence="true"/>  
    <p:option name="href" required="true"/>             <!-- URI of collection -->
    <p:option name="user" select="''"/>                 <!-- eXist username -->
    <p:option name="password" select="''"/>             <!-- eXist password -->
    <p:option name="collection" required="true"/>       <!-- subcollection to create -->
</p:declare-step>
```

The new collection's name is specified by **collection** and created as a subcollection of the location provided by **href**.  The new collection inherits the permissions of the parent collection.

For example, to create a new collection "james" in the root collection:

```
<ex:create href="http://localhost:8080/exist/rest/db/" collection="james" />
```


### ex:list 

Returns a list of resources and/or collections contained in the specified collection.

```
<p:declare-step type="ex:list">
    <p:output port="result" primary="true"/>        
    <p:option name="href" required="true"/>             <!-- URI of collection -->
    <p:option name="user" select="''" />                <!-- eXist username  -->
    <p:option name="password" select="''" />            <!-- eXist password  -->
    <p:option name="resources" select="'true'"/>        <!-- list resources? (boolean) -->
    <p:option name="collections" select="'true'"/>      <!-- list subcollections? (boolean) -->
</p:declare-step>
```

It's behavior is modeled after `<p:directory-list/>`.  It returns a `<c:collection/>` containing a sequence of `<c:resource/>` and `<c:collection/s`s.  The step fails if the resource does not exist or cannot be deleted.


### ex:copy 

Copies a resource or collection to a new location.

```
<p:declare-step type="ex:copy">
    <p:output port="result" primary="true"/>    
    <p:option name="href" required="true"/>             <!-- URI of collection -->
    <p:option name="user" select="''"/>                 <!-- eXist user -->
    <p:option name="password" select="''"/>             <!-- eXist password -->
    <p:option name="resource" select="''"/>             <!-- name of resource to copy -->
    <p:option name="collection" select="''"/>           <!-- name of collection to copy -->
    <p:option name="target" required="true" />          <!-- name of target collection -->
</p:declare-step>

```

If **resource** is specified, it copies that resource to the collection specified by **target**.  If **collection** is specified, then it copies that collection.  It is an error to specify both **collection** and **resource**.  The semantics of this step are the same as that of `<ex:move/>`.

For example, to copy the resource "all_well.xml" into the collection "/db/comedies," use:

```
<ex:copy href="http://localhost:8080/exist/rest/db/shakespeare/plays" user="user" password="password"
   resource="all_well.xml" target="/db/comedies"/>

```

which returns:

```
<c:result>http://localhost:8080/exist/rest/db/comedies/all_well.xml</c:result>
```

To copy a collection, use:

```
<ex:copy href="http://localhost:8080/exist/rest/db/shakespeare" user="user" password="password"
   collection="plays" target="/db/literature"/>
```

which returns:

```
<c:result>http://localhost:8080/exist/rest/db/literature</c:result>
```

### ex:move 

Moves a resource or collection to a new location.

```
<p:declare-step type="ex:move">
    <p:output port="result" primary="true"/>    
    <p:option name="href" required="true"/>             <!-- URI of collection -->
    <p:option name="user" select="''"/>                 <!-- eXist user -->
    <p:option name="password" select="''"/>             <!-- eXist password -->   
    <p:option name="resource" select="''"/>             <!-- name of resource to move -->
    <p:option name="collection" select="''"/>           <!-- name of collection to move -->
    <p:option name="target" required="true" />          <!-- name of target collection -->
</p:declare-step>

```

If **resource** is specified, it moves that resource to the collection specified by **target**.  If **collection** is specified, then it moves that collection.  It is an error to specify both **collection** and **resource**.  The semantics of this step are the same as that of `<ex:copy/>`.


For example, to move the resource "hamlet.xml" to the collection "/db/tragedies," use:

```
<ex:move href="http://localhost:8080/exist/rest/db/shakespeare/plays/" user="user"
   password="password" resource="hamlet.xml" target="/db/tragedies"/>
```

which returns:

```
<c:result>http://localhost:8080/exist/rest/db/tragedies/hamlet.xml</c:result>
```


### ex:xquery 

Applies an XQuery query to an eXist database.

```
<p:declare-step type="ex:xquery">
    <p:input port="source" primary="true"/>
    <p:output port="result" primary="true" sequence="true" />
    <p:option name="href" required="true"/>             <!-- URI of eXist database -->
    <p:option name="user" required="true"/>             <!-- eXist username -->
    <p:option name="password" required="true"/>         <!-- eXist password -->
</p:declare-step>
```

The input port must receive a single document containing a single `<c:query/>`.  The query itself is contained in a `<c:text/>`, and any options can be given inside a `<c:parameters/>`.  The semantics are the same as described in the [eXist REST documentation](http://exist-db.org/devguide_rest.html#N10304), except the XProc step namespace is used.  XProc Its text descendants are considered the query.  Any markup that occurs in the query must be escaped.

The step outputs a sequence of documents.  Any elements that appear in the result sequence will be treated as documents with the element as their document element.  (This is the same as `<p:xquery/>`.)

For an example, see "Examples," above.


### ex:extract 

Extracts resources from a collection.

```
<p:declare-step type="ex:extract">
    <p:output port="result" sequence="true"/>
    <p:option name="href" required="true"/>             <!-- URI of collection -->
    <p:option name="user" select="''"/>                 <!-- eXist username -->
    <p:option name="password" select="''"/>             <!-- eXist password -->
    <p:option name="resource" select="''" />            <!-- resource to extract -->
    <p:option name="subcollections" select="'false'"/>  <!-- extract subcollections? (boolean) -->
    <p:option name="indent" select="'false'"/>          <!-- indent output? (boolean) -->

</p:declare-step>
```

If **resource** is specified, then the step extracts that resource from within the collection specified by **href** and outputs it on the **result** port.  If **resource** is not specified, then it extracts all the resources contained in the collection and outputs them as a sequence of documents.  If **subcollections** is set to 'true,' then it recurses through all of the collections subcollections and extracts those resources as well.  The step fails is the resource or collection is inaccessible or does not exist.

If a resource is a non-xml resource (such as a css document), that resource is return surrounded in a `<c:result/>`.  If an XML resource has an xsl processing instruction, `<ex:extract/>` will retrieve the result of that transformation, and not the original resource.  

The root element of every extracted document is given an **xml:base** attribute containing the absolute URI of the original resource.

For example, to extract a single resource:

```
<ex:extract href="http://localhost:8080/exist/rest/db/shakespeare/plays/" resource="all_well.xml"
   user="user" password="password"/>
```

Or, to extract an entire collection:

```
<ex:extract href="http://localhost:8080/exist/rest/db/shakespeare/plays/"
   user="user" password="password"/>
```

## License

This library is released under the [GNU LGPL](http://www.gnu.org/copyleft/lesser.html) license.
