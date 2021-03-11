<#
.Synopsis
    Stage1.ps1
    Этот скриптр предназначен для поиска ilo в заданных диаппазонах. Step1

.DESCRIPTION
    Скрипт сканирует заданные диапазоны IP и формирует PSObject и сохраняет данные в файл CSV
	Работает с использованием функции Find-HPiLO модуля HPiLOCmdlets

.EXAMPLE
    C:\Scripts\ILO_Inventory\Stage1.ps1 -PatchToIPRange "C:\Scripts\ILO_Inventory\iloiprange_test.txt" -RangeName "TEST"

.INPUTS
	None (by default)

.OUTPUTS
    None (by default)

.NOTES
	Company : 
    Version : 1.0.0.0
    Date    : 27/02/2021 

.LINK
    https://kb.rosbank.rus.socgen/pages/viewpage.action?pageId=29738761
#>
Param(
    [Parameter(Mandatory = $true)]
    [string]$PatchToIPRange,
    [Parameter (Mandatory = $true)]
    [string]$RangeName
)
Clear-Host

$dt = (Get-Date -Format yyyyMMdd).ToString()                                        # Получим сегодняшнюю дату в подходящем формате
$WorkDir = "C:\ScriptsRes\ILOFindRes"                                               # Дирректория с файлами
$PathToSave = $WorkDir + "\" + $dt + "_" + $RangeName + "_" + "St1_FindRes.csv"     # Соберем путь, для сохранения результатов
$iloIPrange = @(Get-Content $PatchToIPRange)                                        # Прочитаем файл с диаппазонами для сканирования
$AlliLOscanedInfo = find-hpilo -range $iloIPrange -Full -Verbose -Timeout 500       # Соберем информацию с помощью find-hpilo
#$AlliLOscanedInfo | Out-GridView

# Преобразуемм данные для последующего сохранения
$ResultInfo = @()
foreach ($OneiLOInfo in $AlliLOscanedInfo) {
    $schetchik++
    $obj_str = New-Object PSObject
    $obj_str | Add-Member -MemberType NoteProperty -Name 'RANGE'         -Value $RangeName
    $obj_str | Add-Member -MemberType NoteProperty -Name 'IP'            -Value $OneiLOInfo.IP
    $obj_str | Add-Member -MemberType NoteProperty -Name 'HOSTNAME'      -Value $OneiLOInfo.HOSTNAME    
    $obj_str | Add-Member -MemberType NoteProperty -Name 'HSI_SBSN'      -Value ($OneiLOInfo.HSI_SBSN -replace " ", "")
    $obj_str | Add-Member -MemberType NoteProperty -Name 'HSI_PRODUCTID' -Value ($OneiLOInfo.HSI_PRODUCTID -replace " ", "")
    $obj_str | Add-Member -MemberType NoteProperty -Name 'MP_PN'         -Value ($OneiLOInfo.MP_PN.Substring(25, 5))
    $obj_str | Add-Member -MemberType NoteProperty -Name 'MP_FWRI'       -Value $OneiLOInfo.MP_FWRI
    $obj_str | Add-Member -MemberType NoteProperty -Name 'HSI_SPN'       -Value $OneiLOInfo.HSI_SPN
    $obj_str | Add-Member -MemberType NoteProperty -Name 'ENC_NAME'      -Value $OneiLOInfo.BLADESYSTEM_MANAGER.ENCL
    $obj_str | Add-Member -MemberType NoteProperty -Name 'ENC_BAY'       -Value $OneiLOInfo.BLADESYSTEM_BAY
    $obj_str | Add-Member -MemberType NoteProperty -Name 'HSI_UUID'      -Value $OneiLOInfo.HSI_UUID
    $obj_str | Add-Member -MemberType NoteProperty -Name 'MP_UUID'       -Value $OneiLOInfo.MP_UUID
    $obj_str | Add-Member -MemberType NoteProperty -Name 'HSI_cUUID'     -Value $OneiLOInfo.HSI_cUUID
    $obj_str | Add-Member -MemberType NoteProperty -Name 'MPHWRI'        -Value $OneiLOInfo.MP_HWRI
    $ResultInfo += $obj_str
    $OneiLOInfo = $null
}
$ResultInfo | Out-GridView                                                          # Выведем результаты на экран
$ResultInfo | Export-Csv -Path $PathToSave -NoTypeInformation -Encoding UTF8        # Выгрузим результаты в csv
Exit
