# Live PR Link Test Examples

## 🚀 Quick Install Python

### Option 1: Microsoft Store (Easiest)
1. Open Microsoft Store
2. Search for "Python 3.12"
3. Click Install

### Option 2: Direct Download
1. Go to: https://www.python.org/downloads/
2. Download Python 3.12 (or latest)
3. Run installer - **CHECK "Add Python to PATH"**
4. Restart PowerShell

---

## 🔗 Live PR Links to Test

Once Python is installed, try these **real** GitHub PRs:

### Example 1: Small PR (Good for first test)
```powershell
python pr_review_agent.py https://github.com/microsoft/vscode/pull/200000
```

### Example 2: TypeScript Project
```powershell
python pr_review_agent.py https://github.com/facebook/react/pull/25000
```

### Example 3: Python Project
```powershell
python pr_review_agent.py https://github.com/pallets/flask/pull/5000
```

### Example 4: Recent VS Code PR
```powershell
python pr_review_agent.py https://github.com/microsoft/vscode/pull/215000
```

---

## ⚡ One-Line Install & Test

Copy and paste this into PowerShell:

```powershell
# Install Python from Microsoft Store (opens store)
start ms-windows-store://pdp/?ProductId=9NRWMJP3717K

# After installing, restart PowerShell and run:
cd C:\Users\tadhikary\githubPR
python pr_review_agent.py https://github.com/microsoft/vscode/pull/200000
```

---

## 📊 What You'll See

The agent will analyze the live PR and show:
- 📊 File changes summary
- 🐛 Potential bugs found
- 💡 Code improvement suggestions  
- 📝 TODO comments
- 📏 Large methods flagged
- 🔄 Duplicate code detected
- 📰 Auto-generated release notes

---

## 🔑 For Private Repos (Optional)

```powershell
# Set your GitHub token
$env:GITHUB_TOKEN="ghp_your_token_here"

# Then run any PR
python pr_review_agent.py https://github.com/your-org/private-repo/pull/123
```

Get token at: https://github.com/settings/tokens

---

## ✅ Quick Verification After Installing Python

```powershell
# Check Python installed correctly
python --version

# Should show: Python 3.x.x

# Test the agent
python pr_review_agent.py --help

# Should show: GitHub Pull Request Review Agent help
```
