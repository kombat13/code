
<#
.Synopsis
    scanHPiLO.ps1
    Этот скрипт предназначен для поиска ilo в заданных диапазонах.

.DESCRIPTION
    Скрипт сканирует заданные диапазоны IP и формирует массив и сохраняет данные в файл CSV
	Работает с использованием функции Find-HPiLO модуля HPiLOCmdlets
    Перед использованием настроить $PathToSaveResult - путь для сохранения результата.

.EXAMPLE
    None (by default)

.INPUTS
	None (by default)

.OUTPUTS
    None (by default)

.NOTES
	Company : 
    Version : 1.0.0.0
    Date    : 22/11/2019 



.LINK
    
#>
$CurDate = (Get-Date -Format yyyyMMdd).ToString()
$PathToSaveResult = $env:USERPROFILE + "\" + $CurDate + "_ilo_scaned_info.csv"
$ILOscanedIPs = $null
$iloIPRange =   "192.168.0.", 
                "192.168.1."                
$ILOscanedIPs = find-hpilo -range $iloIPRange -Full -Timeout 30 -Verbose
$ILOscanedIPs.Count
$FieldNames =   'IP',
                'HOSTNAME',
                'HSI_SBSN',
                'HSI_PRODUCTID',
                'MP_PN',
                'MP_FWRI',
                'HSI_SPN',
                'BLADESYSTEM_MANAGER.ENCL',
                'BLADESYSTEM_BAY',
                'MP_PWRM',
                'MP_UUID',
                'HSI_cUUID',
                'HEALTH_STATUS'

$AllColectedData = @()
foreach ($iloInfo in $ILOscanedIPs) {
    $obj = New-Object PSObject
    foreach ($fieldName in $FieldNames) {
        $value = $fieldName.Split('.') | ForEach-Object `
            -Begin { $field = $iloInfo } `
            -Process { $field = $field.$_ } `
            -End { $field }
        if (-not $value) {$value = ''}
        if ($fieldName -eq 'BLADESYSTEM_MANAGER.ENCL'){$fieldName = 'ENC_NAME'}
        if ($fieldName -eq 'BLADESYSTEM_BAY'){$fieldName = 'ENC_BAY'}
        $obj | Add-Member -MemberType NoteProperty -Name $fieldName -Value ([string]$value).Trim()
    }
    $AllColectedData += $obj
}
$AllColectedData | Export-Csv -Path $PathToSaveResult -NoTypeInformation
Write-Host "Script ilo_findtoscv end. Scanned " $alladresscount " IPs"
$dtcount = $AllColectedData.count
Write-Host "Result write to File "$PathToSaveResult ". File contains " $dtcount " lines"
$customTitle = 'HP iLO scan result. Found ' + $dtcount + " servers"
$AllColectedData | Out-GridView -Title $customTitle
