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
			var indexName = "someTestIndex";
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

	<cffunction name="t05_deleteIndex_shouldThrowError_whenIndexDoesNotExist" returntype="void">
		<cfscript>
			var indexName = "iDoNOTExist";
			var failed    = false;

			try {
				wrapper.deleteIndex( indexName );
			} catch ( "cfelasticsearch.IndexMissingException" e ) {
				failed = true;
				super.assertEquals( "[#indexName#] missing", e.message );
				super.assertEquals( 404, e.errorCode );
			}

			super.assert( failed, "The API did not throw an error when attempting to delete an index that did not exist." );
		</cfscript>
	</cffunction>

	<cffunction name="t06_addDoc_shouldAddASingleDocument" returntype="void">
		<cfscript>
			var indexName = "addDocTest";
			var result    = wrapper.createIndex( indexName );
			var doc      = {
				  id = 3499
				, title = "This is a title"
				, category = "Category"
				, dateCreated = "2012-07-22"
			};

			result = wrapper.addDoc(
				  index = indexName
				, type  = "someType"
				, id    = doc.id
				, doc   = doc
			);

			super.assert( result.ok );
			super.assertEquals( doc.id    , result['_id']      );
			super.assertEquals( indexName , result['_index']   );
			super.assertEquals( 'someType', result['_type']    );
			super.assertEquals( 1         , result['_version'] );
		</cfscript>
	</cffunction>

	<cffunction name="t07_addDoc_shouldUpdateExistingDoc" returntype="void">
		<cfscript>
			var indexName = "addDocTest";
			var result    = wrapper.createIndex( indexName );
			var doc      = {
				  id = 3499
				, title = "This is a title"
				, category = "Category"
				, dateCreated = "2012-07-22"
			};

			wrapper.addDoc(
				  index = indexName
				, type  = "someType"
				, id    = doc.id
				, doc   = doc
			);

			doc.title = "Changed";

			result = wrapper.addDoc(
				  index = indexName
				, type  = "someType"
				, id    = doc.id
				, doc   = doc
			);

			super.assert( result.ok );
			super.assertEquals( doc.id    , result['_id']      );
			super.assertEquals( indexName , result['_index']   );
			super.assertEquals( 'someType', result['_type']    );
			super.assertEquals( 2         , result['_version'] );
		</cfscript>
	</cffunction>

	<cffunction name="t08_addDocs_shouldAddAndUpdateMultipleDocsAtOnce" returntype="void">
		<cfscript>
			var indexName = "addDocsTest";
			var type      = "someType";
			var result    = wrapper.createIndex( indexName );
			var i         = "";
			var docs      = [{
				  id = 1
				, title = "Title 1"
				, category = "Category 1"
			},{
				  id = 2
				, title = "Title 2"
				, category = "Category 2"
			},{
				  id = 3
				, title = "Title 3"
				, category = "Category 3"
			},{
				  id = 4
				, title = "Title 4"
				, category = "Category 4"
			},{
				  id = 5
				, title = "Title 5"
				, category = "Category 5"
			} ];

			wrapper.addDoc(
				  index = indexName
				, type = type
				, id   = docs[1].id
				, doc  = docs[1]
			);

			wrapper.addDoc(
				  index = indexName
				, type = type
				, id   = docs[2].id
				, doc  = docs[2]
			);

			docs[1].title = "Title 1 edited";
			docs[2].title = "Title 2 edited";

			result = wrapper.addDocs( indexName, type, docs );

			super.assert( StructKeyExists( result, 'items' ) and IsArray( result.items ), "Return format is not as expected" );
			super.assertEquals( ArrayLen( docs ), ArrayLen( result.items ), "Result did not confirm that all docs were added" );

			for( i=1; i LTE ArrayLen( result.items ); i++ ){
				super.assert( result.items[i].index.ok, "The item was not added" );
				if ( result.items[i].index._id lte 2 ) {
					super.assertEquals( 2, result.items[i].index._version, "Item should have been updated to version 2 but wasn't." );
				} else {
					super.assertEquals( 1, result.items[i].index._version, "Item should have been at version 1 but wasn't." );
				}
			}
		</cfscript>
	</cffunction>

	<cffunction name="t09_addDocs_shouldThrowErrorWhenDocIsNotStruct" returntype="void">
		<cfscript>
			var indexName = "addDocsTestBadDoc";
			var type      = "someType";
			var result    = wrapper.createIndex( indexName );
			var failed    = false;
			var docs      = [{
				  id = 1
				, title = "Title 1"
				, category = "Category 1"
			},"bad doc",{
				  id = 3
				, title = "Title 3"
				, category = "Category 3"
			}];

			try {
				result = wrapper.addDocs( indexName, type, docs );
			} catch ( "cfelasticsearch.addDocs.badDoc" e ) {
				failed = true;
			}

			assert( failed, "The addDocs method did not throw an appropriate error when a bad document was passed in the array" );
		</cfscript>
	</cffunction>

	<cffunction name="t10_addDocs_shouldHaveElasticSearchCreateIds_whenDocsDoNotHaveIdField" returntype="void">
		<cfscript>
			var indexName = "addDocsTestNoId";
			var type      = "someType";
			var result    = wrapper.createIndex( indexName );
			var i         = 0;
			var docs      = [{
				  idfield = "someIdHere"
				, title = "Title 1"
				, category = "Category 1"
			},{
				  title = "Title 3"
				, category = "Category 3"
			}];

			result = wrapper.addDocs( indexName, type, docs, 'idfield' );
			super.assert( StructKeyExists( result, 'items' ) and IsArray( result.items ), "Return format is not as expected" );
			super.assertEquals( ArrayLen( docs ), ArrayLen( result.items ), "Result did not confirm that all docs were added" );

			super.assertEquals( docs[1].idfield, result.items[1].index._id );
			super.assert( Len( Trim( result.items[2].create._id ) ) );
		</cfscript>
	</cffunction>

	<cffunction name="t11_addDocs_shouldThrowError_whenNoDocsPassed" returntype="void">
		<cfscript>
			var indexName = "addDocsTestNoDocs";
			var type      = "someType";
			var result    = wrapper.createIndex( indexName );
			var failed    = false;

			try {
				result = wrapper.addDocs( indexName, type, [] );
			} catch ( "cfelasticsearch.addDocs.noDocs" e ) {
				failed = true;
			}

			assert( failed, "The addDocs method did not throw an appropriate error when no documents were passed" );
		</cfscript>
	</cffunction>

	<cffunction name="t12_addDoc_shouldLetElasticSearchCreateId_whenNoIdSupplied" returntype="void">
		<cfscript>
			var indexName = "addDocTest";
			var result    = "";
			var doc      = {
				  title = "This is a title"
				, category = "Category"
				, dateCreated = "2012-07-22"
			};

			result = wrapper.addDoc(
				  index = indexName
				, type  = "someType"
				, doc   = doc
			);

			super.assert( result.ok );
			super.assert( Len( Trim( result['_id'] ) ) );
			super.assertEquals( indexName , result['_index']   );
			super.assertEquals( 'someType', result['_type']    );
			super.assertEquals( 1         , result['_version'] );
		</cfscript>
	</cffunction>

	<cffunction name="t13_refresh_shouldRefreshAnIndex" returntype="void">
		<cfscript>
			var indexName = "refreshTest";
			var type      = "dummyType";
			var nDocs     = _addABunchOfDocs( indexName, type );
			var result    = wrapper.refresh( indexName );

			super.assert( IsStruct( result ), "Result not in expected format" );
			super.assert( result.ok );
		</cfscript>
	</cffunction>

	<cffunction name="t14_search_shouldReturnAllDocs_whenStarIsSuppliedAsQuery" returntype="void">
		<cfscript>
			var indexName = "simpleSearchTest";
			var type      = "dummyType";
			var result    = "";
			var nDocs     = _addABunchOfDocs( indexName, type );

			wrapper.refresh( indexName );
			result = wrapper.search( index=indexName, q="*" );
			super.assert( IsStruct( result ) and StructKeyExists( result, 'hits' ), "Result was not in expected format" );
			super.assertEquals( nDocs, result.hits.total );
		</cfscript>
	</cffunction>

	<cffunction name="t15_refresh_shouldThrowError_whenIndexDoesNotExist" returntype="void">
		<cfscript>
			var indexName = "nonexistantindex";
			var failed    = false;

			try {
				result = wrapper.refresh( indexName );
			} catch ( "cfelasticsearch.IndexMissingException" e ) {
				failed = true;
				super.assertEquals( "[#indexName#] missing", e.message );
				super.assertEquals( 404, e.errorCode );
			}

			super.assert( failed, "The API did not throw an error when attempting to refresh a non-existant index" );
		</cfscript>
	</cffunction>

	<cffunction name="t16_refresh_shouldRefreshALLIndexes_whenNoIndexSupplied" returntype="void">
		<cfscript>
			var result = "";
			_addABunchOfDocs( "someindex", "sometype" );
			_addABunchOfDocs( "another"  , "sometype" );
			_addABunchOfDocs( "blah"     , "sometype" );

			result = wrapper.refresh();

			super.assert( IsStruct( result ), "Result not in expected format" );
			super.assert( result.ok );
		</cfscript>
	</cffunction>

	<cffunction name="t17_search_shouldSearchAgainstAType_whenSupplied" returntype="void">
		<cfscript>
			var result = "";
			var indexName = "someIndex";
			var nDocs  = _addABunchOfDocs( indexName, "sometype" );

			_addABunchOfDocs( indexName, "someOtherType" );

			wrapper.refresh( indexName );

			result = wrapper.search( index=indexName, q="*" );
			super.assert( IsStruct( result ) and StructKeyExists( result, 'hits' ), "Result was not in expected format" );
			super.assertNotEquals( nDocs, result.hits.total );
			super.assertNotEquals( nDocs, ArrayLen( result.hits.hits ) );

			result = wrapper.search( index=indexName, type="sometype", q="*" );

			super.assert( IsStruct( result ) and StructKeyExists( result, 'hits' ), "Result was not in expected format" );
			super.assertEquals( nDocs, result.hits.total );
		</cfscript>
	</cffunction>

	<cffunction name="t18_search_shouldSearchAcrossAllIndexes_whenNoIndexSupplied" returntype="void">
		<cfscript>
			var result = "";
			var indexName = "someIndex";
			var nDocs  = _addABunchOfDocs( indexName, "sometype" );

			nDocs = nDocs + _addABunchOfDocs( indexName, "someOtherType" );

			wrapper.refresh( indexName );

			result = wrapper.search( q="*" );
			super.assert( IsStruct( result ) and StructKeyExists( result, 'hits' ), "Result was not in expected format" );

			super.assertEquals( nDocs, result.hits.total );
		</cfscript>

	</cffunction>

	<cffunction name="t19_search_shouldSearchAcrossAllIndexes_whenTypeSuppliedWithoutAnIndex" returntype="void">
		<cfscript>
			var result = "";
			var nDocs  = _addABunchOfDocs( "someindex", "sometype" );

			nDocs = nDocs + _addABunchOfDocs( "another", "sometype" );
			_addABunchOfDocs( "blah", "someOthertype" );

			wrapper.refresh();
			result = wrapper.search( type="sometype", q="*" );

			super.assert( IsStruct( result ), "Result not in expected format" );
			super.assertEquals( nDocs, result.hits.total );
		</cfscript>
	</cffunction>

	<cffunction name="t20_search_shouldSearchAcrossMultipleIndexesAndMultipleTypes" returntype="void">
		<cfscript>
			var result        = "";
			var nDocsExpected = 0;

			nDocsExpected += _addABunchOfDocs( "index1", "type1" );
			nDocsExpected += _addABunchOfDocs( "index1", "type3" );
			nDocsExpected += _addABunchOfDocs( "index3", "type1" );
			nDocsExpected += _addABunchOfDocs( "index3", "type3" );

			_addABunchOfDocs( "index1", "type2" );
			_addABunchOfDocs( "index2", "type1" );
			_addABunchOfDocs( "index2", "type2" );
			_addABunchOfDocs( "index2", "type3" );
			_addABunchOfDocs( "index3", "type2" );

			wrapper.refresh();

			result = wrapper.search( index="index1,index3", type="type1,type3", q="*" );

			super.assert( IsStruct( result ), "Result not in expected format" );
			super.assertEquals( nDocsExpected, result.hits.total );
		</cfscript>
	</cffunction>

	<cffunction name="t21_search_shouldReturnPaginatedResults" returntype="void">
		<cfscript>
			var result        = "";
			var result2       = "";
			var nDocsExpected = 0;

			nDocsExpected += _addABunchOfDocs( "index1", "type1" );
			nDocsExpected += _addABunchOfDocs( "index1", "type2" );
			nDocsExpected += _addABunchOfDocs( "index1", "type3" );
			nDocsExpected += _addABunchOfDocs( "index1", "type4" );


			wrapper.refresh();

			result  = wrapper.search( q="*", page=3, pageSize=1 );
			result2 = wrapper.search( q="*", page=4, pageSize=1 );

			super.assert( IsStruct( result ), "Result not in expected format" );
			super.assertEquals( nDocsExpected, result.hits.total );
			super.assertEquals( 1, ArrayLen( result.hits.hits ) );

			super.assert( IsStruct( result2 ), "Result not in expected format" );
			super.assertEquals( nDocsExpected, result2.hits.total );
			super.assertEquals( 1, ArrayLen( result2.hits.hits ) );

			super.assertNotEquals( result2.hits.hits[1]._source, result.hits.hits[1]._source );
		</cfscript>
	</cffunction>

	<cffunction name="t22_search_shouldThrowError_whenPageNumberIsSubZero" returntype="void">
		<cfscript>
			var failed = false;

			_addABunchOfDocs( "index1", "type1" );
			_addABunchOfDocs( "index1", "type2" );
			_addABunchOfDocs( "index1", "type3" );
			_addABunchOfDocs( "index1", "type4" );

			wrapper.refresh();

			try {
				wrapper.search( q="*", page=-2 );
			} catch ( "cfelasticsearch.search.invalidPage" e ) {
				failed = true;
			} catch ( any e ) {}

			assert( failed, "The search method did not throw an appropriate error when the page number was zero or less" );
		</cfscript>
	</cffunction>

	<cffunction name="t23_search_shouldReturnNoResults_whenPageNumberIsGreaterThanNumberOfPagesForQuery" returntype="void">
		<cfscript>
			var result = "";

			_addABunchOfDocs( "index1", "type1" );
			_addABunchOfDocs( "index1", "type2" );
			_addABunchOfDocs( "index1", "type3" );
			_addABunchOfDocs( "index1", "type4" );

			wrapper.refresh();

			result = wrapper.search( q="*", page=1000, pageSize=100 );

			super.assert( IsStruct( result ), "Result not in expected format" );
			super.assert( result.hits.total );
			super.assertEquals( 0, ArrayLen( result.hits.hits ) );
		</cfscript>
	</cffunction>

<!--- private --->
	<cffunction name="_teardownTestIndexes" access="private" returntype="void" output="false">
		<cftry>
			<cfset wrapper.deleteIndex( "_all" ) />
			<cfcatch>
			</cfcatch>
		</cftry>
	</cffunction>

	<cffunction name="_checkRunningInstanceOfES" access="private" returntype="void" output="false">
		<cftry>
			<cfhttp url="http://localhost:9200" throwonerror="true" timeout="10" />
			<cfcatch>
				<cfthrow type="cfelasticsearch.testsuite" message="The elastic search engine could not be reached. Please ensure that an instance of elasticsearch is running on localhost at port 9200. Please note, while the test suite makes every effort to clean up after itself, you should not use a working elastic search instance to run these tests against." />
			</cfcatch>
		</cftry>
	</cffunction>

	<cffunction name="_addABunchOfDocs" access="private" returntype="numeric" output="false">
		<cfargument name="index" type="string" required="true" />
		<cfargument name="type"  type="string" required="true" />

		<cfscript>
			var docs      = [{
				  id = 1
				, title = "Title 1"
				, category = "Category 1"
			},{
				  id = 2
				, title = "Title 2"
				, category = "Category 2"
			},{
				  id = 3
				, title = "Title 3"
				, category = "Category 3"
			},{
				  id = 4
				, title = "Title 4"
				, category = "Category 4"
			},{
				  id = 5
				, title = "Title 5"
				, category = "Category 5"
			} ];

			wrapper.addDocs( index, type, docs );

			return ArrayLen( docs );
		</cfscript>
	</cffunction>
</cfcomponent>