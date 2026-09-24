@{
    ModuleVersion     = '2024.1.0'
    GUID              = 'dcf2a76e-e9c7-4637-ada6-a35822a9df2f'
    Author            = 'vilante.andrey@outlook.com; a.a.panasenko@gmail.com'
    CompanyName       = 'Private Automated Lab'
    RootModule        = 'DeploymentCore.psm1' # Имя вашего основного файла скрипта
    FunctionsToExport = @('Get-FolderSizeByComObjct', 'Get-StoragePointsInfo', 'Start-TryEjectUsbDrive', 'Get-CalculationDirsSize', 'Start-Myrobocopyingfiles', 'Set-ObjectPremissionForCurrentUser', 'Get-UnlockDriveWithNumericalPassword', 'Get-UnlockBitlockerByPassPhrase', 'Get-UnlockByBEKFile', 'Set-FolderNamesContainer', 'Get-CaptureFoldersArrayWithMyPresets', 'Get-DestinationContainer', 'Get-JoinedInPEWimImagePath', 'Set-NetStatAdapConf', 'Start-MapNetDrive', 'Start-RemoveNetworkDrives', 'Start-AutoSearchForDriveWithFreeSpace', 'Start-AskForSaving', 'Get-PartitionByFileOrDirectory', 'Start-FormatingDiskByPartitionLetter', 'Start-FormatingDisk', 'Start-ApplyingAnImage', 'Set-BcdBoot', 'Get-UsedSpaceOnVolumeByExistsFileOrDir', 'Get-BackOutWimsContent', 'Get-MyPSModuleCommands')
    CmdletsToExport   = '*'
    VariablesToExport = '*'
    AliasesToExport   = '*'
}
