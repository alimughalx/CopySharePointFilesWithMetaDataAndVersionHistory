Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue
 
#Copy Files from Source Folder to Target
Function Copy-Files($SourceFolder, $TargetFolder)
{
    write-host "Copying Files from:$($SourceFolder.URL) to $($TargetFolder.URL)"
    #Get Each File from the Source
    $SourceFilesCollection = $SourceFolder.Files
    
    #Iterate through each item from the source
    Foreach($SourceFile in $SourceFilesCollection)
    {
        $CountFileVersions = $SourceFile.Versions.Count
        #Get the created by and created
        $CreatedBy = $SourceFile.Author;
        #Convert the "TimeCreated" property to local time
        $CreatedOn = $SourceFile.TimeCreated.ToLocalTime();
        #Loop Through Each File Version
        for ($i = 0; $i -le $CountFileVersions; $i++){
            #Initialize variables
            $SourceProp;
            $FileStream;
            $ModifiedBy;
            $ModifiedOn;
            $VersionComment = "";
            $MajorVer = $False;
            #If Index is not the Last Published Version
            if ($i -lt $CountFileVersions){
                      #Get all versions file, history, properties, createdBy, checkInComment
                      $fileSourceVer = $SourceFile.Versions[$i];
                      $SourceProp = $fileSourceVer.Properties;
                      $ModifiedBy = If ($i -eq 0) {$CreatedBy}  ELSE {$fileSourceVer.CreatedBy};
                      $ModifiedOn = $fileSourceVer.Created.ToLocalTime();
                      $VersionComment = $fileSourceVer.CheckInComment;
                      $MajorVer = If ($fileSourceVer.VersionLabel.EndsWith("0")) {$True} Else {$False}
                      $FileStream = $fileSourceVer.OpenBinaryStream();
            }
            else {
                       #Get current versions file, history, properties, createdBy, checkInComment
                       $ModifiedBy = $SourceFile.ModifiedBy;
                       $ModifiedOn = $SourceFile.TimeLastModified;
                       $SourceProp = $SourceFile.Properties;
                       $VersionComment = $SourceFile.CheckInComment;
                       $MajorVer = If ($SourceFile.MinorVersion -eq 0) {$True} Else {$False}
                       $FileStream = $SourceFile.OpenBinaryStream();
            }
            #URL library destination
            $DestFileURL = $TargetFolder.URL + "/" + $SourceFile.Name;
            #Add initial File to destination library         
            $DestFile = $TargetFolder.Files.Add($DestFileURL, $FileStream, $SourceProp, $CreatedBy, $ModifiedBy, $CreatedOn, $ModifiedOn, $VersionComment, $True);
            #If Major Version Publish it
            if ($MajorVer){
                $DestFile.Publish($strVerComment);
            }   
            else{
                #Update all previous file versions
                $itmNewVersion = $DestFile.Item;
                $itmNewVersion["Created"] = $dateCreatedOn;
                $itmNewVersion["Modified"] = $dateModifiedOn;
                $itmNewVersion.UpdateOverwriteVersion();
            }                  
        }
     
        Write-host "File:"$SourceFile.Name ." is uploaded successfully with version count:" $countVersions
    }
     
    #Process SubFolders
    Foreach($SubFolder in $SourceFolder.SubFolders)
    {
        if($SubFolder.Name -ne "Forms")
        {
            #Check if Sub-Folder exists in the Target Library!
            $NewTargetFolder = $TargetFolder.ParentWeb.GetFolder($SubFolder.Name)
  
            if ($NewTargetFolder.Exists -eq $false)
            {
                #Create a Folder
                $NewTargetFolder = $TargetFolder.SubFolders.Add($SubFolder.Name)
            }
            #Call the function recursively
            Copy-Files $SubFolder $NewTargetFolder
        }
    }
}
 
#Variables for Processing
$WebURL="http://Weburl/"
$SourceLibrary ="SourceLibrary"
$TargetLibrary = "DestinationLibrary"
 
#Get Objects
$Web = Get-SPWeb $WebURL
$SourceFolder = $Web.GetFolder($SourceLibrary)
$TargetFolder = $Web.GetFolder($TargetLibrary)
 
#Call the Function to Copy All Files
Copy-Files $SourceFolder $TargetFolder
