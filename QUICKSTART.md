# Quick Start Guide

## Test the Agent

Try it with a public PR to see it in action:

```powershell
python pr_review_agent.py https://github.com/microsoft/vscode/pull/100000
```

## What You'll Get

The agent analyzes the PR and provides:

### ✅ Core Features
1. **Summary** - Files changed, lines added/removed, file types breakdown
2. **Bug Detection** - Finds:
   - Hardcoded credentials (API keys, passwords)
   - Debug statements (console.log, debugger)
   - Empty catch blocks
   - Assignment in conditions
   - Wrong equality operators (== vs ===)
   - Unnecessary return await

3. **Improvement Suggestions** - Identifies:
   - Large functions that need refactoring
   - Complex conditions
   - Promise chains (suggests async/await)
   - Old-style loops (suggests modern syntax)

4. **Release Notes** - Auto-generated with:
   - Features, bug fixes, improvements categorization
   - Statistics on changes

### ✅ Stretch Goals
5. **TODO Detection** - Finds all TODO, FIXME, XXX, HACK comments
6. **Large Method Flagging** - Warns about methods over 50 lines
7. **Duplicate Code Detection** - Finds repeated code blocks

## Configuration Tips

### For Private Repos
```powershell
# Set your GitHub token
$env:GITHUB_TOKEN="ghp_your_token_here"
```

### Customize Analysis
Edit `pr_review_agent.py` to:
- Adjust large method threshold (default: 50 lines)
- Add custom bug patterns
- Modify duplication detection sensitivity (default: 5 lines)
- Add language-specific rules

## Typical Workflow

1. **Receive PR notification**
2. **Run the agent**: `python pr_review_agent.py <PR_URL>`
3. **Review the output**:
   - Check critical bugs first (❌)
   - Review warnings (⚠️)
   - Consider improvement suggestions (💡)
   - Review TODOs and notes (📝)
4. **Post feedback** on the PR
5. **Use release notes** for changelog

## Pro Tips

- Use the GitHub token to avoid rate limits (60 req/hour without, 5000 with token)
- For large PRs, pipe output to a file: `python pr_review_agent.py <url> > review.txt`
- Integrate into CI/CD by calling the script in your pipeline
- Customize patterns for your team's coding standards

## Troubleshooting

**"Authentication failed"**: Set `GITHUB_TOKEN` environment variable
**"PR not found"**: Check the URL format (must be github.com/owner/repo/pull/number)
**"Network error"**: Check internet connection and GitHub status

## Next Steps

Consider enhancing the agent with:
- Email notifications
- Slack/Teams integration
- Database storage of reviews
- Trend analysis across multiple PRs
- Custom rule configuration files
