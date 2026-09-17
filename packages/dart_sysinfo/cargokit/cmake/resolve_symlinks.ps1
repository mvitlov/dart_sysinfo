function Resolve-Symlinks {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Position = 0, Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string] $Path
    )

    if (-not $Path) {
        return ''
    }

    $separator = '/'
    $normalizedPath = $Path.Replace('\', '/')
    $parts = $normalizedPath.Split($separator, [System.StringSplitOptions]::RemoveEmptyEntries)

    [string] $realPath = ''
    if ($normalizedPath.StartsWith('/')) {
        $realPath = '/'
    }

    foreach ($part in $parts) {
        if ($part -eq '.') {
            continue
        }

        if ($part -eq '..') {
            if ($realPath) {
                $parent = Split-Path -Parent $realPath
                if ($parent) {
                    $realPath = $parent.Replace('\', '/')
                }
            }
            continue
        }

        if ($realPath -and !$realPath.EndsWith($separator)) {
            $realPath += $separator
        }

        $realPath += $part

        # Handle drive letter root (e.g. "D:")
        if (-not ($realPath.Contains($separator)) -and $realPath.EndsWith(':')) {
            $realPath += '/'
        }

        $item = Get-Item -LiteralPath $realPath -Force -ErrorAction SilentlyContinue
        if ($item) {
            $target = $null
            if ($item.PSObject.Properties['LinkTarget'] -and $item.LinkTarget) {
                $target = $item.LinkTarget
            } elseif ($item.PSObject.Properties['Target'] -and $item.Target) {
                if ($item.Target -is [System.Collections.IEnumerable] -and -not ($item.Target -is [string])) {
                    $target = $item.Target[0]
                } else {
                    $target = $item.Target
                }
            }

            if ($target) {
                $target = [string]$target
                # Strip NT object manager prefix if present (\??\)
                if ($target -match '^\\\?\?\\(.+)') {
                    $target = $matches[1]
                }
                # If relative, resolve relative to parent directory of the link
                if (-not [System.IO.Path]::IsPathRooted($target)) {
                    $parent = Split-Path -Parent $realPath
                    $target = [System.IO.Path]::Combine($parent, $target)
                }
                $realPath = [System.IO.Path]::GetFullPath($target).Replace('\', '/')
            }
        }
    }

    return $realPath
}

$path = Resolve-Symlinks -Path $args[0]
[Console]::Out.Write($path)
