[CmdletBinding(SupportsShouldProcess=$true,ConfirmImpact='High')]
param([ValidateRange(1,1048576)][int]$ThresholdMB=500,[switch]$StopTopProcess)
$ErrorActionPreference='Stop'
$processes=@(Get-Process | Sort-Object WorkingSet64 -Descending)
$processes | Select-Object -First 10 Id,ProcessName,@{n='RAM_MB';e={[math]::Round($_.WorkingSet64/1MB,2)}} | Format-Table -AutoSize
$top=$processes | Where-Object {$_.WorkingSet64 -gt $ThresholdMB*1MB} | Select-Object -First 1
if(-not $top){Write-Host "$ThresholdMB MB eşiğini aşan işlem bulunamadı.";return}
Write-Warning "$($top.ProcessName) (PID $($top.Id)) eşik üzerinde. Bu durum tek başına bellek sorunu olduğunu göstermez."
if($StopTopProcess -and $PSCmdlet.ShouldProcess("$($top.ProcessName) / PID $($top.Id)",'İşlemi zorla sonlandır')){
    $current=Get-Process -Id $top.Id
    if($current.StartTime -ne $top.StartTime){throw 'İşlem kimliği değişti; sonlandırılmadı.'}
    if($current.Id -in @(0,4,$PID)){throw 'Bu sistem işlemi veya mevcut PowerShell oturumu sonlandırılamaz.'}
    Stop-Process -InputObject $current -Force -ErrorAction Stop
    Write-Host 'İşlem sonlandırıldı.'
}