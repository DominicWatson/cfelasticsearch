<cfcomponent output="false" hint="I am a base class providing common utility methods for all components. All CfStatic components extend me">

<!--- utility methods --->
	<cffunction name="$directoryList" access="private" returntype="query" output="false" hint="I return a query of files and subdirectories for a given directory">
		<cfargument name="directory"	type="string" required="true"					/>
		<cfargument name="filter"		type="string" required="false"	default="*"	/>
		<cfargument name="recurse"		type="boolean" required="false"	default="true"	/>

		<cfset var result = QueryNew('') />

		<cfif DirectoryExists( arguments.directory )>
			<cfdirectory	action="list"
							directory="#arguments.directory#"
							filter="#arguments.filter#"
							recurse="#arguments.recurse#"
							name="result" />
		</cfif>

		<cfreturn result />
	</cffunction>



	<cffunction name="$normalizeUnixAndWindowsPaths" access="private" returntype="string" output="false">
		<cfargument name="path" type="string" required="true" />

		<cfreturn Replace( arguments.path, '\', '/', 'all' ) />
	</cffunction>


	<cffunction name="$newline" access="private" returntype="string" output="false">
		<cfreturn Chr(13) & Chr(10) />
	</cffunction>

	<cffunction name="$calculateRelativePath" access="private" returntype="string" output="false">
		<cfargument name="basePath"     type="string" required="true" />
		<cfargument name="relativePath" type="string" required="true" />

		<cfscript>
			var basePathArray     = ListToArray( GetDirectoryFromPath( arguments.basePath ), "\/" );
			var relativePathArray = ListToArray( arguments.relativePath, "\/" );
			var finalPath         = ArrayNew(1);
			var pathStart         = 0;
			var i                 = 0;

			/* Define the starting path (path in common) */
			for (i = 1; i LTE ArrayLen(basePathArray); i = i + 1) {
				if (basePathArray[i] NEQ relativePathArray[i]) {
					pathStart = i;
					break;
				}
			}

			if ( pathStart EQ 0 ) {
				ArrayAppend( finalPath, "." );
				pathStart = ArrayLen(basePathArray);
			}

			/* Build the prefix for the relative path (../../etc.) */
			for ( i = ArrayLen(basePathArray) - pathStart; i GTE 0; i=i-1 ) {
				ArrayAppend( finalPath, ".." );
			}

			/* Build the relative path */
			for ( i = pathStart; i LTE ArrayLen(relativePathArray); i=i+1 ) {
				ArrayAppend( finalPath, relativePathArray[i] );
			}

			return ArrayToList( finalPath, "/" );
		</cfscript>
	</cffunction>


	<cffunction name="$ensureFullDirectoryPath" access="private" returntype="string" output="false">
		<cfargument name="dir" type="string" required="true" />
		<cfscript>
			if ( directoryExists( ExpandPath( arguments.dir ) ) ) {
				return ExpandPath( arguments.dir );
			}
			return arguments.dir;
		</cfscript>
	</cffunction>

	<cffunction name="$ensureFullFilePath" access="private" returntype="string" output="false">
		<cfargument name="file" type="string" required="true" />

		<cfscript>
			if ( fileExists( ExpandPath( arguments.file ) ) ) {
				return ExpandPath( arguments.file );
			}
			return arguments.file;
		</cfscript>
	</cffunction>

	<cffunction name="$getStringBuffer" access="private" returntype="any" output="false">
		<cfreturn CreateObject("java","java.lang.StringBuffer") />
	</cffunction>

	<cffunction name="$mappedPathToComponentPath" access="private" returntype="string" output="false">
		<cfargument name="mappedPath" type="string" required="true" />

		<cfscript>
			var componentPath = Replace( mappedPath, '/', '.', 'all' );

			componentPath = ReReplace( componentPath, '\.+', '.', 'all' );
			componentPath = ReReplace( componentPath, '\.cfc$', '' );
			componentPath = ReReplace( componentPath, '^\.', '' );

			return componentPath;
		</cfscript>
	</cffunction>

</cfcomponent>