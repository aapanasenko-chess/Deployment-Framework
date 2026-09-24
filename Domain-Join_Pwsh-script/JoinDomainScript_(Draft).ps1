<#PSScriptInfo

.VERSION 26.02.2018

.GUID dcf2a76e-e9c7-4637-ada6-a35822a9df2f

.AUTHOR vilante.andrey@outlook.com

.COMPANYNAME

.COPYRIGHT

.TAGS

.LICENSEURI

.PROJECTURI

.ICONURI

.EXTERNALMODULEDEPENDENCIES

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES


#>

<#
.DESCRIPTION
 script for rename PC name and join its to domain
#>
Param()
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
 try{
       $srcdir    = Split-Path $Script:MyInvocation.MyCommand.Path;
    }catch{
       Write-Host "Cannot resolve path in Split-Path `$Script:MyInvocation.MyCommand.Path.
       Automation will be skipped after pressing Enter key" -ForegroundColor Red -BackgroundColor Black;
        # $waitFOrPressingEnter=Read-Host "";
        Exit;
    }
try {
        $prDir     = (Get-Item $srcdir).Parent.FullName;
    }catch{
       Write-Host "Cannot resolve path in Split-Path (Get-Item `$srcdir).Parent.FullName.
       Automation will be skipped after pressing Enter key" -ForegroundColor Red -BackgroundColor Black;
       # $waitFOrPressingEnter=Read-Host "";
       Exit;
    }
        <# [string]$notePC    = "$srcdir\notebook.txt";
        [string]$myxml     = "$srcdir\myxml.xml";
        $spc_chars = '[^-a-zA-Z0-9]'; #>
        $CredentialContainerObject= New-Object -TypeName PSObject -Property ([ordered]@{DNUN = $null; Password = $null});
        try {
            [xml]$gcXMLFile =[xml](Get-Content $myxml);
        }
        catch {
            Write-Host "xml file not found or cannot be readable. Automation will be skipped after pressing Enter key";
            # $waitFOrPressingEnter=Read-Host "";
            Exit;
        }
        if(($gcXMLFile.DocumentElement.Name -ne "data") -and ($gcXMLFile.DocumentElement.HasChildNodes -ne $true)){
            Write-Host "xml file found but inner content not acceptable for using. Automation will be skipped after pressing Enter key";
            # $waitFOrPressingEnter=Read-Host "";
            Exit;
        }
  $XmlObjReader=New-Object -TypeName PSObject `
    -Property ([ordered]@{
    InfoDomainConnection=$null;
    CharSetDepends=$null;
    SiteIdentification=$null;
    OUPATHIDs=$null;
    CSVFileName=$null;
    LaptopModelsFile=$null;
    LaptopModelsXMLInPlace=$null;
    NTPServer=$null;
    AppAdditionalInstallation=$null});

$Objectfiltr=New-Object -TypeName psobject -Property @{FilterType=$getchrstandpctype.ThisPCType;}
Add-Member -InputObject $Objectfiltr -MemberType NoteProperty -Name SiteID -Value $testsrchobj.SiteID

Function Get-XMLNodesMemmbersTable{
[CMDLetBinding()]
param(
  [Parameter(Mandatory=$true,Position=0,ValueFromPipeline=$true)]
  [ValidateScript({($_.GetType().Name) -eq 'PSCustomObject'})]
  $XMLGetterObject,
  [Parameter(Mandatory=$true,Position=1,ValueFromPipeline=$false)]
  [ValidateScript({[System.IO.Path]::GetExtension($_) -match '.xml'})]
  $XMlFilePath
)
BEGIN{
        $XMLGetter= New-Object -TypeName PSObject -Property ([ordered]@{});
      }
PROCESS{
    try {
           [xml]$gcXMLFile =[xml](Get-Content $XMlFilePath);
    } catch {
        Write-Verbose "cannt read xml";
        break;
    }
    $XMLGetter=[PSCustomObject]($XMLGetterObject);
    Write-Verbose $XMLGetter
    ($XMLGetter|Get-Member -MemberType NoteProperty)|ForEach-Object{
    [string]$ElementNameInOrder=$_.Name;
    if($null -eq ($gcXMLFile.GetElementsByTagName("$ElementNameInOrder").ChildNodes)){
        $XMLGetter.$ElementNameInOrder=$gcXMLFile.GetElementsByTagName($ElementNameInOrder);
      } else {
        $chldnodesname=($gcXMLFile.GetElementsByTagName("$ElementNameInOrder").ChildNodes|Get-Member -MemberType Property|Where-Object{$_.Name -notmatch "#text"}).Name;
        if($null -ne $chldnodesname){
            $XMLGetter.$ElementNameInOrder=$gcXMLFile.GetElementsByTagName($ElementNameInOrder).ChildNodes;
        } else {
            $XMLGetter.$ElementNameInOrder=$gcXMLFile.GetElementsByTagName($ElementNameInOrder);
        }
      } 
    }
   }
END{
      Write-Verbose $XMLGetter;
      return $XMLGetter;
    } 
 } #Get-XMLNodesMemmbersTable
Function Get-CharsetForThisPCModel {
    <#
    .SYNOPSIS
    Determinating PC model type such as destop or notebook
    and then return charset that depend on function parameters
    or which chosed in existing xml file
    .DESCRIPTION
    Return charset from existing set of chars (specified in Parameters or in XML file)
    by comparing ChassisTypes representing in Win32_SystemEnclosure wmi class. Additionaly,
    specified model name can be inserted to existing txt file to override automatic depends
    #>
    [CmdletBinding()]
    param(
        # Object which must contains ordered state of DesktopVariant and NotebookVariant Charset for feature using of this function process
        [Parameter(Position=0,ValueFromPipeline=$true)]
        [PSCustomObject]$ObjectWithVariant=([ordered]@{DesktopVariant=$null;LaptopVariant=$null}),
        # Charset that was included to xml file, place here path to file
        [ValidateScript({[System.IO.File]::Exists($_)})]
        [String]$XMLFile,
        [ValidateNotNullOrEmpty()]
        [String]$XMLTagName,
        # Help to manualy override systems that can be identify as notebooks. Here in-place array keyswitch for manipulating data return
        [string[]]$NoteBooksModelsArray,
        # Same as NoteBooksModelsArray but using txt file  with a line-by-line structure that includes laptop model names 
        [ValidateScript({[System.IO.File]::Exists($_)})]
        [String]$NotebookModelsFile
    )
    Begin{
        #[string]$sGetPCModelTypeByXMLexpln=$Null;
        $getCharID=$null;
        $contentXMLFile=$null;
        $VariantContainerObj=[PSCustomObject]([Ordered]@{
            DesktopVariant = $null;
            NotebookVariant = $null
        })
        [string[]]$PresetOfNoteBooks=$Null;
        $ResultSelectionTypeAndCharset=[PSCustomObject]([ordered]@{
            ThisPCType=$null;
            ThisPCCharset=$null
        })
    }
    Process{
        [string]$getThisPCModel = (Get-WmiObject Win32_computersystem).model.Trim();
        $NoteBooksModelsArray|ForEach-Object{$PresetOfNoteBooks+=$_};
        try {
            (Get-Content -Path $NotebookModelsFile -Encoding UTF8)|ForEach-Object{$PresetOfNoteBooks+=,$_}
        }
        catch {
            Write-Verbose "Notebooks Models File not available"
        }
        
        switch ($true) {
            {$PSBoundParameters.ContainsKey('ObjectWithVariant')}{$VariantContainerObj=[PSCustomObject]($ObjectWithVariant);break}
            {$PSBoundParameters.ContainsKey('XMLFile')}{
                $contentXMLFile=[xml](Get-Content $XMLFile);
                $getCharID=$contentXMLFile.GetElementsByTagName($XMLTagName);
                $VariantContainerObj.DesktopVariant=$getCharID.DesktopVariant;
                $VariantContainerObj.NotebookVariant=$getCharID.NotebookVariant;
                break
            }
        }
        switch($null -eq (Get-WmiObject win32_battery)){
            {$true} {
                Write-Verbose "battery controller not present";
                 switch (((Get-WmiObject Win32_SystemEnclosure).ChassisTypes)[0]) {
                    {$_ -in "3", "4", "5", "6", "7", "15", "16","23"}{
                         $ResultSelectionTypeAndCharset.ThisPCType='DesktopVariant';
                         $ResultSelectionTypeAndCharset.ThisPCCharset ="$($VariantContainerObj.DesktopVariant)";
                         Write-Verbose "ChassisTypes is ($((Get-WmiObject Win32_SystemEnclosure).ChassisTypes[0])). charset switched to $($VariantContainerObj.DesktopVariant)";
                         break
                    }
                    {$_ -in "8", "9", "10", "11", "12", "14", "18", "21","31"} {
                         $ResultSelectionTypeAndCharset.ThisPCType='NotebookVariant';
                         $ResultSelectionTypeAndCharset.ThisPCCharset ="$($VariantContainerObj.NotebookVariant)";
                         Write-Verbose "ChassisTypes is ($((Get-WmiObject Win32_SystemEnclosure).ChassisTypes[0])). charset switched to $($VariantContainerObj.NotebookVariant)";
                         break
                    }
                 }
                    break
            }
            {$false}{
                Write-Verbose "battery controller is present";
                 switch(((Get-WmiObject Win32_SystemEnclosure).ChassisTypes)[0]){
                        {$_ -in "8", "9", "10", "11", "12", "14", "18", "21","31"} {
                        $ResultSelectionTypeAndCharset.ThisPCType='NotebookVariant';
                        $ResultSelectionTypeAndCharset.ThisPCCharset ="$($VariantContainerObj.NotebookVariant)";
                        Write-Verbose "ChassisTypes is ($((Get-WmiObject Win32_SystemEnclosure).ChassisTypes[0])). charset switched to $($VariantContainerObj.NotebookVariant)";
                        break
                    }
                }
                break
            }
                default{
                        $ResultSelectionTypeAndCharset.ThisPCType='DesktopVariant';
                        $ResultSelectionTypeAndCharset.ThisPCCharset ="$($VariantContainerObj.DesktopVariant)";
                        Write-Verbose "following default switch Char set to $($VariantContainerObj.DesktopVariant)";   
                }
        }
        if ($getThisPCModel -in $PresetOfNoteBooks) {
            Write-Verbose "Charset switched to NotebookVariant because system model was placed in NotebookModelsFile or contains in NoteBooksModelsArray keyswitch preset"
            $ResultSelectionTypeAndCharset.ThisPCType='NotebookVariant';
            $ResultSelectionTypeAndCharset.ThisPCCharset ="$($VariantContainerObj.NotebookVariant)";
        }
    }
    End{
        return $ResultSelectionTypeAndCharset
    }
}#Get-CharsetForThisPCModel

Function Wait-EthernetLinkPlugged{
    $dashchars=@('|';'/';'-';'\')
    do{
        $macaddress=(gcim Win32_NetworkAdapter|Where-Object{
            $_.NetEnabled -eq $true -and $_.PhysicalAdapter -eq $true -and $_.Manufacturer -ne 'Microsoft' -and $_.NetConnectionID -match "Ethernet"}).MACAddress;
        if($null -eq $macaddress){
          $dashchars|ForEach-Object{
            Write-Host "`rNetwork not connected to any physical Ethernet adapter, please plug in cable to PC's LAN-port $_" -NoNewline -ForegroundColor Yellow -BackgroundColor Black;
          Start-Sleep -Seconds 1;
          }
        }
    }while($null -eq $macaddress)
}

Function Get-SiteIdentityObject {
    <#
    .SYNOPSIS
    Search in object for IP mask DHCPEnabled PCs (with IPAddress or DHCP IP Address)and return founded results
    .DESCRIPTION
    Filtering inputed object to output specified information based on network configuration of this PC 
    #>
    [CmdletBinding()]
    param(
    [Parameter(Position=0,ValueFromPipeline=$true)]
    $CustomObject=([ordered]@{IPMaskID=$null;SiteID=$null})
    )
    Begin{
        $ResltThisFunc=$Null;
    }
    Process{
    $ConvertToCustmObj=[PSCustomObject]($CustomObject);
    Write-Verbose "checking Ethernet connection"
    Wait-EthernetLinkPlugged;
    $currentnetadapteridentify=(gcim Win32_NetworkAdapter|Where-Object{
        $_.PhysicalAdapter -eq $true -and $_.Manufacturer -ne 'Microsoft' -and $_.NetEnabled -eq $true -and $_.NetConnectionID -match "Ethernet"});
    $gtmac=$currentnetadapteridentify.MACAddress;
    if($null -eq $ConvertToCustmObj.IPMaskID){Break}
    if(!(gcim Win32_NetworkAdapterConfiguration|Where-Object{$_.MACAddress -eq $gtmac}).DHCPEnabled){Break}
        $currentDHCP=(gcim Win32_NetworkAdapterConfiguration|Where-Object{$_.MACAddress -eq $gtmac}).DHCPServer;
        $currentIPAddress=(gcim Win32_NetworkAdapterConfiguration|Where-Object{$_.MACAddress -eq $gtmac}).IPAddress;
        $getcurrentipv4=$currentIPAddress|Where-Object{$_ -match "\d{1,3}\.\d{1,3}\.\d{1,3}.\d{1,3}"}
        $ResltThisFunc=$ConvertToCustmObj|Where-Object{$getcurrentipv4 -match $_.IPMaskID}
        if ($null -eq $ResltThisFunc){$ResltThisFunc=$ConvertToCustmObj|Where-Object{$currentDHCP -match $_.IPMaskID}}
    }
    End{
        Return $ResltThisFunc
    }
}#end Get-SiteIdentityObject

Function Find-NewSuffixNameForThisPC {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false,Position=0,ValueFromPipeline=$true)]
        $InsertObjectSrchs=([ordered]@{SerialNumber={};OldName={};NewNameSuffix={}}),
        [Parameter(Mandatory=$false)]
        [ValidateScript({[System.IO.File]::Exists($_)})]
        [string]$PathToCSVFile
    )
    Begin{
        $NewSuffixName=$null;
        $SysInfoObject=[PSCustomObject]([ordered]@{
            ThisPCSerialNumber=[string]((gcim win32_bios).serialnumber).Trim();
            ThisPCCurrentName=[string]((gcim win32_computersystem).name).Trim();
            ThisPCBaseBoardSN=[string]((gcim Win32_BaseBoard).SerialNumber).Trim();
            ThisPCPhysAdapMac=[string]((gcim win32_networkadapter|Where-Object{$_.Manufacturer -ne "Microsoft" -and $_.NetEnabled -eq $true -and $_.PhysicalAdapter -eq $true -and $_.NetConnectionID -match "Ethernet"}).MACAddress) -replace "[^0-9A-F]","";
            })
    }
    Process{
   
    switch ($true) {
        {$PSBoundParameters.ContainsKey('InsertObjectSrchs')}{$ImportCSVdata = [PSCustomObject]($InsertObjectSrchs);break}
        {$PSBoundParameters.ContainsKey('PathToCSVFile')}{
            try {
            $ImportCSVdata = Import-Csv $PathToCSVFile -Header SerialNumber, OldName, NewNameSuffix -Delimiter ';';
            } catch {
            $ImportCSVdata = $null;
            }
        break}
    }
    try{
    Write-Verbose $ImportCSVdata
    }catch{
    }
    #filter non-valued properies
    $resltgtcstmobjt=([PSCustomObject]@{});
    ($SysInfoObject|Get-Member -MemberType NoteProperty).Name|Where-Object{
         $null -ne ($SysInfoObject.$_) -and "None" -ne ($SysInfoObject.$_)}|ForEach-Object{
            $resltgtcstmobjt|Add-Member -MemberType NoteProperty -Name $_ -Value $SysInfoObject.$_ }

    if ($null -ne $ImportCSVdata){
        ($resltgtcstmobjt|Get-Member -MemberType NoteProperty).Name|ForEach-Object{
         $valnoteprop=$resltgtcstmobjt.$_;
          $ImportCSVdata|Where-Object{$csvrow=$_;
           if((("$($csvrow.SerialNumber)".Trim() -replace "[^-0-9a-zA-Z]","") -eq $valnoteprop) `
           -or (("$($csvrow.OldName)".Trim()  -replace "[^-0-9a-zA-Z]",""))){
            $NewSuffixName=$csvrow.NewNameSuffix;
            Write-Verbose "$NewSuffixName";
            }
           }
        }
    }
    }   
    End{
        While($NewSuffixName.Length -lt 9){$NewSuffixName= '0'+$NewSuffixName;}
        Write-Verbose "$NewSuffixName"
        return $NewSuffixName
    }
}#end Find-NewSuffixNameForThisPC
Function Get-FilterMyObject{
    <#
    .SYNOPSIS
    filter one object by another object.
    .DESCRIPTION
    Acceptable object must be PScustomobject with data or get xml properties by Get-XMLNodesMemmbersTable
    #>
 [CMDLetBinding()]
 param(
         [Parameter(Mandatory=$true,Position=0,ValueFromPipeline=$true)]
         [ValidateScript({(($_|Get-Member -MemberType Properties).TypeName) -eq 'System.Xml.XmlElement' `
         -or (($_|Get-Member -MemberType Properties).TypeName) -eq 'System.Management.Automation.PSCustomObject'})]
         $InputSourceObject,
         [Parameter(Mandatory=$true,Position=1,ValueFromPipeline=$true)]
         [ValidateScript({(($_|Get-Member -MemberType Properties).TypeName) -eq 'System.Xml.XmlElement' `
         -or (($_|Get-Member -MemberType Properties).TypeName) -eq 'System.Management.Automation.PSCustomObject'})]
         $SearchObject
        )
BEGIN{
         $WorkObject = New-Object -TypeName PSObject -Property ([ordered]@{});
         $Objectfilt = New-Object -TypeName PSObject -Property ([ordered]@{});
        }
PROCESS{
         $WorkObject=[PSCustomObject]($InputSourceObject);
         $Objectfilt=[PSCustomObject]($SearchObject);
    
         $propertynamereslt=($WorkObject|Get-Member -MemberType Properties).Name|Where-Object{
         ($Objectfilt|Get-Member -MemberType Properties).Name -eq $_}
         
         $propertynamereslt|ForEach-Object{
         $tempitmname=$_;
         $tempitmval=$Objectfilt.$tempitmname;
         $WorkObject=$WorkObject|Where-Object{($_.$tempitmname -eq $tempitmval)}
         }
    }
END{
     return $WorkObject
    }    
}
Function Get-MyPass{
  [CmdletBinding()]
  # Parameter help description
  param(
    [Parameter(Mandatory=$false)]
    [string]
    $DomainUserName='domain\username',
    [Parameter(Mandatory=$false)]
    [string]
    $DomainUserPSWD
  )
  begin{
    $MyCredentialObject = $null;
    $MyCredentialObject = New-Object -TypeName PSObject -Property ([ordered]@{DNUN = $null; Password = $null})
    if ([string]::IsNullOrEmpty($DomainUserPSWD)) {
        try {
            $srcdir    = Split-Path $Script:MyInvocation.MyCommand.Path
        }
        catch {
            $srcdir =$Null
        }
        try {
            $prDir     = (Get-Item $srcdir).Parent.FullName
        }
        catch {
            $prDir     = $null;
        }
    }
  }
  process{
    <#
        if ($Phrase.Length -lt 8) {
            do {
                [securestring]$PhraseRH = $null;
                Write-Host "Passpharse less then 8 digits" -ForegroundColor DarkGray;
                $PhraseRH = Read-Host "Enter Bitlocker Password, Please" -AsSecureString;
            } while ($PhraseRH.Length -lt 8)
            $BSTR = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($PhraseRH);
            $Phrase = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($BSTR);
        }
    #>

    if ([System.IO.File]::Exists("$prDir\input_data\pass.txt")) {
      #если есть pass.txt в указанном расположении
      [string[]]$DomainUserPSWD = Get-Content "$prDir\input_data\pass.txt";
      if ($DomainUserPSWD.Count -gt 0) {
          #если есть данные в pass.txt
          $MyCredentialObject.Password = $DomainUserPSWD.Trim();
      }
      else {
          #если pass.txt пуст
          Write-Verbose "Введите пароль для пользователя с правами в Active Directory"
          try {
              $gtCrds = (Get-Credential -Credential $DomainUserName);
          }
          catch {
            Write-Verbose "get credential fails. the script will be stoped";
           <# $getPressEnter=$Null;
            $getPressEnter= Read-Host "Press Enter"; #>
            break; exit}
          $MyCredentialObject.Password = $gtCrds.GetNetworkCredential().Password;
          if ($gtCrds.UserName -ne 'domain\username') {
              $MyCredentialObject.DNUN = $gtCrds.UserName;
          }
      }
  }
  else {
      #если нету файла в указанном расположении
      Write-Verbose "Введите пароль для пользователя с правами в Active Directory"
      try {
          $gtCrds = (Get-Credential -Credential $DomainUserName)
      }
      catch {
        Write-Verbose "get credential fails. the script will be stoped";
        # $getPressEnter=$Null;
        # $getPressEnter= Read-Host "Press Enter";
         break;
          exit}
        $MyCredentialObject.DNUN = $gtCrds.UserName
        $MyCredentialObject.Password = $gtCrds.GetNetworkCredential().Password
    }
  }
  end{
    return $MyCredentialObject
  }
}#Get-MyPass
Function Start-GetOSName{
    $mOS = (Get-WmiObject win32_operatingsystem)|Select-Object Caption,BuildNumber,Version;
    return $mOS;
}#GetOSName
Function Start-RenameOldName {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({("$_").Length -eq 15})]
        [String]
        $NewComputerName
    )
    [string]$oldName = (Get-WmiObject win32_ComputerSystem).Name;
    if ($NewComputerName -eq $oldName){
        $NewComputerName = Read-Host "новое и старое имена совпадают .`n напишите новое имя ПК в этом окне";
    }
    $rtn = 0;
    if ($NewComputerName -ne $oldName) {
        Write-Verbose "изменение имени ПК..."
        $my_rslt = (Get-WmiObject win32_computersystem -ComputerName $oldName).Rename($NewComputerName);
        #Start-Sleep 3;
        $rtn = $my_rslt.ReturnValue;
    }    
    switch ($rtn) {
        0 { Write-Verbose "New computer name $newName"; break }
        default { Write-Verbose "Operation for Rename Computer return value $rtn" }
    }
}#RenameOldName

function New-WScriptNetworkMapDrives {
    [CmdletBinding()]
    param (
        [string]$NetworkPath,
        [string]$MapToDriveLetter,
        [string]$CredentialUserName,
        [string]$CredentialPassword
    )
    
    begin {
        $WscriptNetObj = New-Object -ComObject WScript.Network;
    }
    
    process {
        if ($MapToDriveLetter -notcontains ':') {
            $MapToDriveLetter=$MapToDriveLetter+ ':';
        }
        "$MapToDriveLetter";
        $WscriptNetObj.MapNetworkDrive($MapToDriveLetter, $NetworkPath, $false, $CredentialUserName, $CredentialPassword);
    }
    
    end {
        return $MapToDriveLetter
    }
}
function Start-Myrobocopyingfiles {
    [CmdletBinding(PositionalBinding=$true)]
    param(
        #ParameterSet: SourcePath, DestinationPath, NamedContainer
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [ValidateScript({(Get-Item $_).Exists -eq $true})]    
        [string]$SourcePath,
        [Parameter(Mandatory = $true, Position = 1)]
        [string]$DestinationPath,
        [Parameter(Mandatory = $false, Position = 2,
            HelpMessage="
                         (0)-default; 
                         (4)-Do not display a progress dialog box;
                         (8)-Give the file being operated on a new name in a move, copy, or rename operation if a file with the target name already exists;
                        (16)-Respond with 'Yes to All' for any dialog box that is displayed
                        (64)Preserve undo information, if possible.
                        (128)-Perform the operation on files only if a wildcard file name (*.*) is specified.
                        (256)-Display a progress dialog box but do not show the file names.
                        (512)-Do not confirm the creation of a new directory if the operation requires one to be created.
                        (1024)-Do not display a user interface if an error occurs.
                        (2048)-Version 4.71. Do not copy the security attributes of the file.
                        (4096)-Only operate in the local directory. Do not operate recursively into subdirectories.
                        (8192)-Do not copy connected files as a group. Only copy the specified files.
                        Summ of values for vOptions can be used for multiple dialog operations while copying files")]
        [ValidateSet(0,4,8,16,64,128,256,512,1024,4096,8192)]
        [Int[]]$CopyHereINTOptions=0
    )
    begin {
    
    try{
        Get-Item $DestinationPath -ErrorAction Stop;
    }
    catch [System.Management.Automation.ItemNotFoundException]{
    mkdir $DestinationPath -ErrorAction Stop
    }
    catch [System.UnauthorizedAccessException]{
       Write-Host -Object "Cann't create item in destination path: $($_.Exception.Message)" -ForegroundColor Red 
    }
    catch {
      Write-Host -Object "Some error occurs: $($_.Exception.Message)"
      Break;
    }
        # [string]$IFSourceFileOrDir = $null;
        [int]$SumIntOptions=$null;
    }
    process {
        $CopyHereINTOptions|ForEach-Object{$SumIntOptions+=$_;}
        (New-Object -ComObject "Shell.Application").Namespace($DestinationPath).CopyHere($SourcePath,$SumIntOptions);  
    }
    end {
    try{
        Get-ChildItem $DestinationPath -ErrorAction Stop;
        }
        catch [System.UnauthorizedAccessException]{
         Write-Host "Cann't access item in destination path:" "$($_.Exception.Message)" -ForegroundColor Red
    }
    catch{Write-Host "$_.Exception.Message" -ForegroundColor Red}
        return $DestinationPath;
    }
}#end Start-Myrobocopyingfiles
Function Start-InstCCM {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateScript({(Get-Item $_).Exists})]
        [string]
        $BatOrExeFullPath
    )
    # $ccmsetupid=$null;
    #Start-Myrobocopyingfiles -SourcePath "$prDir\ccmclient" -DestinationPath "C:\Intel\NewCCMClient" -CopyHereINTOptions 16;
<#

#>
     try {
            $ccmsetupid = (Start-Process $BatOrExeFullPath -PassThru).Id;
        }
    catch {
            $ccmsetupid = $null;
        }
    #Start-Sleep -Seconds 2;
    $countersetup=0;
    do {
        $countersetup++;
        $gwmiccmsetup =(Get-WmiObject win32_process -Filter "Name='ccmsetup.exe'");
        $gwmiccmexec  =(Get-WmiObject win32_process -Filter "Name='CCMExec.exe'");
        $frmtlog="`r $countersetup Waiting for ccmsetup execute..." ;
        Write-Host "$frmtlog" -NoNewline -ForegroundColor Yellow -BackgroundColor Black;
        Start-Sleep -Seconds 3
    } while (($null -eq $gwmiccmsetup) -and ($null -eq $gwmiccmexec))
}#Search For SCCM remote control service and Start its if disabled

Function Set-LocalUserName{
    <#
    .SYNOPSIS
    Search wmi win32_useraccount for SID 
    .DESCRIPTION
    By default SID for key 'SearchSIDWithOldName' is "^S-\d{1}-\d{1}-\d{2}-\d{10}-\d{10}-\d{10}-500$". You can use exact SID or put string mask like it was placed by default
    #>
    [CmdletBinding()]
    param(
        [Parameter(HelpMessage="Use Regex like '^S-\d{1}-\d{1}-\d{2}-\d{10}-\d{10}-\d{10}-500$' or exact user sid for this key")]
        [String]$SearchSIDWithOldName="^S-\d{1}-\d{1}-\d{2}-\d{10}-\d{10}-\d{10}-500$",
        [Parameter(Mandatory=$true)]
        [String]$NewUserName
    )
BEGIN{

    }
PROCESS{
    {Get-WmiObject win32_useraccount -filter "LocalAccount='TRUE'"|Where-Object{$_.SID -eq "$SearchSIDWithOldName"}|ForEach-Object{
        $_.disabled=$False;
        $_.Put()
        $_.Rename($NewUserName)
        }
    }
    }
END{

   }
}

Function myExit{
    param(
        [ValidateSet ("Yes", "No")]
        [string]
        $ExitWithDomainJoined = 'No',
        [ValidateSet ("Yes", "No", 'Ask')]
        [string]
        $DoRebootTheSystem = 'No'
    )
    begin {

    }
    process {
        if ($ExitWithDomainJoined -eq 'Yes') {
            #Rename administrator account

        }
        #ASK FOR RESTARTING THE $CN SYSTEM
        switch ($DoRebootTheSystem) {
            Yes { Restart-Computer -Force }
            No { Write-Host "`n Просьба перезагрузить ПК после проверки. press Enter to Exit"; Start-Sleep 10; Exit; }
            Ask {
                $mYorN = [System.Windows.Forms.MessageBox]::Show( "Хотите перезагрузить ПК?", "", 'YesNo');
                if ($mYorN -eq 'No') {
                    Write-Host "Просьба перезагрузить ПК после проверки. press Enter to Exit"; Start-Sleep 10; Exit;
                }
                elseif ($mYorN -eq 'Yes') {
                    Restart-Computer -Force;
                }
            }
        }
    }
    end {
        Write-Host "Изменения вступят в силу после перезапуска ПК";
    }
}#end function
Function Jn_W7{
 [string[]]$FiltrDN=Get-WmiObject win32_networkadapterconfiguration -filter 'DNSDomain!=Null'| `
                    Select-Object -expandproperty DNSDomain;
 $hexSum=(0x423);
 if($FiltrDN.Count -gt 0){
  $DN=$FiltrDN[0];
 }
 if($FiltrDN.Count -lt 1){
  break;
 }
 Write-Host "производится ввод в домен...$DN"
 $tUSRNM=$CredentialContainerObject.DNUN;
 $tPass=$CredentialContainerObject.Password;
 if(!([string]::IsNullOrEmpty($tOU)))
 {
  Write-Host "Ожидается ввод ячейку $tOU..."
  $jnw7_PC=(Get-WmiObject win32_computersystem).JoinDomainOrWorkgroup($DN,$tPass,$tUSRNM,$tOU,$hexSum).ReturnValue
 }
 else
 {
  Write-Host "Ожидается ввод в домен, без указания OU в AD..."
  $jnw7_PC=(Get-WmiObject win32_computersystem).JoinDomainOrWorkgroup($DN,$tPass,$tUSRNM,$null,$hexSum).ReturnValue
 }
 if($jnw7_PC -ne 0){Write-Host "ввод в домен не выполнен, возвращенный код ошибки: $jnw7_PC"}
 return $jnw7_PC
}
Function MyAddPC{
 RenameOldName;
 Start-Sleep 2;
 $jndm=Jn_W7;
 switch($jndm){
                     0{Write-Host "Ввод выполнено успешно"; break;}
                     5{Write-Host "Недостаточно прав"; break;}
                    87{Write-Host "Не корректно введены параметры" ;break;}
                  1326{Write-Host "Неправильное имя или пароль"; break;}
                  1355{Write-Host "Домен не доступен, проверьте подключение к доменной сети"}
                  2224{Write-host "$DN не доступен или учетная запись ПК отключена в Active Directory"}
               default{Write-Host "Join Domain return value $jndm"}
              }
    return $jndm;
}#end of MyAddPC
Function WinTMserv{
 param(
     [string]
     $ManualPeerList,
     [string]
     $SearchForDomain
 )
 begin{
    [string]$GetCurrentDomain=$null;
    [string]$GetServiceStatus=$null;
 }
 process{
    [string]$GetCurrentDomain=(Get-WmiObject win32_computersystem).Domain;
    [string]$GetServiceStatus=(Get-Service -name W32Time).Status;
    if( $GetCurrentDomain -ne "$DN")
    {
      if( $GetServiceStatus -ne 'Running'){
          Write-Host "Ожидайте идет установка настроек даты и времени...";
          set-service -name w32time -startuptype manual -status running|Out-Null;
          w32tm /config /manualpeerlist:"$tNTPServer" /syncfromflags:manual /reliable:yes /update|Out-Null;
          set-service -name w32time -status stopped|Out-Null;
          set-service -name w32time -status running|Out-Null;
          Start-Sleep 2;
          #w32tm /query /status
      }
    }
 }
  end{
        w32tm /resync|Out-Null;
        Start-Sleep 2;
    }
}#end wintmserv
Function MyStart{
 $Error.Clear()

    #Write-Host "Здраствуйте!

           #     Давайте приступим к вводу этого ПК в домен $DN";

    switch (Start-GetOSName) {
        10 {
            Set-WinUserLanguageList -LanguageList en-US, ru-RU, uk-UA -Force;
            Start-Process -FilePath "C:\WINDOWS\system32\rundll32.exe" -ArgumentList 'Shell32.dll,Control_RunDLL "C:\WINDOWS\system32\intl.cpl",,1'
        }
        default {
            write-host "language list automation skiped for this OS";
        }
    }
    if ([string]::IsNullOrEmpty($tNTPServer)) {
        Write-Host "Просьба выставить корректную дату и время, а затем закройте окно Параметров для продолжения сценария"
        $msBox = [System.Windows.Forms.MessageBox]::Show( "Хотите изменить Дату или Время?", "", "YesNo")
        switch ($msBox) {
            Yes {
                $st_Tm_Dt = (Start-Process "C:\windows\system32\rundll32.exe" `
                        -ArgumentList 'Shell32.dll,Control_RunDLL "C:\windows\system32\timedate.cpl"' `
                        -PassThru).Id;
                Wait-Process -Id $st_Tm_Dt;
            }
            No {
               # Write-Host "Если в системе будет содержаться некорректная
                                       # дата или время то произойдет сбой активации Windows";
                #Start-Sleep 2;
            }
        }
    }
    else { WinTMserv -ManualPeerList $tNTPServer -SearchForDomain $DN; }
    Start-Sleep 2
    Write-Host "automate searched computer name $CN";
    if ([string]::IsNullOrEmpty($CredentialContainerObject.DNUN) -or [string]::IsNullOrEmpty($CredentialContainerObject.Password)) {
        $CredentialContainerObject = Get-MyPass -DomainUserName $tUSRNM;
    }
    If (((Get-WmiObject win32_computersystem).Domain) -eq "$DN") {
        $askRenPC = [System.Windows.Forms.MessageBox]::Show( "ПК уже является частью домена. Хотите изменить имя ПК?", "", "YesNo")
        switch ($askRenPC) {
            Yes {
                RenameOldName;
                InstCCM;
                #SearchForService;
                Break
            }
            No {
                InstCCM;
                #SearchForService;
                Break
            }
            default { Read-host "Choise is closed, run against this script"; }
        }
    }
    else {
        $GetRsltMyAdd=MyAddPC;
        InstCCM;
        #SearchForService;
        return $GetRsltMyAdd;
    }
}#end MyStart
#Write-Host "Инициализация переменных. для некоторых может понадобиться ручной ввод"
#initializing variables


            $fstChr    = Set-FirstChar; #write-host "4";
            $setSt	   = Set-Site; #write-host "5";
            $setPF	   = Set-Postfix; #write-host "6";"PF-$setPF";
            $CN        = "$fstChr$setST-$setPF"; #write-host "7";$CN;
            $tgetXml  = Get-MyXMl -XmlPath $myxml; #write-host "8";
            $tOU      = ForOUPATH -PathToXMLFile $myxml; #write-host "9";
[string]$shdomain  = $tgetXml[0]; #write-host "11";
[string]$DN        = $tgetXml[1]; #write-host "12";
[string]$tUZ       = $tgetXml[2]; #write-host "13";
#[string]$tCSVFileName = $tgetXml[3]; #write-host "14";
[string]$tNTPServer   = $tgetXml[4]; #write-host "15";
[string]$FSMBMapping = $tgetXml[5];
[string]$tUSRNM   	  = "$shdomain\"+"$tUZ"; #write-host "17";

$tstDNSDom= Get-WmiObject win32_networkadapterconfiguration -filter 'DNSDomain!=Null'| `
                        Select-Object -expandproperty DNSDomain;
#Write-host "ПК подключен к сети $tstDNSDom"
[int]$DNSDomLength=$tstDNSDom.Length
[bool]$DNSbool=$DNSDomLength -gt 3
switch($DNSbool)
{
  $true{
    #Write-Host "Call MyStart";
    if(Mystart -eq 0){
        myExit -ExitWithDomainJoined Yes -DoRebootTheSystem Ask;
    }else{
        myExit -ExitWithDomainJoined No -DoRebootTheSystem No;
    }
  }
  $false{
    Write-host "Domain placed in xml and connection for this PC doesn't equals or you doesn't connected to any network";
    myExit -ExitWithDomainJoined  No -DoRebootTheSystem No;
  }
}

