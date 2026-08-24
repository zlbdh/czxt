$ErrorActionPreference = 'Stop'

$credentialSafetyPath = Join-Path `
  ([IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)) 'credential-safety.ps1'
if (-not (Get-Command Test-BorrowingCredentialMaterial -CommandType Function `
      -ErrorAction SilentlyContinue)) {
  . $credentialSafetyPath
}

function global:New-BorrowingFailureException {
param([string]$Stage,[string]$ReasonCode,[Alias('Message')][string]$Reason)
if ([string]::IsNullOrWhiteSpace($Reason)) {$Reason='borrowing operation failed'}
$e=New-Object InvalidOperationException $Reason
$e.Data['BorrowingStage']=$Stage
$e.Data['BorrowingReasonCode']=$ReasonCode
$e
}

function global:Throw-BorrowingFailure {
param([string]$Stage,[string]$ReasonCode,[Alias('Message')][string]$Reason)
throw (New-BorrowingFailureException $Stage $ReasonCode $Reason)
}

function global:Assert-BorrowingSafeIdentifier {
param([string]$Value,[string]$FieldName)
if ($null -eq $Value -or $Value -cnotmatch '\A[a-z0-9](?:[a-z0-9._-]{0,126}[a-z0-9_-])?\z') {
Throw-BorrowingFailure input invalid-parameters 'identifier is invalid'
}
$stem=$Value.Split('.')[0]
if ($stem -match '\A(?:con|prn|aux|nul|com[1-9]|lpt[1-9])\z') {
Throw-BorrowingFailure input invalid-parameters 'identifier is reserved'
}
$Value
}

function global:Resolve-BorrowingCaptureRequest {
param([Collections.IDictionary]$BoundParameters)
$fail={param($code) Throw-BorrowingFailure input $code 'capture request is invalid'}
$all=@(
'Root','SourceType','SourceId','GitLocator','GitRef','LocalPath','LocalDisplayName',
'WebRawBytesPath','WebResponseMetadataPath','RightsStatus','AccessPolicy','ReuseScope',
'ExecutionPolicy','NetworkPolicy','StoragePolicy','DistributionPolicy',
'UpstreamWritePolicy','AutoRefresh','AuthorizationTime','AuthorizationSource','AuthorizationScope'
)
if ($null -eq $BoundParameters) {&$fail invalid-parameters}
foreach($key in $BoundParameters.Keys) {
if ($all -notcontains [string]$key) {&$fail invalid-parameters}
}
foreach($name in @('Root','SourceType','SourceId')) {
if (-not $BoundParameters.Contains($name) -or [string]::IsNullOrWhiteSpace($BoundParameters[$name])) {
&$fail invalid-parameters
}
}
$type=([string]$BoundParameters['SourceType']).ToLowerInvariant()
if (@('git','local','web') -cnotcontains $type) {&$fail invalid-parameters}
$sourceId=Assert-BorrowingSafeIdentifier ([string]$BoundParameters['SourceId']) SourceId
if (Test-BorrowingCredentialMaterial $sourceId) {&$fail invalid-parameters}
if ($type -eq 'git') {$required=@('GitLocator','GitRef');$forbidden=@('LocalPath','LocalDisplayName','WebRawBytesPath','WebResponseMetadataPath')}
elseif ($type -eq 'local') {$required=@('LocalPath','LocalDisplayName');$forbidden=@('GitLocator','GitRef','WebRawBytesPath','WebResponseMetadataPath')}
else {$required=@('WebRawBytesPath','WebResponseMetadataPath');$forbidden=@('GitLocator','GitRef','LocalPath','LocalDisplayName')}
foreach($name in $required) {
if (-not $BoundParameters.Contains($name) -or [string]::IsNullOrWhiteSpace($BoundParameters[$name])) {
&$fail invalid-parameters
}
}
foreach($name in $forbidden) {
if ($BoundParameters.Contains($name)) {&$fail invalid-parameters}
}
if ($type -eq 'local') {
$displayName=Assert-BorrowingSafeIdentifier ([string]$BoundParameters['LocalDisplayName']) LocalDisplayName
if (Test-BorrowingCredentialMaterial $displayName) {&$fail invalid-parameters}
}

$pn=@('RightsStatus','AccessPolicy','ReuseScope','ExecutionPolicy','NetworkPolicy','StoragePolicy','DistributionPolicy','UpstreamWritePolicy','AutoRefresh')
$defaults=[ordered]@{
RightsStatus='unverified';AccessPolicy='local-read-only';ReuseScope='inspect-and-analyze-only'
ExecutionPolicy='deny';NetworkPolicy='deny';StoragePolicy='local-only';DistributionPolicy='deny'
UpstreamWritePolicy='deny';AutoRefresh='false'
}
$allowed=@{
RightsStatus=@('unverified','verified','restricted');AccessPolicy=@('local-read-only','source-read-only')
ReuseScope=@('inspect-and-analyze-only','copy-internal-approved','adapt-internal-approved','redistribute-approved')
ExecutionPolicy=@('deny','sandbox-approved');NetworkPolicy=@('deny','source-read-only')
StoragePolicy=@('local-only','tracked-metadata-only','tracked-content-approved')
DistributionPolicy=@('deny','internal-approved','external-approved');UpstreamWritePolicy=@('deny');AutoRefresh=@('false')
}
$values=[ordered]@{}
foreach($name in $pn) {
$value=$defaults[$name]
if ($BoundParameters.Contains($name)) {$value=[string]$BoundParameters[$name]}
if ([string]::IsNullOrWhiteSpace($value) -or $allowed[$name] -cnotcontains $value) {
&$fail invalid-permissions
}
$values[$name]=$value
}
$access=if($type -eq 'local'){'local-read-only'}else{'source-read-only'}
$network=if($type -eq 'local'){'deny'}else{'source-read-only'}
if ($values.AccessPolicy -cne $access -or $values.NetworkPolicy -cne $network -or
$values.ExecutionPolicy -cne 'deny' -or $values.UpstreamWritePolicy -cne 'deny') {
&$fail invalid-permissions
}
$deviation=$false
foreach($name in $pn) {if($values[$name] -cne $defaults[$name]) {$deviation=$true}}
$en=@('AuthorizationTime','AuthorizationSource','AuthorizationScope');$ec=0
foreach($name in $en) {if($BoundParameters.Contains($name)) {$ec++}}
if (($deviation -and $ec -ne 3) -or (-not $deviation -and $ec -ne 0)) {
&$fail invalid-permissions
}
$at=$null;$as=$null;$ac=$null
if ($deviation) {
foreach($name in $en) {
if ([string]::IsNullOrWhiteSpace($BoundParameters[$name])) {&$fail invalid-permissions}
}
$text=[string]$BoundParameters['AuthorizationTime'];$dto=[DateTimeOffset]::MinValue
if ($text -cnotmatch '\A[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}(?:\.[0-9]{1,7})?(?:Z|[+-][0-9]{2}:[0-9]{2})\z' -or
-not [DateTimeOffset]::TryParse($text,[cultureinfo]::InvariantCulture,[Globalization.DateTimeStyles]::None,[ref]$dto)) {
&$fail invalid-permissions
}
$at=$dto.ToUniversalTime().ToString("yyyy-MM-dd'T'HH:mm:ss.fff'Z'",[cultureinfo]::InvariantCulture)
foreach($name in @('AuthorizationSource','AuthorizationScope')) {
try {$normalized=([string]$BoundParameters[$name]).Normalize([Text.NormalizationForm]::FormC)}
catch {&$fail invalid-permissions}
if ([Text.Encoding]::UTF8.GetByteCount($normalized) -gt 512 -or $normalized -match '[\x00-\x1F\x7F-\x9F\u2028\u2029\|\x60]') {
&$fail invalid-permissions
}
if (Test-BorrowingCredentialMaterial $normalized) {&$fail invalid-permissions}
if($name -eq 'AuthorizationSource') {$as=$normalized}else{$ac=$normalized}
}
}
$dn=@('rights_status','access_policy','reuse_scope','execution_policy','network_policy','storage_policy','distribution_policy','upstream_write_policy','auto_refresh')
$pa=@(for($i=0;$i -lt 9;$i++) {
$name=$pn[$i];$isDefault=$values[$name] -ceq $defaults[$name]
[pscustomobject][ordered]@{
Dimension=$dn[$i];Value=$values[$name]
AuthorizationTime=$(if($isDefault){$null}else{$at})
AuthorizationSource=$(if($isDefault){'default-policy'}else{$as})
AuthorizationScope=$(if($isDefault){'current-capture'}else{$ac});IsDefault=$isDefault
}
})
$r=[ordered]@{
Root=[string]$BoundParameters['Root'];SourceType=$type;SourceId=$sourceId
GitLocator=$null;GitRef=$null;LocalPath=$null;LocalDisplayName=$null
WebRawBytesPath=$null;WebResponseMetadataPath=$null
}
foreach($name in @('GitLocator','GitRef','LocalPath','LocalDisplayName','WebRawBytesPath','WebResponseMetadataPath')) {
if($BoundParameters.Contains($name)) {$r[$name]=[string]$BoundParameters[$name]}
}
foreach($name in $pn) {$r[$name]=$values[$name]}
$r.AuthorizationTime=$at;$r.AuthorizationSource=$as;$r.AuthorizationScope=$ac
$r.PermissionAuthorizations=$pa
[pscustomobject]$r
}

function global:Get-BorrowingSha256Hex {
param([byte[]]$Bytes)
if ($null -eq $Bytes) {Throw-BorrowingFailure input invalid-parameters 'hash bytes are missing'}
$sha=[Security.Cryptography.SHA256]::Create()
try {([BitConverter]::ToString($sha.ComputeHash($Bytes))).Replace('-','').ToLowerInvariant()}
finally {$sha.Dispose()}
}

function global:ConvertTo-BorrowingCanonicalJsonString {
param([string]$Value)
if ($null -eq $Value) {Throw-BorrowingFailure input invalid-parameters 'JSON string is missing'}
try {$Value=$Value.Normalize([Text.NormalizationForm]::FormC)}
catch {Throw-BorrowingFailure input invalid-parameters 'JSON string is invalid'}
$b=New-Object Text.StringBuilder;[void]$b.Append('"')
for($i=0;$i -lt $Value.Length;$i++) {
$ch=$Value[$i];$n=[int]$ch
$escape=switch($n) {34{'\"'};92{'\\'};8{'\b'};12{'\f'};10{'\n'};13{'\r'};9{'\t'};default{$null}}
if($null -ne $escape) {[void]$b.Append($escape)}
elseif($n -le 31 -or ($n -ge 127 -and $n -le 159) -or $n -in @(124,0x2028,0x2029)) {[void]$b.Append(('\u{0:X4}' -f $n))}
else {[void]$b.Append($ch)}
}
[void]$b.Append('"');$b.ToString()
}
