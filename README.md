#CFFileUpload
##Replacement for CFFILE to prevent the MIME/FILE upload security vulnerability 

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

###Instead of:

	<cffile
		action="UPLOAD"
		filefield="form.thefile"
		destination="#expandpath('.')#"
		nameconflict="MAKEUNIQUE">
	<cfset form.thefile = cffile.serverfile>

###You replace with:

	<!--- In this example I cached all my UDF into a struct called functions within the application scope --->
	<cfset myfile = application.functions.cffileupload(
		,filefield="form.thefile"
		,destination="#expandpath('.')#"
		,nameconflict="MAKEUNIQUE"
		)>
	<cfset form.thefile = myfile.serverfile>

##Advanced Features

Besides being a dropin replacement, CFFileUpload also allows you to do some advanced stuff as well such as:

- You can append the list of bad extensions to further lock down your application
- You can add additional mimetypes or overload the already supported ones
- You can allow a custom extension to be valid

##Arguments

###deleteBadFile (boolean)

Set to *true* by default. Tells the function to delete the uploaded file from the directory when it throws an error.

By default any invalid files will be deleted from the ColdFusion Temp directory. By setting this argument to *false*
the files will be kept. This can be used to analyze what security attempts are being used to target the server.

###badExtensions (string)

Blank by default. Appends a list of extensions to the internal extensions list that shouldn't be uploaded.

To prevent malicious files from being uploaded, CFFileUpload maintains an internal list of extensions
that cannot be uploaded. This internal list CANNOT be overwritten, however it can be appended to include other
extensions that the user wants to prevent from being uploaded. The following extension are in this internal list:

	cfm,cfml,cfc,dbm,jsp,asp,aspx,exe,php,cgi,shtml

###mimeTypes (struct)

Empty by default. Allows to extend or replace the internal list of MIME types.

In order for an extension to have permission to be uploaded it must have a MIME type registered with it. When a file
is uploaded, CFFileUpload tries to determine MIME type by checking the registered MIME types on the server using:

	getPageContext().getServletContext().getMimeType()
	
If it finds that the MIME type is registered it will use make sure that the extension of the file uploaded matches the
MIME types associated with the extension from the internal mimetypes structure. If the file's extension doesn't match
an associated MIME type, it is invalid.

However sometimes an extension must be allowed to be uploaded even though the MIME type is not  registered on the server.
This could be because the site is in a shared hosting environment or has other restrictions. By appending the internal list
with custom extensions and MIME types, you can allow for these files to be uploaded.

The default list of MIME types are as follows:

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