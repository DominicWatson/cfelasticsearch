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

<!--- private utility --->
	<cffunction name="_call" access="private" returntype="any" output="false">
		<cfargument name="uri" type="string" required="true" />
		<cfargument name="method" type="string" required="true" />

		<cfset var result = "" />

		<cfhttp url="#_getEndpoint()##uri#" method="#arguments.method#" result="result"></cfhttp>

		<cfreturn _processResult( result.filecontent ) />
	</cffunction>

	<cffunction name="_processResult" access="private" returntype="any" output="false">
		<cfargument name="result" type="string" required="true" />

		<cfscript>
			try {
				return DeserializeJson( result );
			} catch ( any e ) {
				throw(  type    = "cfelasticsearch.api.Wrapper"
					  , message = "Could not parse result from Elastic Search Server. See detail for response."
					  , detail  = result
				);
			}
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