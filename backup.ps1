#takes the file used to create a backup job on frmc-vmback01 and adds 5hrs or so to frmc-vmback02 to backup to the other exagrid site

#$ints = Import-csv "backup-test.csv"

#for ($i=0; $i -le $ints.Length – 1; $i++)
#{Write-Host $ints[$i]}

#foreach ($i in $ints)
#{Write-host $i}

$backups = Import-csv "backup-list.csv"

foreach ($i in $backups){
#for ($i=0; $i -le $backups.Length – 1; $i++)


$JobName = $i.VM
$Repo = $i.Target


if (Get-VBRJob -name $Jobname) {

	Write-Host 'Job ' $JobName ' Exists'
	
	}
Else {	

	Write-Host 'Add-VBRViBackupJob -Name' $JobName '-BackupRepository (Get-VBRBackupRepository -Name' $Repo') -Entity (Find-VBRViEntity -Name' $i.VM')'
	Add-VBRViBackupJob -Name $JobName -BackupRepository (Get-VBRBackupRepository -Name $Repo) -Entity (Find-VBRViEntity -Name $i.VM) 

	#function Set-VeeamBackupOptions
	#   {
	#   param   (
	#         [Parameter](
	#         Position=0, 
	#              Mandatory=$true, 
	#              ValueFromPipeline=$true,
	#              ValueFromPipelineByPropertyName=$false)
	#         ]
	#         [Veeam.Backup.Core.CBackupJob]$Job
	#         )
	#Set Job Options
   
	$Job = Get-VBRJob | where {$_.name -eq $JobName}
   
	$JobOptions = Get-VBRJobOptions $Job 
      $JobOptions.BackupStorageOptions.RetainCycles = 30
      $JobOptions.JobOptions.SourceProxyAutoDetect = $true
      $JobOptions.JobOptions.RunManually = $false
      $JobOptions.BackupStorageOptions.RetainDays = 30
      $JobOptions.BackupStorageOptions.EnableDeduplication = $true
      $JobOptions.BackupStorageOptions.StgBlockSize = "KbBlockSize512"
	  $JobOptions.BackupStorageOptions.CompressionLevel = 0
      $JobOptions.BackupTargetOptions.Algorithm = "Increment"
      $JobOptions.BackupTargetOptions.TransformToSyntethicDays = ((Get-Date).adddays((Get-Random -Minimum 0 -Maximum 6))).dayofweek
      $JobOptions.BackupTargetOptions.TransformIncrementsToSyntethic = $false
	  
	  $JobOptions.BackupStorageOptions.EnableFullBackup = $true
	  $JobOptions.BackupTargetOptions.FullBackupScheduleKind = "Monthly"
	  $JobOptions.BackupTargetOptions.FullBackupMonthlyScheduleOptions.DayNumberInMonth = (Get-Random -Minimum 1 -Maximum 4)
	  $JobOptions.BackupTargetOptions.FullBackupMonthlyScheduleOptions.DayOfWeek = ((Get-Date).adddays((Get-Random -Minimum 0 -Maximum 6))).dayofweek
	  
   $Job | Set-VBRJobOptions -Options $JobOptions

   #Set schedule options
      #Create random backup time between 6PM and 4AM
	#	$Hours = (18,19,20,21,22,23,'00','01','02','03','04') | Get-Random | Out-String
	#	$Minutes = "{0:D2}" -f (Get-Random -Minimum 0 -Maximum 59) | Out-String
	#	$Time = ($Hours+':'+$Minutes+':00').replace("`n","")
	$HR = $i.Hour	
	[int]$HR

	$HR = 5 + $HR 
	
	If ($HR -gt 6){
		If ($HR -lt 17){
			$HR = 10 + $HR
		}
		If ($HR -eq 24){
			$HR = 0
		}
		If ($HR -gt 24){
			$HR = $HR - 24
		}
	}
	$HR = "{0:D2}" -f $HR
	
	[string]$HR
	
	$Time = ($HR+':00:00')
	
      
   $JobScheduleOptions = Get-VBRJobScheduleOptions $Job 
      $JobScheduleOptions.OptionsDaily.Enabled = $true
      $JobScheduleOptions.OptionsDaily.Kind = "Everyday"
      $JobScheduleOptions.OptionsDaily.Time = $Time
      $JobScheduleOptions.NextRun = $Time
      $JobScheduleOptions.StartDateTime = $Time
   $Job | Set-VBRJobScheduleOptions -Options $JobScheduleOptions
   $Job.EnableScheduler()

   #Set VSS Options
   #$JobVSSOptions = $Job | Get-VBRJobVSSOptions
    #  $VSSUSername = 'DOMAIN\USERNAME'
     # $VSSPassword = 'PASSWORD'
      #$VSSCredentials = New-Object -TypeName Veeam.Backup.Common.CCredentials -ArgumentList $VSSUSername,$VSSPassword,0,0
    #  $JobVSSOptions.Credentials = $VSSCredentials
    #  $JobVSSOptions.Enabled = $false
      #Change default behavior per job object
    #  foreach ($JobObject in ($Job | Get-VBRJobObject))
    #     {
    #     $ObjectVSSOptions = Get-VBRJobObjectVssOptions -ObjectInJob $JobObject
    #     $ObjectVSSOptions.IgnoreErrors = $true
     #    Set-VBRJobObjectVssOptions -Object $JobObject -Options $ObjectVSSOptions
     #    }
   #$Job | Set-VBRJobVssOptions -Options $JobVSSOptions
   #}
   
   
   
	#$VMNames = @("VM1","VM2","VM3","VM4","VM5")

}
}