<cfcomponent extends="mxunit.framework.TestCase" output="false">

<!--- setup, teardown, etc --->
	<cffunction name="setup" access="public" returntype="void" output="false">
		<cfscript>
			super.setup();
			wrapper = CreateObject( "component", "cfelasticsearch.api.Wrapper" ).init();
			indexName = "";
		</cfscript>
	</cffunction>

	<cffunction name="teardown" access="public" returntype="void" output="false">
		<cfscript>
			super.teardown();
			_teardownTestIndexes();
		</cfscript>
	</cffunction>

<!--- tests --->
	<cffunction name="t01_ping_shouldReturnServerInformation" returntype="void">
		<cfscript>
			var result = wrapper.ping();

			super.assert( result.ok );
			super.assertEquals( 200, result.status );
			super.assert( StructKeyExists( result, "version" ) );
			super.assert( StructKeyExists( result, "tagline" ) );
			super.assert( StructKeyExists( result, "name"    ) );
		</cfscript>
	</cffunction>

	<cffunction name="t02_createIndex_shouldCreateANewIndex" returntype="void">
		<cfscript>
			var indexName = "sometestindex";
			var result    = wrapper.createIndex( indexName );

			super.assert( result.ok );
			super.assert( result.acknowledged );
		</cfscript>
	</cffunction>

	<cffunction name="t03_deleteIndex_shouldDeleteAnIndex" returntype="void">
		<cfscript>
			var indexName = "sometestindexfordeleting";
			var result    = wrapper.createIndex( indexName );

			result = wrapper.deleteIndex( indexName );

			super.assert( result.ok );
			super.assert( result.acknowledged );
		</cfscript>
	</cffunction>

	<cffunction name="t04_createIndex_shouldThrowError_whenIndexAlreadyExists" returntype="void">
		<cfscript>
			var indexName = "sometestindex";
			var result    = wrapper.createIndex( indexName );
			var failed    = false;

			try {
				result = wrapper.createIndex( indexName );
			} catch ( "cfelasticsearch.IndexAlreadyExistsException" e ) {
				failed = true;
				super.assertEquals( "[#indexName#] Already exists", e.message );
				super.assertEquals( 400, e.errorCode );
			}

			super.assert( failed, "The API did not throw an error when attempting to create an index that already exists." );
		</cfscript>
	</cffunction>

<!--- private --->
	<cffunction name="_teardownTestIndexes" access="private" returntype="void" output="false">
		<cftry>
			<cfset wrapper.deleteIndex( indexName ) />
			<cfcatch>
			</cfcatch>
		</cftry>
	</cffunction>
</cfcomponent>