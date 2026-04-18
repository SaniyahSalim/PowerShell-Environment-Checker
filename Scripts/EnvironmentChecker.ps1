$ServerListFilePath = "D:\Saniyah Salim\PowerShell\Environment Checker\Config\EnvCheckerList.csv"
$LogFile = "D:\Saniyah Salim\PowerShell\Environment Checker\Logs\serverlog.txt"
$JsonFile = "D:\Saniyah Salim\PowerShell\Environment Checker\Dashboard\servers.json"
$From = "saniyah.salim@gmail.com"
$To = "Saniyah.salim20@gmail.com"
$SMTPServer = "smtp.gmail.com"
$Port = 587
$Credential = Import-Clixml "D:\Saniyah Salim\PowerShell\Environment Checker\Credentials\gmail_cred.xml"

$ServerList = Import-Csv -Path $ServerListFilePath
$UpdatedList = @()

Foreach ($server in $ServerList) {
  $DateTime = Get-Date
  $DownSince = $server.DownSince
  $LastDownAlertTime = $server.LastDownAlertTime
  $previous = if ($server.LastStatus) { $server.LastStatus } else { "Unknown" }

  try {
    $start = Get-Date
    Invoke-WebRequest -Uri $server.Url -UseBasicParsing -TimeoutSec 3 -ErrorAction Stop | Out-Null
    $current = "UP"
    $end = Get-Date
    $ResponseTime = ($end - $start).TotalMilliseconds
  }
  catch {
    $ResponseTime = 0
    $current = "DOWN"
  }

  if ($current -eq "UP") {
    Write-Host "$($server.ServerName) is UP ($([math]::Round($ResponseTime)) ms)" -ForegroundColor Green
  }
  else {
    Write-Host "$($server.ServerName) is DOWN" -ForegroundColor Red
  }

  Add-Content $LogFile "$($DateTime.ToString("yyyy-MM-dd HH:mm:ss")) | $($server.ServerName) | $current"

  if ($current -eq "DOWN" -and $previous -eq "UP") {
    $DownSince = $DateTime
    $LastDownAlertTime = $DateTime

    $Subject = "ALERT: $($server.ServerName) is DOWN"
    $Body = @"
<html>
<body style='margin:0;padding:0;background:#f0f2f5;font-family:Arial,sans-serif;'>
<table width='100%' cellpadding='0' cellspacing='0' style='background:#f0f2f5;padding:32px 0;'>
  <tr><td align='center'>
    <table width='520' cellpadding='0' cellspacing='0' style='background:#ffffff;border-radius:8px;overflow:hidden;border:1px solid #e0e0e0;'>

      <tr><td style='background:#c0392b;padding:24px 28px;'>
        <p style='margin:0;color:#ffffff;font-size:17px;font-weight:bold;'>Server down alert</p>
        <p style='margin:4px 0 0;color:#f5c6c6;font-size:12px;'>PowerShell Environment Checker</p>
      </td></tr>

      <tr><td style='padding:24px 28px;'>
        <table width='100%' cellpadding='0' cellspacing='0'>
          <tr><td style='padding:8px 0;border-bottom:1px solid #f0f0f0;color:#888888;font-size:12px;'>Server name</td><td align='right' style='padding:8px 0;border-bottom:1px solid #f0f0f0;color:#1a1a2e;font-size:12px;font-weight:bold;'>$($server.ServerName)</td></tr>
          <tr><td style='padding:8px 0;border-bottom:1px solid #f0f0f0;color:#888888;font-size:12px;'>URL</td><td align='right' style='padding:8px 0;border-bottom:1px solid #f0f0f0;color:#1a1a2e;font-size:12px;font-weight:bold;'>$($server.Url)</td></tr>
          <tr><td style='padding:8px 0;border-bottom:1px solid #f0f0f0;color:#888888;font-size:12px;'>Status</td><td align='right' style='padding:8px 0;border-bottom:1px solid #f0f0f0;color:#a32d2d;font-size:12px;font-weight:bold;'>DOWN</td></tr>
          <tr><td style='padding:8px 0;color:#888888;font-size:12px;'>Detected at</td><td align='right' style='padding:8px 0;color:#1a1a2e;font-size:12px;font-weight:bold;'>$($DateTime.ToString("dd-MM-yyyy HH:mm:ss"))</td></tr>
        </table>
      </td></tr>

      <tr><td style='background:#fafafa;border-top:1px solid #f0f0f0;padding:12px 28px;text-align:center;color:#aaaaaa;font-size:11px;'>
        Auto-generated alert &middot; PowerShell Environment Checker
      </td></tr>

    </table>
  </td></tr>
</table>
</body>
</html>
"@

    Send-MailMessage -From $From -To $To -Subject $Subject -Body $Body -BodyAsHtml `
      -SmtpServer $SMTPServer -Port $Port -Credential $Credential -UseSsl
    Write-Host "Email alert sent for $($server.ServerName)" -ForegroundColor Yellow
  }
  elseif ($current -eq "DOWN" -and $DownSince) {
    $DownFor = (($DateTime) - (Get-Date -Date $DownSince)).TotalDays
    $SinceLastDownAlert = (($DateTime) - (Get-Date -Date $LastDownAlertTime)).TotalDays

    if (($DownFor -ge 1) -and ($SinceLastDownAlert -ge 1)) {
      $Subject = "REMINDER: $($server.ServerName) still DOWN"
      $Body = @"
<html>
<body style='margin:0;padding:0;background:#f0f2f5;font-family:Arial,sans-serif;'>
<table width='100%' cellpadding='0' cellspacing='0' style='background:#f0f2f5;padding:32px 0;'>
  <tr><td align='center'>
    <table width='520' cellpadding='0' cellspacing='0' style='background:#ffffff;border-radius:8px;overflow:hidden;border:1px solid #e0e0e0;'>

      <tr><td style='background:#b7770d;padding:24px 28px;'>
        <p style='margin:0;color:#ffffff;font-size:17px;font-weight:bold;'>Server still down</p>
        <p style='margin:4px 0 0;color:#fde9b0;font-size:12px;'>PowerShell Environment Checker</p>
      </td></tr>

      <tr><td style='padding:24px 28px;'>
        <table width='100%' cellpadding='0' cellspacing='0'>
          <tr><td style='padding:8px 0;border-bottom:1px solid #f0f0f0;color:#888888;font-size:12px;'>Server name</td><td align='right' style='padding:8px 0;border-bottom:1px solid #f0f0f0;color:#1a1a2e;font-size:12px;font-weight:bold;'>$($server.ServerName)</td></tr>
          <tr><td style='padding:8px 0;border-bottom:1px solid #f0f0f0;color:#888888;font-size:12px;'>URL</td><td align='right' style='padding:8px 0;border-bottom:1px solid #f0f0f0;color:#1a1a2e;font-size:12px;font-weight:bold;'>$($server.Url)</td></tr>
          <tr><td style='padding:8px 0;border-bottom:1px solid #f0f0f0;color:#888888;font-size:12px;'>Status</td><td align='right' style='padding:8px 0;border-bottom:1px solid #f0f0f0;color:#a32d2d;font-size:12px;font-weight:bold;'>DOWN</td></tr>
          <tr><td style='padding:8px 0;border-bottom:1px solid #f0f0f0;color:#888888;font-size:12px;'>Down since</td><td align='right' style='padding:8px 0;border-bottom:1px solid #f0f0f0;color:#1a1a2e;font-size:12px;font-weight:bold;'>$DownSince</td></tr>
          <tr><td style='padding:8px 0;color:#888888;font-size:12px;'>Total downtime</td><td align='right' style='padding:8px 0;color:#a32d2d;font-size:12px;font-weight:bold;'>$([math]::Round($DownFor, 1)) days</td></tr>
        </table>
      </td></tr>

      <tr><td style='background:#fafafa;border-top:1px solid #f0f0f0;padding:12px 28px;text-align:center;color:#aaaaaa;font-size:11px;'>
        Auto-generated reminder &middot; PowerShell Environment Checker
      </td></tr>

    </table>
  </td></tr>
</table>
</body>
</html>
"@

      Send-MailMessage -From $From -To $To -Subject $Subject -Body $Body -BodyAsHtml `
        -SmtpServer $SMTPServer -Port $Port -Credential $Credential -UseSsl
      Write-Host "Reminder email sent for $($server.ServerName)" -ForegroundColor Yellow
      $LastDownAlertTime = $DateTime
    }
  }

  if ($current -eq "UP" -and $previous -eq "DOWN") {
    $Subject = "RESOLVED: $($server.ServerName) is UP"
    $Body = @"
<html>
<body style='margin:0;padding:0;background:#f0f2f5;font-family:Arial,sans-serif;'>
<table width='100%' cellpadding='0' cellspacing='0' style='background:#f0f2f5;padding:32px 0;'>
  <tr><td align='center'>
    <table width='520' cellpadding='0' cellspacing='0' style='background:#ffffff;border-radius:8px;overflow:hidden;border:1px solid #e0e0e0;'>

      <tr><td style='background:#27500a;padding:24px 28px;'>
        <p style='margin:0;color:#ffffff;font-size:17px;font-weight:bold;'>Server recovered</p>
        <p style='margin:4px 0 0;color:#c0dd97;font-size:12px;'>PowerShell Environment Checker</p>
      </td></tr>

      <tr><td style='padding:24px 28px;'>
        <table width='100%' cellpadding='0' cellspacing='0'>
          <tr><td style='padding:8px 0;border-bottom:1px solid #f0f0f0;color:#888888;font-size:12px;'>Server name</td><td align='right' style='padding:8px 0;border-bottom:1px solid #f0f0f0;color:#1a1a2e;font-size:12px;font-weight:bold;'>$($server.ServerName)</td></tr>
          <tr><td style='padding:8px 0;border-bottom:1px solid #f0f0f0;color:#888888;font-size:12px;'>URL</td><td align='right' style='padding:8px 0;border-bottom:1px solid #f0f0f0;color:#1a1a2e;font-size:12px;font-weight:bold;'>$($server.Url)</td></tr>
          <tr><td style='padding:8px 0;border-bottom:1px solid #f0f0f0;color:#888888;font-size:12px;'>Status</td><td align='right' style='padding:8px 0;border-bottom:1px solid #f0f0f0;color:#27500a;font-size:12px;font-weight:bold;'>UP</td></tr>
          <tr><td style='padding:8px 0;color:#888888;font-size:12px;'>Recovery time</td><td align='right' style='padding:8px 0;color:#1a1a2e;font-size:12px;font-weight:bold;'>$($DateTime.ToString("dd-MM-yyyy HH:mm:ss"))</td></tr>
        </table>
      </td></tr>

      <tr><td style='background:#fafafa;border-top:1px solid #f0f0f0;padding:12px 28px;text-align:center;color:#aaaaaa;font-size:11px;'>
        Auto-generated alert &middot; PowerShell Environment Checker
      </td></tr>

    </table>
  </td></tr>
</table>
</body>
</html>
"@

    Send-MailMessage -From $From -To $To -Subject $Subject -Body $Body -BodyAsHtml `
      -SmtpServer $SMTPServer -Port $Port -Credential $Credential -UseSsl
    Write-Host "$($server.ServerName) recovered. Email sent." -ForegroundColor Cyan

    $DownSince = $null
    $LastDownAlertTime = $null
  }

  if ($current -eq "UP") {
    $DownSince = ""
    $LastDownAlertTime = ""
  }

  $UpdatedList += [PSCustomObject]@{
    ServerName        = $server.ServerName
    Url               = $server.Url
    LastStatus        = $current
    ResponseTime      = [math]::Round($ResponseTime)
    LastCheckTime     = $DateTime.ToString("dd-MM-yyyy HH:mm:ss")
    DownSince         = if ($DownSince -and $DownSince -is [DateTime]) { $DownSince.ToString("dd-MM-yyyy HH:mm:ss") } else { "$DownSince" }
    LastDownAlertTime = if ($LastDownAlertTime -and $LastDownAlertTime -is [DateTime]) { $LastDownAlertTime.ToString("dd-MM-yyyy HH:mm:ss") } else { "$LastDownAlertTime" }
  }
}

$UpdatedList | Export-Csv -Path $ServerListFilePath -NoTypeInformation
$json = $UpdatedList | ConvertTo-Json
[System.IO.File]::WriteAllText($JsonFile, $json, [System.Text.UTF8Encoding]::new($false))