# CPU yüzdesi iki örnek arasındaki işlemci süresinden hesaplanır.
[CmdletBinding(SupportsShouldProcess=$true,ConfirmImpact='High')]
param(
    [ValidateRange(1,100)][double]$Threshold=80,
    [ValidateRange(1,60)][int]$SampleSeconds=2,
    [switch]$StopTopProcess
)
$ErrorActionPreference='Stop'
$cores=[Environment]::ProcessorCount
$before=@{}
Get-Process | ForEach-Object {
    try { $before[$_.Id]=@{ CPU=$_.TotalProcessorTime.TotalSeconds; Start=$_.StartTime.Ticks } } catch {}
}
$timer=[Diagnostics.Stopwatch]::StartNew()
Start-Sleep -Seconds $SampleSeconds
$elapsed=$timer.Elapsed.TotalSeconds
$rows=@(Get-Process | ForEach-Object {
    try {
        $old=$before[$_.Id]
        if($old -and $old.Start -eq $_.StartTime.Ticks){
            $percent=100*($_.TotalProcessorTime.TotalSeconds-$old.CPU)/$elapsed/$cores
            [pscustomobject]@{Id=$_.Id;ProcessName=$_.ProcessName;CPUPercent=[math]::Round([math]::Max(0,$percent),2);StartTicks=$_.StartTime.Ticks}
        }
    } catch {}
} | Sort-Object CPUPercent -Descending)
$rows | Select-Object -First 10 Id,ProcessName,CPUPercent | Format-Table -AutoSize
$top=$rows | Where-Object {$_.CPUPercent -gt $Threshold} | Select-Object -First 1
if(-not $top){Write-Host "Örnekleme sırasında %$Threshold eşiğini aşan işlem bulunamadı.";return}
Write-Warning "$($top.ProcessName) (PID $($top.Id)): %$($top.CPUPercent)"
if($StopTopProcess -and $PSCmdlet.ShouldProcess("$($top.ProcessName) / PID $($top.Id)",'İşlemi zorla sonlandır')){
    $current=Get-Process -Id $top.Id
    if($current.StartTime.Ticks -ne $top.StartTicks){throw 'İşlem kimliği değişti; sonlandırılmadı.'}
    if($current.Id -in @(0,4,$PID)){throw 'Bu sistem işlemi veya mevcut PowerShell oturumu sonlandırılamaz.'}
    Stop-Process -InputObject $current -Force -ErrorAction Stop
    Write-Host 'İşlem sonlandırıldı.'
}