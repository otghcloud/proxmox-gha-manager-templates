$ErrorActionPreference = 'Continue'
$transcriptPath = 'C:\Windows\Temp\guest-tools-install.log'
$failurePath = 'C:\Windows\Temp\guest-tools-FAILED.txt'

Start-Transcript -Path $transcriptPath -Append
try {
    $virtioRoot = Get-PSDrive -PSProvider FileSystem |
        ForEach-Object { $_.Root } |
        Where-Object { Test-Path (Join-Path $_ 'virtio-win-guest-tools.exe') } |
        Select-Object -First 1

    if (-not $virtioRoot) {
        throw 'Could not find virtio-win-guest-tools.exe on any mounted drive.'
    }

    $guestTools = Join-Path $virtioRoot 'virtio-win-guest-tools.exe'
    $guestAgentMsi = Join-Path $virtioRoot 'guest-agent\qemu-ga-x86_64.msi'
    $deadline = (Get-Date).AddMinutes(10)

    do {
        pnputil /scan-devices | Out-Null

        $toolsProcess = Start-Process -FilePath $guestTools -ArgumentList '/install','/quiet','/norestart','/log','C:\Windows\Temp\virtio-gt.log' -Wait -PassThru
        Write-Output ('virtio-win-guest-tools.exe exit code: ' + $toolsProcess.ExitCode)

        if (-not (Get-Service QEMU-GA -ErrorAction SilentlyContinue) -and (Test-Path $guestAgentMsi)) {
            $msiProcess = Start-Process -FilePath msiexec.exe -ArgumentList '/i',$guestAgentMsi,'/qn','/norestart','/l*v','C:\Windows\Temp\qemu-ga.log' -Wait -PassThru
            Write-Output ('qemu-ga msi exit code: ' + $msiProcess.ExitCode)
        }

        Start-Sleep -Seconds 10
        $service = Get-Service QEMU-GA -ErrorAction SilentlyContinue
        if ($service -and $service.Status -ne 'Running') {
            Start-Service QEMU-GA -ErrorAction SilentlyContinue
            $service.Refresh()
        }
    } until (($service -and $service.Status -eq 'Running') -or (Get-Date) -gt $deadline)

    if (-not ($service -and $service.Status -eq 'Running')) {
        'QEMU-GA not running - Packer will never discover this VM. See virtio-gt.log / qemu-ga.log.' | Set-Content $failurePath
    }
} catch {
    $_ | Out-String | Set-Content $failurePath
} finally {
    Stop-Transcript
}