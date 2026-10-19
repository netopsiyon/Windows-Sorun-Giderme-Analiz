[CmdletBinding(SupportsShouldProcess=$true)]
param([switch]$StartService)
$ErrorActionPreference='Stop'
$service=Get-Service -Name TermService
Write-Host "RDP servis durumu: $($service.Status)"
if($StartService -and $service.Status -ne 'Running' -and $PSCmdlet.ShouldProcess('TermService','Servisi başlat')){
    Start-Service -Name TermService -ErrorAction Stop
    $service.Refresh()
    Write-Host "RDP servis durumu: $($service.Status)"
}
$settings=Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server'
if($settings.fDenyTSConnections -eq 1){Write-Warning 'RDP bağlantıları sistem ayarlarında kapalı.'}
$port=(Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp').PortNumber
$listeners=@(Get-NetTCPConnection -State Listen -ErrorAction Stop | Where-Object {$_.LocalPort -eq $port})
if($listeners.Count){Write-Host "Yerel TCP $port dinleniyor."}
else{Write-Warning "Yerel TCP $port üzerinde dinleyici bulunamadı."}
Write-Host 'Yerel dinleme durumu, güvenlik duvarından veya uzak ağdan erişilebildiğini kanıtlamaz.'
Write-Host 'Güvenlik duvarı kuralları değiştirilmedi; port ve kaynak IP kapsamı ayrıca incelenmelidir.'
try {
    Get-LocalGroupMember -SID 'S-1-5-32-555' -ErrorAction Stop | Select-Object Name,ObjectClass | Format-Table
}catch{Write-Warning "Yerel Uzak Masaüstü Kullanıcıları grubu okunamadı (etki alanı denetleyicilerinde bulunmayabilir): $($_.Exception.Message)"}