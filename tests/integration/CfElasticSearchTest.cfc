<cfcomponent extends="mxunit.framework.TestCase" output="false">

<!--- setup, teardown, etc --->
	<cffunction name="beforeTests" access="public" returntype="void" output="false">
		<cfscript>
			_checkRunningInstanceOfES();
		</cfscript>
	</cffunction>

	<cffunction name="setup" access="public" returntype="void" output="false">
		<cfscript>
			super.setup();
			cfelasticsearch = CreateObject( "component", "cfelasticsearch.CfElasticSearch" );
		</cfscript>
	</cffunction>

	<cffunction name="teardown" access="public" returntype="void" output="false">
		<cfscript>
			super.teardown();
		</cfscript>
	</cffunction>

<!--- tests --->
	<cffunction name="t01_init_shouldReturnSelf" returntype="void">
		<cfscript>
			var cfes = cfelasticsearch.init(
				indexFolders = '/tests/integration/resources/indexes/goodset1'
			);

			super.assertEquals( cfes, cfelasticsearch );
		</cfscript>
	</cffunction>

	<cffunction name="t02_index_shouldIndexProvidedIndexAndType" returntype="void">
		<cfscript>
			var nDocsIndexed         = "";
			var expectedNDocsIndexed = 7;

			cfelasticsearch = cfelasticsearch.init(
				indexFolders = '/tests/integration/resources/indexes/goodset1'
			);

			nDocsIndexed = cfelasticsearch.index(
				  index = "test1"
				, type  = "default"
			);

			super.assertEquals( expectedNDocsIndexed, nDocsIndexed );
		</cfscript>
	</cffunction>

	<cffunction name="t03_index_shouldThrowError_whenIndexDoesNotExist" returntype="void">
		<cfscript>
			var failed = false;

			cfelasticsearch = cfelasticsearch.init(
				indexFolders = '/tests/integration/resources/indexes/goodset1'
			);

			try {
				cfelasticsearch.index( index="IdoNotExist", type="someType" );
			} catch ( "cfelasticsearch.index.notfound" e ) {
				failed = true;
			} catch ( any e ) {}


			super.assert( failed, "CfElasticSearch did not throw an appropriate error when an index was not found." );
		</cfscript>
	</cffunction>

	<cffunction name="t04_index_shouldThrowError_whenTypeDoesNotExist" returntype="void">
		<cfscript>
			var failed = false;

			cfelasticsearch = cfelasticsearch.init(
				indexFolders = '/tests/integration/resources/indexes/goodset1'
			);

			try {
				cfelasticsearch.index( index="test1", type="typeThatDoesNotExist" );
			} catch ( "cfelasticsearch.index.type.notfound" e ) {
				failed = true;
			} catch ( any e ) {}


			super.assert( failed, "CfElasticSearch did not throw an appropriate error when an index type was not found." );

		</cfscript>
	</cffunction>

<!--- private helpers --->
	<cffunction name="_checkRunningInstanceOfES" access="private" returntype="void" output="false">
		<cftry>
			<cfhttp url="http://localhost:9200" throwonerror="true" timeout="10" />
			<cfcatch>
				<cfthrow type="cfelasticsearch.testsuite" message="The elastic search engine could not be reached. Please ensure that an instance of elasticsearch is running on localhost at port 9200. Please note, while the test suite makes every effort to clean up after itself, you should not use a working elastic search instance to run these tests against." />
			</cfcatch>
		</cftry>
	</cffunction>
</cfcomponent>