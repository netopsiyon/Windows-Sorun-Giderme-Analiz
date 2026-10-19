[CmdletBinding()]
param([ValidateRange(1,365)][int]$Days=7)
$ErrorActionPreference='Stop'
if(Get-Command repadmin.exe -ErrorAction SilentlyContinue){
    & repadmin.exe /replsummary
    if($LASTEXITCODE -ne 0){Write-Warning "repadmin başarısız, çıkış kodu: $LASTEXITCODE"}
    else{Write-Host 'Rapor üretildi. Replikasyon hata sayıları yukarıdaki rapordan değerlendirilmelidir.'}
}else{Write-Warning 'repadmin bulunamadı; AD DS/RSAT araçlarını kontrol edin.'}
try {
    Get-WinEvent -FilterHashtable @{LogName='Security';Id=4625;StartTime=(Get-Date).AddDays(-$Days)} -MaxEvents 20 -ErrorAction Stop |
        Format-Table TimeCreated,Id,Message -Wrap
}catch{Write-Warning "Başarısız oturum kayıtları alınamadı; eşleşen kayıt bulunmaması veya erişim hatası olabilir: $($_.Exception.Message)"}
if(Get-Command gpresult.exe -ErrorAction SilentlyContinue){
    & gpresult.exe /R
    if($LASTEXITCODE -ne 0){Write-Warning "gpresult başarısız, çıkış kodu: $LASTEXITCODE"}
}
if([string]::IsNullOrWhiteSpace($env:USERDNSDOMAIN)){
    Write-Warning 'Oturum için USERDNSDOMAIN tanımlı değil; AD DNS sorgusu atlandı.'
}else{
    try {
        Resolve-DnsName -Name "_ldap._tcp.dc._msdcs.$env:USERDNSDOMAIN" -Type SRV -ErrorAction Stop | Format-Table
        Write-Host 'SRV sorgusu başarılı; bu sonuç AD yapılandırmasının tamamını doğrulamaz.'
    }catch{Write-Warning "AD SRV sorgusu başarısız: $($_.Exception.Message)"}
}