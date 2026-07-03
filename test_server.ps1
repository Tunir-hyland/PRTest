# Test Script for PR Review Agent Server
# Run this to verify the server is working correctly

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "  Testing PR Review Agent Server" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# Test 1: Check if server is responding
Write-Host "Test 1: Checking if server is running..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:3000" -UseBasicParsing -TimeoutSec 5
    if ($response.StatusCode -eq 200) {
        Write-Host "✅ Server is UP and responding!" -ForegroundColor Green
    }
} catch {
    Write-Host "❌ Server is NOT responding!" -ForegroundColor Red
    Write-Host "   Make sure you ran: node server.js" -ForegroundColor Yellow
    exit
}

Write-Host ""

# Test 2: Test API with a real PR
Write-Host "Test 2: Testing API with a real GitHub PR..." -ForegroundColor Yellow
Write-Host "   (This may take 5-10 seconds...)" -ForegroundColor Gray

$testBody = @{
    prUrl = "https://github.com/microsoft/vscode/pull/200000"
} | ConvertTo-Json

try {
    $apiResponse = Invoke-RestMethod -Uri "http://localhost:3000/api/review" `
        -Method Post `
        -Body $testBody `
        -ContentType "application/json" `
        -TimeoutSec 30

    Write-Host "✅ API is working!" -ForegroundColor Green
    Write-Host ""
    Write-Host "   📋 PR: $($apiResponse.meta.title)" -ForegroundColor Cyan
    Write-Host "   👤 Author: $($apiResponse.meta.author)" -ForegroundColor Cyan
    Write-Host "   📁 Files: $($apiResponse.analysis.total_files)" -ForegroundColor White
    Write-Host "   ➕ Added: $($apiResponse.analysis.additions) lines" -ForegroundColor Green
    Write-Host "   ➖ Removed: $($apiResponse.analysis.deletions) lines" -ForegroundColor Red
    Write-Host "   🐛 Bugs found: $($apiResponse.bugs.Count)" -ForegroundColor Magenta
    Write-Host "   💡 Suggestions: $($apiResponse.suggestions.Count)" -ForegroundColor Blue
    Write-Host "   📝 TODOs: $($apiResponse.todos.Count)" -ForegroundColor Yellow
} catch {
    Write-Host "❌ API test failed!" -ForegroundColor Red
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
    exit
}

Write-Host ""
Write-Host "=====================================" -ForegroundColor Green
Write-Host "  ✨ All tests passed!" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green
Write-Host ""
Write-Host "Your server is fully functional at:" -ForegroundColor White
Write-Host "  👉 http://localhost:3000" -ForegroundColor Cyan
Write-Host ""
Write-Host "What to do next:" -ForegroundColor Yellow
Write-Host "  1. Open http://localhost:3000 in your browser" -ForegroundColor White
Write-Host "  2. Paste any GitHub PR URL" -ForegroundColor White
Write-Host "  3. Click 'Review Pull Request'" -ForegroundColor White
Write-Host ""
Write-Host "Example PRs to try:" -ForegroundColor Yellow
Write-Host "  • https://github.com/microsoft/vscode/pull/200000" -ForegroundColor Gray
Write-Host "  • https://github.com/facebook/react/pull/25000" -ForegroundColor Gray
Write-Host "  • https://github.com/golang/go/pull/65000" -ForegroundColor Gray
Write-Host ""
