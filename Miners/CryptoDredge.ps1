﻿using module ..\Modules\Include.psm1

param(
    [PSCustomObject]$Pools,
    [Bool]$InfoOnly
)

if ((-not $IsWindows -and -not $IsLinux) -or $Session.IsVM) {return}

$ManualUri = "https://github.com/technobyl/CryptoDredge/releases"
$Port = "313{0:d2}"
$DevFee = 1.0
$Version = "0.26.0"
$Enable_Logfile = $false
$DeviceCapability = "5.0"

if ($IsLinux) {
    $Path = ".\Bin\NVIDIA-CryptoDredge\CryptoDredge"
    $UriCuda = @(
        [PSCustomObject]@{
            Uri = "https://github.com/RainbowMiner/miner-binaries/releases/download/v0.26.0-cryptodredge/CryptoDredge_0.26.0_cuda_11.2_linux.tar.gz"
            Cuda = "11.2"
        }
    )
} else {
    $Path = ".\Bin\NVIDIA-CryptoDredge\CryptoDredge.exe"
    $UriCuda = @(
        [PSCustomObject]@{
            Uri = "https://github.com/RainbowMiner/miner-binaries/releases/download/v0.26.0-cryptodredge/CryptoDredge_0.26.0_cuda_11.2_windows.zip"
            Cuda = "11.2"
        }
    )
}

if (-not $Global:DeviceCache.DevicesByTypes.NVIDIA -and -not $InfoOnly) {return} # No NVIDIA present in system

$Commands = [PSCustomObject[]]@(
    [PSCustomObject]@{MainAlgorithm = "argon2d-dyn"; MinMemGb = 1; Params = ""} #Argon2d-Dyn
    [PSCustomObject]@{MainAlgorithm = "argon2d-nim"; MinMemGb = 1; Params = ""} #Argon2d-Nim
    [PSCustomObject]@{MainAlgorithm = "argon2d250";  MinMemGb = 1; Params = ""} #Argon2d250
    [PSCustomObject]@{MainAlgorithm = "argon2d4096"; MinMemGb = 3.3; Params = ""} #Argon2d4096
    [PSCustomObject]@{MainAlgorithm = "chukwa";      MinMemGb = 1.5; Params = ""} #Chukwa, new with v0.21.0
    [PSCustomObject]@{MainAlgorithm = "chukwa2";     MinMemGb = 1.5; Params = ""; ExtendInterval = 2; FaultTolerance = 0.5} #ChukwaV2, new with v0.26.0
    [PSCustomObject]@{MainAlgorithm = "cnconceal";   MinMemGb = 1.5; Params = ""} #CryptonighConceal, new with v0.21.0
    [PSCustomObject]@{MainAlgorithm = "cnfast2";     MinMemGb = 1.5; Params = ""} #CryptonightFast2 / Masari
    [PSCustomObject]@{MainAlgorithm = "cngpu";       MinMemGb = 3.3; Params = ""} #CryptonightGPU
    [PSCustomObject]@{MainAlgorithm = "cnhaven";     MinMemGb = 3.3; Params = ""} #Cryptonighthaven
    [PSCustomObject]@{MainAlgorithm = "cnheavy";     MinMemGb = 3.3; Params = ""} #Cryptonightheavy
    [PSCustomObject]@{MainAlgorithm = "cntlo";       MinMemGb = 3.3; Params = ""} #CryptonightTLO, new with v0.24.0
    [PSCustomObject]@{MainAlgorithm = "cnturtle";    MinMemGb = 3.3; Params = ""} #Cryptonightturtle
    [PSCustomObject]@{MainAlgorithm = "cnupx2";      MinMemGb = 1.5; Params = ""} #CryptoNightLiteUpx2, new with v0.23.0
    [PSCustomObject]@{MainAlgorithm = "cnzls";       MinMemGb = 3.3; Params = ""} #CryptonightZelerius, new with v0.23.0
    #[PSCustomObject]@{MainAlgorithm = "kawpow";      MinMemGb = 3;   Params = ""; DAG = $true} #CryptonightZelerius, new with v0.26.0
    #[PSCustomObject]@{MainAlgorithm = "mtp";         MinMemGb = 5; Params = ""; ExtendInterval = 2; DevFee = 2.0} #MTP
    #[PSCustomObject]@{MainAlgorithm = "mtp-tcr";     MinMemGb = 5; Params = ""; ExtendInterval = 2} #MTP-TCR
)

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

if ($InfoOnly) {
    [PSCustomObject]@{
        Type      = @("NVIDIA")
        Name      = $Name
        Path      = $Path
        Port      = $Miner_Port
        Uri       = $UriCuda.Uri
        DevFee    = $DevFee
        ManualUri = $ManualUri
        Commands  = $Commands
    }
    return
}

$Cuda = $null
for($i=0;$i -lt $UriCuda.Count -and -not $Cuda;$i++) {
    if (Confirm-Cuda -ActualVersion $Session.Config.CUDAVersion -RequiredVersion $UriCuda[$i].Cuda -Warning $(if ($i -lt $UriCuda.Count-1) {""}else{$Name})) {
        $Uri  = $UriCuda[$i].Uri
        $Cuda = $UriCuda[$i].Cuda
    }
}

if (-not $Cuda) {return}

$Global:DeviceCache.DevicesByTypes.NVIDIA | Select-Object Vendor, Model -Unique | ForEach-Object {
    $Miner_Model = $_.Model
    $Device = $Global:DeviceCache.DevicesByTypes."$($_.Vendor)".Where({$_.Model -eq $Miner_Model -and (-not $_.OpenCL.DeviceCapability -or (Compare-Version $_.OpenCL.DeviceCapability $DeviceCapability) -ge 0)})

    if (-not $Device) {return}

    $Commands.Where({-not $_.Version -or (Compare-Version $Version $_.Version) -ge 0}).ForEach({
        $First = $true
        $MinMemGb = if ($_.DAG) {Get-EthDAGSize -CoinSymbol $Pools.$Algorithm_Norm_0.CoinSymbol -Algorithm $Algorithm_Norm_0 -Minimum $_.MinMemGb} else {$_.MinMemGb}
        $Miner_Device = $Device | Where-Object {Test-VRAM $_ $MinMemGb}

        $Algorithm = if ($_.Algorithm) {$_.Algorithm} else {$_.MainAlgorithm}
        $Algorithm_Norm_0 = Get-Algorithm $_.MainAlgorithm
        
		foreach($Algorithm_Norm in @($Algorithm_Norm_0,"$($Algorithm_Norm_0)-$($Miner_Model)","$($Algorithm_Norm_0)-GPU")) {
			if ($Pools.$Algorithm_Norm.Host -and $Miner_Device -and (-not $_.ExcludePoolName -or $Pools.$Algorithm_Norm.Name -notmatch $_.ExcludePoolName)) {
                if ($First) {
		            $Miner_Port = $Port -f ($Miner_Device | Select-Object -First 1 -ExpandProperty Index)
                    $Miner_Name = (@($Name) + @($Miner_Device.Name | Sort-Object) | Select-Object) -join '-'
		            $DeviceIDsAll = $Miner_Device.Type_Vendor_Index -join ','
                    #$Hashrate = if ($Algorithm -eq "argon2d-nim") {($Miner_Device | Foreach-Object {Get-NimqHashrate $_.Model} | Measure-Object -Sum).Sum}
                    $First = $false
                }
                if ($Algorithm -eq "argon2d-nim" -and $Pools.$Algorithm_Norm.Name -eq "Icemining") {
                    $Pool_Proto = "wss"
                    $Pool_User  = $Pools.$Algorithm_Norm.Wallet
                    if ($Pool_User -match "^([A-Z0-9]{4})\s*([A-Z0-9]{4})\s*([A-Z0-9]{4})\s*([A-Z0-9]{4})\s*([A-Z0-9]{4})\s*([A-Z0-9]{4})\s*([A-Z0-9]{4})\s*([A-Z0-9]{4})\s*([A-Z0-9]{4})$") {
                        $Pool_User = @(1..9 | Foreach-Object {$Matches[$_]}) -join " "
                    }
                    $Pool_UserAndPassword = "-u `"$Pool_User`" -p $($Pools.$Algorithm_Norm.Worker)"
                } else {
                    $Pool_Proto = $Pools.$Algorithm_Norm.Protocol
                    $Pool_UserAndPassword = "-u $($Pools.$Algorithm_Norm.User)$(if ($Pools.$Algorithm_Norm.Pass) {" -p $($Pools.$Algorithm_Norm.Pass)"})"
                }
				$Pool_Port = if ($Pools.$Algorithm_Norm.Ports -ne $null -and $Pools.$Algorithm_Norm.Ports.GPU) {$Pools.$Algorithm_Norm.Ports.GPU} else {$Pools.$Algorithm_Norm.Port}
				[PSCustomObject]@{
					Name           = $Miner_Name
					DeviceName     = $Miner_Device.Name
					DeviceModel    = $Miner_Model
					Path           = $Path
					Arguments      = "-r 10 -R 1 -b 127.0.0.1:`$mport -d $($DeviceIDsAll) -a $($Algorithm) --no-watchdog -o $($Pool_Proto)://$($Pools.$Algorithm_Norm.Host):$($Pool_Port) $($Pool_UserAndPassword)$(if ($Hashrate) {" --hashrate $($hashrate)"})$(if ($Enable_Logfile) {" --log log_`$mport.txt"}) --no-nvml $($_.Params)" # --no-nvml"
					HashRates      = [PSCustomObject]@{$Algorithm_Norm = $Global:StatsCache."$($Miner_Name)_$($Algorithm_Norm_0)_HashRate".Week}
					API            = "Ccminer"
					Port           = $Miner_Port
					Uri            = $Uri
                    FaultTolerance = $_.FaultTolerance
					ExtendInterval = $_.ExtendInterval
                    Penalty        = 0
					DevFee         = if ($_.DevFee -ne $null) {$_.DevFee} else {$DevFee}
					ManualUri      = $ManualUri
                    Version        = $Version
                    PowerDraw      = 0
                    BaseName       = $Name
                    BaseAlgorithm  = $Algorithm_Norm_0
				}
			}
		}
    })
}