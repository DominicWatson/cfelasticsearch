<cfcomponent extends="mxunit.framework.TestCase" output="false">

<!--- setup, teardown, etc --->
	<cffunction name="setup" access="public" returntype="void" output="false">
		<cfscript>
			super.setup();
			wrapper = CreateObject( "component", "cfelasticsearch.api.Wrapper" );
		</cfscript>
	</cffunction>

	<cffunction name="teardown" access="public" returntype="void" output="false">
		<cfscript>
			super.teardown();
		</cfscript>
	</cffunction>

<!--- tests --->
	<cffunction name="t01_ping_shouldReturnServerInformation" returntype="void">
		<cfscript>
			fail("t01_ping_shouldReturnServerInformation not yet implemented");
		</cfscript>
	</cffunction>

</cfcomponent>