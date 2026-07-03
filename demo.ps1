# Quick Demo - Test PR Review Agent with Real GitHub PR
# Run this script to see the agent analyze a real PR

Write-Host "`n🚀 Starting PR Review Agent..." -ForegroundColor Cyan

# Start server in background
$server = Start-Process node -ArgumentList "server.js" -NoNewWindow -PassThru
Start-Sleep -Seconds 3

Write-Host "✅ Server started on http://localhost:3000" -ForegroundColor Green
Write-Host "`n📋 Testing with React PR #25000..." -ForegroundColor Yellow
Write-Host "(This analyzes a real Facebook React pull request)" -ForegroundColor Gray
Write-Host "`nAnalyzing... (may take 5-10 seconds)" -ForegroundColor Gray

try {
    # Test with a real React PR
    $body = @{
        prUrl = "https://github.com/facebook/react/pull/25000"
    } | ConvertTo-Json

    $result = Invoke-RestMethod -Uri "http://localhost:3000/api/review" `
        -Method Post `
        -Body $body `
        -ContentType "application/json" `
        -TimeoutSec 30

    # Display results
    Write-Host "`n" + ("=" * 60) -ForegroundColor Green
    Write-Host "✅ PR REVIEW RESULTS" -ForegroundColor Green
    Write-Host ("=" * 60) -ForegroundColor Green

    Write-Host "`n📌 PR Information:" -ForegroundColor Cyan
    Write-Host "   Title: $($result.meta.title)"
    Write-Host "   Author: $($result.meta.author)"
    Write-Host "   Repo: $($result.meta.owner)/$($result.meta.repo)"
    Write-Host "   URL: $($result.meta.url)" -ForegroundColor Blue

    Write-Host "`n📊 Code Changes:" -ForegroundColor Cyan
    Write-Host "   Files Changed: $($result.analysis.total_files)"
    Write-Host "   Lines Added: +$($result.analysis.additions)" -ForegroundColor Green
    Write-Host "   Lines Deleted: -$($result.analysis.deletions)" -ForegroundColor Red

    Write-Host "`n🐛 Bugs Found: $($result.bugs.Count)" -ForegroundColor Magenta
    if ($result.bugs.Count -gt 0) {
        $critical = ($result.bugs | Where-Object {$_.severity -eq 'critical'}).Count
        $warning = ($result.bugs | Where-Object {$_.severity -eq 'warning'}).Count
        $info = ($result.bugs | Where-Object {$_.severity -eq 'info'}).Count
        
        if ($critical -gt 0) { Write-Host "   🔴 Critical: $critical" -ForegroundColor Red }
        if ($warning -gt 0) { Write-Host "   🟡 Warning: $warning" -ForegroundColor Yellow }
        if ($info -gt 0) { Write-Host "   🔵 Info: $info" -ForegroundColor Cyan }
        
        Write-Host "`n   Examples:"
        $result.bugs | Select-Object -First 3 | ForEach-Object {
            Write-Host "   • [$($_.severity)] $($_.message)" -ForegroundColor Gray
            Write-Host "     File: $($_.file)" -ForegroundColor DarkGray
        }
    } else {
        Write-Host "   ✅ No obvious bugs detected!" -ForegroundColor Green
    }

    Write-Host "`n💡 Improvement Suggestions: $($result.suggestions.Count)" -ForegroundColor Blue
    if ($result.suggestions.Count -gt 0) {
        $result.suggestions | Select-Object -First 2 | ForEach-Object {
            Write-Host "   • $($_.suggestion)" -ForegroundColor Gray
            Write-Host "     File: $($_.file)" -ForegroundColor DarkGray
        }
    }

    Write-Host "`n📝 TODOs Found: $($result.todos.Count)" -ForegroundColor Yellow
    if ($result.todos.Count -gt 0) {
        $result.todos | Select-Object -First 2 | ForEach-Object {
            Write-Host "   • [$($_.type)] $($_.message)" -ForegroundColor Gray
        }
    }

    Write-Host "`n📏 Large Methods: $($result.largeMethods.Count)" -ForegroundColor Yellow
    Write-Host "🔄 Code Duplications: $($result.duplicates.Count)" -ForegroundColor Yellow

    Write-Host "`n📰 Release Notes Generated: ✅" -ForegroundColor Green
    Write-Host "   Features: $($result.releaseNotes.features.Count)"
    Write-Host "   Bug Fixes: $($result.releaseNotes.fixes.Count)"

    Write-Host "`n" + ("=" * 60) -ForegroundColor Green
    Write-Host "✨ Full interactive UI available at:" -ForegroundColor Cyan
    Write-Host "   👉 http://localhost:3000" -ForegroundColor Blue
    Write-Host ("=" * 60) -ForegroundColor Green
    Write-Host "`n💡 Try more PRs in your browser!" -ForegroundColor Yellow
    Write-Host "   Press Ctrl+C in the server terminal to stop." -ForegroundColor Gray
    Write-Host ""

} catch {
    Write-Host "`n❌ Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Make sure the server started correctly." -ForegroundColor Yellow
} finally {
    # Keep server running
    Write-Host "Server is still running. Open http://localhost:3000 to continue testing." -ForegroundColor Cyan
}
