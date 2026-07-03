# Quick Setup and Test Script
# This script helps you install Python and test the PR Review Agent

Write-Host "================================" -ForegroundColor Cyan
Write-Host "PR Review Agent - Quick Setup" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# Check if Python is installed
$pythonInstalled = $false
try {
    $version = python --version 2>&1
    if ($version -match "Python \d+\.\d+") {
        Write-Host "✅ Python is already installed: $version" -ForegroundColor Green
        $pythonInstalled = $true
    }
} catch {
    Write-Host "❌ Python is not installed" -ForegroundColor Red
}

# If not installed, offer to install
if (-not $pythonInstalled) {
    Write-Host ""
    Write-Host "Would you like to install Python now?" -ForegroundColor Yellow
    Write-Host "1. Yes - Open Microsoft Store (Recommended)" -ForegroundColor White
    Write-Host "2. Yes - Open python.org download page" -ForegroundColor White
    Write-Host "3. No - I'll install it manually" -ForegroundColor White
    Write-Host ""
    
    $choice = Read-Host "Enter your choice (1, 2, or 3)"
    
    switch ($choice) {
        "1" {
            Write-Host "Opening Microsoft Store..." -ForegroundColor Cyan
            Start-Process "ms-windows-store://pdp/?ProductId=9NRWMJP3717K"
            Write-Host ""
            Write-Host "After installing Python:" -ForegroundColor Yellow
            Write-Host "1. Close and reopen PowerShell" -ForegroundColor White
            Write-Host "2. Run this script again: .\setup_and_test.ps1" -ForegroundColor White
            exit
        }
        "2" {
            Write-Host "Opening python.org..." -ForegroundColor Cyan
            Start-Process "https://www.python.org/downloads/"
            Write-Host ""
            Write-Host "IMPORTANT: When installing, check 'Add Python to PATH'" -ForegroundColor Yellow
            Write-Host ""
            Write-Host "After installing Python:" -ForegroundColor Yellow
            Write-Host "1. Close and reopen PowerShell" -ForegroundColor White
            Write-Host "2. Run this script again: .\setup_and_test.ps1" -ForegroundColor White
            exit
        }
        "3" {
            Write-Host ""
            Write-Host "Manual installation instructions:" -ForegroundColor Yellow
            Write-Host "1. Visit: https://www.python.org/downloads/" -ForegroundColor White
            Write-Host "2. Download Python 3.12 or later" -ForegroundColor White
            Write-Host "3. Run installer and CHECK 'Add Python to PATH'" -ForegroundColor White
            Write-Host "4. Restart PowerShell" -ForegroundColor White
            Write-Host "5. Run this script again" -ForegroundColor White
            exit
        }
        default {
            Write-Host "Invalid choice. Exiting." -ForegroundColor Red
            exit
        }
    }
}

# Python is installed, let's test the agent
Write-Host ""
Write-Host "================================" -ForegroundColor Cyan
Write-Host "Testing with Live GitHub PR" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Select a PR to analyze:" -ForegroundColor Yellow
Write-Host "1. VS Code PR (Small, ~5-10 files)" -ForegroundColor White
Write-Host "2. React PR (Medium)" -ForegroundColor White
Write-Host "3. Enter your own PR URL" -ForegroundColor White
Write-Host ""

$prChoice = Read-Host "Enter your choice (1, 2, or 3)"

$prUrl = ""
switch ($prChoice) {
    "1" {
        $prUrl = "https://github.com/microsoft/vscode/pull/200000"
        Write-Host "Selected: VS Code PR" -ForegroundColor Green
    }
    "2" {
        $prUrl = "https://github.com/facebook/react/pull/25000"
        Write-Host "Selected: React PR" -ForegroundColor Green
    }
    "3" {
        $prUrl = Read-Host "Enter GitHub PR URL"
        Write-Host "Selected: Custom PR" -ForegroundColor Green
    }
    default {
        Write-Host "Invalid choice. Using default VS Code PR" -ForegroundColor Yellow
        $prUrl = "https://github.com/microsoft/vscode/pull/200000"
    }
}

Write-Host ""
Write-Host "Running PR Review Agent..." -ForegroundColor Cyan
Write-Host ""

# Run the agent
python pr_review_agent.py $prUrl

Write-Host ""
Write-Host "================================" -ForegroundColor Cyan
Write-Host "Review Complete!" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Try more PRs with:" -ForegroundColor Yellow
Write-Host "  python pr_review_agent.py <PR_URL>" -ForegroundColor White
Write-Host ""
Write-Host "For private repos, set GITHUB_TOKEN:" -ForegroundColor Yellow
Write-Host "  `$env:GITHUB_TOKEN=`"your_token`"" -ForegroundColor White
Write-Host ""
