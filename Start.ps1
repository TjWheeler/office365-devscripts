#Script:	start.ps1
#Author:	Tim Wheeler (http://timwheeler.io)
#Version:	0.1
Import-Module -Name "$PSScriptRoot\modules\common.module.psm1" -Force -DisableNameChecking
Import-Module -Name "$PSScriptRoot\modules\initialization.module.psm1" -Force -DisableNameChecking
Write-Host "Initialized" -ForegroundColor Green
$InformationPreference = "Continue"
