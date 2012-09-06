<cfcomponent output="false" extends="util.Base">

<!--- properties --->
	<cfscript>
		_apiWrapper      = "";
		_indexFolders    = "";
		_indexes         = StructNew();
		_constructorArgs = StructNew();
	</cfscript>

<!--- constructor --->
	<cffunction name="init" access="public" returntype="any" output="false">
		<cfargument name="indexFolders"          type="string" required="true"                                  hint="Comma separated list of *mapped* folder paths. Mapped paths must be used in order for CfElasticSearch to know how to instantiate components that live in these folders." />
		<cfargument name="elasticSearchEndpoint" type="string" required="false" default="http://localhost:9200" hint="Full enpoint address of the elasticsearch server including protocol and port. The default is 'http://localhost:9200'." />

		<cfscript>
			_setupApiWrapper( elasticSearchEndpoint );
			_setIndexFolders( indexFolders );
			_setConstructorArgs( arguments );

			_loadIndexDefinitions();

			return this;
		</cfscript>
	</cffunction>

<!--- public methods --->
	<cffunction name="index" access="public" returntype="numeric" output="false">
		<cfargument name="index" type="string" required="true"  />
		<cfargument name="type"  type="string" required="false" />
		<cfargument name="id"    type="string" required="false" default="" />

		<cfscript>
			var types            = "";
			var totalIndexedDocs = 0;
			var i                = 0;

			if ( StructKeyExists( arguments, 'type' ) ) {
				types = ListToArray( type );
			} else {
				types = _getIndexTypes( index );
			}

			for( i=1; i lte ArrayLen( types ); i++ ){
				totalIndexedDocs += _indexType( index, types[i], id );
			}

			return totalIndexedDocs;
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
		<cfargument name="id"    type="string" required="true" />

		<cfscript>
			var typeCfc = _getTypeComponent( index, type );
			var docs    = "";

			if ( Len( Trim( id ) ) ) {
				docs = typeCfc.get( id );
			} else {
				docs = typeCfc.get();
			}

			return _queryToArrayOfStructs( docs );
		</cfscript>
	</cffunction>

	<cffunction name="_getTypeComponent" access="private" returntype="any" output="false">
		<cfargument name="index" type="string" required="true" />
		<cfargument name="type"  type="string" required="true" />

		<cfscript>
			_checkIndexAndTypeExist( index, type );
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
			var typeName      = ListLast( componentPath, '.' );

			instance = _injectConstructorArgs( typeName, instance );

			_indexes[ index ][ typeName ] = instance;
		</cfscript>
	</cffunction>

	<cffunction name="_indexType" access="private" returntype="numeric" output="false">
		<cfargument name="index" type="string" required="true" />
		<cfargument name="type"  type="string" required="true" />
		<cfargument name="id"    type="string" required="true" />

		<cfscript>
			var docs   = _getDocsForIndexing( index, type, id );
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

	<cffunction name="_getIndexTypes" access="private" returntype="array" output="false">
		<cfargument name="index" type="string" required="true" />

		<cfscript>
			_checkIndexAndTypeExist( index );

			return StructKeyArray( _indexes[ index ] );
		</cfscript>
	</cffunction>

	<cffunction name="_checkIndexAndTypeExist" access="private" returntype="void" output="false">
		<cfargument name="index" type="string" required="true" />
		<cfargument name="type" type="string" required="false" />

		<cfscript>
			if ( not StructKeyExists( _indexes, index ) ) {
				throw(
					  type = "cfelasticsearch.index.notfound"
					, message = "The index, '#index#', could not be found. Please ensure that the index name is correct and that index is defined within your indexFolders as per the CfElasticSearch documentation."
				);
			}

			if ( StructKeyExists( arguments, 'type' ) and not StructKeyExists( _indexes[ index ], type ) ) {
				throw(
					  type = "cfelasticsearch.index.type.notfound"
					, message = "The index type, '#index#.#type#', could not be found. Please ensure that the type name is correct and that type component is defined within your indexFolders as per the CfElasticSearch documentation."
				);
			}
		</cfscript>
	</cffunction>

	<cffunction name="_injectConstructorArgs" access="private" returntype="any" output="false">
		<cfargument name="type" type="string" required="true" />
		<cfargument name="typeCfc" type="any" required="true" />

		<cfscript>
			var md = GetMetaData( typeCfc );
			var i  = 0;

			if ( StructKeyExists( md, 'functions' ) and IsArray( md.functions ) ) {
				for( i=1; i lte ArrayLen( md.functions ); i++ ){
					if ( md.functions[i].name eq "init" ) {
						_checkConstructorArgsAreAvailable( type, md.functions[i].parameters );
						return typeCfc.init( argumentCollection = _getConstructorArgs() );
					}
				}
			}

			return typeCfc;
		</cfscript>
	</cffunction>

	<cffunction name="_checkConstructorArgsAreAvailable" access="private" returntype="void" output="false">
		<cfargument name="type" type="string" required="true" />
		<cfargument name="parameters" type="array" required="true" />

		<cfscript>
			var i = 0;
			var constructorArgs = _getConstructorArgs();
			var isRequired = "";

			for( i=1; i lte ArrayLen( parameters ); i++ ){
				isRequired = StructKeyExists( parameters[i], 'required' ) and IsBoolean( parameters[i].required ) and parameters[i].required;
				if ( isRequired and not StructKeyExists( constructorArgs, parameters[i].name ) ) {
					throw(
						  type    = "cfelasticsearch.typecfc.missingargument"
						, message = "The index type, #type#, expected the argument '#parameters[i].name#' to its constructor but it was not available. See detail for help resolving this issue."
						, detail  = "TODO: Help resolving issue here."
					);
				}
			}
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

	<cffunction name="_getConstructorArgs" access="private" returntype="struct" output="false">
		<cfreturn _constructorArgs>
	</cffunction>
	<cffunction name="_setConstructorArgs" access="private" returntype="void" output="false">
		<cfargument name="constructorArgs" type="struct" required="true" />
		<cfset _constructorArgs = arguments.constructorArgs />
	</cffunction>

</cfcomponent>