[CmdletBinding(SupportsShouldProcess=$true)]
param([string]$PingTarget='8.8.8.8',[string]$DnsName='google.com',[switch]$ClearDnsCache)
$ErrorActionPreference='Stop'
if(Test-Connection -ComputerName $PingTarget -Count 2 -Quiet){
    Write-Host "$PingTarget ICMP yanıtı verdi."
}else{Write-Warning "$PingTarget ICMP yanıtı vermedi. Bu tek başına internet bağlantısının kesik olduğunu göstermez."}
Get-NetRoute -DestinationPrefix '0.0.0.0/0' | Select-Object InterfaceAlias,NextHop,RouteMetric | Format-Table
try {Resolve-DnsName -Name $DnsName -ErrorAction Stop | Format-Table;Write-Host 'DNS sorgusu başarılı.'}
catch {Write-Warning "DNS sorgusu başarısız: $($_.Exception.Message)"}
if($ClearDnsCache -and $PSCmdlet.ShouldProcess('Yerel DNS önbelleği','Temizle')){
    Clear-DnsClientCache -ErrorAction Stop
    Write-Host 'DNS önbelleği temizlendi. DNS testi yeniden çalıştırılmalıdır.'
}
Get-NetIPAddress -AddressFamily IPv4 | Format-Table InterfaceAlias,IPAddress