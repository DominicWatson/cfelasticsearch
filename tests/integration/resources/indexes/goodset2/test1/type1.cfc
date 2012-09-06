<cfcomponent output="false">

	<cffunction name="init" access="public" returntype="any" output="false">
		<cfargument name="returnXDocs" type="numeric" required="true" />

		<cfscript>
			_nDocsToReturn = returnXDocs;
			return this;
		</cfscript>
	</cffunction>

	<cffunction name="get" access="public" returntype="query" output="false">
		<cfscript>
			var qry = QueryNew( 'id,title,category' );
			var i   = 0;

			for( i=1; i lte _nDocsToReturn; i++ ){
				QueryAddRow( qry );
				QuerySetCell( qry, 'id'      , i             );
				QuerySetCell( qry, 'title'   , 'title#i#'    );
				QuerySetCell( qry, 'category', 'category#i#' );
			}

			return qry;
		</cfscript>
	</cffunction>

</cfcomponent>