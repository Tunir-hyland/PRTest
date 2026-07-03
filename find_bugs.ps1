# Find PR with Potential Bugs - Auto Test Multiple PRs
# This script tests several PRs to find one with detectable issues

Write-Host "`n🔍 Starting PR Bug Hunter..." -ForegroundColor Cyan
Write-Host "Testing multiple PRs to find one with potential bugs...`n" -ForegroundColor Yellow

# Start server
$server = Start-Process node -ArgumentList "server.js" -NoNewWindow -PassThru
Start-Sleep -Seconds 3

$testPRs = @(
    "https://github.com/facebook/react/pull/28000",
    "https://github.com/vercel/next.js/pull/50000",
    "https://github.com/webpack/webpack/pull/16000",
    "https://github.com/facebook/react/pull/25000",
    "https://github.com/nodejs/node/pull/45000"
)

foreach ($prUrl in $testPRs) {
    Write-Host "Testing: $prUrl" -ForegroundColor Gray
    
    try {
        $body = @{ prUrl = $prUrl } | ConvertTo-Json
        $result = Invoke-RestMethod -Uri "http://localhost:3000/api/review" `
            -Method Post `
            -Body $body `
            -ContentType "application/json" `
            -TimeoutSec 30 `
            -ErrorAction Stop

        $bugCount = $result.bugs.Count
        $critical = ($result.bugs | Where-Object {$_.severity -eq 'critical'}).Count
        $warning = ($result.bugs | Where-Object {$_.severity -eq 'warning'}).Count
        
        if ($bugCount -gt 0) {
            Write-Host "`n" + ("=" * 70) -ForegroundColor Green
            Write-Host "🎯 FOUND PR WITH BUGS!" -ForegroundColor Green
            Write-Host ("=" * 70) -ForegroundColor Green
            Write-Host "`n📌 PR URL: $prUrl" -ForegroundColor Cyan
            Write-Host "   Title: $($result.meta.title)" -ForegroundColor White
            Write-Host "   Files: $($result.analysis.total_files)" -ForegroundColor White
            Write-Host "`n🐛 BUGS DETECTED: $bugCount" -ForegroundColor Magenta
            if ($critical -gt 0) { Write-Host "   🔴 Critical: $critical" -ForegroundColor Red }
            if ($warning -gt 0) { Write-Host "   🟡 Warnings: $warning" -ForegroundColor Yellow }
            
            Write-Host "`n   Details:" -ForegroundColor Yellow
            $result.bugs | Select-Object -First 5 | ForEach-Object {
                $color = if($_.severity -eq 'critical'){'Red'}elseif($_.severity -eq 'warning'){'Yellow'}else{'Cyan'}
                Write-Host "   • [$($_.severity.ToUpper())] $($_.message)" -ForegroundColor $color
                Write-Host "     📁 $($_.file)" -ForegroundColor DarkGray
                Write-Host "     💻 $($_.code)" -ForegroundColor DarkGray
            }
            
            Write-Host "`n" + ("=" * 70) -ForegroundColor Green
            Write-Host "✅ Use this URL to test your agent!" -ForegroundColor Green
            Write-Host ("=" * 70) -ForegroundColor Green
            Write-Host "`n🌐 Test in browser: http://localhost:3000" -ForegroundColor Cyan
            Write-Host "📋 Paste this URL: $prUrl`n" -ForegroundColor Blue
            
            break
        } else {
            Write-Host "   ✅ No bugs found, trying next PR..." -ForegroundColor Gray
        }
        
    } catch {
        Write-Host "   ⚠️  Couldn't fetch this PR, trying next..." -ForegroundColor Yellow
    }
    
    Start-Sleep -Milliseconds 500
}

Write-Host "`nServer still running at http://localhost:3000" -ForegroundColor Cyan
Write-Host "Press Ctrl+C to stop.`n" -ForegroundColor Gray
