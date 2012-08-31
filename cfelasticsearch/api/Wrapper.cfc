<cfcomponent output="false">

	<cffunction name="init" access="public" returntype="any" output="false">
		<cfargument name="endpoint" type="string" required="true" default="http://localhost:9200" />

		<cfscript>
			_setEndpoint( endpoint );

			return this;
		</cfscript>
	</cffunction>

	<cffunction name="ping" access="public" returntype="struct" output="false">
		<cfreturn _call( uri="/", method="GET" ) />
	</cffunction>

	<cffunction name="createIndex" access="public" returntype="struct" output="false">
		<cfargument name="indexName" type="string" required="true" />

		<cfreturn _call( uri="/#_safeIndexName( indexName )#", method="PUT" ) />
	</cffunction>

	<cffunction name="deleteIndex" access="public" returntype="struct" output="false">
		<cfargument name="indexName" type="string" required="true" />

		<cfreturn _call( uri="/#_safeIndexName( indexName )#", method="DELETE" ) />
	</cffunction>

	<cffunction name="addDoc" access="public" returntype="struct" output="false">
		<cfargument name="index" type="string" required="true" />
		<cfargument name="type"  type="string" required="true" />
		<cfargument name="id"    type="string" required="false" />
		<cfargument name="doc"   type="struct" required="true" />

		<cfscript>
			var uri    = "/#_safeIndexName( index )#/#Trim( type )#/";
			var method = "POST";

			if ( StructKeyExists( arguments, 'id' ) and Len( Trim( id ) ) ) {
				uri    = uri & "#id#";
				method = "PUT";
			}

			return _call(
				  uri    = uri
				, method = method
				, body   = SerializeJson( doc )
			);
		</cfscript>
	</cffunction>

	<cffunction name="addDocs" access="public" returntype="any" output="false">
		<cfargument name="index"   type="string" required="true" />
		<cfargument name="type"    type="string" required="true" />
		<cfargument name="docs"    type="array"  required="true" />
		<cfargument name="idField" type="string" required="false" default="id" />

		<cfscript>
			var uri  = "/#_safeIndexName( index )#/#Trim( type )#/_bulk";
			var body = CreateObject( "java", "java.lang.StringBuffer" );
			var i    = 0;

			if ( not ArrayLen( docs ) ){
				throw(
					  type    = "cfelasticsearch.addDocs.noDocs"
					, message = "No documents to index."
					, detail  = "An empty array was passed to the addDocs() method."
				);
			}

			for( i=1; i LTE ArrayLen( docs ); i++ ){
				if ( not IsStruct( docs[i] ) ) {
					throw(
						  type    = "cfelasticsearch.addDocs.badDoc"
						, message = "The document at index #i# was not of type struct. All docs passed to the addDocs() method must be of type Struct."
					);
				}

				if ( StructKeyExists( docs[i], idField ) ) {
					body.append( '{"index":{"_id":"#docs[i][idField]#"}}' & chr(10) );
				} else {
					body.append( '{"index":{}}' & chr(10) );
				}
				body.append( SerializeJson( docs[i] ) & chr(10) );
			}

			return _call(
				  uri    = uri
				, method = "PUT"
				, body   = body.toString()
			);
		</cfscript>
	</cffunction>

	<cffunction name="search" access="public" returntype="struct" output="false">
		<cfargument name="index" type="string" required="true"  />
		<cfargument name="q"     type="string" required="true"  />
		<cfargument name="type"  type="string" required="false" />

		<cfscript>
			var uri = "/#_safeIndexName( index )#";

			if ( StructKeyExists( arguments, "type" ) ) {
				uri = uri & "/#Trim( type )#";
			}

			uri = uri & "/_search?q=#q#";

			return _call(
				  uri    = uri
				, method = "GET"
			);
		</cfscript>
	</cffunction>

	<cffunction name="refresh" access="public" returntype="struct" output="false">
		<cfargument name="index" type="string" required="false" />

		<cfscript>
			var uri = "";

			if ( StructKeyExists( arguments, "index" ) ) {
				uri = "/#_safeIndexName( index )#";
			}
			uri = uri & "/_refresh";

			return _call(
				  uri = uri
				, method = "POST"
			);
		</cfscript>
	</cffunction>

<!--- private utility --->
	<cffunction name="_call" access="private" returntype="any" output="false">
		<cfargument name="uri" type="string" required="true" />
		<cfargument name="method" type="string" required="true" />
		<cfargument name="body" type="string" required="false" />

		<cfset var result = "" />

		<cfhttp url="#_getEndpoint()##uri#" method="#arguments.method#" result="result">
			<cfif StructKeyExists( arguments, 'body' )>
				<cfhttpparam type="body" value="#body#" />
			</cfif>
		</cfhttp>

		<cfreturn _processResult( result ) />
	</cffunction>

	<cffunction name="_processResult" access="private" returntype="any" output="false">
		<cfargument name="result" type="struct" required="true" />

		<cfscript>
			var deserialized = "";
			var errorMessage = "";

			try {
				deserialized = DeserializeJson( result.filecontent );
			} catch ( any e ) {
				throw(
					  type    = "cfelasticsearch.api.Wrapper"
					, message = "Could not parse result from Elastic Search Server. See detail for response."
					, detail  = result.filecontent
				);
			}

			if ( left( result.status_code, 1 ) EQ "2" ) {
				return deserialized;
			}

			_throwErrorResult( deserialized, result.status_code );
		</cfscript>
	</cffunction>

	<cffunction name="_throwErrorResult" access="private" returntype="void" output="false">
		<cfargument name="result"     type="any"     required="true" />
		<cfargument name="statusCode" type="numeric" required="true" />

		<cfscript>
			var errorMessage = "An unexpected error occurred";
			var errorType    = "UnknownError";
			var errorDetail  = SerializeJson( result );

			if ( IsStruct( result ) and StructKeyExists( result, "error" ) ) {
				errorType    = ListFirst( result.error, "[" );
				errorMessage = Replace( result.error, errorType, "" );
				if ( Len( Trim( errorMessage ) ) gt 2 ) {
					errorMessage = mid( errorMessage, 2, Len( errorMessage) - 2 );
				}
			}

			throw(
				  type      = "cfelasticsearch." & errorType
				, message   = errorMessage
				, detail    = errorDetail
				, errorCode = statusCode
			);

		</cfscript>
	</cffunction>

	<cffunction name="_safeIndexName" access="private" returntype="string" output="false">
		<cfargument name="indexName" type="string" required="true" />

		<cfreturn Trim( LCase( indexName ) ) />
	</cffunction>

<!--- accessors --->
	<cffunction name="_getEndpoint" access="private" returntype="string" output="false">
		<cfreturn _endpoint>
	</cffunction>
	<cffunction name="_setEndpoint" access="private" returntype="void" output="false">
		<cfargument name="endpoint" type="string" required="true" />
		<cfset _endpoint = arguments.endpoint />
	</cffunction>
</cfcomponent>