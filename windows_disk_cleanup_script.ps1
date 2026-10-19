[CmdletBinding(SupportsShouldProcess=$true,ConfirmImpact='High')]
param(
    [ValidateRange(1,100)][int]$Threshold=90,
    [switch]$ListLargeFiles,
    [switch]$CleanTemp
)
$ErrorActionPreference='Stop'
$drives=@(Get-PSDrive -PSProvider FileSystem | Where-Object {($_.Used+$_.Free) -gt 0})
foreach($drive in $drives){
    $percent=[math]::Round(100*$drive.Used/($drive.Used+$drive.Free),2)
    Write-Host "$($drive.Root): %$percent dolu"
    if($percent -ge $Threshold){
        Write-Warning "$($drive.Root) eşik üzerinde."
        if($ListLargeFiles){
            Write-Host 'Dosya taraması zaman alabilir; erişilemeyen konumlar uyarı üretir.'
            Get-ChildItem -LiteralPath $drive.Root -File -Recurse -ErrorAction Continue |
                Sort-Object Length -Descending | Select-Object -First 10 FullName,@{n='MB';e={[math]::Round($_.Length/1MB,2)}} |
                Format-Table -AutoSize
        }
    }
}
# Yalnızca mevcut kullanıcının TEMP dizini; diğer kullanıcı profilleri ve Windows Temp kapsam dışı.
if($CleanTemp){
    $tempRoot=[IO.Path]::GetFullPath($env:TEMP).TrimEnd('\')
    $profileRoot=[IO.Path]::GetFullPath($env:USERPROFILE).TrimEnd('\')
    if(-not $tempRoot.StartsWith($profileRoot+'\',[StringComparison]::OrdinalIgnoreCase)){
        throw 'TEMP dizini mevcut kullanıcı profilinin altında değil; temizlik durduruldu.'
    }
    $ancestor=Get-Item -LiteralPath $tempRoot -Force -ErrorAction Stop
    while($ancestor.FullName.TrimEnd('\') -ne $profileRoot){
        if($ancestor.Attributes -band [IO.FileAttributes]::ReparsePoint){throw 'TEMP yolu bir dizin bağlantısından geçiyor; temizlik durduruldu.'}
        $ancestor=$ancestor.Parent
        if(-not $ancestor){throw 'TEMP üst dizinleri doğrulanamadı.'}
    }
    if($PSCmdlet.ShouldProcess($tempRoot,'Mevcut kullanıcının geçici dosyalarını sil')){
        $failed=0
        Get-ChildItem -LiteralPath $tempRoot -Force | ForEach-Object {
            # Bağlantılar üzerinden başka dizinlere geçilmez.
            if($_.Attributes -band [IO.FileAttributes]::ReparsePoint){Write-Warning "Bağlantı atlandı: $($_.FullName)";return}
            $target=[IO.Path]::GetFullPath($_.FullName)
            if(-not $target.StartsWith($tempRoot+'\',[StringComparison]::OrdinalIgnoreCase)){throw 'Hedef TEMP dışında.'}
            $links=@()
            if($_.PSIsContainer){$links=@(Get-ChildItem -LiteralPath $target -Recurse -Force -Attributes ReparsePoint -ErrorAction Stop)}
            if($links.Count){Write-Warning "Bağlantı içeren dizin atlandı: $target";return}
            try {Remove-Item -LiteralPath $target -Recurse -Force -ErrorAction Stop}
            catch {$failed++;Write-Warning "Silinemedi: $target — $($_.Exception.Message)"}
        }
        Write-Host "Temizlik tamamlandı. Silinemeyen hedef sayısı: $failed"
    }
}