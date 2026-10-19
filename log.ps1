# Yalnızca yerel durum raporu üretir; güncelleme yüklemez ve e-posta göndermez.
[CmdletBinding()]
param([string]$LogDirectory=(Join-Path $env:LOCALAPPDATA 'Windows-Sorun-Giderme\logs'))
$ErrorActionPreference='Stop'
$null=New-Item -ItemType Directory -Path $LogDirectory -Force
$logFile=Join-Path $LogDirectory ("rapor-{0}-{1}.txt" -f (Get-Date -Format 'yyyyMMdd-HHmmss'),[guid]::NewGuid().ToString('N').Substring(0,8))
$report=New-Object 'System.Collections.Generic.List[string]'
$report.Add("Windows durum raporu — $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
try {
    $os=Get-CimInstance Win32_OperatingSystem
    $ramPercent=100*($os.TotalVisibleMemorySize-$os.FreePhysicalMemory)/$os.TotalVisibleMemorySize
    $report.Add("RAM kullanımı: %$([math]::Round($ramPercent,2))")
}catch{$report.Add("RAM okunamadı: $($_.Exception.Message)")}
try {
    $cpu=Get-CimInstance Win32_Processor | Measure-Object LoadPercentage -Average
    $report.Add("CPU yükü (CIM örneği): %$($cpu.Average)")
}catch{$report.Add("CPU okunamadı: $($_.Exception.Message)")}
try {
    foreach($disk in Get-PSDrive -PSProvider FileSystem | Where-Object {($_.Used+$_.Free) -gt 0}){
        $percent=[math]::Round(100*$disk.Used/($disk.Used+$disk.Free),2)
        $report.Add("$($disk.Root) disk kullanımı: %$percent")
    }
}catch{$report.Add("Disk okunamadı: $($_.Exception.Message)")}
try {$report.Add("Windows Update servisi: $((Get-Service wuauserv).Status)")}
catch{$report.Add("Servis okunamadı: $($_.Exception.Message)")}
$report | Set-Content -LiteralPath $logFile -Encoding UTF8
$report | ForEach-Object {Write-Host $_}
Write-Host "Rapor kaydedildi: $logFile"