﻿using module ..\Include.psm1

param(
    [PSCustomObject]$Pools,
    [PSCustomObject]$Stats,
    [PSCustomObject]$Config,
    [PSCustomObject]$Devices
)

if (-not $Devices.NVIDIA) {return} # No NVIDIA mining device present in system


$DriverVersion = (Get-Devices).NVIDIA.Platform.Version -replace ".*CUDA ",""
$RequiredVersion = "9.1.00"
if ($DriverVersion -lt $RequiredVersion) {
    Write-Log -Level Warn "Miner ($($Name)) requires CUDA version $($RequiredVersion) or above (installed version is $($DriverVersion)). Please update your Nvidia drivers to 390.77 or newer. "
    return
}

$Type = "NVIDIA"
$Path = ".\Bin\ZEnemy-NVIDIA-111v3\z-enemy.exe"
$Uri = "http://semitest.000webhostapp.com/binary/z-enemy.1-11-public-final_v3.zip"
$Port = 4068
$Fee = 1

$Commands = [PSCustomObject]@{
    "aeriumx"    = "" #aeriumx
    "bitcore"    = "" #Bitcore
    "c11"        = "" #c11
    "phi"        = "" #Phi
    "poly"       = "" #poly
    "vit"        = "" #Vitalium
    "skunk"      = "" #skunk
    "timetravel" = "" #timetravel
    "tribus"     = "" #Tribus
    "x16s"       = " -i 21" #Pigeon CcminerPigeoncoin-26
    "x16r"       = " -i 21" #Raven
    "x17"        = "" #X17
    "xevan"      = "" #Xevan
}

$CommonCommands = "" #eg. " -d 0,1,8,9"

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | Where-Object {$Pools.(Get-Algorithm $_).Protocol -eq "stratum+tcp" <#temp fix#>} | ForEach-Object {

    $Algorithm_Norm = Get-Algorithm $_

    Switch ($Algorithm_Norm) {
        "allium"        {$ExtendInterval = 2}
        "CryptoNightV7" {$ExtendInterval = 2}
        "Lyra2RE2"      {$ExtendInterval = 2
		$N = 1}
        "lyra2z"        {$N = 1}
        "phi"           {$N = 1}
        "phi2"          {$ExtendInterval = 2}
        "tribus"        {$ExtendInterval = 2
		$N = 1}
        "X16R"          {$ExtendInterval = 3}
        "X16S"          {$ExtendInterval = 3}
        "X17"           {$ExtendInterval = 2}
        "Xevan"         {$ExtendInterval = 2
		$N = 1}
        default         {$ExtendInterval = 0
		$N = 3}
    }

    $HashRate = $Stats."$($Name)_$($Algorithm_Norm)_HashRate".Week * (1 - $Fee / 100)

    [PSCustomObject]@{
        Type           = $Type
        Path           = $Path
        Arguments      = "-q -b $($Port) -a $_ -o $($Pools.$Algorithm_Norm.Protocol)://$($Pools.$Algorithm_Norm.Host):$($Pools.$Algorithm_Norm.Port) -u $($Pools.$Algorithm_Norm.User) -p $($Pools.$Algorithm_Norm.Pass)$($Commands.$_)$(CommonCommands) -N $($N)"
        HashRates      = [PSCustomObject]@{$Algorithm_Norm = $HashRate}
        API            = "Ccminer"
        Port           = $Port
        URI            = $Uri
        MinerFee       = @($Fee)
        ExtendInterval = $ExtendInterval
    }
}