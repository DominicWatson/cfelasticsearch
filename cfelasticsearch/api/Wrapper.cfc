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

		<cfreturn _call( uri="/#Trim(indexName)#", method="PUT" ) />
	</cffunction>

	<cffunction name="deleteIndex" access="public" returntype="struct" output="false">
		<cfargument name="indexName" type="string" required="true" />

		<cfreturn _call( uri="/#Trim(indexName)#", method="DELETE" ) />
	</cffunction>

<!--- private utility --->
	<cffunction name="_call" access="private" returntype="any" output="false">
		<cfargument name="uri" type="string" required="true" />
		<cfargument name="method" type="string" required="true" />

		<cfset var result = "" />

		<cfhttp url="#_getEndpoint()##uri#" method="#arguments.method#" result="result"></cfhttp>

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
					, detail  = result
				);
			}

			if ( result.status_code EQ "200" ) {
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

<!--- accessors --->
	<cffunction name="_getEndpoint" access="private" returntype="string" output="false">
		<cfreturn _endpoint>
	</cffunction>
	<cffunction name="_setEndpoint" access="private" returntype="void" output="false">
		<cfargument name="endpoint" type="string" required="true" />
		<cfset _endpoint = arguments.endpoint />
	</cffunction>
</cfcomponent>