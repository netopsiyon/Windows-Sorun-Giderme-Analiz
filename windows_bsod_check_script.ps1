[CmdletBinding()]
param([ValidateRange(1,365)][int]$Days=30)
$ErrorActionPreference='Stop'
function Show-SystemEvents([int[]]$EventIds){
    try {
        Get-WinEvent -FilterHashtable @{LogName='System';Id=$EventIds;StartTime=(Get-Date).AddDays(-$Days)} -MaxEvents 20 -ErrorAction Stop |
            Format-Table TimeCreated,ProviderName,Id,Message -Wrap
    }catch{Write-Warning "Olaylar alınamadı; eşleşen kayıt bulunmaması veya erişim hatası olabilir: $($_.Exception.Message)"}
}
Write-Host 'BugCheck / beklenmeyen yeniden başlatma aday kayıtları:'
Write-Host 'Olay 41 tek başına BSOD kanıtı değildir; olay 1001 sağlayıcısı ve mesajı ayrıca incelenmelidir.'
Show-SystemEvents @(1001,41)
$dumpPath=Join-Path $env:SystemRoot 'Minidump'
if(Test-Path -LiteralPath $dumpPath){
    Get-ChildItem -LiteralPath $dumpPath -Filter '*.dmp' -ErrorAction Stop | Format-Table FullName,LastWriteTime
}else{Write-Host 'Minidump dizini bulunamadı.'}
$memoryDump=Join-Path $env:SystemRoot 'MEMORY.DMP'
if(Test-Path -LiteralPath $memoryDump){Get-Item -LiteralPath $memoryDump | Format-Table FullName,LastWriteTime}
Write-Host 'Sürücü yükleme olayları (tek başına BSOD nedeni değildir):'
Show-SystemEvents @(219)
Write-Host 'Döküm dosyaları bu betikle analiz edilmez. Bellek testi için bakım zamanında mdsched.exe çalıştırılabilir.'