<#
.Synopsis
    Stage2.ps1
    Этот скриптр предназначен для добавления данных о iLO в CSV файл. Step2

.DESCRIPTION
    Скрипт импортирует данные из файла CSV подготовленного с помощью Stage1.ps1
    Затем опрашивает указанные там адреса iLO и с помощью функций Get-HPiLOLicense и Get-HPiLODirectory
	модуля HPiLOCmdlets получает дополнительные данные о iLO и формирует новый расширенный CSV

.EXAMPLE
    C:\Scripts\ILO_Inventory\Stage2.ps1 -RangeName "TST"

.INPUTS
	None (by default)

.OUTPUTS
    None (by default)

.NOTES
	Company : 
    Version : 1.0.0.0
    Date    : 27/02/2021 

.LINK

#>
Param(
    [Parameter (Mandatory = $true)]
    [string]$RangeName
)
Clear-Host
if ($RangeName -eq 'RSB') { $iLo_Username = 'Administrator'; $iLo_Passwd = '' }
if ($RangeName -eq 'DKB') { $iLo_Username = 'Administrator'; $iLo_Passwd = '' }
if ($RangeName -eq 'PAR') { $iLo_Username = 'Administrator'; $iLo_Passwd = '' }
if ($RangeName -eq 'TST') { $iLo_Username = 'Administrator'; $iLo_Passwd = '' }
if ($RangeName -eq 'TTT') { $iLo_Username = 'Administrator'; $iLo_Passwd = '' }
if ($RangeName -eq 'RFB') { $iLo_Username = 'Administrator'; $iLo_Passwd = '' }
# Зададим параметры по умолчанию
$PSDefaultParameterValues = @{ 
    "Get-HPiLO*:Username"                         = $iLo_Username
    "Get-HPiLO*:Password"                         = $iLo_Passwd
    "Get-HPiLO*:DisableCertificateAuthentication" = $true
    "Get-HPiLO*:ErrorAction"                      = "SilentlyContinue"
    "Get-HPiLO*:Verbose"                          = $true
}
# Подготовим пути к файлам
$WorkDir = 'C:\ScriptsRes\ILOFindRes'                                                     # Дирректория с файлами
$dt = (Get-Date -Format yyyyMMdd).ToString()                                              # Получим сегодняшнюю дату в подходящем формате
$Path_to_import_csv = $WorkDir + "\" + $dt + "_" + $RangeName + "_" + "St1_FindRes.csv"   # Соберем путь, для загрузки списка
$Path_to_export_csv = $WorkDir + '\' + $dt + " " + $RangeName + "_" + "St2_DetInfo.csv"   # Соберем путь, для сохранения результатов
# Проверим наличие файлов с входными данными
if ((test-path -path $Path_to_import_csv) -eq $true) {
    Write-Host "Файл для импорта "$Path_to_import_csv
}
else {
    Write-Host "Файл "$Path_to_import_csv" не найден" -ForegroundColor Red
    return
}
# Импортируем данные от скрипта Stage1
$AlliLOscanedInfo = Import-Csv -Path $Path_to_import_csv
Write-Host "Импортировано "$AlliLOscanedInfo.Count" записи"
$All_result = @()
$AlliLOscanedInfo.Count
$schetchik = 0
#$AlliLOscanedInfo = $AlliLOscanedInfo | select-object -First 20 | select-object -Last 10
# $AlliLOscanedInfo | ft
# Опросим все полученные хосты
foreach ($key in $AlliLOscanedInfo) {
    $schetchik++
    $procent = [math]::Round($schetchik * 100 / $AlliLOscanedInfo.Count, 2) 
    Write-Host "`nConnecting using Connect-HPiLO`n" -ForegroundColor Yellow
    Write-Host "Выполнено" $procent"%." "Хост:"$key.IP"-"$key.HOSTNAME "Элемент:"$schetchik "из:"$AlliLOscanedInfo.Count -ForegroundColor Green

    # Выполним запросы к ILO, ILO2 пропустим.
    if ($key.MP_PN -like "*2") {
        Write-Host "Ilo 2 - skip"
        $result_lic = ""
        $result_ads = ""
        $result_SNM = ""
        $result_FQDN = ""
        $result_SRVI = ""
        $result_FIRMWARE = ""
        $result_SNMPSET = ""
        $result_iLONet = ""
        $result_iLOHealth = ""
        $result_iLOHostPower = ""
        $result_iLOSDCard = ""
    }
    else {
        $result_lic = Get-HPiLOLicense             -Server $key.IP
        $result_ads = Get-HPiLODirectory           -Server $key.IP
        $result_SNM = Get-HPiLOServerName          -Server $key.IP
        $result_FQDN = Get-HPiLOServerFQDN         -Server $key.IP
        $result_SRVI = Get-HPiLOServerInfo         -Server $key.IP
        $result_FIRMWARE = Get-HPiLOFirmwareInfo   -Server $key.IP
        $result_SNMPSET = Get-HPiLOSNMPIMSetting   -Server $key.IP
        $result_iLONet = Get-HPiLONICInfo          -Server $key.IP
        $result_iLOHealth = Get-HPiLOHealthSummary -Server $key.IP
        $result_iLOHostPower = Get-HPiLOHostPower  -Server $key.IP
        $result_iLOSDCard = Get-HPiLOSDCardStatus  -Server $key.IP
        if ($key.MP_PN -like "*4" -or $key.MP_PN -like "*5") {
            $connection = Connect-HPEiLO $key.IP -Username $iLo_Username -Password $iLo_Passwd -DisableCertificateAuthentication -ErrorAction SilentlyContinue
            if ($connection) {
                $NTPSettings = Get-HPEiLOSNTPSetting           -Connection $connection
                $iLORemoteSup = Get-HPEiLORemoteSupportSetting -Connection $connection
                $iLOAMSstatus = Get-HPEiLOHealthSummary        -Connection $connection
                $iLOAHSstatus = Get-HPEiLOAHSStatus            -Connection $connection
            }
        }
    }

    $obj_str = New-Object PSObject
    # Добавим поля из импортированного файла
    $obj_str | Add-Member -MemberType NoteProperty -Name RANGE         -Value $key.RANGE
    $obj_str | Add-Member -MemberType NoteProperty -Name IP            -Value $key.IP
    $obj_str | Add-Member -MemberType NoteProperty -Name HOSTNAME      -Value $key.HOSTNAME
    $obj_str | Add-Member -MemberType NoteProperty -Name HSI_SBSN      -Value $key.HSI_SBSN
    $obj_str | Add-Member -MemberType NoteProperty -Name HSI_PRODUCTID -Value $key.HSI_PRODUCTID
    $obj_str | Add-Member -MemberType NoteProperty -Name MP_PN         -Value $key.MP_PN
    $obj_str | Add-Member -MemberType NoteProperty -Name MP_FWRI       -Value $key.MP_FWRI
    $obj_str | Add-Member -MemberType NoteProperty -Name HSI_SPN       -Value $key.HSI_SPN
    $obj_str | Add-Member -MemberType NoteProperty -Name ENC_NAME      -Value $key.ENC_NAME
    $obj_str | Add-Member -MemberType NoteProperty -Name ENC_BAY       -Value $key.ENC_BAY
    $obj_str | Add-Member -MemberType NoteProperty -Name HSI_cUUID     -Value $key.HSI_cUUID
    # Добавляем результаты запросов
    $temp = $result_lic.LICENSE_KEY; if ($result_lic.STATUS_TYPE -ne "OK") { $temp = $result_lic.STATUS_MESSAGE }
    $obj_str | Add-Member -MemberType NoteProperty -Name LICENSE_KEY -Value $temp
    $obj_str | Add-Member -MemberType NoteProperty -Name LICENSE_INSTALL_DATE -Value $result_lic.LICENSE_INSTALL_DATE
    $temp = $result_ads.DIR_AUTHENTICATION_ENABLED; if ($result_ads.STATUS_TYPE -ne "OK") { $temp = $result_ads.STATUS_MESSAGE }
    $obj_str | Add-Member -MemberType NoteProperty -Name DIR_AUTHENTICATION_ENABLED -Value $temp
    $obj_str | Add-Member -MemberType NoteProperty -Name DIR_SERVER_ADDRESS -Value $result_ads.DIR_SERVER_ADDRESS
    $temp = $null; $temp = $result_SNMPSET.SECURITY_NAME
    $obj_str | Add-Member -MemberType NoteProperty -Name SMTP_SECURITY_NAME -Value $temp
    $temp = $result_SNMPSET.SNMP_PORT
    $obj_str | Add-Member -MemberType NoteProperty -Name SMTP_SNMP_PORT -Value $temp
    $obj_str | Add-Member -MemberType NoteProperty -Name SERVER_NAME -Value $result_SNM.SERVER_NAME
    $obj_str | Add-Member -MemberType NoteProperty -Name SERVER_FQDN -Value $result_FQDN.SERVER_FQDN
    $obj_str | Add-Member -MemberType NoteProperty -Name SERVER_OSNAME -Value $result_SNM.SERVER_OSNAME
    $obj_str | Add-Member -MemberType NoteProperty -Name SERVER_OSVERSION -Value $result_SNM.SERVER_OSVERSION
    if ($result_FIRMWARE -ne "") { $temp = $result_FIRMWARE.FirmwareInfo[1].FIRMWARE_VERSION }else { $temp = "" }
    $obj_str | Add-Member -MemberType NoteProperty -Name SERVER_FIRMVER -Value $temp
    $temp = $null; $temp = $result_SRVI.PROCESSOR.Count; $temp = $temp -replace "`r`n" , ''
    $obj_str | Add-Member -MemberType NoteProperty -Name SRV_Info_CPUcount -Value $temp
    $temp = $null; $temp = $result_SRVI.PROCESSOR.Name | Select-Object -First 1
    $obj_str | Add-Member -MemberType NoteProperty -Name SRV_Info_CPUname -Value $temp
    $temp = $null; $temp = $result_SRVI.PROCESSOR.Speed | Select-Object -First 1
    $obj_str | Add-Member -MemberType NoteProperty -Name SRV_Info_CPUspeed -Value $temp
    $temp = $null; $temp = $result_SRVI.PROCESSOR.EXECUTION_TECHNOLOGY | Select-Object -First 1
    $temp = $temp -replace ';' , ''
    $obj_str | Add-Member -MemberType NoteProperty -Name SRV_Info_CPUcores -Value $temp
    
    $m = 0 # Тут считаем память
    if(($result_SRVI.MEMORY).MEMORY_DETAILS){
        ($result_SRVI.MEMORY).MEMORY_DETAILS | ForEach-Object {(($_.MemoryData).SIZE)} | % { If( $_ -like 'N/A' ) { Return; }; ($_.Split(' ')[0]) } |% {$m = $m + $_}; $m = [math]::Round( $m * 1Mb / 1Gb, 0)

    }
    elseif($result_SRVI.MEMORY.MEMORY_COMPONENTS){
        $result_SRVI.MEMORY.MEMORY_COMPONENTS | ForEach-Object {($_.Memory_SIZE)} | % { If( $_ -like 'Not Installed' ){ Return; }; ($_.Split(' ')[0]) } |% {$m = $m + $_} ; $m = [math]::Round( $m * 1Mb / 1Gb, 0)
    }
    else{
    $m = ""
    }
    $obj_str | Add-Member -MemberType NoteProperty -Name 'RAM(GB)' -Value $m

    $i = 0 # Тут считаем блоки питания.
    if(($result_SRVI.POWER_SUPPLY).SUPPLY){($result_SRVI.POWER_SUPPLY).SUPPLY | ForEach-Object { $c = ($_).CAPACITY; $i += 1}; $powres = "" + $i  + "x " + $c}else{$powres = ""}
    $obj_str | Add-Member -MemberType NoteProperty -Name POWER_SUPP -Value $powres
    if ($result_iLONet.NIC) { $mac = ($result_iLONet.NIC[0].MAC_ADDRESS).ToUpper() } else { $mac = "" }
    $obj_str | Add-Member -MemberType NoteProperty -Name ilo_Info_mac -Value $mac
    #$macN = $result_SRVI.NICInfo.NIC | ForEach-Object{if($_.PORT_DESCRIPTION -like "iLO*"){ $_.MAC_ADDRESS} } 
    #if($macN){$macN = $macN.ToUpper()}Else{$macN = ""}
    #$obj_str | Add-Member -MemberType NoteProperty -Name ilo_Info_macN -Value $macN
    $obj_str | Add-Member -MemberType NoteProperty -Name NTP_DHCPv4NTPServer -Value $NTPSettings.DHCPv4NTPServer
    $obj_str | Add-Member -MemberType NoteProperty -Name NTP_DHCPv6NTPServer -Value $NTPSettings.DHCPv6NTPServer
    $obj_str | Add-Member -MemberType NoteProperty -Name NTP_PropagateTimetoHost -Value $NTPSettings.PropagateTimetoHost
    $obj_str | Add-Member -MemberType NoteProperty -Name NTP_SNTPServer1 -Value $NTPSettings.SNTPServer[0]
    $obj_str | Add-Member -MemberType NoteProperty -Name NTP_SNTPServer2 -Value $NTPSettings.SNTPServer[1]
    $obj_str | Add-Member -MemberType NoteProperty -Name NTP_TimeZone $NTPSettings.TimeZone
    $obj_str | Add-Member -MemberType NoteProperty -Name RemSuppURL -Value $iLORemoteSup.DestinationURL
    $obj_str | Add-Member -MemberType NoteProperty -Name RemSuppPort -Value $iLORemoteSup.DestinationPort
    $obj_str | Add-Member -MemberType NoteProperty -Name RemSuppDate -Value $iLORemoteSup.LastTransmissionDate
    $obj_str | Add-Member -MemberType NoteProperty -Name RemSuppError -Value $iLORemoteSup.LastTransmissionError
    $obj_str | Add-Member -MemberType NoteProperty -Name AgentlessMangtServ -Value $iLOAMSstatus.AgentlessManagementService
    $obj_str | Add-Member -MemberType NoteProperty -Name AHSEnabled -Value $iLOAHSstatus.AHSEnabled

    $MemNames = $result_iLOHealth | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | Where-Object { $_ -notcontains 'HOSTNAME' -and $_ -notcontains 'IP' }
    foreach ($MemName in $MemNames) {
        $temp = $result_iLOHealth.$MemName
        $iloHelth = $null
        if ($temp -ne 'OK') {
            #Write-Host $temp
            $iloHelth = "Error"
        }
        else {
            $iloHelth = "OK"
        }
    }
    $obj_str | Add-Member -MemberType NoteProperty -Name Ilo_Healt -Value $iloHelth
    $obj_str | Add-Member -MemberType NoteProperty -Name Power -Value $result_iLOHostPower.HOST_POWER
    $obj_str | Add-Member -MemberType NoteProperty -Name SDCard_Status -Value $result_iLOSDCard.SDCARD_STATUS


    #$result_SRVI.NICInfo.NIC | ft 
    Write-Host $obj_str
    #Pause
    $All_result += $obj_str

}
$All_result | Out-GridView                                                                            # Выведем результаты на экран
$All_result | Export-Csv -Path $Path_to_export_csv -NoTypeInformation -Encoding UTF8 -Delimiter ";"   # Выгрузим результаты в csv
Exit
