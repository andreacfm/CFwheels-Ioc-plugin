<!---
LICENSE 
Copyright 2008 Brian Kotek

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.

File Name: 

	DynamicXMLBeanFactory.cfc
	
Version: 1.0	

Description: 

	This component will replace dynamic properties in a ColdSpring XML file with
	values specified in the passed structure, then create a ColdSpring Bean Factory
	and return it for use. ColdSpring itself allows for some dynamic properties, but 
	only in certain places in the XML such as constructor argument values. Using this 
	CFC allows you to place dynamic properties anywhere in the XML. It also will handle 
	including and replacing dynamic properties in any included ColdSpring files that 
	use <include> tag.
	
	Note that this CFC expands on and supplants the XML replacement capabilities in the
	ColdSpringXMLUtils CFC. ColdSpringXMLUtils can be considered deprecated and will
	be removed from this project at some point in the future.

Usage:

	Usage is fairly straightforward. Simply create your properties structure, instantiate
	the DynamicXMLBeanFactory, and call loadBeansFromDynamicXmlFile(): 

		<cfset dynamicProperties = StructNew() />
		<cfset dynamicProperties.servicePackage = "myapp.components.services" />
	
		 Load the ColdSpring Dynamic XML Bean Factory, which will replace any dynamic values 
			  in the XML with matching properties I specified.
		<cfset application.beanFactory = CreateObject('component', 'myapp.components.factory.DynamicXmlBeanFactory').init() />
		<cfset application.beanFactory.loadBeansFromDynamicXmlFile('/myapp/config/coldspring.xml', dynamicProperties) />

	The DynamicXMLBeanFactory will read in the specified XML file, including all imported XML files,
	replace any properties in the XML that match the supplied property structure, and then create the
	Bean Factory as usual. So in this example, if your ColdSpring XML configuration file had this XML:
	
		<bean id="userService" class="${servicePackage}.userService" />
		
	The DynamicXMLBeanFactory would replace that string with the following before sending the XML to the
	DefaultXMLBeanFactory:
	
		<bean id="userService" class="myapp.components.services.userService" />
		
	The ability to specify dynamic properties for class paths, lazy-init settings, and bean IDs is extremely
	powerful and allows for much greater flexibility in configuration your application.	
	
--->

<cfcomponent name="DynamicXmlBeanFactory" 
			displayname="DynamicXmlBeanFactory" 
			extends="coldspring.beans.DefaultXmlBeanFactory"
			hint="Dynamic XML Bean Factory implimentation" 
			output="false">
	
	<cffunction name="loadBeansFromDynamicXmlFile" returntype="void" access="public" hint="loads bean definitions into the bean factory from an xml file location and replace all dynamic properties">
		<cfargument name="beanDefinitionFile" type="string" required="true" hint="I am the location of the dynamic bean definition xml file"/>
		<cfargument name="properties" type="struct" required="false" default="#StructNew()#" hint="Structure containing the dynamic properties to be replaced. The key names must match the dynamic properties in the XML file." />
		<cfset loadDynamicColdSpring(arguments.beanDefinitionFile, arguments.properties) />
	</cffunction>
	
	<cffunction name="loadDynamicColdSpring" access="public" returntype="void" output="false" hint="I replace any dynamic properties in the specified ColdSpring XML file and return the bean factory.">
		<cfargument name="coldSpringXMLPath" type="string" required="true" hint="Path to ColdSpring XML File i.e. '/myapp/config/coldspring.xml'" />
		<cfargument name="properties" type="struct" required="false" default="#StructNew()#" hint="Structure containing the dynamic properties to be replaced. The key names must match the dynamic properties in the XML file." />
		<cfset var local = StructNew() />
		<cfset local.replacedColdSpringXML = getReplacedColdSpringXML(arguments.coldSpringXMLPath, arguments.properties) />
		<cfset loadBeansFromXmlRaw(beanDefinitionXml=local.replacedColdSpringXML, constructNonLazyBeans=true) />
	</cffunction>
	
	<cffunction name="getReplacedColdSpringXML" access="public" returntype="string" output="false" hint="I return the ColdSpring XML with all imports processed and dynamic properties replaced.">
		<cfargument name="coldSpringXMLPath" type="string" required="true" hint="Path to ColdSpring XML File i.e. '/myapp/config/coldspring.xml'" />
		<cfargument name="properties" type="struct" required="false" default="#StructNew()#" hint="Structure containing the dynamic properties to be replaced. The key names must match the dynamic properties in the XML file." />
		<cfset var local = StructNew() />
		<cfset local.imports = StructNew() />
		<cfset findImports(local.imports, arguments.coldSpringXMLPath) />
		<cfif StructCount(local.imports) eq 1>
			<cfset arguments.coldSpringXMLPath = ExpandPath(arguments.coldSpringXMLPath) />
			<cfset local.replacedColdSpringXML = replaceDynamicValues(arguments.coldSpringXMLPath, arguments.properties) />
			<cfset local.replacedColdSpringXML = '#getXMLHeader()##local.replacedColdSpringXML#' />
			<cfset local.replacedColdSpringXML = local.replacedColdSpringXML & getXMLFooter() />
		<cfelseif StructCount(local.imports) gt 1>
			<cfset local.replacedXMLArray = ArrayNew(1) />
			<cfloop collection="#local.imports#" item="local.thisImport">
				<cfset local.tempImportData = StructNew() />
				<cfset local.tempImportData.importFile = local.thisImport />
		?reload=true		<cfset local.tempImportData.replacedXML = replaceDynamicValues(local.thisImport, arguments.properties) />
				<cfset ArrayAppend(local.replacedXMLArray, local.tempImportData) />
			</cfloop>
			<cfset local.replacedColdSpringXML = getXMLHeader() />
			<cfloop from="1" to="#ArrayLen(local.replacedXMLArray)#" index="local.thisXML">
				<cfset local.replacedColdSpringXML = local.replacedColdSpringXML & '#Chr(13)##Chr(10)##Chr(9)#<!-- @import processed from #local.replacedXMLArray[local.thisXML].importFile# -->#Chr(13)##Chr(10)#' & ReReplaceNoCase(local.replacedXMLArray[local.thisXML].replacedXML, '.*<beans>|<import[^>]*>|</beans>', '', 'All') />	
			</cfloop>			
			<cfset local.replacedColdSpringXML = local.replacedColdSpringXML & getXMLFooter() />
		</cfif>
		<cfreturn local.replacedColdSpringXML />
	</cffunction>
	
	<cffunction name="replaceDynamicValues" access="private" returntype="string" output="false" hint="I replace any dynamic values in the ColdSpring XML with matching values in the specified value structure">
		<cfargument name="coldSpringXMLPath" type="string" required="true" hint="Path to ColdSpring XML File i.e. '/myapp/config/coldspring.xml'" />
		<cfargument name="dynamicValues" type="struct" required="false" default="#StructNew()#" hint="Structure containing the dynamic properties to be replaced. The key names must match the dynamic properties in the XML file." />
		<cfset var local = StructNew() />
		<cffile action="read" file="#arguments.coldSpringXMLPath#" variable="local.coldSpringXML" />
		<cfset local.coldSpringXML = ReReplaceNoCase(local.coldSpringXML, '.*<beans[^>]*>', '', 'all') />
		<cfset local.coldSpringXML = ReReplaceNoCase(local.coldSpringXML, '</beans>.*', '', 'all') />
		<cfset local.matches = ReMatchNoCase('\$\{[^}]*\}', local.coldSpringXML) />
		<cfset local.stringBuilder = CreateObject("java","java.lang.StringBuilder").init(JavaCast("string", local.coldSpringXML)) />
		<cfoutput>
		<cfloop from="1" to="#ArrayLen(local.matches)#" index="local.thisMatch">
			<cfset local.tempString = Mid(local.matches[local.thisMatch], 3, Len(local.matches[local.thisMatch]) - 3) />
			<cfif StructKeyExists(arguments.dynamicValues, local.tempString)>
				<cfset replaceValue(local.stringBuilder, local.matches[local.thisMatch], arguments.dynamicValues[local.tempString]) />
			</cfif>
		</cfloop>
		</cfoutput>
		<cfreturn local.stringBuilder.toString() />
	</cffunction>
	
	<cffunction name="replaceValue" access="private" returntype="void" output="false" hint="I recursively replace the specified dynamic property in the XML.">
		<cfargument name="stringBuffer" type="any" required="true" />
		<cfargument name="targetString" type="string" required="true" />
		<cfargument name="replacementValue" type="string" required="true" />
		<cfargument name="startPosition" type="numeric" required="false" default="0" />
		<cfset var local = StructNew() />
		<cfset local.stringIndex = arguments.stringBuffer.indexOf(JavaCast("string", arguments.targetString), JavaCast("int", arguments.startPosition)) />
		<cfif local.stringIndex neq -1>
			<cfset arguments.stringBuffer.replace(JavaCast("int", local.stringIndex), JavaCast("int", local.stringIndex + Len(arguments.targetString)), JavaCast("string", arguments.replacementValue)) />
			<cfset replaceValue(arguments.stringBuffer, arguments.targetString, arguments.replacementValue, local.stringIndex + Len(arguments.targetString)) />
		</cfif>
	</cffunction>
	
	<cffunction name="getXMLHeader" access="private" returntype="string" output="false" hint="">
		<cfreturn '<!DOCTYPE beans PUBLIC "-//SPRING//DTD BEAN//EN" "http://www.springframework.org/dtd/spring-beans.dtd">#Chr(13)##Chr(10)#<beans>#Chr(13)##Chr(10)##Chr(13)##Chr(10)#' />
	</cffunction>
	
	<cffunction name="getXMLFooter" access="private" returntype="string" output="false" hint="">
		<cfreturn "</beans>" />
	</cffunction>
				
</cfcomponent>