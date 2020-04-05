<#
Purpose - This is to sync local folder with AWS S3 in real time
Developer - K.Janarthanan
Date - 4/4/2020
Replace the following parameters in the script according to your need
    1. $Global:folder_path="D:\\Sync_Folder" #Make sure to put \\ for folder path. If not path will not be detected.
    2. $Global:bucketname='jana-sync' #AWS S3 Bucket
#>

#Input parameters
$Global:folder_path="D:\\Sync_Folder" #Make sure to put \\ for folder path. If not path will not be detected.
$Global:bucketname='jana-sync' #AWS S3 Bucket

#Creating File Monitor
$monitor=New-Object System.IO.FileSystemWatcher

#Include all subdirectories for monitoring
$monitor.IncludeSubdirectories=$true

#Monitoring path
$monitor.Path=$folder_path

#Create Events when new events captured
$monitor.EnableRaisingEvents=$true

$Global:old_msg=""

$command_action=
{
    $file_path=$event.SourceEventArgs.FullPath
    $changetype=$event.SourceEventArgs.changetype
    $old_file=$event.SourceEventArgs.OldName

    $msg="$file_path was $changetype at $(Get-Date)"

    #To filter same events captured twice. Checking the current message with previous message
    if($Global:old_msg -ne $msg)
    {          
        if($changetype -eq 'Renamed')
        {
            $rename_msg="$old_file was renamed to $file_path at $(Get-Date)"
            #Write-Host $rename_msg
            Write-EventLog -LogName"Application" -Source "AWS Sync" -EntryType Information -EventId 3050 -Message $rename_msg
        }
     
        $arguments="s3 sync $Global:folder_path s3://$Global:bucketname --delete"
       
        Start-Process aws -ArgumentList $arguments -Wait -NoNewWindow
        #Write-Host $msg
        Write-EventLog -LogName "Application" -Source "AWS Sync" -EntryType Information -EventId 3050 -Message $msg

    }

    $Global:old_msg=$msg
    
}

#Registering Events
Register-ObjectEvent $monitor 'Created' -Action $command_action
Register-ObjectEvent $monitor 'Deleted' -Action $command_action
Register-ObjectEvent $monitor 'Changed' -Action $command_action
Register-ObjectEvent $monitor 'Renamed' -Action $command_action

while(1)
{

}
