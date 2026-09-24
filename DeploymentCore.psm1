Function New-MYCredsGet{
[CMDLetBinding()]
param(
[ValidateScript({[System.IO.Directory]::Exists($_)})]
[string]$SaveToPath,
[Switch]$Encrypt
)
BEGIN{
$MyCredentialObject = $null;
$MyCredentialObject = New-Object -TypeName PSObject -Property ([ordered]@{DNUN = $null; Password = $null});
$ByteKey = New-Object Byte[] 32;# You can use 16, 24, or 32 for AES;
#Write-Verbose $ByteKey
}
PROCESS{
    $getcreds=Get-Credential;
        if(!$PSBoundParameters.ContainsKey('Encrypt')){
        Write-Verbose "Encrypt switch not set";
         $MyCredentialObject.DNUN=$getcreds.UserName;
         $MyCredentialObject.Password=$getcreds.GetNetworkCredential().Password;
        }
    switch ($true){
        {$PSBoundParameters.ContainsKey('Encrypt')}{
        Write-Verbose "Encrypt switch is set";
         [Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($ByteKey);
         $gtrsltsecpass=$getcreds.GetNetworkCredential().SecurePassword;
         $MyCredentialObject.Password=ConvertFrom-SecureString -SecureString $gtrsltsecpass -Key $ByteKey;
         $gtrsltcredsUsername=$getcreds.UserName;
         $crtsecstringusername=ConvertTo-SecureString -String $gtrsltcredsUsername -AsPlainText -Force;
         $convertusernamesec=ConvertFrom-SecureString -SecureString $crtsecstringusername -Key $ByteKey;
         $MyCredentialObject.DNUN = $convertusernamesec;
         if(!$PSBoundParameters.ContainsKey('SaveToPath')){
         Write-Verbose "Encrypt switch key is set without SaveToPath parameter.`nAdd to existing object decrypt key member"
         Add-Member -InputObject $MyCredentialObject -MemberType NoteProperty -Name DecryptKey -Value $ByteKey;
         }
        }
    }
    switch($true){
        {$PSBoundParameters.ContainsKey('SaveToPath')}{
        Write-Verbose "Save to path $SaveToPath";
         $filenameAddDate=$SaveToPath+"\"+((([datetime]::Now).ToString()) -replace ":| |\.","-");
         if($null -ne $ByteKey){
           $ByteKey|Out-File -FilePath "$("{0}{1}" -f $filenameAddDate, ".key")";
         }
         $MyCredentialObject|Export-Clixml -Path "$("{0}{1}" -f  $filenameAddDate,"_creds2.xml")";
        }
     }
}
END{
    return $MyCredentialObject
}
}

Function Get-MyDecryptSet{
[CmdLetBinding()]
param(
[switch]$Decrypt=[switch]::Present,
[string]$SourceString,
[byte[]]$BytesKey
)
BEGIN{
    $resultstring=$null;
}
PROCESS{
  switch($true){
    {!$Decrypt.IsPresent}{
    Write-Verbose "Decrypt switch disabled"
    $resultstring=$SourceString;
    }
  }
  switch($true){
   {$Decrypt.IsPresent}{
    Write-Verbose "Decrypt switch enabled"
     $secstringconvert =  ConvertTo-SecureString -String $SourceString -Key $BytesKey;
     $BSTR1 = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secstringconvert);
     $resultstring = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($BSTR1);
     [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR1);
   }
  }

}
END{
    return $resultstring;
}
}

function Get-FolderSizeByComObjct {
    param (
        #ParameterSet: FullNamePath
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$FullNamePath
    )
    begin{
        $fsobj=New-Object -ComObject Scripting.FileSystemObject;
    }
    process{
        $fldr=$fsobj.GetFolder($FullNamePath);
        $clcsze=$fldr.Size;
    }
    end{
        $clcsze;
    }
}#end Function

<#function Get-MYDiskInfo {
    param (
        [Parameter(Mandatory = $false, Position = 0)]
        [uint16[]]$DiskNumbers = $null,
        [Parameter(Mandatory = $false, Position = 1)]
        [ValidateSet("Unknown", "SCSI", "ATAPI", "ATA", "IEEE", "SSA",
            "Fibre Channel", "USB", "RAID", "iSCSI", "SAS", "SATA", "SD",
            "MMC", "Virtual", "File-Backed Virtual", "Storage Spaces", "NVMe")]
        [string[]]$FilterByBusType,
        [Parameter(Mandatory = $false, Position = 2)]
        [double]$SizeGreaterOrEqualInGB,
        [Parameter(Mandatory=$false,Position = 3)]
        [switch]$ShowIntegrated,
        [Parameter(Mandatory=$false,Position = 4)]
        [switch]$ShortFormatOutput
    )
    BEGIN {
        [array]$slctitm = $null;
    }
    PROCESS {

        [array]$GetDiskInf = Get-CimInstance -Namespace Root\Microsoft\Windows\Storage -Class msft_disk;

        if ( $PSBoundParameters.ContainsKey('DiskNumbers')) {
            if ($GetDiskInf.Count -gt 0) {
                for ($idisknum = 0; $idisknum -le ($DiskNumbers.Count - 1); $idisknum++) {
                    foreach ($iteminf in $GetDiskInf) {
                        if ($iteminf.Number -eq $DiskNumbers[$idisknum]) {
                            [array]$slctitm += $iteminf;
                        }
                    }
                }
            }
        }

        if ($PSBoundParameters.ContainsKey('FilterByBusType')) {
            if ($GetDiskInf.Count -gt 0) {
                [uint16]$swbustype = 0;
                for ($busindex = 0; $busindex -lt ($FilterByBusType.Count - 1); $busindex++) {
                    switch ($FilterByBusType[$busindex]) {
                        "Unknown" { [uint16]$swbustype = 0; break }
                        "SCSI" { [uint16]$swbustype = 1; break }
                        "ATAPI" { [uint16]$swbustype = 2; break }
                        "ATA" { [uint16]$swbustype = 3; Break }
                        "IEEE 1394" { [uint16]$swbustype = 4; Break }
                        'SSA' { [uint16]$swbustype = 5; break }
                        'Fibre Channel' { [uint16]$swbustype = 6; break }
                        "USB" { [uint16]$swbustype = 7; break }
                        "RAID" { [uint16]$swbustype = 8; break }
                        "iSCSI" { [uint16]$swbustype = 9; break }
                        "SAS" { [uint16]$swbustype = 10; break }
                        "SATA" { [uint16]$swbustype = 11; break }
                        "SD" { [uint16]$swbustype = 12; break }
                        "MMC" { [uint16]$swbustype = 13; break }
                        "Virtual" { [uint16]$swbustype = 14; break }
                        "File-Backed Virtual" { [uint16]$swbustype = 15; break }
                        "Storage Spaces" { [uint16]$swbustype = 16; break }
                        "NVMe" { [uint16]$swbustype = 17; break }
                        Default { [uint16]$swbustype = 0; }
                    }
                    foreach ($itmdisk in $GetDiskInf) {
                        if ($itmdisk.BusType -eq [uint16]$swbustype) {
                            [array]$slctitm += $itmdisk;
                        }
                    }
                }
            }
        }

        if ($PSBoundParameters.ContainsKey('SizeGreaterOrEqualInGB')) {
            foreach ($itemindxdisk in $GetDiskInf) {
                [double]$CalcGBSize = ($itemindxdisk.Size) / 1GB;
                if ($CalcGBSize -ge $SizeGreaterOrEqualInGB) {
                    [array]$slctitm += $itemindxdisk;
                }
            }
        }
        if ($ShortFormatOutput.IsPresent) {
            $GetDiskInf | Select-Object Number, Model, SerialNumber,
            @{label = "BusType"; Expression = {
                    switch ($_.BusType) {
                        0 { "Unknown" }
                        1 { "SCSI" }
                        2 { "ATAPI" }
                        3 { "ATA" }
                        4 { "IEEE 1394" }
                        5 { 'SSA' }
                        6 { 'Fibre Channel' }
                        7 { "USB" }
                        8 { "RAID" }
                        9 { "iSCSI" }
                        10 { "SAS" }
                        11 { "SATA" }
                        12 { "SD" }
                        13 { "MMC" }
                        14 { "Virtual" }
                        15 { "File-Backed Virtual" }
                        16 { "Storage Spaces" }
                        17 { "NVMe" }
                    }
                }
            }, @{label = 'Size'; Expression = { "$([math]::Round(($_.Size)/1GB,4)) GB" } }, Location
        }
    }
    END {
        return $slctitm
    }
}#end Function
#>
function Get-StoragePointsInfo {
    param (
        [uint32]$Disk_Number,
        [string]$Partition_Letter,
        [string]$Disk_Serial_Number,
        [string]$Disk_Model,
        [string]$t_Path
    )
    
    begin {
        [array]$GetDiskInfo=$null;
        [array]$GetPartitionInfo=$null;
        [array]$Test_Result=$null;
    }
    
    process {
        [array]$GetPartitionInfo = Get-WmiObject -Namespace Root\Microsoft\Windows\Storage -Class MSFT_Partition;
        [array]$GetDiskInfo = Get-WmiObject -Namespace Root\Microsoft\Windows\Storage -Class MSFT_Disk;
        if ($GetDiskInfo.Count -gt 0 -and $GetPartitionInfo.Count -gt 0){
        if($PSBoundParameters.Count -eq 0){$Test_Result = $GetPartitionInfo|ForEach-Object{
            $select_disk_number = $_.DiskNumber;
            $_|Select-Object DiskNumber,PartitionNumber,DriveLetter,@{label='Model';Expression = {
            ($GetDiskInfo|Where-Object{$_.Number -eq $select_disk_number}).Model}},@{Label='Disk_SerialNumber';Expression = {
            ($GetDiskInfo|Where-Object{$_.Number -eq $select_disk_number}).SerialNumber}},@{Label='Size';Expression = {
            (($GetDiskInfo|Where-Object{$_.Number -eq $select_disk_number}).Size)/1GB}}
            }}
        if ($PSBoundParameters.Count -gt 1) {
            $Test_Result = $GetDiskInfo|Where-Object{
                (($_.Model).Trim() -eq $Disk_Model) -and (($_.SerialNumber).Trim() -eq  $Disk_Serial_Number)};
        }
            if ($PSBoundParameters.Count -eq 1) {
            
                switch ($PSBoundParameters) {
                    { $_.ContainsKey('Disk_Serial_Number') } { $Test_Result = $GetDiskInfo |Where-Object{try{($_.SerialNumber).Trim() -eq $Disk_Serial_Number}catch{}}; Break }
                    { $_.ContainsKey('Disk_Model') } { $Test_Result = $GetDiskInfo|Where-Object{try{(($_.Model).Trim()) -eq $Disk_Model}catch{}}; Break }
                    { $_.ContainsKey('Disk_Number') } { $Test_Result = $GetDiskInfo|Where-Object{try{($_.Number) -eq $Disk_Number}catch{}}; Break; }
                    { $_.ContainsKey('Partition_Letter') } {$Partition_Letter=(($Partition_Letter.ToUpper()) -replace "[^A-Z]",'').Substring(0,1);
                     $Test_Result = $GetPartitionInfo|Where-Object{try{ $_.DriveLetter -eq $Partition_Letter}catch{} }; Break; }
                    { $_.ContainsKey('t_Path') } {
                        $Test_Result = $GetPartitionInfo | ForEach-Object {
                            [string]$t_create_Path = $_.DriveLetter + ':' + '\' + $t_Path;
                            if (Test-Path -Path $t_create_Path) { return $_ }
                        }; Break;
                    }
                }
            }
        }
    }
    
    end {
        return $Test_Result
    }
}#end function
function Start-TryEjectUsbDrive {
    param(
    # Parameter help description
    [Parameter(Mandatory=$false,Position=0)]
    [String]$EjectByLabel,
    # Parameter help description
    [Parameter(Mandatory=$false,Position=1)]
    [string]$EjectByLetter,
    # Parameter help description
    [Parameter(Mandatory=$false,Position=2)]
    [switch]$EjectEveryUSB
    )
    BEGIN{
        $crtshapl = $null;
        [string]$GetDriveLetter=$null;
    }
    PROCESS{
        $crtshapl = New-Object -ComObject Shell.Application;
        if ($PSBoundParameters.ContainsKey('EjectByLabel')) {
            while ([string]::IsNullOrEmpty($EjectByLabel)) {
                $EjectByLabel = Read-Host "Enter part of dirve label that you want to eject";
            }
            try {
                $GetDriveLetter = (Get-WmiObject win32_volume | Where-Object { $_.Label -eq "$EjectByLabel" }).DriveLetter;
            }
            catch {
                Write-Host "Please, ensure your typed label is present for any pluged device" -ForegroundColor Red -BackgroundColor Black;
            }
        }
        if ($PSBoundParameters.ContainsKey('EjectByLetter')) {
            while ([string]::IsNullOrEmpty($EjectByLetter)) {
                $EjectByLetter= Read-Host "Type drive letter here, please";
            }
            $EjectByLetter=$EjectByLetter.ToUpper();
            if ($EjectByLetter.Length -gt 1) {
                $EjectByLetter=$EjectByLetter.Substring(0,1);
            }
            $GetDriveLetter=$EjectByLetter+':';
            
        }
        if ($EjectEveryUSB.IsPresent) {
            [string[]]$LetterToEject=$null;
            [array]$GetPluggedVolumeInfo=Get-WmiObject Win32_Volume -Filter "DriveType='2'";
            if ($GetPluggedVolumeInfo.Count -gt 0) {
                foreach ($itemvol in $GetPluggedVolumeInfo) {
                    if (-not [string]::IsNullOrEmpty("$($itemvol.DriveLetter)")) {
                        $LetterToEject+=($itemvol.DriveLetter);
                    }
                }
                try {
                    $crtshapl.NameSpace(17).ParseName($LetterToEject).InvokeVerb("Eject");
                }
                catch {
                    Write-Host "$Error"
                }
            }
        }
    }
    END{
        if ($GetDriveLetter.Length -gt 0) {
            $crtshapl.NameSpace(17).ParseName($GetDriveLetter).InvokeVerb("Eject");
        }
    }
}#end Function
function Get-CalculationDirsSize {
    param (
        #ParameterSet: ArrayForCalculation
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,Position = 0,
            HelpMessage = "Need a strings array 
            or a single string with directories path 
            or Drive Letter with backslash")]
        [alias("FN")]
        [String[]]
        $ArrayForCalculation
    )
    begin{
        [double]$totalsizecounter= $null;
        [string]$switchtxtSize = $null;
        [double]$switchtxtTtlSz= $null;
    }
    process{
        if ($ArrayForCalculation.Count -gt 0) {
            foreach ($Diritem in $ArrayForCalculation) {
                if (Test-Path -Path $Diritem) {
                    if ((Get-Item -Path $Diritem -Force -EA 0).PSIsContainer) {
                        Get-ChildItem -Path $Diritem -Force -Recurse -EA 0 | ForEach-Object {
                            $totalsizecounter += $_.Length;
                            [System.Console]::Write("`rbytes calculated: $totalsizecounter");
                        }
                    } else {
                        $totalsizecounter += (Get-Item -Path $Diritem -Force -EA 0 ).Length;
                        [System.Console]::Write("`rbytes calculated: $totalsizecounter");
                    }
                }
            }
            Write-Host "`n";
        }
        switch ($totalsizecounter) {
            { $_ -gt 1MB } { $switchtxtSize = "MegaBytes";}
            { $_ -gt 1GB } { $switchtxtSize = "GigaBytes";}
              Default      { $switchtxtSize= "Bytes";     }
        }
        switch ($totalsizecounter) {
            { $_ -gt 1MB } { $switchtxtTtlSz = [Math]::Round(($totalsizecounter / 1MB), 3) }
            { $_ -gt 1GB } { $switchtxtTtlSz = [Math]::Round(($totalsizecounter / 1GB), 3) }
              Default      { $switchtxtTtlSz = $totalsizecounter;                          }
        }
    }
    end{
        $psobjtablecalcreslt=New-Object -TypeName psobject `
        -Property ([ordered]@{RoundedCalculation="$switchtxtTtlSz $switchtxtSize";SizeInBytes=$totalsizecounter});
        return $psobjtablecalcreslt;
    }
}#end function
function Start-Myrobocopyingfiles {
    [CmdletBinding()]
    param(
        #ParameterSet: SourcePath, DestinationPath, NamedContainer
        [Parameter(
            Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [string]$SourcePath,
        [Parameter(
            Mandatory = $true, Position = 1)]
        [string]$DestinationPath,
        [Parameter(Mandatory = $false, Position = 2)]
        [Alias("separate")]
        [switch]$NamedContainer = [switch]::Present
    )
    begin {
        $ChldsArray=@();
        [double]$TotalSizeLength = $null;
        [double]$CounterSizeLength=0;
    }
    process {
        #Test source
        if (!(Test-Path -Path $SourcePath)) {
            Write-Host "`n Source path not exists" -ForegroundColor Red;
            Break;
        }
        $GetSourceItem = Get-Item -Path $SourcePath -Force -EA 0;
        [string]$IFSourceFileOrDir = $null;
        if ($GetSourceItem.PSIsContainer) {
            $IFSourceFileOrDir = "$GetSourceItem" + "\*";
        }
        else {
            $IFSourceFileOrDir = "$GetSourceItem";
        }
        #Switch argument processing
        if ($NamedContainer.IsPresent) {
            [string]$SourcePathParentName = $GetSourceItem.Name;
            [string]$SourcePathParentRoot = $GetSourceItem.Root;
            if ($SourcePathParentName -ne $SourcePathParentRoot) {
                $DestinationPath = $DestinationPath + "\\" + $SourcePathParentName;
            }
        }
        #Test destination
        if (-not(Test-Path -Path $DestinationPath)) {
            try {
                mkdir $DestinationPath | Out-Null;
            }
            catch {
                Write-Host -Object "Cann't create destination" -ForegroundColor Red;
                Break;
            }
        }
        if (Test-Path -Path $DestinationPath) {
            $DestinationPath = Get-Item -Path $DestinationPath -Force;
            [string]$FLLDestPath = $DestinationPath;
            Write-Host " directory exists: $FLLDestPath `n";
        }
        else {
            Write-host "Destination not created. Something went wrong... Break." -ForegroundColor Red;
            Break;
        }
        Write-Host "`n Collecting items inforamtion about source, please waiting..." -ForegroundColor Yellow;
        $GIContentIfWthAster = @(Get-Item -Path $IFSourceFileOrDir -Force -EA 0);
        $GIContentIfWthAster | ForEach-Object {
            $queueditemFullName=$_.FullName;
            $queueditemIsContainer=$_.PSIsContainer;
            if ($queueditemIsContainer -eq $true) {
                $ChldsArray += $queueditemFullName; 
                (Get-ChildItem -Path $_.FullName -Force -Recurse -EA 0) | ForEach-Object {
                    $ChldsArray += $_.FullName;
                    $TotalSizeLength += $_.Length; 
                    $DoRsltInGB = [math]::Round($TotalSizeLength / 1GB, 9);
                    #[string]$CalcstringofItemBytes = "`r Total Size in GB: {0,6}" -f $dorsltinGB;
                    [System.Console]::Write("`r Total Size in GB: {0,6}" -f $DoRsltInGB);
                }
            } else {
                $ChldsArray += (Get-Item -Path $_.FullName -Force -EA 0).FullName;
                $TotalSizeLength += (Get-Item -Path $_.FullName -Force -EA 0).Length;
                $DoRsltInGB = [math]::Round($TotalSizeLength / 1GB, 9);
                #[string]$CalcstringofItemBytes = "`r Total Size in GB: {0,6}" -f $dorsltinGB;
                [System.Console]::Write("`r Total Size in GB: {0,6}" -f $DoRsltInGB);
            }
        }
        Write-Host "`n Information collected.";
        Write-Host "Start copying files...`n";
        $ChldsArray|ForEach-Object{
            [double]$CurrentFLSizeLength=0;
            [string]$FullNameFile=$_;
            [string]$destedititem=$FullNameFile.Replace("$(($GetSourceItem).Fullname)","$DestinationPath\");
            $iteminfo=(Get-Item -Path $FullNameFile -Force -EA 0);
            $CurrentFLSizeLength=$iteminfo.Length;
            $CounterSizeLength+=$CurrentFLSizeLength;
            [double]$reslthalf=($CounterSizeLength/$TotalSizeLength);
            $PercentComplete=[Math]::Round(($reslthalf*100),2);
            #Write-Progress -Activity "Copying files from $SourcePath" -Status "copy file $($iteminfo.Name). Percent complete: $PercentComplete";
            Copy-Item -Path $FullNameFile -Destination $destedititem -Force -ErrorAction 0;
            $ConsoleWriteRlstString="`r Complete: {0,8} % of Total Bytes: {1,-8} GB" -f $PercentComplete,$DoRsltInGB;
            [System.Console]::Write("$ConsoleWriteRlstString");
        }
        [System.Console]::WriteLine("`n");
        $htTotalSizeLength=New-Object -TypeName PSObject -Property (@{TotalSize=$TotalSizeLength});
    }
    end {
        return $htTotalSizeLength;
    }
}#end myrobocopyingfiles
function Set-ObjectPremissionForCurrentUser {
    param (
        #ParameterSet: ArrayOfFullNamePathes
        [Parameter(Mandatory = $true)]
        [string[]]
        $ArrayOfFullNamePathes
    )
    begin {
        $setuprigthforsystem = "FullControl";
        #$inheritanceforrul='ContainerInherit,ObjectInherit';
        #$propagationforrule='None';
        $AccessType = 'Allow';
    }
    process {
        $SysAccessRule = New-Object System.Security.AccessControl.FilesystemAccessRule("$env:USERNAME", $setuprigthforsystem, $AccessType);
        Write-Host "Working on folders premission" -ForegroundColor Cyan;
        foreach ($i in $ArrayOfFullNamePathes) {
            if (Test-Path $i) {
                $GetACL = Get-Acl -Path ((Get-Item $i -Force).Root);
                if ((Get-Item $i -Force -EA 0).PSIsContainer) {
                    (Get-Acl -Path ((Get-Item $i -Force).FullName)).SetAccessRuleProtection($false, $true);
                    (Get-Acl -Path ((Get-Item $i -Force).FullName)).SetAccessRule($SysAccessRule);
                    Write-Progress -Activity "setup premissions for" -Status "$i" -ErrorAction SilentlyContinue;
                    Set-Acl -Path ((Get-Item $i -Force).FullName) -AclObject $GetACL;
                }
            }
        }
        foreach ($childI in $ArrayOfFullNamePathes) {
            if (Test-Path -Path $childI) {
                    $getXIACL = Get-ACL -Path $childI;
                    $getXIACL.SetAccessRule($SysAccessRule)
                    Set-Acl -Path $childI -AclObject $getXIACL
                    (Get-ChildItem -Path $childI -Force -Recurse -EA 0) | ForEach-Object {
                        $FSObject = $_.FullName
                        Write-Progress -Activity "setup premissions for" -Status "$FSObject" -ErrorAction SilentlyContinue;
                        Set-Acl -Path $FSObject -AclObject $getXIACL -ErrorAction SilentlyContinue;
                    }
            }
        }#
    }
    end {
        Write-Host "Premission setup done" -ForegroundColor Cyan;
    }
}#end function
function Get-UnlockDriveWithNumericalPassword {
    param (
        #ParameterSet: TxtFilePathOrKeyString
        [Parameter(Mandatory = $false, Position = 0,ValueFromPipeline=$true)]
        [Alias('akey','afile')]
        [String]$TxtFilePathOrKeyString
    )

    BEGIN{
        [string]$setDrv = $null;
        [array]$mywin32_encryptablevolume = $null;
        [array]$filterencrypteddrivesby1 = $null;
        [string]$TPass=$null;
        [string[]]$ArrayOfStringsInTxtFile1=$null;
    }

    PROCESS{

        [array]$mywin32_encryptablevolume = Get-WmiObject -NameSpace "Root\cimv2\security\MicrosoftVolumeEncryption" `
        -ClassName "win32_EncryptableVolume"|Where-Object {$_.DriveLetter -gt 0};

        $filterencrypteddrivesby1 =$mywin32_encryptablevolume| `
        Where-Object {($_.EncryptionMethod -gt 0) -and ($_.GetLockStatus().LockStatus -gt 0)};

        if ($filterencrypteddrivesby1.Count -lt 1) {
            Write-Host "There is no one encryptable object that can be added to collection" -ForegroundColor Red;
            $setDrv=$null;
        } else {
            [string]$TxtFilePathOrKeyString1=$TxtFilePathOrKeyString.Trim();
            #[string]$TxtFilePathOrKeyString2=$TxtFilePathOrKeyString1 -replace "[^\d]";
            #[int]$TxtFilePathOrKeyString3=$TxtFilePathOrKeyString2.Length;
            if ([System.IO.File]::Exists($TxtFilePathOrKeyString)) {
                if ([System.IO.Path]::GetExtension($TxtFilePathOrKeyString) -match "txt") {
                    $ArrayOfStringsInTxtFile1=(Get-Content $TxtFilePathOrKeyString).Trim();
                    $TPass=$ArrayOfStringsInTxtFile1|Where-Object{$_ -match "^\d{6}-\d{6}-\d{6}-\d{6}-\d{6}-\d{6}-\d{6}-\d{6}$"};
                    while ($TPass -notmatch "^\d{6}-\d{6}-\d{6}-\d{6}-\d{6}-\d{6}-\d{6}-\d{6}$") {
                        $TPass= Read-Host "enter bitlocker numerical password";
                    }
                }else {
                    while ($TPass -notmatch "^\d{6}-\d{6}-\d{6}-\d{6}-\d{6}-\d{6}-\d{6}-\d{6}$") {
                        $TPass= Read-Host "enter bitlocker numerical password";
                    }
                }
            }
            #($TxtFilePathOrKeyString3 -eq 48) -and 
            if ($TxtFilePathOrKeyString1 -match "^\d{6}-\d{6}-\d{6}-\d{6}-\d{6}-\d{6}-\d{6}-\d{6}$") {
                $TPass=$TxtFilePathOrKeyString1;
            }

            if (-not ([string]::IsNullOrEmpty($TPass))) {
                $TPass = ($TPass.Trim()) -replace "`"";
                foreach ($encdrive in $filterencrypteddrivesby1) {
                    $getrezult = $encdrive.UnlockWithNumericalPassword($TPass);
                    if ($getrezult.ReturnValue -eq 0) {
                        $setDrv = $encdrive.DriveLetter; 
                        Write-Host "Unlocked drive $setDrv";
                    }
                }
            }
        }
    }

    END{
        return $setDrv
    }
}#end function
function Get-UnlockBitlockerByPassPhrase {
    param (
        #ParameterSet: PersistentVolumeID, Phrase
        [#Class Win32_Encryptablevolume, Namespace ROOT/CimV2/Security/MicrosoftVolumeEcnryption  
        Parameter(Mandatory = $false,
            HelpMessage = "Parameter Persistent volume ID 
            consits in win32_encryptablevolume class and can be retrive from there",
            Position = 0)]
        [AllowNull()]
        [ValidateScript( { $_ -match "^{[0-z]{8}-[0-z]{4}-[0-z]{4}-[0-z]{4}-[0-z]{12}}$" -or $_ -match "^[0-z]{8}-[0-z]{4}-[0-z]{4}-[0-z]{4}-[0-z]{12}$" })]
        [String]$PersistentVolumeID,
        [Parameter(Mandatory = $false, Position = 1)]
        [Alias("pw", "sstr")]
        [String]$Phrase
    )
    BEGIN {
        [array]$mywin32_encryptablevolume = $null;
        [array]$setbypersvolid = $null;
        [bool]$TestLetterToPreventReUse = $false;
    }
    PROCESS {
        $mywin32_encryptablevolume = Get-WMIObject `
            -NameSpace "Root\cimv2\security\MicrosoftVolumeEncryption" `
            -ClassName Win32_EncryptableVolume;
        [array]$getlockencvol = $null;
	       $getlockencvol = $mywin32_encryptablevolume | `
            Where-Object { $_.GetLockStatus().LockStatus -gt 0 }
        if (($getlockencvol.Count) -lt 1) {
            Write-Host "there is no encrypted drives and locked drives verify that your disk drive was connected" -ForegroundColor Red;
            $decryptedMountPoint = $null;
        }
        else {
            Write-Host "Trying unlock encrypted drive..." -ForegroundColor DarkGray;
            if (-not[string]::IsNullOrEmpty($PersistentVolumeID)) {
                $setbypersvolid = $mywin32_encryptablevolume | Where-Object { $_.PersistentVolumeID -eq $PersistentVolumeID };
                if ($setbypersvolid.Count -eq 1) {
                    $TestLetterToPreventReUse = Test-Path -Path "$($setbypersvolid.DriveLetter)"
                }
                if ($TestLetterToPreventReUse -eq $false) {
                    if ($Phrase.Length -lt 8) {
                        do {
                            [securestring]$PhraseRH = $null;
                            Write-Host "Passpharse less then 8 digits" -ForegroundColor DarkGray;
                            $PhraseRH = Read-Host "Enter Bitlocker Password, Please" -AsSecureString;
                        } while ($PhraseRH.Length -lt 8)
                        $BSTR = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($PhraseRH);
                        $Phrase = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($BSTR);
                    }
                    if ($setbypersvolid.Count -gt 0) {
                        $doUnlockByPassPhrase = $setbypersvolid.UnlockWithPassphrase($Phrase);
                        $retrnUnlock = $doUnlockByPassPhrase.ReturnValue;
                    }
                    switch ($retrnUnlock) {
                        0 {
                            $EncMountPoint = $setbypersvolid.DriveLetter;
                            $tstMountPoint = Test-Path -Path $EncMountPoint;
                            if ($tstMountPoint -eq $true) {
                                $decryptedMountPoint = $EncMountPoint; 
                                Write-host "Unlock Bitlocker Drive was successful.`n
                            `rDrive letter of unlocked device $decryptedMountPoint" `
                                    -ForegroundColor DarkGray;
                            }
                            else {
                                Write-Host "Encrypted drive not present. result set to null" -ForegroundColor Red;
                                $decryptedMountPoint = $null;
                            }
                            break
                        }
                        Default {
                            Write-host "Drive was not opened. Error code is- $retrnUnlock" `
                                -ForegroundColor Red; $decryptedMountPoint = $null;
                        }
                    }
                }
                else {
                    Write-Host "`rEncrypted drive already unlocked and exists.`n
                `rDrive Letter of unlocked device $($setbypersvolid.DriveLetter)" -ForegroundColor DarkGray;
                    $decryptedMountPoint = $setbypersvolid.DriveLetter;
                }
            }
            else {
                Write-Host "PersistentVolumeID string is null or empty" -ForegroundColor Red;
                [array]$tableofencvol1 = $null;
                [array]$tableofencvol = $null;
                [array]$filteredbypersistentvolumeid = $null;
                $tableofencvol1 = Get-WMIObject `
                    -NameSpace "Root\cimv2\security\MicrosoftVolumeEncryption" `
                    -ClassName Win32_EncryptableVolume;
                $filteredbypersistentvolumeid = $tableofencvol1 | Where-Object { if (-not([string]::IsNullOrEmpty($_.PersistentVolumeID))) {
                        return $_
                    } };
                $tableofencvol = $tableofencvol1 | `
                    Select-Object Driveletter, PersistentVolumeID;
                #Commented output for test ;
                #Write-Host "$($filteredbypersistentvolumeid.Count)"; 
                if ($filteredbypersistentvolumeid.Count -gt 1) {
                    [int]$choosein = $null;
                    [int]$choosein = -1;
                    do {
                        [int]$templecounter = 1;
                        Write-Host "$($filteredbypersistentvolumeid.Count)";
                        Write-Host "Counter `tDriveLetter `tPersistentVolumeID"
                        $tableofencvol | ForEach-Object {
                            Write-Host "$templecounter `t`t$($_.Driveletter) `t`t$($_.PersistentVolumeID)";
                            $templecounter += 1 }
                        [string]$getnumber = Read-Host "Enter Number greate then 0 and not greater then bigest one from table above";
                        $choosein = [convert]::ToInt32($getnumber);
                    } while (($choosein -le 0) -or ($choosein -gt ($tableofencvol.Count)))
                    $editindex = $choosein - 1;
                    $getVolIndxfromselect = $tableofencvol1[$editindex];
                }
                if ($filteredbypersistentvolumeid.Count -eq 1) {
                    $getVolIndxfromselect = $filteredbypersistentvolumeid
                }
                if ($filteredbypersistentvolumeid.Count -lt 1) {
                    Write-Host "cannot determinate connected encrypted drives" -ForegroundColor Red;
                    Break;
                }
                if ((Test-Path "$($getVolIndxfromselect.DriveLetter)") -eq $false) {
                    if ($Phrase.Length -lt 8) {
                        do {
                            Write-Host "Passpharse less then 8 digits" -ForegroundColor DarkGray;
                            $PhraseRH = Read-Host "Enter Bitlocker Password, Please" -AsSecureString;
                        }while ($PhraseRH.Length -lt 8)
                        $BSTR = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($PhraseRH);
                        $Phrase = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($BSTR);
                    }
                    $doUnlockByPassPhrase = $getVolIndxfromselect.UnlockWithPassphrase($Phrase);
                    $retrnUnlock = $doUnlockByPassPhrase.ReturnValue;
                    switch ($retrnUnlock) {
                        0 {
                            $EncMountPoint = $getVolIndxfromselect.DriveLetter;
                            $tstMountPoint = Test-Path -Path $EncMountPoint;
                            if ($tstMountPoint -eq $true) {
                                $decryptedMountPoint = $EncMountPoint; 
                                Write-host "Unlock Bitlocker Drive was successful. Drive letter of unlocked device 
                                `r $decryptedMountPoint" -ForegroundColor Green -BackgroundColor Black;
                            }
                            else {
                                Write-Host "Encrypted drive not present. result set to null" -ForegroundColor Yellow -BackgroundColor Black;
                                $decryptedMountPoint = $null;
                            }
                            Break
                        }
                        Default {
                            Write-host "Drive was not opened. Error code is- $retrnUnlock" -ForegroundColor Red -BackgroundColor Black;
                            $decryptedMountPoint = $null;
                        }
                    }
                }
                else {
                    Write-host "Already unlocked drive letter is $($getVolIndxfromselect.DriveLetter)";
                    $decryptedMountPoint = $getVolIndxfromselect.DriveLetter
                }
            }
        }
    }
    END {
        return $decryptedMountPoint
    }
}
#end function
function Get-UnlockByBEKFile {
    param(
        #ParameterSet: BEKFile, LockedDrive, Auto
        [Parameter(Mandatory = $false, Position = 0)]
        [String]$BEKFile,
        [Parameter(Mandatory = $false, Position = 2)]
        [String]$LockedDrive,
        [Parameter(Mandatory = $false, Position = 1)]
        [Switch]$Auto
    )
    [array]$lockedvolume = $null;
    if ($Auto.IsPresent) {
        [array]$arraya = $null
        [array]$arraya = Get-WmiObject win32_logicaldisk|Where-Object {$_.DriveType -eq 2}
        [array]$id_disks = $arraya.DeviceID;
        [array]$fullnamear = $null;
        foreach ($id in $id_disks) {
            $fullnamear += ((Get-ChildItem -Path $id -Force).FullName);
        }
        $BEKFile = ($fullnamear|Where-Object {$_ -like "*.BEK"})
        $mywin32_encryptablevolume = Get-WMIObject `
            -NameSpace "Root\cimv2\security\MicrosoftVolumeEncryption" `
            -ClassName "win32_EncryptableVolume"|Where-Object {$_.DriveLetter -gt 0};
        $lockedvolume = ($mywin32_encryptablevolume| `
                Where-Object {$_.GetLockStatus().LockStatus -gt 0}).DriveLetter;
    }
    else {
        if ($BEKFile.Length -lt 3) {
            while (Test-Path -Path $BEKFile) {
                $BEKFile = Read-Host "Enter path to bek file"
            }
        }
        if ($LockedDrive.Length -lt 1) {
            $LockedDrive = Read-Host "Enter dirve letter with";
            $LockedDrive = $LockedDrive.ToUpper() -replace "[^A-Z]"
        }
        if ($LockedDrive.Length -gt 1) {$lockedvolume = $LockedDrive[0]}
        if ($LockedDrive.Length -eq 1) {$lockedvolume = $LockedDrive}
        if (($LockedDrive.Length -lt 1)) {
            while ($LockedDrive.Length -lt 1 -and $LockedDrive.Length -gt 1) {
                $LockedDrive = Read-Host "Enter dirve letter with"
            }
            $LockedDrive = $LockedDrive.ToUpper() -replace "[^A-Z]";
            $lockedvolume = $LockedDrive + ':';
        }
    }
    manage-bde -unlock $lockedvolume -rk $BEKFile;
}
#end function
function Set-FolderNamesContainer {
    param (
        #ParameterSet: SourceDiskNumber, SourceUserProfileOnly, MakeAContainer, SourceDriveLetter, SourceVolumeLabel, SourceDiskbySerialNumber, ArrayWhichNeedsToExclude
        # Parameter help description
        [Parameter(Mandatory=$false,Position=0)]
        [Alias("srcdnum")]
        [int32]$SourceDiskNumber = -1,
        [Parameter(Mandatory=$false,Position=1)]
        [Alias("preusrprof")]
        [string]$SourceUserProfileOnly,
        [Parameter(Mandatory=$false,Position=2)]
        [Alias("movetodir")]
        [switch]$MakeAContainer,
        [Parameter(Mandatory=$false,Position=3)]
        [Alias("sdltr")]
        [string[]]$SourceDriveLetter,
        [Parameter(Mandatory=$false,Position=4)]
        [Alias("svollab")]
        [string]$SourceVolumeLabel,
        [Parameter(Mandatory=$false,Position=5)]
        [Alias("sdsrnum")]
        [string]$SourceDiskbySerialNumber,
        [Parameter(Mandatory=$false,Position=6)]
        [Alias("awnte")]
        [string[]]$ArrayWhichNeedsToExclude=@(
	    "Documents and Settings",
        "Windows",
        "Program Files",
        "ProgramData",
        "Perflogs",
        "Recycle",
        "System Volume Information",
        "found.000",
        "Config.Msi",
        "Recovery",
        "MSOCache",
        "Quarantine",
        "`.bat",
        "ForeFront",
        "`.reg",
        "`.sys",
	"bootmgr",
	"UADiagnosticsSystemDrive",
	"_SMS",
	"msdia80.dll",
	"smsbootsect.bak"
        )
    )

    BEGIN{
        [array]$FirstArrayResultwithfolderFN=$null;
    }
    #All next things do indexes of fullnames for files and folders that filtered by some of selected parameters;
    #note: the function not fully tested in all variants, 
    #the best way is to use one "main filter" and MakeAContainer (move all selected to 1 folder)parameter if its needed;
    PROCESS{
        #The Next: do indexes with filtering by drive letters
        if (($SourceDriveLetter).Count -gt 0) {
            [array]$CorrectMyLetters=$null;
            foreach ($itemLetter in $SourceDriveLetter) {
                if ($itemLetter -notmatch ':') {
                    if ($itemLetter.Length -gt 1) {
                        $itemLetter = $itemLetter[0];
                    }
                    $itemLetter = "$($itemLetter.ToUpper() -replace "[^A-Z]")" + ':';
                }
                if (Test-Path -Path $itemLetter) {
                    $CorrectMyLetters+=([System.IO.Directory]::GetDirectoryRoot($itemLetter));
                }
            }
            foreach ($itemCorrected in $CorrectMyLetters) {
                $FirstArrayResultwithfolderFN += ((Get-ChildItem -Path $itemCorrected -Force)| `
                Where-Object {
                         ($_.Mode -notlike "*hs*")}).FullName;
            }
        }
        #The Next: do indexes on selected disk number
        if ($SourceDiskNumber -ge 0) {
            [array]$templarrayofdiskinfo = $null;
            [array]$SelectDriveLettersOnly=$null;
            $templarrayofdiskinfo = Get-WmiObject -Class MSFT_Partition `
            -Namespace 'Root/Microsoft/Windows/Storage'| `
            Where-Object{$_.DiskNumber -eq $SourceDiskNumber};
            if ($templarrayofdiskinfo.Count -gt 0) {
                [array]$SortLettersGTNull=$templarrayofdiskinfo| `
                Where-Object{($_.DriveLetter -gt 0) -and ($_.Size -gt 524288000)};
                foreach ($ZItemLetter in ($SortLettersGTNull.Driveletter)) {
                    $SelectDriveLettersOnly+=($ZItemLetter+':\');
                }
                foreach ($SelectedItmL in $SelectDriveLettersOnly) {
                $FirstArrayResultwithfolderFN += ((Get-ChildItem -Path $SelectedItmL -Force)| `
                Where-Object {
                         ($_.Mode -notlike "*hs*")}).FullName;
                }
            }
        }
        #The Next: do indexes on selected volume which one has a specified Label
        if ($SourceVolumeLabel.Length -gt 0) {
            [array]$filtervolumesbylabel=$null;
            foreach ($itemlabel in $SourceVolumeLabel) {
                $filtervolumesbylabel+=Get-WmiObject -Class Win32_Volume| `
                Where-Object{$_.Label -eq $SourceVolumeLabel};
            }
            foreach ($SelectedItmLetterByLabel in $filtervolumesbylabel) {
                $FirstArrayResultwithfolderFN += ((Get-ChildItem -Path $SelectedItmLetterByLabel -Force)| `
                Where-Object {
                         ($_.Mode -notlike "*hs*")}).FullName;
            }
        }
        #The Next: do indexes by filtering serial number of disks by matching selected one
        if ($SourceDiskbySerialNumber.Length -gt 0) {
            [array]$DiskInfoContainer = $null;
            [array]$PartitionArray = $null;
            [array]$FilterBySN = $null;
                $DiskInfoContainer += (Get-WmiObject -Class MSFT_Disk -Namespace 'Root/Microsoft/Windows/Storage');
                $FilterBySN = $DiskInfoContainer|Where-Object {
                    [string]$TryEQSN=$_.SerialNumber
                    if (-not [string]::IsNullOrEmpty($TryEQSN)) {
                       return $TryEQSN.Trim()
                    }
                }
            [array]$DiskContainerConvertToPartition = $null;
            foreach ($itemDC in $FilterBySN) {
                $DiskContainerConvertToPartition += (Get-WmiObject -Class MSFT_Partition -Namespace 'Root/Microsoft/Windows/Storage')| `
                    Where-Object {($_.DiskNumber -match ($itemDC.Number)) -and ($_.DriveLetter -gt 0) -and ($_.Size -gt 524288000)}
            }
            foreach ($partitionitem in ($DiskContainerConvertToPartition.Driveletter)) {
                $PartitionArray += ($partitionitem + ':\')
            }
            foreach ($itemParitionL in $PartitionArray) {
                $FirstArrayResultwithfolderFN += ((Get-ChildItem -Path $itemParitionL -Force)| `
                 Where-Object {
                         ($_.Mode -notlike "*hs*")}).FullName;
            }
        }
        #the next needs to be tested
        #filter items by *like* operator
        if ($ArrayWhichNeedsToExclude.Count -gt 0) {
            if ($ArrayWhichNeedsToExclude -match "\*") {
                $ArrayWhichNeedsToExcludeRemAstr=$ArrayWhichNeedsToExclude -replace "\*";
            }else {
                $ArrayWhichNeedsToExcludeRemAstr=$ArrayWhichNeedsToExclude;
            }
            [string]$stringfeature = $null;
            (0..($ArrayWhichNeedsToExcludeRemAstr.Count - 1)) | ForEach-Object {
                if ($_ -ne ($ArrayWhichNeedsToExcludeRemAstr.Count - 1)) {
                    $stringfeature += ("`"*$($ArrayWhichNeedsToExcludeRemAstr[$_])*`"" + " -and `$_ -notlike ");
                }
            }
            $stringfeature = "`$_ -notlike " + $stringfeature;
            $stringfeature += "`"*$($ArrayWhichNeedsToExcludeRemAstr[-1])*`"";
            $Error.Clear();
            try {
                $rsltscriptblockstring = [scriptblock]::Create("`$FirstArrayResultwithfolderFN|?{$stringfeature}");
            }
            catch {
                Write-Host "Catch an error. cannot modify string to make a scriptblock" -ForegroundColor Red;
                Break;
            }
            [array]$RsltInvoke = $Null;
            [array]$RsltInvoke = Invoke-Command -scriptblock $rsltscriptblockstring;
            if ($RsltInvoke.Count -gt 0) {
                $FirstArrayResultwithfolderFN=$null;
                $FirstArrayResultwithfolderFN=$RsltInvoke;
            }
        }
        #The Next: do indexes with selected only one user profile
        if ($SourceUserProfileOnly.Length -gt 0) {
            [array]$ArrayPartitionNotNull = $null;
            [array]$ResultwithfolderFN = $null;
            [array]$DefaultSourceUserProfileOnly = $null;
            [array]$TempItemPath = $null;
            $ArrayPartitionNotNull += (Get-WmiObject -Class MSFT_Partition -Namespace 'Root/Microsoft/Windows/Storage')| `
                Where-Object {($_.DriveLetter -gt 0) -and ($_.Size -gt 524288000)};
            if ($ArrayPartitionNotNull.Count -gt 0) {
                foreach ($itmDrive in $ArrayPartitionNotNull.Driveletter) {
                    $TempItemPath += (($itmDrive + ':\' + 'Users')|Where-Object {Test-Path -Path $_});
                }
                foreach ($itmdir in $TempItemPath) {
                    $DefaultSourceUserProfileOnly += (Get-ChildItem -Path $itmdir -Force|Where-Object {$_.FullName -match "$SourceUserProfileOnly"}).FullName
                }
            }
            switch ($null) {
                $SourceDiskNumber  { $ResultwithfolderFN += $FirstArrayResultwithfolderFN|Where-Object {$_ -notlike "*Users"}; break}
                $SourceDriveLetter { $ResultwithfolderFN += $FirstArrayResultwithfolderFN|Where-Object {$_ -notlike "*Users"}; break}
                $SourceVolumeLabel { $ResultwithfolderFN += $FirstArrayResultwithfolderFN|Where-Object {$_ -notlike "*Users"}; break}
                $SourceDiskbySerialNumber { $ResultwithfolderFN += $FirstArrayResultwithfolderFN|Where-Object {$_ -notlike "*Users"}; break}
            }
            [array]$FirstArrayResultwithfolderFN = $ResultwithfolderFN;
            if ($DefaultSourceUserProfileOnly.Count -gt 0) {
                $FirstArrayResultwithfolderFN += $DefaultSourceUserProfileOnly;
            }
        }
        #The next: get all indexed results and move to one folder with typing a name of folder (helps when folders named non-english);
        if ($MakeAContainer) {
            [string]$MakeContainerForEachDrive = $null;
            if ($SourceUserProfileOnly.Length -lt 1) {
                $MakeContainerForEachDrive = Read-Host -Prompt "Type the container name, to make it on a drive before moving items there";
            }
            else {
                $MakeContainerForEachDrive = $SourceUserProfileOnly;
            }
            if ($null -ne $FirstArrayResultwithfolderFN) {
                [array]$ContainersArray = $null;
                foreach ($someitem in $FirstArrayResultwithfolderFN) {
                    [string]$ContainerOfADrive = $null;
                    if (Test-Path -Path $someitem) {
                        [string]$GetRootForArraydir=$null;
                        [string]$GetRootForArraydir = (Get-Item -Path $someitem -Force).PSDrive.Root;
                        [string]$ContainerOfADrive=$null;
                        $ContainerOfADrive = $GetRootForArraydir + $MakeContainerForEachDrive;
                        if (-not([System.IO.Directory]::Exists($ContainerOfADrive))) {
                            #Write-host "making $ContainerOfADrive container on $GetRootForArraydir...";
                            mkdir -Path $ContainerOfADrive|Out-Null;
                        }
                        if (Test-Path -Path $ContainerOfADrive) {
                            #this just for adding new folder to array that would be new container for all others;
                            if ($ContainersArray -notcontains $ContainerOfADrive) {
                                $ContainersArray = $ContainersArray + $ContainerOfADrive;
                            }
                            [string]$DDPath = [regex]::Escape($ContainerOfADrive);
                            if ($someitem -notmatch $DDPath) {
                                #Write-Host "Moving $someitem to $DDPath..." -ForeGroundColor Gray;
                                Move-Item -Path $someitem -Destination $DDPath -Force -ErrorAction 0;
                            }
                        }
                    }
                }
                #reset to all indexed and place only main container
                [array]$FirstArrayResultwithfolderFN = $null;
                [array]$FirstArrayResultwithfolderFN = $ContainersArray;
            }
        }
    }
    END{
        return $FirstArrayResultwithfolderFN;
    }
}#end function
function Get-CaptureFoldersArrayWithMyPresets {
    param (
        #ParameterSet: InputArray, DestinationStorage
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline=$true)]
        [Alias('srcpath')]
        [string[]]$InputArray,
        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [Alias("dstpath", "storage")]
        [string]$DestinationStorage,
	[string]$AddPathToConfigFile,
        [switch]$NamingWithDateTimeNow=[switch]::Present,
        [switch]$NamingWithModelName=[switch]::Present
    )
    BEGIN {
        [string]$rSysModel = $null;
        [string]$getBBSN = $null;
        [array] $SystemModelName = $null;
        [string]$NameOfFile = '';
        [string]$AddWimExtens = '.wim';
        [string]$BaseBoardProduct = $null;
        [string]$tildastring=$null;
        [array] $rtrngci=$null;
        [string]$getMyTime='';
    }
    PROCESS {

        if ($NamingWithModelName.IsPresent) {
            $getBBSN = ((Get-WmiObject win32_BaseBoard).SerialNumber);
            $SystemModelName = Get-WmiObject win32_computersystem;
            $rSysModel = $SystemModelName.Model;
            if (($rSysModel.Length -eq 33) `
                -or ([string]::IsNullOrWhiteSpace($rSysModel))) {
             $BaseBoardProduct = (Get-WmiObject -Class win32_BaseBoard).Product;
             $rSysModel = $BaseBoardProduct;
            }
            [string]$sum_SMmodel_BBSN = "$rSysModel" + '_' + "$getBBSN";
            [string]$NameOfFile = (($sum_SMmodel_BBSN) -replace "[^_0-9\p{Ll}]").Trim();
        }

        if ($PSBoundParameters.ContainsKey('InputArray')) {
            if ($InputArray.Count -eq 0) {
                Write-Host "`n`t array count is null. cann't continue" `
                    -ForegroundColor Red; Start-Sleep 10; Break;
            } else {
                if (-not [System.IO.Directory]::Exists($DestinationStorage)) {
                    mkdir $DestinationStorage | Out-Null;
                }
                if (-not (Test-Path -Path  $DestinationStorage)) {
                    Break;
                }
                ForEach ($xItemOfArray in $InputArray) {
                    if ($NamingWithDateTimeNow.IsPresent) {
                        $getMyTime = (Get-Date).ToString("hhmmss-ddMMyy");
                    }
                    $FolderNameofIVar = $xItemOfArray -replace ':\\', '_';
                    $FolderNameofIVar = $FolderNameofIVar -replace "[^ _0-9\p{Ll}]";
                    [uint32]$XCounterForExists += 1;
                    [int]$cwinwdth = (([System.Console]::WindowWidth) / 2);
                    [string]$tildastring = "~^~" * ($cwinwdth / 2);
                    Write-Host "$tildastring`n" -ForegroundColor Yellow;
                    Write-Host ("`n capture source item: {0} " -f $xItemOfArray) -foregroundcolor DarkGray;
                    if ((Get-Item $xItemOfArray -Force).PSIsContainer) {
                        $rsltUsrNmWimFl = "$DestinationStorage" + '\' + "$NameOfFile" + "_$getMyTime" + "_$XCounterForExists" + "_$FolderNameofIVar" + "$AddWimExtens";
                        if ([System.IO.File]::Exists($rsltUsrNmWimFl)) {
                            $XCounterForExists += 1;
                            $rsltUsrNmWimFl = "$DestinationStorage" + '\' + "$NameOfFile" + "_$getMyTime" + "_$XCounterForExists" + "_$FolderNameofIVar" + "$AddWimExtens";
                        }
                        Write-Host "`ndestination file path:`n $rsltUsrNmWimFl" -ForegroundColor DarkGray;
			if (-not ($PSBoundParameters.ContainsKey('AddPathToConfigFile'))){
                        Dism.exe /Capture-Image /imagefile:$rsltUsrNmWimFl /CaptureDir:$xItemOfArray /Name:"$($FolderNameofIVar+'_'+$NameOfFile)" /Compress:None;}
			
			if (($PSBoundParameters.ContainsKey('AddPathToConfigFile'))){
			if ([string]::IsNullOrEmpty($AddPathToConfigFile) -and $AddPathToConfigFile.Length -lt 8){
			 do{$AddPathToConfigFile=Read-Host "Enter path to config file";
			    $AddPathToConfigFile=$AddPathToConfigFile -replace "`"";
				}while(-not [System.IO.File]::Exists($AddPathToConfigFile));
			}
			$AddPathToConfigFile=$AddPathToConfigFile -replace "`"";
			Dism.exe /Capture-Image /imagefile:$rsltUsrNmWimFl /ConfigFile:$AddPathToConfigFile /CaptureDir:$xItemOfArray /Name:"$($FolderNameofIVar+'_'+$NameOfFile)" /Compress:None;
			}
                    }
                    else {
                        Start-Myrobocopyingfiles -SourcePath $xItemOfArray -DestinationPath $DestinationStorage
                        #Copy-Item -Path $xItemOfArray -Destination $DestinationStorage -ErrorAction 0;
                    }
                }
                $rtrngci=@(Get-ChildItem $DestinationStorage);
                Write-Host "Saving done" -Foreground DarkGray;
            }
        }

    }
    END {
        return $rtrngci;
    }
}#end function
function Get-DestinationContainer {
    param(
        #ParameterSet: DestinationStorage, DestinationHDDSerialNumber, PresetDestinationFolderName, SilentMode
        # Parameter help description: provide a storage destination location
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [string]
        $DestinationStorage = $null,
        # Parameter help description: this parameter select Hard Drive  by SerialNumber for future setup(can get from win32_diskdrive)
        [Parameter(Mandatory = $false)]
        [string]
        [Alias("hddsn")]
        [AllowNull()]
        [string]
        $DestinationHDDSerialNumber = $null,
        # Parameter help description: parameter allow set folder name as you wish
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [string]
        $PresetDestinationFolderName,
        #Paramter help description: this parameter help to specify a silent key of that module logic
        [Parameter(Mandatory = $false,
            HelpMessage = "by default this parameter has set the value to true and 
            its meaning that inside function you will asking for name of users storage")]
        [Alias("silentkey", "s", "quiet", "yn")]
        [ValidateSet($true, $false)]
        [bool]$SilentMode = $true
    )
    [string]$gtDate = (Get-Date).ToString("ddd_dd_MMM_yyyy-tt")
    [array]$dskprt_LsDk = $null;
    [array]$get_logicaldisks = $null;
    [array]$get_msftpartition = $null;
    [uint32]$converToIntDiskNum = $null;
    [array]$getmyextbySN = $null;
    [long[]]$getlogicalthebiggest1 = $null;
    [long]$freespacethebiggest = $null;
    [array]$getlogicalIDs = $null;
    [string]$DestinationUserFolder = $null;
    $get_logicaldisks = Get-WmiObject win32_logicaldisk;
    $dskprt_LsDk = Get-WmiObject -Namespace "ROOT/Microsoft/Windows/Storage" -Class MSFT_Disk;
    $get_msftpartition = Get-WmiObject -Namespace "ROOT/Microsoft/Windows/Storage" -Class MSFT_Partition;
    #next is for destination image location
    if (-not ([string]::IsNullOrEmpty($DestinationStorage))) {
        if ([string]([Char[]]('A'[0]..'Z'[0])) -match $DestinationStorage) {
            $DestinationStorage = $DestinationStorage.ToUpper();
            $DestinationStorage = $DestinationStorage -replace "[^A-Z]"
            $DestinationStorage = $DestinationStorage + ':\';
        }
        if ((Test-Path -Path $DestinationStorage) -eq $false) {
            mkdir $DestinationStorage | out-null;
            if (!(Test-Path -path $DestinationStorage)) {
                $DestinationStorage = $null;
            }
        }
        do {
            if ([string]::IsNullOrEmpty($DestinationStorage)) {
                $DestinationStorage = Read-Host "Destination location equals null or not exists.
                `r Please, type here destination location path"
            }
            if ((Test-Path -Path $DestinationStorage) -eq $false) {
                $DestinationStorage = $null;
            }
        } while ($null -eq $DestinationStorage)
    }
    if (-not [string]::IsNullOrEmpty($DestinationHDDSerialNumber)) {
        $DestinationStorage = $null;
        $getExtDiskBySN = $dskprt_LsDk | Where-Object { ($_.SerialNumber).Trim() -eq $DestinationHDDSerialNumber.Trim() };
        $converToIntDiskNum = $getExtDiskBySN.Number;
        $getmyextbySN = ($get_msftpartition | Where-Object { $_.DiskNumber -eq $converToIntDiskNum });
        $getlogicalIDs = $getmyextbySN.Driveletter | `
            ForEach-Object { $letterX = $_; return $get_logicaldisks.DeviceID -like "*$letterX*" };
        $getlogicalthebiggest1 = $getlogicalIDs | ForEach-Object { $someL = $_; ($get_logicaldisks | Where-Object { $_.DeviceID -eq $someL }).FreeSpace } | Sort-Object;
        $freespacethebiggest = $getlogicalthebiggest1[-1];
        $DestinationStorage = ($get_logicaldisks | Where-Object { $_.FreeSpace -eq $freespacethebiggest }).DeviceID;
        $DestinationStorage = ($DestinationStorage.ToUpper()) -replace "[^A-Z]";
        $DestinationStorage = $DestinationStorage + ':\';
    }
    #next for silent mode
    if ([string]::IsNullOrEmpty($PresetDestinationFolderName)) {
        if ($SilentMode -eq $false) {
            $DestinationUserFolder = Read-Host "Please, type here folder name to save there an images of user data...";
            $DestinationUserFolder = ($DestinationUserFolder.ToUpper()) -replace '[^_a-zA-Z0-9]';
        }
        else {
            $DestinationUserFolder = "_CapturedStorage";
        }
    }
    else {
        $DestinationUserFolder = ($PresetDestinationFolderName.ToUpper()) -replace '[^_a-zA-Z0-9]';
    }
    $SumDestFolderEndPoint = $DestinationStorage + '\\' + $DestinationUserFolder + '\\' + $gtDate;
    if (!(Test-Path -Path $SumDestFolderEndPoint)) {
        mkdir $SumDestFolderEndPoint | Out-Null;
        try {
            [string]$rslvDestinationPath=Resolve-Path -Path $SumDestFolderEndPoint;
        }
        catch {
            $rslvDestinationPath=$null;
        }
    }
    return $rslvDestinationPath;
}#end function
function Get-JoinedInPEWimImagePath {
    param(
        #ParameterSet: PathWithoutRoot, DeploymentStorage
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true,
            HelpMessage = "string with path but without root")]
        [String]$PathWithoutRoot,
        # Parameter help description
        [Parameter(Mandatory = $false, Position = 1)]
        [ValidateSet('Local', 'Network')]
        [string]
        $DeploymentStorage = 'Local'
    )
    BEGIN {
        [string]$SelectFl = $null;
    }
    PROCESS {
        #Write-Host "`n Starting setup image path..." -ForegroundColor DarkGray;
        if ($DeploymentStorage -eq "Network") {
            [array]$getdrivetype4 = $null;
            Write-Host "trying to start network deployment..." -ForegroundColor DarkGray;
            $getdrivetype4 = Get-WmiObject Win32_Volume | Where-Object { $_.DriveType -eq 4 }
            ForEach ($driveT4 in $getdrivetype4) {
                [string]$netwimpath = "$($driveT4.DriveLetter)\$PathWithoutRoot";
                if ((Test-Path -Path "$netwimpath") -eq $true) {
                    $SelectFl = $netwimpath;
                }
            }
            if (-not [System.IO.File]::Exists($SelectFl)) {
                $DeploymentStorage = "Local";
            }
        }
        if ($DeploymentStorage -eq "Local") {
            [array]$vlms = $null;
            #Write-Host "trying to use local based images that placed on mounted hard drives" `
                #-ForegroundColor Yellow;
            $PathWithoutRoot = $PathWithoutRoot -replace "`"";
            [array]$vlms = Get-WmiObject win32_volume | Where-Object { if ([System.IO.File]::Exists("$($_.Name)\$PathWithoutRoot")) { return $_ } };
            if ($vlms.Count -gt 1) { $vlms = $vlms[0] }
            [string]$exsPth = "$($vlms.Name)\$PathWithoutRoot";
            [string]$rslvexcPath = Resolve-Path -Path $exsPth -ea 0;
            Write-Host "Error Count while searching for path $($seterrorcontainer.Count)";
            if ($seterrorcontainer.Count -lt 1) {
                $SelectFl = $rslvexcPath;
            }
        }
        if (-not [System.IO.File]::Exists($SelectFl)) {
            Start-Process -FilePath "$env:windir\system32\notepad.exe";
            $SelectFl = Read-Host " Please, type or insert here full path to your image
            `r (install.wim or install.swm or install.esd)";
        }
    }
    END {
        return $SelectFl;
    }
}#end function
function Set-NetStatAdapConf {
    param(
        #ParameterSet: ServerNetworkAddress, rezervedIP, rezervedIPMask, rezervedGateWay
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [Alias("servCN", "servComputerName", "servIP")]
        [String]
        $ServerNetworkAddress,
        [Parameter(Mandatory = $true)]
        [ValidateScript( {$_ -match [IPAddress]$_})]
        [IPAddress]
        $rezervedIP,
        [Parameter(Mandatory = $true)]
        [ValidateScript( {$_ -match [IPAddress]$_})]
        [IPAddress]
        $rezervedIPMask,
        [Parameter(Mandatory = $true)]
        [ValidateScript( {$_ -match [IPAddress]$_})]
        [IPAddress]
        $rezervedGateWay
    )
    $returnfuncresult=$null;
    Write-Host "Initializing network adapter..." -ForegroundColor DarkGray;
    if ([string]::IsNullOrEmpty($ServerNerworkAddress)) {
        $ServerNerworkAddress = Read-Host "Enter IP address of server or computername"
    }
    try {
        $trytestnetconntosrvr = Test-Connection $ServerNerworkAddress -count 2 -quiet;
    }
    catch {
        $trytestnetconntosrvr = $false;
    }
    $IpEndAdap = Get-WmiObject Win32_NetworkAdapterConfiguration|Where-Object {$_.IPEnabled -eq "True"};
    if ($trytestnetconntosrvr -eq $false) {
        if ([string]::IsNullOrEmpty($IpEndAdap)) {
            Write-Host "Network configuration is choosen to be a static,
            but the adapter of current system
            have not any connection or driver for net adapter" -ForegroundColor Red;
        }
        else {
            Write-Host "Network adapter is present and connected to network
            trying to configure your static options" -ForegroundColor Blue;
        
            if (($rezervedIP.Length -gt 7) `
                    -and ($rezervedIPMask.Length -gt 7) `
                    -and ($rezervedGateWay.Length -gt 7) `
                    -and ($rezervedIP -ne $rezervedGateWay)) {
                try {
                    $staticIPenableresult = $IpEndAdap.EnableStatic("$rezervedIP", "$rezervedIPMask");
                    $staticgatewayresult = $IpEndAdap.SetGateWays("$rezervedGateWay", 1);
                }
                catch {
                    Write-Host "Static Address initialization error $_" -ForegroundColor Red;
                    Break;
                }
                Start-Sleep 4;
            }
            else {
                $rezervedIP = Read-Host "type here ip address for for static configuration of this network PC";
                $rezervedIPMask = Read-Host "type here ip address mask of your network";
                $rezervedGateWay = Read-Host "type here ip of gateway (must be different form IP-address for this machine)";
                $rezervedIP = $rezervedIP.Trim();
                $SplIP = $rezervedIP.Split('.');
                [int]$lastOct = $SplIP[-1];
                if ($lastOct -gt 254) {
                    do {
                        $lastOct = Read-Host "Ip address range greater than available. 
                    Please check for first free IP and type here integer number from 1 to 254";
                    } while (($lastOct -lt 1) -or ($lastOct -gt 254))
                }
                $SplIP[-1] = $lastOct;
                $rezervedIP = $SplIP -join '.';
                try {
                    $staticIPenableresult = $IpEndAdap.EnableStatic("$rezervedIP", "$rezervedIPMask");
                    $staticgatewayresult = $IpEndAdap.SetGateWays("$rezervedGateWay", 1);
                }
                catch {
                    Write-Host "Static Address initialization error $_" -ForegroundColor Red;
                    Read-Host "Press Enter to Exit";
                    Break;
                }
                Start-Sleep 4;
            }
            $getEnabledAdapter = Get-WmiObject Win32_NetworkAdapterConfiguration|Where-Object {$_.IPEnabled -eq "True"};
            $tGEn = $getEnabledAdapter|Select-Object -expandproperty IPAddress;
            $splGen = $tGen.Split(',');
            $getFstIndxGen = $splGen[0];
            $FirstIndxGenspl = $getFstIndxGen.Split('.');
            #while splited then first index started from the last octet of IP-address ($FirstIndxGenspl[-1])
            $lastOctRange = $FirstIndxGenspl[-1]..254;
            [array]$IPAddressArray = $null;
            foreach ($octR in $lastOctRange) {
                $FirstIndxGenspl[-1] = $octR;
                $changedIPAddress = $FirstIndxGenspl -join '.';
                [array]$IPAddressArray += "$changedIPAddress";
            }
            foreach ($addrss in $IPAddressArray) {
                $aconnstat = Test-Connection $addrss -Count 2 -Quiet;
                Write-host "$addrss tested. not available- $aconnstat" -ForegroundColor DarkGray;
                if ($aconnstat -eq $false) {$freeIPAddress = $addrss; break}
            }
            Write-Host "trying to use this $freeIPAddress ip address..." -ForegroundColor DarkGray;
            try {
                $staticIPenableresult = $IpEndAdap.EnableStatic("$freeIPAddress", "$rezervedIPMask");
                $staticgatewayresult = $IpEndAdap.SetGateWays("$rezervedGateWay", 1);
            }
            catch {
                Write-Host "Network Initialization fails on error $_
            `n`tGonna beak now" -ForegroundColor Red;
                Break
            }
        }
        else {
            Write-Host `
                "Already connected,`n
            test connection to server $tempvarIP has status $trytestnetconntosrvr" `
                -ForegroundColor Blue;
        }
        if ($staticIPenableresult.returnvalue -eq 0)
        {Write-Host "Static IP enabled" -ForegroundColor } else {
            Write-Host "Static IP was not enabled. Error code: $staticIPenableresult" `
                -ForegroundColor Red; Read-Host "Press enter to exit"; Break
        }
        if ($staticgatewayresult.returnvalue -eq 0)
        {Write-Host  "Static GateWay enabled" -ForegroundColor } else {
            Write-Host "Static GateWay was not enabled. Error code: $staticgatewayresult" `
                -ForegroundColor Red; Read-Host "Press enter to exit"; Break
        }
        Start-Sleep 4;
        Write-Host "Network adapter initializing done..." -ForegroundColor ;
        $returnfuncresult=1;
    }
    return $returnfuncresult;
}#end function
Function Start-MapNetDrive {
    param(
        #ParameterSet: UserNameOnServer, RootOfRemotePath, ServerUsrPassw, MapDriveLetter, Agreekey
        [Parameter(Mandatory = $false, Position = 0)]
        [Alias("letter")]
        [String]$MapDriveLetter,
        [Parameter(Mandatory = $false, Position = 1)]
        [Alias("snun")]
        [String]$UserName,
        [Parameter(Mandatory = $false, Position = 2)]
        [Alias('pw', 'password')]
        [String]$UserPassw,
        [Parameter(Mandatory = $false, Position = 3)]
        [string]$RemotePath,
        [Parameter(Mandatory = $false, Position = 4)]
        [switch]$TruePersistentKey
    )
    [string]$SrvrNm=$null;
    $GetUserNetCredential=$null;
    #start network configuration and maping drives
    #Write-Host "Start mapping network drive" -ForegroundColor DarkGray;
    if (-not ($PSBoundParameters.ContainsKey('MapDriveLetter'))) {
        Write-Host "Enter Drive Letter to Map. Ensure that its free to use" -ForegroundColor Red;
        while ($MapDriveLetter -notmatch "[a-zA-Z]") {
            $MapDriveLetter= Read-Host "Type here";
        }
    }
    if($MapDriveLetter.Length -gt 1){
        $MapDriveLetter=$MapDriveLetter -replace "[^a-zA-Z]"
        $MapDriveLetter=($MapDriveLetter.Substring(0,1));
    }
    $MapDriveLetter=$MapDriveLetter.ToUpper();
    $MapDriveLetter="$MapDriveLetter"+':';
    if (-not ($PSBoundParameters.ContainsKey('UserName'))) {
        if ([string]::IsNullOrEmpty($UserName)) {
            $GetUserNetCredential=(Get-Credential -Message "Enter your credential for network drive").GetNetworkCredential();
            $DomainNm=$GetUserNetCredential.Domain;
            $UserPassw=$GetUserNetCredential.Password;
            if ($null -notmatch $DomainNm) {
                $UserName="$DomainNm"+'\'+"$($GetUserNetCredential.UserName)";
            }
        }
    }
    if (-not ([string]::IsNullOrEmpty($UserName))) {
        $UserName=$UserName -replace "`"";
    }
    if (-not ($PSBoundParameters.ContainsKey('RemotePath'))) {
        [string]$RemotePath=Read-Host "Enter remote path";
    }
    if (-not ([string]::IsNullOrEmpty($RemotePath))) {
        $RemotePath=$RemotePath -replace "`"";
        if ($RemotePath -match "`\") {
            try {
                [array]$SrvrNm0=$RemotePath -split "`\";
            }
            catch {
                $SrvrNm=$RemotePath;
            }
        }
    }
    if ($SrvrNm0.Count -gt $null) {
        [array]$SrvrNm1=$SrvrNm0|Where-Object{$_ -notmatch $null};
        $SrvrNm=$SrvrNm1[0];
    }
    if ([string]::IsNullOrEmpty($UserPassw)) {
        $GetUserNetCredential=(Get-Credential -Message "Need a password to connect to a network drive" -UserName $UserName).GetNetworkCredential();
        $UserPassw = $GetUserNetCredential.Password;
    }
    [bool]$GetPersist=$false;
    if($PSBoundParameters.ContainsKey('TruePersistentKey')){
        $GetPersist=$true;
    }
    #Write-Host "trying connect to server with user credential $UserName";
    $getconnectstatus = Test-Connection $SrvrNm -count 2 -quiet;
    if ($getconnectstatus -eq $true) {
        $WscriptNetObj = New-Object -ComObject WScript.Network;
        $WscriptNetObj.MapNetworkDrive($MapDriveLetter, $RemotePath, $GetPersist, $UserName, $UserPassw);
    }
    else {
        Write-host "Cann't connect to your server $RemotePath. Connection status - $getconnectstatus" -ForegroundColor Red;
    }
    if ((Test-Path -Path "$MapDriveLetter") -eq $false) {
        $MapDriveLetter = $null
    }
    return $MapDriveLetter;
}#end function
function Start-RemoveNetworkDrives {
    param (
        [string[]]$NetworkDrivesToRemove
    )
    if($NetworkDrivesToRemove.Count -gt 0){
        foreach ($itemdrive in $NetworkDrivesToRemove) {
            $WscriptNetObj.RemoveNetworkDrive($itemdrive, $true, $true);
        }
    }
}#end function
function Start-AutoSearchForDriveWithFreeSpace {
    param (
        #ParameterSet: ArrayOFDiskNumbersWhichExcludesFromSearch
        [Parameter(Mandatory = $true, Position = 0,ValueFromPipeline=$true)]
        [uint32[]]$ArrayOFDiskNumbersWhichExcludesFromSearch
    )
    [array]$mywin32_encryptablevolume = Get-WMIObject `
        -namespace "Root\cimv2\security\MicrosoftVolumeEncryption" `
        -ClassName "win32_EncryptableVolume";
    [array]$SearchForNotEncDrvLtr = $mywin32_encryptablevolume| `
        Where-Object {$_.EncryptionMethod -eq 0}| `
        Select-Object -ExpandProperty DriveLetter;
    [array]$diskexcludesinfo = (Get-Disk -Number $ArrayOFDiskNumbersWhichExcludesFromSearch|Get-Partition|Where-Object {
            $_.DriveLetter -gt 0});
    if ($diskexcludesinfo.Count -gt 0) {
        [array]$arrayofexcludes = $diskexcludesinfo| `
            ForEach-Object {$arrayofexcludes = $_.DriveLetter + ':'; return $arrayofexcludes};
        [array]$myarrayofexcludesinwin32volume = $arrayofexcludes|ForEach-Object {
            $exL = $_;
        [array]$myarrayoffreespaceonexcludes = Get-WmiObject -Class Win32_Volume|Where-Object {
                $_.DriveLetter -eq $exL};
                 return $myarrayoffreespaceonexcludes};
        [long]$TotalSizeOfexcludes = (($myarrayofexcludesinwin32volume.Capacity)|Measure-Object -Sum).Sum;
        [long]$TotalFreeSpaceOfExcludes = (($myarrayofexcludesinwin32volume.FreeSpace)|Measure-Object -Sum).Sum;
    }
    [long]$CalcUsedSpace = $TotalSizeOfexcludes - $TotalFreeSpaceOfExcludes;
    [array]$ChangedArrayLetters = $SearchForNotEncDrvLtr| `
        Select-String -Pattern $arrayofexcludes -NotMatch| `
        ForEach-Object {$ChangedArrayLetters = $_ -replace '`n'; return $ChangedArrayLetters};
    [array]$arrayofvol = $ChangedArrayLetters|ForEach-Object {$L = $_;
        $arrayofvol = Get-WmiObject win32_volume| `
            Where-Object {$_.DriveLetter -eq $L}; return $arrayofvol};
    [array]$arrayoffreesize = $arrayofvol|Foreach-Object {
        $arrayoffreesize = $_.FreeSpace; return $arrayoffreesize}|Sort-Object;
    $selectthebigestoneofvolumeset = $arrayofvol| `
        Where-Object {$_.FreeSpace -eq $arrayoffreesize[-1]};
    if (-not ($selectthebigestoneofvolumeset.FreeSpace -gt $CalcUsedSpace)) {
        Write-Host "Not enough free space even on the bigest one`n
          like disk $($selectthebigestoneofvolumeset.DriveLetter)" `
            -ForegroundColor Red;
        Break;
    }
    $dotstPath = Test-Path $selectthebigestoneofvolumeset.DriveLetter;
    if ($dotstPath -eq $true) {
        $myreturnresult = $selectthebigestoneofvolumeset.DriveLetter;
    }
    return $myreturnresult;
}#end function
function Start-AskForSaving {
    param (
        #ParameterSet: SilentModeOn, DoNotSaveData
        #Parameter help description: by default this func. ask you to save users data or no.
        [Parameter(Mandatory = $false, Position = 0)]
        [ValidateSet($true, $false)]
        [bool]$SilentModeOn = $false,
        # Parameter help description
        [Parameter(Mandatory = $false, Position = 1)]
        [ValidateSet($true, $false)]
        [Bool]$DoNotSaveData=$false
        )
        [string]$ResultFolderName = $null;
        [array] $SystemModelName = Get-WmiObject win32_computersystem;
        [string]$ResultSystemModel = $SystemModelName.Model;
        if (($ResultSystemModel.Length -eq 33) -or ([string]::IsNullOrWhiteSpace($ResultSystemModel)))
        {
            $ResultSystemModel = (Get-WmiObject -Class win32_BaseBoard).Product;
        }
        [string]$ResultSystemModel = $ResultSystemModel -replace ' ','';
        [string]$getBBSN = (Get-WmiObject win32_BaseBoard).SerialNumber;
        [string]$getBBSN = $getBBSN -replace '/','';
        [string]$getDate = (Get-Date).ToString('ddMMyyhhmm');
        switch ($SilentModeOn) {
        $false {
            if ($DoNotSaveData -eq $false) {
                $ResultFolderName = Read-Host "Please, type here folder name to save there an images of user data...";
            }
            if ($DoNotSaveData -eq $true) {
                $ResultFolderName = $null;
            }
            break;
        }
        $true{
            if ($DoNotSaveData -eq $false) {
                $ResultFolderName = "S_"+"$getDate"+"_"+"$getBBSN"+"$ResultSystemModel";
            }
            if ($DoNotSaveData -eq $true) {
                $ResultFolderName = $null;
            }
            break;
        }
        Default {
            $ResultFolderName = "S_"+"$getDate"+"_"+"$getBBSN"+"$ResultSystemModel";
        }
    }
    return $ResultFolderName;
}#end function
function Get-PartitionByFileOrDirectory {
    param(
        #ParameterSet: SearchForExistingFileOrDir
        [Parameter(Mandatory = $false)]
        [string]$SearchForExistingFileOrDir='Windows'
    )
    if ([string]::IsNullOrEmpty($SearchForExistingFileOrDir)) {
        Write-Host "The parameter string of the Get-PartitionByFileOrDirectory function is null or empty" -ForegroundColor Red;
        Write-Host "Please, check xml file before running against this script" -ForegroundColor Red;
        Write-Host "The Node: SerachForDirOrFileInARoot
        `tin xml file must contains a name of directory or file name that exists on partition" -ForegroundColor Red;
        Break;
    }
    [array]$GetPartitionInformation = $null;
    $GetPartitionInformation = Get-WmiObject -Namespace 'Root/Microsoft/Windows/Storage' -Class MSFT_Partition| `
        Where-Object {$_.DriveLetter -gt 0 -and $_.DriveLetter -ne "X"};
    [array]$FilterArrayByPartialName = $GetPartitionInformation.DriveLetter| `
        Where-Object {
        $letterPartition = $_;
        $rootLetter = $letterPartition + ':\';
        $pathforexists = "$rootLetter" + "$SearchForExistingFileOrDir";
        if ((Test-Path -Path $pathforexists) -eq $true) {return $letterPartition}
    };
    if ($FilterArrayByPartialName.Length -lt 1) {
        Write-Host "Automate searching skiped by null expression" `
            -ForegroundColor Red;
        $FilterArrayByPartialName = $null;
    }
    [array]$PartitionInfoByDriveLetter = $null;
    if ($FilterArrayByPartialName.Length -gt 0 ) {
        foreach ($letterX in $FilterArrayByPartialName) {
            $PartitionInfoByDriveLetter += ($GetPartitionInformation|Where-Object{$_.Driveletter -eq $letterX});
        }
    }
    return $PartitionInfoByDriveLetter
}#end function
function Start-FormatingDiskByPartitionLetter {
    param (
        #ParameterSet: ArrayOfLetters, DoAsking
        [Parameter(Mandatory = $true, HelpMessage = "
        Need at least one drive letter")]
        [Alias("letter")]
        [String[]]$ArrayOfLetters,
        [Bool]$DoAsking = $true
    )
    if ($ArrayOfLetters.Count -gt 0) {
        foreach ($partitem in $ArrayOfLetters) {
            $getPartNum = (Get-Partition -DriveLetter $partitem).PartitionNumber;
            $getSelectedDiskInfo = Get-Partition -DriveLetter $partitem | Get-Disk;
            $getSelectedDiskNumber = $getSelectedDiskInfo.Number;
            $getSystemPartition = (Get-Disk -Number $getSelectedDiskNumber | `
                    Get-Partition).PartitionNumber;
            if ($getSystemPartition.Count -eq 1) {
                Get-Disk -Number $getSelectedDiskNumber | `
                    Get-Partition -PartitionNumber $getSystemPartition | `
                    Remove-partition -Confirm:$DoAsking;
            }
            Get-Disk -Number $getSelectedDiskNumber | `
                Get-Partition -PartitionNumber $getPartNum | `
                Remove-partition -Confirm:$DoAsking;
            #Working with partition
            New-Partition -DiskNumber $getSelectedDiskNumber `
                -Size 350MB -DriveLetter 'S' -IsActive:$true | `
                Format-Volume -FileSystem NTFS -NewFileSystemLabel 'System' `
                -Confirm:$DoAsking | Out-Null;
            New-Partition -DiskNumber $getSelectedDiskNumber -UseMaximumsize -DriveLetter 'W' | `
                Format-Volume -FileSystem NTFS -NewFileSystemLabel 'Windows' `
                -Confirm:$DoAsking | Out-Null;
        }
    }
    else {
        Write-Host "The array count of entry parameter is null or less
        `n`t please make shure your are using existing file`n
        `t to determinate partition place" -ForegroundColor Red;
        Break;
    }
}#end function
function Start-FormatingDisk {
    param(
        #ParameterSet: DiskNumberToFormat, PartitionStyle, Confirmkey, MSRSize
        [Parameter(Mandatory = $true,
            HelpMessage = "Need disk number from collection of
        `"GWMI -Namespace `"ROOT/Microsoft/Windows/Storage`" -ClassName MSFT_Disk`"")]
        [ValidateNotNullOrEmpty()]
        [uint32]
        [ValidatePattern("[0-9]")]
        $DiskNumberToFormat,
        [Parameter(Mandatory = $true,
            HelpMessage = "Valid partition table states: GPT or MBR")]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("MBR", "GPT")]
        [String]$PartitionStyle,
        [bool]$Confirmkey = $true,
        [Parameter(Mandatory=$false,HelpMessage='msr partition size for gpt style')]
        [string]$MSRSize=16MB
    )

    [int]$tDskNum=$null;
    [string]$ReplaceCharsMSR=$MSRSize -replace "[^0-9]";
    [int32]$ConvertMSRToInt32=[convert]::ToInt32($ReplaceCharsMSR);
    [uint64]$MSRSizeUINT64=$ConvertMSRToInt32 * 1MB;
    try {
        $tDskNum=[System.Convert]::ToInt32($DiskNumberToFormat);
    }
    catch {
        $DiskNumberToFormat=$null;
    }
    if ($null -eq $DiskNumberToFormat ) {
        [array]$arrOfDiskNumbers=$null;
        [string]$ADiskNumber=$null;
        [int]$converToInt=$null;
        [array]$arrOfDiskNumbers=(Get-WmiObject -Namespace 'root/microsoft/windows/storage' -Class msft_disk).Number|Sort-Object;
        $getFirstDiskNumber=$arrOfDiskNumbers[0];
        $getLastDiskNumber=$arrOfDiskNumbers[-1];
        do {
          Write-Host "Disk Number";
          $arrOfDiskNumbers|ForEach-Object{Write-Host "$_"}
          $ADiskNumber=Read-Host "`n Please, type integer disk number($getFirstDiskNumber-$getLastDiskNumber) from the list above";
          try {
            $converToInt=[convert]::ToInt32($ADiskNumber);
          }
          catch {
            $converToInt= -1;
            Write-Host "Incorrect inputs please type here only integer number from $getFirstDiskNumber to $getLastDiskNumber"
          }
        } while (($converToInt -lt $getFirstDiskNumber) -or ($converToInt -gt $getLastDiskNumber));
        $tDskNum = $converToInt;
    }
    if ($null -eq $PartitionStyle) {
        do {
            Write-Host "`n`t`t`tWarning! if selected partition style is different from the current then all not saved data will be destroyed!!!`n" -ForegroundColor Red;
            $PartitionStyle = Read-Host "Please, type here(GPT or MBR), which partition style to use?";
        } until (($PartitionStyle -eq 'GPT') -or ($PartitionStyle -eq 'MBR'))
    }
    [string]$PresetPartStyle=$null;
    $PresetPartStyle = $PartitionStyle;
    Write-Host "Begin formating disk $tDskNum..." -ForegroundColor Red;
    switch ($PresetPartStyle) {
        GPT {
            Write-Host "Selected Disk type: $PresetPartStyle" -ForegroundColor Cyan;
            #clear disk
            if (-not ((Get-Disk -Number $tDskNum).PartitionStyle -eq 'RAW')) {
                Get-Disk -Number $tDskNum| `
                    Get-Partition | `
                    Remove-Partition -Confirm:$ConfirmKey -Verbose|Out-Null;
                Clear-Disk -Number $tDskNum `
                    -RemoveData -RemoveOEM -Confirm:$ConfirmKey -Verbose|Out-Null;
            }
            #initialize cleared disk
            Get-Disk -Number $tDskNum|Initialize-Disk -PartitionStyle GPT -Verbose;
            #create the system partition
            New-Partition -DiskNumber $tDskNum -GptType '{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}' `
                -Size 350MB -DriveLetter 'S' -Verbose| `
                Format-Volume -FileSystem FAT32 -NewFileSystemLabel 'System' `
                -Confirm:$ConfirmKey -Verbose|Out-Null;
            #create MSR
            New-Partition -DiskNumber $tDskNum `
                -Size $MSRSizeUINT64 -GptType '{e3c9e316-0b5c-4db8-817d-f92df00215ae}' -Verbose|Out-Null;
            #create Primary (Windows) Partition
            New-Partition -DiskNumber $tDskNum -GptType '{ebd0a0a2-b9e5-4433-87c0-68b6b72699c7}' `
                -UseMaximumSize -DriveLetter 'W' -Verbose| `
                Format-Volume -FileSystem NTFS -NewFileSystemLabel 'Windows' `
                -Confirm:$ConfirmKey -Verbose|Out-Null;
            Write-Host "Information after action";
            Get-Disk -Number $tDskNum|Get-Partition;
            break;
        }
        MBR {
            Write-Host "Selected Disk type: $PresetPartStyle" -ForegroundColor Cyan;
            #clear disk
            if (-not ((Get-Disk -Number $tDskNum).PartitionStyle -eq 'RAW')) {
                Get-Disk   -Number $tDskNum| `
                    Get-Partition | `
                    Remove-partition -Confirm:$ConfirmKey -Verbose|Out-Null;
                Clear-Disk -Number $tDskNum -RemoveData -RemoveOEM `
                    -Confirm:$ConfirmKey -Verbose|Out-Null;
            }
            #initialize cleared disk
            Get-Disk -number $tDskNum|Initialize-Disk -PartitionStyle MBR -Verbose|Out-Null;
            #create the system partition
            New-Partition -DiskNumber $tDskNum -Size 350MB -DriveLetter 'S' -IsActive:$true -Verbose| `
                Format-Volume -FileSystem NTFS -NewFileSystemLabel 'System' -Confirm:$ConfirmKey -Verbose|Out-Null;
            #create Primary (Windows) Partition
            New-Partition -DiskNumber $tDskNum -UseMaximumSize -DriveLetter 'W' -Verbose| `
                Format-Volume -FileSystem NTFS -NewFileSystemLabel 'Windows' -Confirm:$ConfirmKey -Verbose|Out-Null;
            Write-Host "Information after action";
            Get-Disk -Number $tDskNum|Get-Partition;
            break;
        }
        default {Write-Host "getting wrong disk type" -ForegroundColor Red; Break}
    }
}
#end function
function Start-ApplyingAnImage {
    param (
        #ParameterSet: FullNameImagePathString, ApplyPath, UseImageIndex
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$FullNameImagePathString,
        [Parameter(Mandatory = $true, Position = 1,
        HelpMessage="Choose a letter: A, B, C, D, E, F, G, H, I, J,
        K, L, M, N, O, P, Q, R, S, T, U, V, W, Y, Z or type directory path")]
        [string]$ApplyPath,
        [Parameter(Mandatory = $true, Position = 2)]
        [uint32]
        $UseImageIndex
    )
    if ([string]::IsNullOrEmpty($FullNameImagePathString) -or (-not[System.IO.File]::Exists($FullNameImagePathString))) {
        Write-Host "The parameter string is null or empty or the specified path doesn't exists";
        Start-Sleep 10;
        Break;
    }
    #working with image path
    $mytmp = $FullNameImagePathString -replace "`"";
    $mytmp_2 = $FullNameImagePathString -replace '\d+.swm','*.swm';
    $splt_FullPathExtension = ([System.IO.Path]::GetExtension($mytmp));
    #correct apply image path
    if ($ApplyPath -notmatch ':') {
        $ApplyPath = $ApplyPath.ToUpper() -replace "[^A-Z]";
        $ApplyPath = $ApplyPath + ':';
    }
    $ApplyTOPath = $ApplyPath -replace "`"";
    if ([string]::IsNullOrEmpty($UseImageIndex)) {
        $getwimindxs = Get-WindowsImage -ImagePath $mytmp;
        if (($getwimindxs.ImageIndex).Count -eq 1) {
            $UseImageIndex = $getwimindxs.ImageIndex;
        }
        elseif (($getwimindxs.ImageIndex).Count -gt 1) {
            $getwimindxs|ForEach-Object {Write-Host "$($_.ImageName)`t`t$($_.ImageIndex)"}
            Write-Host "Please, make a choise of index"
            $UseImageIndex = Read-Host "type index number here"
        }
    }
    Write-Host "Starting deployment 
    `n`tImage: $mytmp . 
    `n`tPlease, waiting..."`
        -ForegroundColor DarkGray;
    switch ($splt_FullPathExtension) {
        .swm {
            #Expand-WindowsImage -ImagePath $mySelectedImage -SplitImageFilePattern $mytmp_2 -Index $UseImageIndex `
            #-ApplyPath "W:\" -Verify -LogLevel WarningsInfo;
            dism /apply-image /ImageFile:"$mytmp" /SWMFile:$mytmp_2 /index:$UseImageIndex /applydir:$ApplyTOPath;
            break
        }
        .wim {
            #Expand-WIndowsImage -ImagePath "$mySelectedImage" -Index $UseImageIndex -ApplyPath $ApplyTOPath -LogLevel WarningsInfo;
            dism /apply-image /ImageFile:"$mytmp" /index:$UseImageIndex /applydir:$ApplyTOPath; break
        }
        .esd {
            dism /apply-image /ImageFile:$mytmp /index:$UseImageIndex /applydir:$ApplyTOPath; break
        }
        default {
            Write-Host "image with $splt_FullPathExtension extension isn't support" `
                -ForegroundColor Red; Break
        }
    }
    $drLImages = (Get-Item $mytmp).DirectoryName;
    $unattendFl = "$drLImages\unattend.xml";
    if ([System.IO.File]::Exists($unattendFl)) {
        $destpath = "$ApplyPath" + "Windows\System32\Sysprep\unattend.xml"
        Copy-Item `
            -Path $unattendFl `
            -Destination $destpath `
            -PassThru;
    }
    $StartMenuLayout = "$drLImages\LayoutModification.xml";
    if ([System.IO.File]::Exists($StartMenuLayout)) {
        $destpath2 = "$ApplyPath" + 'users\default\appdata\local\Microsoft\Windows\Shell\LayoutModification.xml'
        if ([System.IO.Directory]::Exists("$("$ApplyPath" + 'users\default\appdata\local\Microsoft\Windows\Shell')")) {
            $DefltShellXML = $ApplyPath + 'users\default\appdata\local\Microsoft\Windows\Shell';
            [array]$GetCIDefltShellXML = Get-ChildItem -Path $DefltShellXML -Force | Select-Object -ExpandProperty FullName;
            $GetCIDefltShellXML | ForEach-Object { if ($_ -match "\.xml") { Remove-Item -Path "$_" } }
        }
        Copy-Item `
            -Path $StartMenuLayout `
            -Destination $destpath2 `
            -PassThru;
    }
    [string]$WallpaperRoot = $null;
    [string]$WallpaperRoot = "$ApplyPath\Windows\Web\Wallpaper\Theme2\" ;
    [array]$getdrivewithimages = Get-WmiObject -Class Win32_Volume | `
        Where-Object { [System.IO.Directory]::Exists("$($_.Name)\Images_W10") };
    if ($getdrivewithimages.Count -gt 0) { 
        $getNameofimagesw10 = $getdrivewithimages[0].Name;
        $myimgs = @((Get-ChildItem $getNameofimagesw10\Images_W10\).FullName);
        if (($myimgs.Count -gt 0) -and ((Test-Path $WallpaperRoot)) -eq $true) {
            foreach ($img in $myimgs) {
                Copy-Item -Path $img -Destination "$WallpaperRoot" -Force -ErrorAction 0;
            }
        }
    }
}#end function
function Set-BcdBoot {
    param (
        #ParameterSet: WindowsDirPath, SystemPartition, StylePartitionTable
        [Parameter(Mandatory = $true)]
        [string]$WindowsDirPath,
        [Parameter(Mandatory = $true)]
        [string]$SystemPartition,
        [Parameter(Mandatory = $true)]
        [ValidateSet("Legacy", "UEFI")]
        [string]$StylePartitionTable
    )
    if($SystemPartition.Length -gt 0){
        $SystemPartition=$SystemPartition.ToUpper() -replace "[^A-Z]";
        if ($SystemPartition.Length -gt 0) {
            $SystemPartition=$SystemPartition[0]
        }
        $SystemPartition=$SystemPartition+':';
    } else {
        $SystemPartition=Read-Host "Please, enter drive letter for system partition";
        $SystemPartition=$SystemPartition.ToUpper() -replace "[^A-Z]";
        if ($SystemPartition.Length -gt 0) {
            $SystemPartition=$SystemPartition[0]
        }
        $SystemPartition=$SystemPartition+':';
    }
    if ([string]::IsNullOrEmpty($StylePartitionTable)) {
        if ($env:firmware_type -eq 'Legacy') {
            bcdboot.exe $WindowsDirPath /l ru-ru /s $SystemPartition
        }
        if ($env:firmware_type -eq 'UEFI') {
            bcdboot.exe $WindowsDirPath /l ru-ru /s $SystemPartition /f UEFI
        }
    }
    else {
        if ($StylePartitionTable -eq 'Legacy') {
            bcdboot.exe $WindowsDirPath /l ru-ru /s $SystemPartition
        }
        if ($StylePartitionTable -eq 'UEFI') {
            bcdboot.exe $WindowsDirPath /l ru-ru /s $SystemPartition /f UEFI
        }
    }
}#end function
function Get-UsedSpaceOnVolumeByExistsFileOrDir {
    param(
        #ParameterSet: SearchString
        [Parameter(Mandatory=$true,Position=0,ValueFromPipeline=$true)]
        [string]$SearchString
    )
    Begin{
        [array]$getDriveByTestPath = $null;
        [long[]]$arrayOfCapacities = $null;
        [long[]]$arrayFreeSpaces = $null;
        [long]$totalCapacity = $null;
        [long]$totalFreeSpace = $null;
    }
    Process{
        $getDriveByTestPath = Get-WmiObject win32_volume| `
        Where-Object {if ((Test-Path "$($_.Name)\$SearchString") -and (($_.Name) -notlike "X*")) {return $_.Name}};
        $arrayOfCapacities = $getDriveByTestPath.Capacity;
        $arrayFreeSpaces = $getDriveByTestPath.FreeSpace;
        if ($arrayOfCapacities.Count -gt 1 -and $arrayFreeSpaces -gt 1) {
            foreach ($capacity in $arrayOfCapacities) {
                $totalCapacity += $capacity;
            }
            foreach ($freespace in $arrayFreeSpaces) {
                $totalFreeSpace += $freespace;
            }
        }
        else {
            $totalCapacity += $arrayOfCapacities[-1];
            $totalFreeSpace += $arrayFreeSpaces[-1];
        }
        $rslt = $totalCapacity - $totalFreeSpace;
    }
    End{
        return $rslt
    }
}
#end function
function Get-BackOutWimsContent {
    param (
        #ParameterSet: SourcePath,DestinationPath
        [Parameter(Mandatory = $true,Position=0,ValueFromPipeline=$true)]
        [string]$SourcePath,
        [Parameter(Mandatory=$true,Position=1)]
        [string]$DestinationPath
    )
    begin{
        [array]$fileswim = $null;
        [int]$counterx = 0;
    }
    process {
        if ($SourcePath.Length -lt 1) {
            do {
                $SourcePath = Read-Host "`nPlease, enter exists source directory fullname ";
            } while ((Test-Path -Path $SourcePath) -eq $false)
        }
        $SourcePath = $SourcePath -replace "`"";
        if ($DestinationPath.Length -lt 1) {
            do {
                $DestinationPath = Read-Host "`nPlease, enter exists destination directory fullname ";
            } while ((Test-Path -Path $DestinationPath) -eq $false)
        }
        $DestinationPath = $DestinationPath -replace "`"";
        Write-Host "source path $SourcePath"
        Write-Host "destination path $DestinationPath"
        if (-not (Test-Path -Path $DestinationPath)) {
            mkdir -Path $DestinationPath | Out-Null;
        }
        #copying everything but not a wim files;
        [array]$filesnonwim = ((Get-ChildItem -Path $SourcePath).FullName) | Where-Object { $_ -notlike "*.wim" }
        if ($filesnonwim.Count -gt 0) {
            foreach ($itmnonwim in $filesnonwim) {
                Start-Myrobocopyingfiles -SourcePath $itmnonwim -DestinationPath $DestinationPath;
                #Copy-Item -Path $itmnonwim -Destination $DestinationPath;
            }
        }
        #copying files with wim extension
        [array]$fileswim = ((Get-ChildItem -Path $SourcePath).FullName) | Where-Object { $_ -like "*.wim" }
        foreach ($wimfile in $fileswim) {
            $splitchinwim = $wimfile.Split(':\');
            $splittofolderame = $splitchinwim[-1].Split('_');
            $lastinstring = $splittofolderame[-1];
            $previosinstring = $splittofolderame[-2];
            $newsplt1 = $lastinstring -replace '\.wim';
            if ([string]::IsNullOrEmpty($newsplt1)) {
                $newsplt1 = $newsplt1 + $previosinstring;
            }
            $counterx++;
            $mkdirpath = $DestinationPath + '\' + $counterx + '_' + $newsplt1;
            if (-not ([System.IO.Directory]::Exists($mkdirpath))) {
                New-Item -Path $mkdirpath -ItemType Directory;
            }
            Dism.exe /apply-image /imagefile:$wimfile /index:1 /applydir:"$mkdirpath";
            [int]$HalfWidthOfTheConsole = ([System.Console]::WindowWidth) / 2;
            $SumTOWriteHost = '::' * ($HalfWidthOfTheConsole/2);
            Write-Host "$SumTOWriteHost" -ForegroundColor Yellow;
        }
    }
    end {
        Write-Host "done" -ForegroundColor Green;
    }
}#end function
function Get-MyPSModuleCommands {
    [CmdletBinding(DefaultParameterSetName='Path')]
    param(
        #ParameterSet: ScriptFile
        [Parameter(
           Mandatory = $true,
           Position  = 0,
           ValueFromPipeline=$true)]
        [Alias("sf", "scrfl")]
        [string]
        $ScriptFile
    )
    BEGIN {
        [array]$contarray    = $null;
        [array]$Namefuncword = $null;
        [array]$Parameterset = $null;
        [array]$mypsobjtable = $null;
        [array]$startandend  = $null;
        [int[]]$indxfuncname = $null;
          [int]$tempcount    = 0;
    }
    PROCESS {
	    $ScriptFile=$ScriptFile -replace "`"";
        $rslvdPath=Resolve-Path -Path $ScriptFile;
        $contarray = (Get-Content $rslvdPath);
        if ($contarray.Count -gt 0) {
            $contarray | ForEach-Object {
                $tempitempoint = $_;
                if (("$($tempitempoint.TrimStart())" -match "^function") -and ($tempitempoint -notmatch "=")) {
                    $indxfuncname += ($contarray.IndexOf($tempitempoint));
                    $Namefuncword += (($tempitempoint -replace "function\s+") `
                    -replace "\s+{").Trim();
                }
            }
            for ($i = 0; $i -lt ($indxfuncname.Count); $i++) {
                $a = $i + 1;
                [int]$fstindx = ($indxfuncname[$i]);
                [int]$lstindx = ($indxfuncname[$a]);
                [int]$startslineinterpreter = $fstindx + 1;
                [int]$endslineinterpreter = $lstindx;
                if ($lstindx -eq 0) {
                    [int]$lstindx = $contarray.Count - 1;
                    while ([string]::IsNullOrEmpty($contarray[$lstindx])) {
                        $lstindx--;
                    }
                    [int]$endslineinterpreter = $lstindx + 1;
                }
                $startandend += "$startslineinterpreter----$endslineinterpreter";
                [int[]]$blockstoarray = $fstindx..$lstindx;
                if ($contarray[$blockstoarray] -match "\s+#ParameterSet:") {
                    foreach ($catitmindx in $blockstoarray) {
                        if ($contarray[$catitmindx].TrimStart() -match "^#ParameterSet:") {
                            $Parameterset += (($contarray[$catitmindx] `
                            -replace "#ParameterSet:").Trim());
                        }
                    }
                }
                else {
                    $Parameterset += "0; ParameterSet not commented";
                }
            }
            foreach ($titem in $Namefuncword) {
                $tempcount = $Namefuncword.IndexOf($titem);
                $splitstartend=$startandend[$tempcount] -split "----";
                    $objtofuncnms = New-Object -TypeName PSObject `
                    -Property ([ordered]@{
                    Index = $tempcount;
                    FunctionName = $titem;
                    ParameterSet = $ParameterSet[$tempcount];
                    StartsLine=$splitstartend[0];
                    EndsLine=$splitstartend[-1]}
                    )
                $mypsobjtable += $objtofuncnms;
            }
        }
    }
    END {
        return $mypsobjtable;
    }
}

Export-ModuleMember -Function Get-FolderSizeByComObjct, Get-StoragePointsInfo, Start-TryEjectUsbDrive, Get-CalculationDirsSize, Start-Myrobocopyingfiles, Set-ObjectPremissionForCurrentUser, Get-UnlockDriveWithNumericalPassword, Get-UnlockBitlockerByPassPhrase, Get-UnlockByBEKFile, Set-FolderNamesContainer, Get-CaptureFoldersArrayWithMyPresets, Get-DestinationContainer, Get-JoinedInPEWimImagePath, Set-NetStatAdapConf, Start-MapNetDrive, Start-RemoveNetworkDrives, Start-AutoSearchForDriveWithFreeSpace, Start-AskForSaving, Get-PartitionByFileOrDirectory, Start-FormatingDiskByPartitionLetter, Start-FormatingDisk, Start-ApplyingAnImage, Set-BcdBoot, Get-UsedSpaceOnVolumeByExistsFileOrDir, Get-BackOutWimsContent, Get-MyPSModuleCommands
