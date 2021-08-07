
<#PSScriptInfo
.VERSION 1.0
.GUID 55081cab-08e3-4c05-96bb-a70c79cb5b3b

.AUTHOR Rodrigo Cordeiro <rodrigomendoncca@gmail.com>

.COMPANYNAME 

.COPYRIGHT 

.TAGS PersonalConfiguration PersonalAssistant Terminal Powershell

.LICENSEURI 

.PROJECTURI https://rodcordeiro.com.br/

.ICONURI 

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS 

.EXTERNALSCRIPTDEPENDENCIES 

.RELEASENOTES


#>

<# 

.DESCRIPTION 
 Profile configuration 

#> 
Param()

function SignScripts{
<# 
.SYNOPSIS 
    Sign a script with a certificate 
.DESCRIPTION
    Sign a script with a valid certificate
.Parameter <Path>
    Path to script to sign
.Example
    sign ./example.ps1
.Example
    sign C:\Scripts\example.ps1
#> 
    
    param([parameter(ValueFromPipelineByPropertyName)][string]$Path)
    if (!$Path){
      Write-Host "You must pass the path argument"
      Break
    }
    Write-Host ""
      $certificates = Get-ChildItem cert:\LocalMachine\My
      $counter = 1;
      Write-Host "Bellow are the available certificates:"
      $certificates | ForEach-Object {
        $cer = $_ | Select-Object Subject
        Write-Host "$counter | $cer"
        $counter = $counter + 1
      }
      Write-Host ""
      
      $opt = $(Read-Host -Prompt "Enter the certificate number choosed") - 1
      $certificate = $certificates[$opt]
      
      Set-AuthenticodeSignature $Path $certificate
}

    
## ALIASES
Set-Alias sign SignScripts

## Configs
$console = $host.ui.rawui
$console.backgroundcolor = "black"
$console.foregroundcolor = "cyan"
