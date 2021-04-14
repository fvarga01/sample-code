$servername = ""
#port ping, port 1433 (SQL Server) port
Test-NetConnection -ComputerName $servername -Port 1433

#check dns cache
Get-DnsClientCache -Name $servername

#clear local dns cache
#Clear-DnsClientCache