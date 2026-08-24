$ErrorActionPreference = 'Stop'

function global:Get-BorrowingPathRelation {
  param($Left, $Right)
  $form = [Text.NormalizationForm]::FormC
  $a = $Left.Normalize($form).Replace('/', '\').TrimEnd('\')
  $b = $Right.Normalize($form).Replace('/', '\').TrimEnd('\')
  $comparison = [StringComparison]::OrdinalIgnoreCase
  if ([string]::Equals($a, $b, $comparison)) { return 'equal' }
  if ($b.StartsWith($a + '\', $comparison)) { return 'ancestor' }
  if ($a.StartsWith($b + '\', $comparison)) { return 'descendant' }
  return 'disjoint'
}
