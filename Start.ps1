#Script:	Start.ps1 https://github.com/TjWheeler/office365-devscripts
#Author:	Tim Wheeler (http://timwheeler.io)
#Version:	0.4
Import-Module -Name "$PSScriptRoot\modules\common.module.psm1" -Force -DisableNameChecking
Import-Module -Name "$PSScriptRoot\modules\initialization.module.psm1" -Force -DisableNameChecking
Import-Module -Name "$PSScriptRoot\modules\sp.module.psm1" -Force -DisableNameChecking
$InformationPreference = "Continue"
