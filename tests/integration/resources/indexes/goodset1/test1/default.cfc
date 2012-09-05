<cfcomponent output="false">

	<cffunction name="get" access="public" returntype="query" output="false">
		<cfargument name="id" type="numeric" required="false" />
		<cfscript>
			var idUsedToTestIdBeingPassedCorrectly = 1337;

			if ( StructKeyExists( arguments, 'id' ) and arguments.id eq idUsedToTestIdBeingPassedCorrectly ) {
				return _getSingle();
			} else {
				return _getAll();
			}

		</cfscript>
	</cffunction>

	<cffunction name="_getAll" access="private" returntype="query" output="false">
		<cfscript>
			var ids        = ListToArray( '1,2,3,4,5,6,7')
			var titles     = ListToArray( 'title1,title2,title3,title4,title5,title6,title7')
			var categories = ListToArray( 'category1,category2,category3,category4,category5,category6,category7')
			var qry        = QueryNew('');

			queryAddColumn( qry, 'id'      , 'cf_sql_integer', ids        );
			queryAddColumn( qry, 'title'   , 'cf_sql_varchar', titles     );
			queryAddColumn( qry, 'category', 'cf_sql_varchar', categories );

			return qry;
		</cfscript>
	</cffunction>

	<cffunction name="_getSingle" access="private" returntype="query" output="false">
		<cfscript>
			var ids        = ListToArray( '1337')
			var titles     = ListToArray( 'someTitle')
			var categories = ListToArray( 'someCategory')
			var qry        = QueryNew('');

			queryAddColumn( qry, 'id'      , 'cf_sql_integer', ids        );
			queryAddColumn( qry, 'title'   , 'cf_sql_varchar', titles     );
			queryAddColumn( qry, 'category', 'cf_sql_varchar', categories );

			return qry;
		</cfscript>
	</cffunction>

</cfcomponent>