<cfcomponent output="false" extends="util.Base">

<!--- properties --->
	<cfscript>
		_apiWrapper   = "";
		_indexFolders = "";
		_indexes      = StructNew();
	</cfscript>

<!--- constructor --->
	<cffunction name="init" access="public" returntype="any" output="false">
		<cfargument name="endpoint"     type="string" required="false" default="http://localhost:9200" />
		<cfargument name="indexFolders" type="string" required="true" />

		<cfscript>
			_setupApiWrapper( endpoint     );
			_setIndexFolders( indexFolders );

			_loadIndexDefinitions();

			return this;
		</cfscript>
	</cffunction>

<!--- public methods --->
	<cffunction name="index" access="public" returntype="numeric" output="false">
		<cfargument name="index" type="string" required="true" />
		<cfargument name="type"  type="string" required="true" />

		<cfscript>
			var docs   = _getDocsForIndexing( index, type );
			var result = _getApiWrapper().addDocs(
				  index = index
				, type  = type
				, docs  = docs
			);
			if ( StructKeyExists( result, 'items' ) and IsArray( result.items ) ) {
				return ArrayLen( result.items );
			}

			return 0;
		</cfscript>
	</cffunction>

<!--- private helpers --->
	<cffunction name="_setupApiWrapper" access="private" returntype="void" output="false">
		<cfargument name="endpoint" type="string" required="false" default="http://localhost:9200" />

		<cfscript>
			var wrapper = CreateObject( 'component', 'api.Wrapper' ).init( endpoint = endpoint );

			_setApiWrapper( wrapper );
		</cfscript>
	</cffunction>

	<cffunction name="_loadIndexDefinitions" access="private" returntype="void" output="false">
		<cfscript>
			var folders   = ListToArray( _getIndexFolders() );
			var i         = 0;
			var indexes   = "";
			var types     = "";
			var n         = "";
			var x         = "";

			for( i=1; i lte ArrayLen( folders ); i++ ){
				indexes = $directoryList( directory = $ensureFullDirectoryPath( folders[i] ), recurse = false );
				for( n=1; n lte indexes.recordCount; n++ ){
					if ( indexes.type[n] eq 'dir' ) {
						_addIndex( indexes.name[n] );
						types     = $directoryList(
							  directory = indexes.directory[n] & '/' & indexes.name[n]
							, filter    = "*.cfc"
							, recurse   = true
						);

						for( x=1; x lte types.recordCount; x++ ){
							_addTypeToIndex(
								  type      = types.name[x]
								, index     = indexes.name[n]
								, indexRoot = folders[i]
							);
						}
					}
				}
			}
		</cfscript>
	</cffunction>

	<cffunction name="_getDocsForIndexing" access="private" returntype="array" output="false">
		<cfargument name="index" type="string" required="true" />
		<cfargument name="type"  type="string" required="true" />

		<cfscript>
			var typeCfc = _getTypeComponent( index, type );
			var docs    = typeCfc.get();

			return _queryToArrayOfStructs( docs );
		</cfscript>
	</cffunction>

	<cffunction name="_getTypeComponent" access="private" returntype="any" output="false">
		<cfargument name="index" type="string" required="true" />
		<cfargument name="type"  type="string" required="true" />

		<cfscript>
			return _indexes[ index ][ type ];
		</cfscript>
	</cffunction>

	<cffunction name="_queryToArrayOfStructs" access="private" returntype="array" output="false">
		<cfargument name="qry" type="query" required="true" />

		<cfscript>
			var cols    = ListToArray( qry.columnList );
			var col     = "";
			var i       = 0;
			var n       = 0;
			var record  = "";
			var records = ArrayNew(1);

			for( i=1; i LTE qry.recordCount; i++ ){
				record = StructNew();
				for( n=1; n LTE ArrayLen( cols ); n++ ){
					col = cols[n];
					record[col] = qry[col][i];
				}
				ArrayAppend( records, record );
			}

			return records;
		</cfscript>
	</cffunction>

	<cffunction name="_addIndex" access="private" returntype="void" output="false">
		<cfargument name="index" type="string" required="true" />

		<cfset _indexes[ index ] = StructNew() />
	</cffunction>

	<cffunction name="_addTypeToIndex" access="private" returntype="void" output="false">
		<cfargument name="type"      type="string" required="true" />
		<cfargument name="index"     type="string" required="true" />
		<cfargument name="indexRoot" type="string" required="true" />

		<cfscript>
			var componentPath = $mappedPathToComponentPath( "#indexRoot#/#index#/#type#" )
			var instance      = CreateObject( "component", componentPath );

			_indexes[ index ][ ListLast( componentPath, '.' ) ] = instance;
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

	<cffunction name="_getIndexFolders" access="private" returntype="string" output="false">
		<cfreturn _indexFolders>
	</cffunction>
	<cffunction name="_setIndexFolders" access="private" returntype="void" output="false">
		<cfargument name="indexFolders" type="string" required="true" />
		<cfset _indexFolders = arguments.indexFolders />
	</cffunction>

</cfcomponent>