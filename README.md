# GitHub Pull Request Review Agent

A comprehensive Python tool for analyzing GitHub Pull Requests to provide automated code reviews, bug detection, and release notes generation.

## Features

### Core Features ✅
- **Accept PR URL**: Works with any public GitHub Pull Request URL
- **Read Changed Files**: Fetches and analyzes all files modified in the PR
- **Summarize Changes**: Provides statistics on additions, deletions, file types, and more
- **Find Possible Bugs**: Detects common issues like:
  - Debug statements (`console.log`, `debugger`)
  - Hardcoded credentials (passwords, API keys)
  - Empty catch blocks
  - Assignment in conditionals
  - Incorrect equality operators
- **Suggest Improvements**: Recommends better practices for:
  - Large functions
  - Complex conditions
  - Promise chains (suggest async/await)
  - Loop modernization
- **Generate Release Notes**: Creates formatted release notes with categorization

### Stretch Goals ✅
- **Check for TODOs**: Finds and lists all TODO, FIXME, XXX, HACK, and NOTE comments
- **Flag Large Methods**: Identifies methods that exceed size thresholds
- **Detect Duplicated Code**: Finds potential code duplication across changed files

## Installation

No external dependencies required! Uses only Python standard library.

```bash
# Clone or copy the pr_review_agent.py file
# Run directly with Python 3.6+
```

## Usage

### Basic Usage (Public Repositories)

```bash
python pr_review_agent.py https://github.com/owner/repo/pull/123
```

### With Authentication (Private Repositories)

For private repositories, you'll need a GitHub Personal Access Token:

1. Create a token at: https://github.com/settings/tokens
2. Select scope: `repo` (for private repos) or `public_repo` (for public repos only)

**Option 1: Environment Variable (Recommended)**
```bash
# Windows PowerShell
$env:GITHUB_TOKEN="your_token_here"
python pr_review_agent.py https://github.com/owner/repo/pull/123

# Windows Command Prompt
set GITHUB_TOKEN=your_token_here
python pr_review_agent.py https://github.com/owner/repo/pull/123

# Linux/Mac
export GITHUB_TOKEN=your_token_here
python pr_review_agent.py https://github.com/owner/repo/pull/123
```

**Option 2: Command Line Argument**
```bash
python pr_review_agent.py https://github.com/owner/repo/pull/123 --token your_token_here
```

## Example Output

```
================================================================================
🔍 GitHub Pull Request Review Agent
================================================================================

📋 Analyzing: microsoft/vscode PR #123456

📊 SUMMARY
--------------------------------------------------------------------------------
Title: Add new feature for code navigation
Author: developer123
State: open
Files Changed: 8
Lines Added: +245
Lines Removed: -67

File Types:
  ts: 6
  json: 1
  md: 1

🐛 POTENTIAL BUGS
--------------------------------------------------------------------------------
❌ Critical (1):
  - src/auth.ts: Hardcoded API key detected
    + const apiKey = "sk-1234567890";

⚠️  Warnings (2):
  - src/logger.ts: Debug console.log found
  - src/handler.ts: Empty catch block

💡 IMPROVEMENT SUGGESTIONS
--------------------------------------------------------------------------------

Large function (1):
  - src/processor.ts: Consider breaking down large function

Code style (1):
  - src/service.ts: Chain of promises - consider async/await

📝 TODOs & NOTES
--------------------------------------------------------------------------------
  [TODO] src/feature.ts: Implement error handling for edge cases
  [FIXME] src/utils.ts: Optimize this algorithm

📏 LARGE METHODS
--------------------------------------------------------------------------------
  - src/processor.ts: ~67 lines
    function processData(input) {

🔄 DUPLICATED CODE
--------------------------------------------------------------------------------
✅ No obvious duplication detected

📰 RELEASE NOTES
--------------------------------------------------------------------------------
### Add new feature for code navigation

**Features:**
- Add new feature for code navigation

**Changed Files:** 8
**Lines Added:** 245
**Lines Removed:** 67

================================================================================
✨ Review Complete!
================================================================================
```

## How It Works

1. **PR URL Parsing**: Extracts owner, repository, and PR number from the URL
2. **GitHub API Calls**: Fetches PR metadata, changed files, and patches
3. **Code Analysis**: 
   - Pattern matching for common bugs and anti-patterns
   - Heuristic-based detection for code quality issues
   - Statistical analysis of code changes
4. **Report Generation**: Formats findings into a comprehensive review

## Customization

You can customize the analysis by modifying:

- **Bug Patterns**: Add/remove patterns in `detect_bugs()` method
- **Improvement Rules**: Modify `suggest_improvements()` method
- **Thresholds**: Adjust `threshold` parameter in `flag_large_methods()`
- **Duplication Detection**: Tune `min_lines` in `detect_duplicated_code()`

## Limitations

- Pattern-based detection may have false positives
- Works best with text-based diffs (no binary file analysis)
- Large method detection uses heuristics (not full AST parsing)
- Duplication detection is basic (no semantic analysis)
- Rate limited by GitHub API (60 requests/hour unauthenticated, 5000 with token)

## Future Enhancements

Potential improvements:
- AST-based analysis for more accurate bug detection
- Integration with linters (ESLint, Pylint, etc.)
- Cyclomatic complexity calculation
- Security vulnerability scanning
- Test coverage analysis
- Comparison with repository coding standards

## License

MIT License - Feel free to use and modify!

## Contributing

Suggestions and improvements welcome! Key areas for contribution:
- Additional bug detection patterns
- Language-specific analysis
- Better duplicate code detection
- Integration with CI/CD pipelines
