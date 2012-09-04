<cfcomponent output="false">

<!--- properties --->
	<cfscript>

	</cfscript>

<!--- constructor --->
	<cffunction name="init" access="public" returntype="any" output="false">
		<cfargument name="endpoint" type="string" required="false" default="http://localhost:9200" />

		<cfscript>
			_setupApiWrapper( endpoint );

			return this;
		</cfscript>
	</cffunction>

<!--- public methods --->

<!--- private helpers --->
	<cffunction name="_setupApiWrapper" access="private" returntype="void" output="false">
		<cfargument name="endpoint" type="string" required="false" default="http://localhost:9200" />

		<cfscript>
			var wrapper = CreateObject( 'component', 'api.Wrapper' ).init( endpoint = endpoint );

			_setApiWrapper( wrapper );
		</cfscript>
	</cffunction>

<!--- accessors --->
	<cffunction name="_getApiWrapper" access="private" returntype="any" output="false">
		<cfreturn _apiWrapper>
	</cffunction>
	<cffunction name="_setApiWrapper" access="private" returntype="void" output="false">
		<cfargument name="apiWrapper" type="any" required="true" />
		<cfset _apiWrapper = arguments.apiWrapper />
	</cffunction>

</cfcomponent>