<!--- /*		
Project:     CfWheels Ioc Interface  http://cfwheels.org/plugins/listing/22
Author:      Andrea Campolonghi <andrea@getrailo.org>
Version:     0.3
Build Date:  martedì dic 15, 2009
Build:		 09

Copyright 2009 Andrea Campolonghi

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.	
			
*/--->
<cfcomponent output="false" mixin="global">
	
	<!----------------------------------------------------->
	
	<cffunction name="init">
		<cfset this.version = "1.0">
		<cfset application.wheels.cache.ioc = {} />
		<cfreturn this />
	</cffunction>
	
	<!----------------------------------------------------->
	
	<cffunction name="loadBeanFactory" hint="">
		<cfargument name="id" default="beanFactory">
		<cfargument name="type" default="ColdSpring">		
		<cfargument name="configPath" default="beanFactory">
		<cfargument name="properties" default="#structNew()#">
		
		<cfset var loc = {} />
		
		<cfif type neq 'ColdSpring'>
			<cfthrow message="Ioc plugin support only Coldspring at the moment." />
		</cfif>
		
		<cfif type eq 'ColdSpring'>
			<cfset loc.cspath = '#application.wheels.PLUGINCOMPONENTPATH#.ioc.coldspring.DynamicXmlBeanFactory' />
			<cfset loc.cs = createObject('component',loc.cspath).init() />
			<cfset loc.cs.loadBeansFromDynamicXmlFile(configPath,arguments.properties) />		
			<cfset application.wheels.cache.ioc[arguments.id] = loc.cs />
		</cfif>	
		
	</cffunction>
	
	<!----------------------------------------------------->
	
	<cffunction name="getBeanFactory" returntype="any" >
		<cfargument name="id" default="beanFactory" />
		<cfreturn application.wheels.cache.ioc[arguments.id] />
	</cffunction>
	
	<!----------------------------------------------------->
		
</cfcomponent>