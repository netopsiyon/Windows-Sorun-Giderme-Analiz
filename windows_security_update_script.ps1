[CmdletBinding(SupportsShouldProcess=$true,ConfirmImpact='High')]
param([switch]$InstallUpdates)
$ErrorActionPreference='Stop'
if(-not (Get-Module -ListAvailable -Name PSWindowsUpdate)){
    throw 'PSWindowsUpdate gerekli. Modülü inceleyip ayrı olarak kurun: Install-Module -Name PSWindowsUpdate -Scope CurrentUser'
}
Import-Module PSWindowsUpdate -ErrorAction Stop
$service=Get-Service wuauserv
Write-Host "Windows Update servis durumu: $($service.Status)"
try {
    $updates=@(Get-WindowsUpdate -MicrosoftUpdate -ErrorAction Stop)
    if($updates.Count){
        $updates | Format-Table -AutoSize
        if($InstallUpdates -and $PSCmdlet.ShouldProcess('Listelenen Windows güncellemeleri','Yükle (otomatik yeniden başlatma yok)')){
            Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -IgnoreReboot -ErrorAction Stop
            Write-Host 'Yükleme işlemi tamamlandı; sonuçları ve yeniden başlatma gereksinimini kontrol edin.'
        }
    }else{Write-Host 'Bu sorguda uygulanabilir güncelleme bulunamadı.'}
}catch{throw "Güncelleme sorgusu veya yüklemesi başarısız: $($_.Exception.Message)"}
if(Get-Command Get-ADDefaultDomainPasswordPolicy -ErrorAction SilentlyContinue){
    try {
        Get-ADDefaultDomainPasswordPolicy -ErrorAction Stop |
            Select-Object MinPasswordLength,ComplexityEnabled,LockoutThreshold | Format-List
        Write-Host 'Bu alanlar tek başına parola politikasının güçlü olduğunu kanıtlamaz.'
    }catch{Write-Warning "Etki alanı parola politikası okunamadı: $($_.Exception.Message)"}
}else{Write-Host 'AD parola politikası komutu yok; kontrol atlandı.'}
if(Get-Command Get-MpComputerStatus -ErrorAction SilentlyContinue){
    try {
        Get-MpComputerStatus -ErrorAction Stop |
            Select-Object AMServiceEnabled,AntivirusEnabled,RealTimeProtectionEnabled,AntivirusSignatureLastUpdated |
            Format-List
    }catch{Write-Warning "Defender durumu okunamadı: $($_.Exception.Message)"}
}else{Write-Host 'Defender komutu yok; kontrol atlandı.'}