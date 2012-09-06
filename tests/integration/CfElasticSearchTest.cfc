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
			wrapper         = CreateObject( "component", "cfelasticsearch.api.Wrapper" ).init();
		</cfscript>
	</cffunction>

	<cffunction name="teardown" access="public" returntype="void" output="false">
		<cfscript>
			super.teardown();
			_teardownTestIndexes();
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

	<cffunction name="t05_index_shouldIndexAllTypes_whenNoTypePassed" returntype="void">
		<cfscript>
			var nDocsIndexed         = "";
			var expectedNDocsIndexed = 21;

			cfelasticsearch = cfelasticsearch.init(
				indexFolders = '/tests/integration/resources/indexes/goodset1'
			);

			nDocsIndexed = cfelasticsearch.index(
				  index = "test1"
			);

			super.assertEquals( expectedNDocsIndexed, nDocsIndexed );
		</cfscript>
	</cffunction>

	<cffunction name="t06_index_shouldIndexMultipleTypes_whenTypesPassedAsList" returntype="void">
		<cfscript>
			var nDocsIndexed         = "";
			var expectedNDocsIndexed = 14;

			cfelasticsearch = cfelasticsearch.init(
				indexFolders = '/tests/integration/resources/indexes/goodset1'
			);

			nDocsIndexed = cfelasticsearch.index(
				  index = "test1"
				, type  = "default,type2"
			);

			super.assertEquals( expectedNDocsIndexed, nDocsIndexed );
		</cfscript>
	</cffunction>

	<cffunction name="t07_index_shouldThrowError_whenNoTypeSuppliedAndIndexDoesNotExist" returntype="void">
		<cfscript>
			var failed = false;

			cfelasticsearch = cfelasticsearch.init(
				indexFolders = '/tests/integration/resources/indexes/goodset1'
			);

			try {
				cfelasticsearch.index( index="IdoNotExist" );
			} catch ( "cfelasticsearch.index.notfound" e ) {
				failed = true;
			} catch ( any e ) {}


			super.assert( failed, "CfElasticSearch did not throw an appropriate error when an index was not found." );
		</cfscript>
	</cffunction>

	<cffunction name="t08_index_shouldIndexASingleDocument_whenIdSupplied" returntype="void">
		<cfscript>
			var nDocsIndexed         = "";
			var expectedNDocsIndexed = 1;

			cfelasticsearch = cfelasticsearch.init(
				indexFolders = '/tests/integration/resources/indexes/goodset1'
			);

			nDocsIndexed = cfelasticsearch.index(
				  index = "test1"
				, type  = "default"
				, id    = 1337
			);

			super.assertEquals( expectedNDocsIndexed, nDocsIndexed );
		</cfscript>
	</cffunction>

	<cffunction name="t09_indexTypeCfcs_shouldHaveConstructorArgsPassedOnToThemFromApiConstructorArgs" returntype="void">
		<cfscript>
			var nDocsIndexed = "";

			cfelasticsearch = cfelasticsearch.init(
				  indexFolders = '/tests/integration/resources/indexes/goodset2'
				, returnXDocs  = 4
			);
			nDocsIndexed = cfelasticsearch.index(
				  index = "test1"
				, type  = "type1"
			);
			super.assertEquals( 4, nDocsIndexed );

			// test again with different args to see different result
			cfelasticsearch = cfelasticsearch.init(
				  indexFolders = '/tests/integration/resources/indexes/goodset2'
				, returnXDocs  = 21
			);
			nDocsIndexed = cfelasticsearch.index(
				  index = "test1"
				, type  = "type1"
			);

			super.assertEquals( 21, nDocsIndexed );
		</cfscript>
	</cffunction>

	<cffunction name="t10_init_shouldThrowHelpfulError_whenIndexTypeCfcsDoNotHaveAllConstructorArgumentsAvailableToThem" returntype="void">
		<cfscript>
			var failed = false;

			try {
				cfelasticsearch = cfelasticsearch.init(
					  indexFolders = '/tests/integration/resources/indexes/goodset2'
				);
			} catch ( "cfelasticsearch.typecfc.missingargument" e ) {
				failed = true;
				super.assertEquals( "The index type, type1, expected the argument 'returnXDocs' to its constructor but it was not available. See detail for help resolving this issue.", e.message );
			} catch ( any e ) {}

			super.assert( failed, "CfElasticSearch failed to throw a helpful error when an index type cfc did not have all constructor arguments available." );
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

	<cffunction name="_teardownTestIndexes" access="private" returntype="void" output="false">
		<cftry>
			<cfset wrapper.deleteIndex( "_all" ) />
			<cfcatch>
			</cfcatch>
		</cftry>
	</cffunction>

</cfcomponent>