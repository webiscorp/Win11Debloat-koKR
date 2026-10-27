<#
    .SYNOPSIS
        Imports a JSON file, optionally validates its version, and returns $null on failure.
#>
function Import-JsonFile {
    param (
        [string]$filePath,
        [string]$expectedVersion = $null,
        [switch]$optionalFile
    )
    
    if (-not (Test-Path $filePath)) {
        if (-not $optionalFile) {
            Write-Error "File not found / 파일을 찾을 수 없습니다: $filePath"
        }
        return $null
    }
    
    try {
        $jsonContent = Get-Content -Path $filePath -Raw -Encoding UTF8 | ConvertFrom-Json
        
        # Validate version if specified
        if ($expectedVersion -and $jsonContent.Version -and $jsonContent.Version -ne $expectedVersion) {
            Write-Error "$(Split-Path $filePath -Leaf) version mismatch / 파일 버전 불일치 (필요: $expectedVersion, 현재: $($jsonContent.Version))"
            return $null
        }
        
        return $jsonContent
    }
    catch {
        Write-Error "Failed to parse JSON file / JSON 파일을 해석하지 못했습니다: $filePath"
        return $null
    }
}
