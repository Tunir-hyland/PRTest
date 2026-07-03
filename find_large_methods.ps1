# Find PR with Large Methods - Auto Test Multiple PRs
# This script tests several PRs to find one with large methods (>50 lines)

Write-Host "`n📏 Starting Large Method Hunter..." -ForegroundColor Cyan
Write-Host "Testing PRs to find ones with large methods...`n" -ForegroundColor Yellow

# Start server
$server = Start-Process node -ArgumentList "server.js" -NoNewWindow -PassThru
Start-Sleep -Seconds 3

$testPRs = @(
    @{url="https://github.com/tensorflow/tensorflow/pull/60000"; desc="TensorFlow"},
    @{url="https://github.com/microsoft/vscode/pull/180000"; desc="VS Code"},
    @{url="https://github.com/django/django/pull/16000"; desc="Django"},
    @{url="https://github.com/golang/go/pull/50000"; desc="Go"},
    @{url="https://github.com/microsoft/TypeScript/pull/50000"; desc="TypeScript"}
)

foreach ($pr in $testPRs) {
    Write-Host "Testing $($pr.desc): $($pr.url)" -ForegroundColor Gray
    
    try {
        $body = @{ prUrl = $pr.url } | ConvertTo-Json
        $result = Invoke-RestMethod -Uri "http://localhost:3000/api/review" `
            -Method Post `
            -Body $body `
            -ContentType "application/json" `
            -TimeoutSec 30 `
            -ErrorAction Stop

        $largeMethodCount = $result.largeMethods.Count
        
        if ($largeMethodCount -gt 0) {
            Write-Host "`n" + ("=" * 70) -ForegroundColor Green
            Write-Host "🎯 FOUND PR WITH LARGE METHODS!" -ForegroundColor Green
            Write-Host ("=" * 70) -ForegroundColor Green
            Write-Host "`n📌 PR URL: $($pr.url)" -ForegroundColor Cyan
            Write-Host "   Project: $($pr.desc)" -ForegroundColor White
            Write-Host "   Title: $($result.meta.title)" -ForegroundColor White
            Write-Host "   Files Changed: $($result.analysis.total_files)" -ForegroundColor White
            Write-Host "`n📏 LARGE METHODS DETECTED: $largeMethodCount" -ForegroundColor Magenta
            
            Write-Host "`n   Details:" -ForegroundColor Yellow
            $result.largeMethods | Select-Object -First 5 | ForEach-Object {
                Write-Host "   • ~$($_.estimated_lines) lines" -ForegroundColor Red
                Write-Host "     📁 $($_.file)" -ForegroundColor DarkGray
                Write-Host "     🔧 $($_.method)" -ForegroundColor Cyan
                Write-Host ""
            }
            
            # Show other findings
            Write-Host "   Other Findings:" -ForegroundColor Yellow
            Write-Host "   🐛 Bugs: $($result.bugs.Count)" -ForegroundColor Magenta
            Write-Host "   💡 Suggestions: $($result.suggestions.Count)" -ForegroundColor Blue
            Write-Host "   📝 TODOs: $($result.todos.Count)" -ForegroundColor Yellow
            Write-Host "   🔄 Duplicates: $($result.duplicates.Count)" -ForegroundColor Yellow
            
            Write-Host "`n" + ("=" * 70) -ForegroundColor Green
            Write-Host "✅ Use this URL to test your agent!" -ForegroundColor Green
            Write-Host ("=" * 70) -ForegroundColor Green
            Write-Host "`n🌐 Test in browser: http://localhost:3000" -ForegroundColor Cyan
            Write-Host "📋 Paste this URL: $($pr.url)`n" -ForegroundColor Blue
            
            break
        } else {
            Write-Host "   ✅ No large methods found (threshold: 50 lines)" -ForegroundColor Gray
        }
        
    } catch {
        Write-Host "   ⚠️  Error: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    
    Start-Sleep -Milliseconds 500
}

Write-Host "`n💡 Pro Tip: Lower the threshold by editing server.js" -ForegroundColor Cyan
Write-Host "   Change: flagLargeMethods(files, threshold = 50)" -ForegroundColor Gray
Write-Host "   To:     flagLargeMethods(files, threshold = 30)" -ForegroundColor Gray
Write-Host "`nServer still running at http://localhost:3000" -ForegroundColor Cyan
Write-Host "Press Ctrl+C to stop.`n" -ForegroundColor Gray
