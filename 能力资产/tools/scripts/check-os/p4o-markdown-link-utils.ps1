function Get-Rel([string]$Path) {
  $full = [System.IO.Path]::GetFullPath($Path)
  $rootFull = [System.IO.Path]::GetFullPath($Root).TrimEnd('\')
  if ($full.StartsWith($rootFull, [System.StringComparison]::OrdinalIgnoreCase)) {
    return $full.Substring($rootFull.Length).TrimStart('\') -replace '\\','/'
  }
  return $Path
}

function Get-Line([string]$Text, [int]$Index) {
  if ($Index -le 0) { return 1 }
  return (($Text.Substring(0, $Index) -split "`n").Count)
}

function Decode-Part([string]$Value) {
  try { return [System.Uri]::UnescapeDataString($Value) } catch { return $Value }
}

function Remove-CodeFences([string]$Text) {
  $out = New-Object System.Collections.Generic.List[string]
  $inFence = $false
  foreach ($line in ($Text -split "`r?`n")) {
    if ($line -match '^\s*(```|~~~)') {
      $inFence = -not $inFence
      $out.Add("") | Out-Null
      continue
    }
    $out.Add($(if ($inFence) { "" } else { $line })) | Out-Null
  }
  return ($out -join "`n")
}

function ConvertTo-Slug([string]$Heading) {
  $s = (Decode-Part $Heading).Trim().ToLowerInvariant()
  $s = $s -replace '`',''
  $s = $s -replace '\[([^\]]+)\]\([^)]+\)','$1'
  $s = $s -replace '<[^>]+>',''
  $s = $s -replace '[^\p{L}\p{Nd}\s_-]',''
  $s = $s -replace '\s','-'
  return $s.Trim('-')
}

function Get-SlugSet([string]$Path) {
  $text = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
  $seen = @{}
  $set = New-Object System.Collections.Generic.HashSet[string]
  foreach ($m in [regex]::Matches($text, '(?m)^\s{0,3}#{1,6}\s+(.+?)\s*#*\s*$')) {
    $base = ConvertTo-Slug $m.Groups[1].Value
    if ([string]::IsNullOrWhiteSpace($base)) { continue }
    $slug = $base
    if ($seen.ContainsKey($base)) {
      $slug = "$base-$($seen[$base])"
      $seen[$base] = [int]$seen[$base] + 1
    } else {
      $seen[$base] = 1
    }
    $set.Add($slug) | Out-Null
    $set.Add(($slug -replace '-+','-')) | Out-Null
  }
  return $set
}

function Get-LinkTarget([string]$Raw) {
  $v = $Raw.Trim()
  if ($v.StartsWith("<")) {
    $end = $v.IndexOf(">")
    if ($end -gt 0) { return $v.Substring(1, $end - 1) }
  }
  return (($v -split '\s+')[0])
}

function Normalize-RefLabel([string]$Label) {
  return $Label.Trim().ToLowerInvariant()
}

function Check-Link([object]$Source, [int]$Index, [string]$Raw) {
  $raw = Get-LinkTarget $Raw
  if ([string]::IsNullOrWhiteSpace($raw) -or $raw.StartsWith("#")) { return }
  if ($raw -match '^[a-zA-Z][a-zA-Z0-9+.-]*:') { return }
  $targetPart = $raw
  $anchor = ""
  $hash = $raw.IndexOf("#")
  if ($hash -ge 0) {
    $targetPart = $raw.Substring(0, $hash)
    $anchor = $raw.Substring($hash + 1)
  }
  if ([string]::IsNullOrWhiteSpace($targetPart)) { return }
  $targetPart = (Decode-Part $targetPart) -replace '/', '\'
  $target = [System.IO.Path]::GetFullPath((Join-Path (Split-Path -Parent $Source.Path) $targetPart))
  $rootFull = [System.IO.Path]::GetFullPath($Root).TrimEnd('\') + '\'
  $script:linkCount++
  if (-not $target.StartsWith($rootFull, [System.StringComparison]::OrdinalIgnoreCase)) {
    $issues.Add("$(Get-Rel $Source.Path):L$(Get-Line $Source.Text $Index) 越界链接：$raw") | Out-Null
    return
  }
  if (-not (Test-Path -LiteralPath $target)) {
    if ($script:IsTemplateRoot) {
      $targetRel = $target.Substring($rootFull.Length).TrimStart('\') -replace '/', '\'
      if ($targetRel -match '^(TASKS\.md|Docs\\(1-需求文档|2-产品文档|4-测试文档|5-运维文档)\\|确认改动\\(已审批|拒绝)\\|交接区\\历史归档\\)') {
        return
      }
    }
    $issues.Add("$(Get-Rel $Source.Path):L$(Get-Line $Source.Text $Index) 断链：$raw") | Out-Null
    return
  }
  if (-not [string]::IsNullOrWhiteSpace($anchor) -and (Test-Path -LiteralPath $target -PathType Leaf) -and $target.ToLowerInvariant().EndsWith(".md")) {
    if (-not $slugCache.ContainsKey($target)) { $slugCache[$target] = Get-SlugSet $target }
    $slug = ConvertTo-Slug $anchor
    if (-not $slugCache[$target].Contains($slug)) {
      $issues.Add("$(Get-Rel $Source.Path):L$(Get-Line $Source.Text $Index) 缺锚点：$raw") | Out-Null
    }
  }
}
