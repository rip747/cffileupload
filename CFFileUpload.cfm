<!---
http://gist.github.com/138542

Replacement for <cffile action="upload"> to prevent the MIME/FILE Upload
Security Issue as documented at:

http://www.coldfusionjedi.com/index.cfm/2009/6/30/Are-you-aware-of-the-MIMEFile-Upload-Security-Issue

This is basically a drop in UDF to replace your <cffile> tag. What it will do is
intercept the destination directory passed to it and upload the file to CF temp
directory using getTempDirectory(). It then performs some checks to make sure that
the file uploaded is of the correct MIME type through the file extension and a list
of known MIME types for that extension. If everything checks out, it will MOVE the
file to the desired destination. If not then it will throw an error that you can
catch. You also have the option of deleteing the invalid file from the temp direcotry
(which is the default) or keeping it so you can inspect it later (which might be good).

I've included some of the most popular MIME types that people upload like office documents,
images, and pdfs as default checks. You can add to this list or overwrite it by passing
your own value with the mimeTypes argument.

Lastly, I've included a list of invalid file extensions that you can append to by passing
in your own list with the badExtensions arguments. Note that the you can't override the
internal list, only append it.

Instead of:

<cffile
	action="UPLOAD"
	filefield="form.thefile"
	destination="#expandpath('.')#"
	nameconflict="MAKEUNIQUE">
<cfset form.thefile = cffile.serverfile>

You replace with: 


<!--- In this example I cached all my UDF into a struct called functions within the application scope --->
<cfset myfile = application.functions.cffileupload(
		action="UPLOAD"
        ,filefield="form.thefile"
        ,destination="#expandpath('.')#"
        ,nameconflict="MAKEUNIQUE"
	)>
<cfset form.thefile = myfile.serverfile>
 --->
<cffunction name="CFFileUpload" returntype="struct" access="public" output="false">
	<cfargument name="deleteBadFile" type="boolean" required="false" default="true" hint="should we delete an invalid files that are uploaded from the temp directory.">
	<cfargument name="badExtensions" type="string" required="false" default="" hint="appends the internal extension list. any file with these extensions is automatically invalid.">
	<cfargument name="mimeTypes" type="struct" required="false" default="#structnew()#" hint="appends or replace the internal list of mimetypes with your own custom list.">
	<cfargument name="allowExtensions" type="string" required="false" default="" hint="extensions that don't have a mimetype associated with them, but should be allowed.">
	<cfset var loc = {}>
	<cfset loc.badExtensions = "cfm,cfml,cfc,dbm,jsp,asp,aspx,exe,php,cgi,shtml">
	<cfset loc.mimetypes = {}>
	<!--- pdf --->
	<cfset loc.mimetypes.pdf = "application/pdf,application/x-pdf,app/pdf">
	<!--- office --->
	<cfset loc.mimetypes.ppt = "application/vnd.ms-powerpoint">
	<cfset loc.mimetypes.xls = "application/vnd.ms-excel">
	<cfset loc.mimetypes.doc = "application/msword">
	<cfset loc.mimetypes.pub = "application/x-mspublisher,application/vnd.ms-publisher">
	<cfset loc.mimetypes.docm = "application/vnd.ms-word.document.macroEnabled.12">
	<cfset loc.mimetypes.docx = "application/vnd.openxmlformats-officedocument.wordprocessingml.document">
	<cfset loc.mimetypes.dotm = "application/vnd.ms-word.template.macroEnabled.12">
	<cfset loc.mimetypes.dotx = "application/vnd.openxmlformats-officedocument.wordprocessingml.template">
	<cfset loc.mimetypes.potm = "application/vnd.ms-powerpoint.template.macroEnabled.12">
	<cfset loc.mimetypes.potx = "application/vnd.openxmlformats-officedocument.presentationml.template">
	<cfset loc.mimetypes.ppam = "application/vnd.ms-powerpoint.addin.macroEnabled.12">
	<cfset loc.mimetypes.ppsm = "application/vnd.ms-powerpoint.slideshow.macroEnabled.12">
	<cfset loc.mimetypes.ppsx = "application/vnd.openxmlformats-officedocument.presentationml.slideshow">
	<cfset loc.mimetypes.pptm = "application/vnd.ms-powerpoint.presentation.macroEnabled.12">
	<cfset loc.mimetypes.pptx = "application/vnd.openxmlformats-officedocument.presentationml.presentation">
	<cfset loc.mimetypes.xlam = "application/vnd.ms-excel.addin.macroEnabled.12">
	<cfset loc.mimetypes.xlsb = "application/vnd.ms-excel.sheet.binary.macroEnabled.12">
	<cfset loc.mimetypes.xlsm = "application/vnd.ms-excel.sheet.macroEnabled.12">
	<cfset loc.mimetypes.xlsx = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet">
	<cfset loc.mimetypes.xltm = "application/vnd.ms-excel.template.macroEnabled.12">
	<cfset loc.mimetypes.xltx = "application/vnd.openxmlformats-officedocument.spreadsheetml.template">
	<!--- images --->
	<cfset loc.mimetypes.jpg = "image/jpg,image/pjpg,image/jpeg,image/pjpeg">
	<cfset loc.mimetypes.jpeg = "image/jpg,image/pjpg,image/jpeg,image/pjpeg">
	<cfset loc.mimetypes.gif = "image/gif">
	<cfset loc.mimetypes.png = "image/png">
	
	<!--- append our mime types with any custom ones --->
	<cfif not structisempty(arguments.mimeTypes)>
		<cfset structappend(loc.mimetypes, arguments.mimeTypes, true)>
	</cfif>
	<cfset structdelete(arguments, "mimeTypes")>
	
	<!--- append our badExtensions with any custom ones --->
	<cfset loc.badExtensions = listappend(loc.badExtensions, arguments.badExtensions)>
	<cfset structdelete(arguments, "badExtensions")>
	
	<!--- the result to use internally --->
	<cfset arguments.result = "loc.cffile">

	<!---
		intercept the upload destination and set it to the tempdirectory,
		save it so we can move the file later
	 --->
	<cfset loc.destination = arguments.destination>
	<cfset arguments.destination = getTempDirectory()>

	<!--- execute upload --->
	<cffile attributeCollection="#arguments#">

	<!--- get the full filename that was uploaded --->
	<cfset loc.fileuploaded = arguments.destination & loc.cffile["serverFile"]>

	<!--- try to get the mimetype of the uploaded file --->
	<cfset loc.filemimetype = getPageContext().getServletContext().getMimeType(loc.fileuploaded)>

	<cfif
		listfindnocase(loc.badExtensions, loc.cffile["serverFileExt"])
		or not structkeyexists(loc.mimetypes, loc.cffile["serverFileExt"])
		or (not len(arguments.allowExtensions) && not structkeyexists(loc, "filemimetype"))
		or (len(arguments.allowExtensions) && not listfindnocase(arguments.allowExtensions, loc.cffile["serverFileExt"]))
		or (structkeyexists(loc, "filemimetype") && not listfindnocase(loc.mimetypes[loc.cffile["serverFileExt"]], loc.filemimetype))>
		<cfif arguments.deleteBadFile>
			<cffile action="delete" file="#loc.fileuploaded#">
		</cfif>
		<cfthrow type="Custom" message="Invalid file type">
	</cfif>
	
	<!--- full path to move the file to --->
	<cfset loc.finaldestination = listappend(loc.destination, loc.cffile["serverFile"], "\/")>
	
	<!--- handle makeunique when moving --->
	<cfif structkeyexists(arguments, "nameconflict") and arguments.nameconflict eq "makeunique">
	
		<cfif fileexists(loc.finaldestination)>
			<cfset loc.cffile["serverFileName"] = loc.cffile["serverFileName"] & gettickcount()>
			<cfset loc.cffile["serverFile"] = listappend(loc.cffile["serverFileName"], loc.cffile["serverFileExt"], ".")>
			<cfset loc.finaldestination = listappend(loc.destination, loc.cffile["serverFile"], "\/")>
		</cfif>
	
	</cfif>

	<!--- forgot to handle mode in unix --->
	<cfset loc.args = {}>
	<cfset loc.args.action = "move">
	<cfset loc.args.source = "#loc.fileuploaded#">
	<cfset loc.args.destination = "#loc.finaldestination#">
	<cfif structkeyexists(arguments, "mode")>
		<cfset loc.args.mode = "#arguments.mode#">
	</cfif>

	<!--- move the file --->
	<cffile attributeCollection="#loc.args#">

	<!--- append the mimetype to the returning structure for convinence --->
	<cfset loc.cffile.mimetype = listfirst(loc.mimetypes[loc.cffile["serverFileExt"]])>
	<cfif structkeyexists(loc, "filemimetype")>
		<cfset loc.cffile.mimetype = loc.filemimetype>
	</cfif>
	
	<cfreturn loc.cffile>
</cffunction>