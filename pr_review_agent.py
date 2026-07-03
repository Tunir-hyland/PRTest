#!/usr/bin/env python3
"""
GitHub Pull Request Review Agent

Analyzes GitHub PRs to provide:
- Summary of changes
- Bug detection
- Improvement suggestions
- Release notes
- TODO detection
- Large method flagging
- Duplicate code detection
"""

import re
import sys
import json
import argparse
from typing import Dict, List, Tuple, Set
from urllib.request import Request, urlopen
from urllib.error import URLError, HTTPError


class PRReviewAgent:
    def __init__(self, github_token: str = None):
        self.token = github_token
        self.headers = {
            'Accept': 'application/vnd.github.v3+json',
            'User-Agent': 'PR-Review-Agent'
        }
        if self.token:
            self.headers['Authorization'] = f'token {self.token}'
    
    def _make_request(self, url: str) -> dict:
        """Make a GitHub API request"""
        try:
            req = Request(url, headers=self.headers)
            with urlopen(req) as response:
                return json.loads(response.read().decode())
        except HTTPError as e:
            if e.code == 401:
                print("⚠️  Authentication failed. Set GITHUB_TOKEN environment variable for private repos.")
            elif e.code == 404:
                print("⚠️  PR not found. Check the URL.")
            else:
                print(f"⚠️  HTTP Error {e.code}: {e.reason}")
            sys.exit(1)
        except URLError as e:
            print(f"⚠️  Network error: {e.reason}")
            sys.exit(1)
    
    def parse_pr_url(self, pr_url: str) -> Tuple[str, str, int]:
        """Extract owner, repo, and PR number from URL"""
        pattern = r'github\.com/([^/]+)/([^/]+)/pull/(\d+)'
        match = re.search(pattern, pr_url)
        if not match:
            raise ValueError("Invalid GitHub PR URL format")
        return match.group(1), match.group(2), int(match.group(3))
    
    def get_pr_info(self, owner: str, repo: str, pr_number: int) -> dict:
        """Fetch PR information from GitHub API"""
        url = f'https://api.github.com/repos/{owner}/{repo}/pulls/{pr_number}'
        return self._make_request(url)
    
    def get_pr_files(self, owner: str, repo: str, pr_number: int) -> List[dict]:
        """Fetch files changed in the PR"""
        url = f'https://api.github.com/repos/{owner}/{repo}/pulls/{pr_number}/files'
        return self._make_request(url)
    
    def get_pr_commits(self, owner: str, repo: str, pr_number: int) -> List[dict]:
        """Fetch commits in the PR"""
        url = f'https://api.github.com/repos/{owner}/{repo}/pulls/{pr_number}/commits'
        return self._make_request(url)
    
    def analyze_file_changes(self, files: List[dict]) -> Dict:
        """Analyze the changed files"""
        analysis = {
            'total_files': len(files),
            'additions': sum(f.get('additions', 0) for f in files),
            'deletions': sum(f.get('deletions', 0) for f in files),
            'file_types': {},
            'large_changes': []
        }
        
        for file in files:
            # Count file types
            filename = file.get('filename', '')
            ext = filename.split('.')[-1] if '.' in filename else 'no_extension'
            analysis['file_types'][ext] = analysis['file_types'].get(ext, 0) + 1
            
            # Flag large files
            changes = file.get('changes', 0)
            if changes > 200:
                analysis['large_changes'].append({
                    'filename': filename,
                    'changes': changes
                })
        
        return analysis
    
    def detect_bugs(self, files: List[dict]) -> List[Dict]:
        """Detect potential bugs in the code changes"""
        bugs = []
        
        bug_patterns = [
            (r'console\.log\(', 'Debug console.log found', 'info'),
            (r'debugger;', 'Debugger statement found', 'warning'),
            (r'TODO|FIXME|XXX', 'TODO/FIXME comment found', 'info'),
            (r'==\s*null', 'Use === instead of ==', 'warning'),
            (r'var\s+\w+', 'Use let/const instead of var', 'info'),
            (r'catch\s*\([^)]*\)\s*\{\s*\}', 'Empty catch block', 'warning'),
            (r'if\s*\([^)]*=\s*[^=]', 'Assignment in if condition', 'critical'),
            (r'return\s+await\s+', 'Unnecessary return await', 'info'),
            (r'password\s*=\s*["\'].*["\']', 'Hardcoded password detected', 'critical'),
            (r'api[_-]?key\s*=\s*["\'].*["\']', 'Hardcoded API key detected', 'critical'),
        ]
        
        for file in files:
            patch = file.get('patch', '')
            filename = file.get('filename', '')
            
            if not patch:
                continue
            
            # Analyze only added lines
            added_lines = [line for line in patch.split('\n') if line.startswith('+') and not line.startswith('+++')]
            
            for line_num, line in enumerate(added_lines, 1):
                for pattern, message, severity in bug_patterns:
                    if re.search(pattern, line, re.IGNORECASE):
                        bugs.append({
                            'file': filename,
                            'line': line_num,
                            'severity': severity,
                            'message': message,
                            'code': line[:100]
                        })
        
        return bugs
    
    def suggest_improvements(self, files: List[dict]) -> List[Dict]:
        """Suggest code improvements"""
        suggestions = []
        
        improvement_patterns = [
            (r'function\s+\w+\s*\([^)]*\)\s*\{[^}]{500,}', 'Consider breaking down large function', 'Large function'),
            (r'if\s*\([^)]*\&\&[^)]*\&\&[^)]*\)', 'Complex condition - consider extracting to variable', 'Complex logic'),
            (r'\.then\(.*\.then\(.*\.then\(', 'Chain of promises - consider async/await', 'Code style'),
            (r'for\s*\(.*\.length', 'Consider using forEach, map, or for...of', 'Modern syntax'),
        ]
        
        for file in files:
            patch = file.get('patch', '')
            filename = file.get('filename', '')
            
            if not patch:
                continue
            
            for pattern, message, category in improvement_patterns:
                matches = re.finditer(pattern, patch, re.DOTALL)
                for match in matches:
                    suggestions.append({
                        'file': filename,
                        'category': category,
                        'suggestion': message
                    })
        
        return suggestions
    
    def check_todos(self, files: List[dict]) -> List[Dict]:
        """Find TODO comments in the changes"""
        todos = []
        
        todo_pattern = r'(TODO|FIXME|XXX|HACK|NOTE):\s*(.+)'
        
        for file in files:
            patch = file.get('patch', '')
            filename = file.get('filename', '')
            
            if not patch:
                continue
            
            added_lines = [line for line in patch.split('\n') if line.startswith('+') and not line.startswith('+++')]
            
            for line_num, line in enumerate(added_lines, 1):
                match = re.search(todo_pattern, line, re.IGNORECASE)
                if match:
                    todos.append({
                        'file': filename,
                        'line': line_num,
                        'type': match.group(1).upper(),
                        'message': match.group(2).strip()
                    })
        
        return todos
    
    def flag_large_methods(self, files: List[dict], threshold: int = 50) -> List[Dict]:
        """Flag methods that are too large"""
        large_methods = []
        
        for file in files:
            patch = file.get('patch', '')
            filename = file.get('filename', '')
            
            if not patch:
                continue
            
            # Simple heuristic: count lines between function definition and closing brace
            # This is a basic implementation - more sophisticated parsing would be better
            function_patterns = [
                r'(function\s+\w+|const\s+\w+\s*=\s*(?:async\s+)?\([^)]*\)\s*=>|\w+\s*\([^)]*\)\s*\{)',
                r'(def\s+\w+\([^)]*\):)',  # Python
                r'(public|private|protected)?\s*\w+\s+\w+\([^)]*\)\s*\{',  # Java/C#
            ]
            
            for pattern in function_patterns:
                matches = re.finditer(pattern, patch)
                for match in matches:
                    # Count lines after match
                    start_pos = match.end()
                    remaining = patch[start_pos:]
                    lines_count = len([l for l in remaining.split('\n')[:threshold+10] if l.strip()])
                    
                    if lines_count > threshold:
                        large_methods.append({
                            'file': filename,
                            'method': match.group(0)[:50],
                            'estimated_lines': lines_count
                        })
        
        return large_methods
    
    def detect_duplicated_code(self, files: List[dict], min_lines: int = 5) -> List[Dict]:
        """Detect potential code duplication"""
        duplicates = []
        code_blocks = {}
        
        for file in files:
            patch = file.get('patch', '')
            filename = file.get('filename', '')
            
            if not patch:
                continue
            
            # Extract added code blocks
            added_lines = [line[1:].strip() for line in patch.split('\n') 
                          if line.startswith('+') and not line.startswith('+++') and line.strip()]
            
            # Look for repeated blocks of min_lines
            for i in range(len(added_lines) - min_lines + 1):
                block = '\n'.join(added_lines[i:i+min_lines])
                # Skip very short or generic blocks
                if len(block) < 50 or block.count('{') > 3:
                    continue
                
                if block in code_blocks:
                    duplicates.append({
                        'block': block[:100] + '...',
                        'locations': [code_blocks[block], filename]
                    })
                else:
                    code_blocks[block] = filename
        
        return duplicates
    
    def generate_release_notes(self, pr_info: dict, files: List[dict], analysis: Dict) -> str:
        """Generate release notes from the PR"""
        notes = []
        
        title = pr_info.get('title', 'No title')
        body = pr_info.get('body', '')
        labels = [label['name'] for label in pr_info.get('labels', [])]
        
        # Categorize changes
        features = []
        fixes = []
        refactors = []
        docs = []
        
        # Parse from PR body or labels
        if any(label in ['feature', 'enhancement'] for label in labels):
            features.append(title)
        elif any(label in ['bug', 'fix'] for label in labels):
            fixes.append(title)
        elif any(label in ['refactor', 'improvement'] for label in labels):
            refactors.append(title)
        elif any(label in ['documentation', 'docs'] for label in labels):
            docs.append(title)
        else:
            # Default categorization based on file types
            if any(f.get('filename', '').endswith('.md') for f in files):
                docs.append(title)
            else:
                features.append(title)
        
        # Build release notes
        notes.append(f"### {title}\n")
        
        if features:
            notes.append("**Features:**")
            for f in features:
                notes.append(f"- {f}")
        
        if fixes:
            notes.append("\n**Bug Fixes:**")
            for fix in fixes:
                notes.append(f"- {fix}")
        
        if refactors:
            notes.append("\n**Improvements:**")
            for r in refactors:
                notes.append(f"- {r}")
        
        if docs:
            notes.append("\n**Documentation:**")
            for d in docs:
                notes.append(f"- {d}")
        
        notes.append(f"\n**Changed Files:** {analysis['total_files']}")
        notes.append(f"**Lines Added:** {analysis['additions']}")
        notes.append(f"**Lines Removed:** {analysis['deletions']}")
        
        return '\n'.join(notes)
    
    def print_report(self, pr_url: str):
        """Generate and print complete review report"""
        print("=" * 80)
        print("🔍 GitHub Pull Request Review Agent")
        print("=" * 80)
        print()
        
        # Parse URL and fetch data
        owner, repo, pr_number = self.parse_pr_url(pr_url)
        print(f"📋 Analyzing: {owner}/{repo} PR #{pr_number}")
        print()
        
        pr_info = self.get_pr_info(owner, repo, pr_number)
        files = self.get_pr_files(owner, repo, pr_number)
        
        # Analysis
        analysis = self.analyze_file_changes(files)
        
        # 1. Summary
        print("📊 SUMMARY")
        print("-" * 80)
        print(f"Title: {pr_info.get('title')}")
        print(f"Author: {pr_info.get('user', {}).get('login')}")
        print(f"State: {pr_info.get('state')}")
        print(f"Files Changed: {analysis['total_files']}")
        print(f"Lines Added: +{analysis['additions']}")
        print(f"Lines Removed: -{analysis['deletions']}")
        print(f"\nFile Types:")
        for ext, count in sorted(analysis['file_types'].items(), key=lambda x: x[1], reverse=True):
            print(f"  {ext}: {count}")
        print()
        
        # 2. Potential Bugs
        print("🐛 POTENTIAL BUGS")
        print("-" * 80)
        bugs = self.detect_bugs(files)
        if bugs:
            critical = [b for b in bugs if b['severity'] == 'critical']
            warnings = [b for b in bugs if b['severity'] == 'warning']
            info = [b for b in bugs if b['severity'] == 'info']
            
            if critical:
                print(f"❌ Critical ({len(critical)}):")
                for bug in critical:
                    print(f"  - {bug['file']}: {bug['message']}")
                    print(f"    {bug['code'].strip()}")
            
            if warnings:
                print(f"\n⚠️  Warnings ({len(warnings)}):")
                for bug in warnings[:5]:  # Limit output
                    print(f"  - {bug['file']}: {bug['message']}")
            
            if info:
                print(f"\nℹ️  Info ({len(info)}):")
                for bug in info[:5]:  # Limit output
                    print(f"  - {bug['file']}: {bug['message']}")
        else:
            print("✅ No obvious bugs detected!")
        print()
        
        # 3. Improvement Suggestions
        print("💡 IMPROVEMENT SUGGESTIONS")
        print("-" * 80)
        suggestions = self.suggest_improvements(files)
        if suggestions:
            by_category = {}
            for s in suggestions:
                cat = s['category']
                by_category.setdefault(cat, []).append(s)
            
            for category, items in by_category.items():
                print(f"\n{category} ({len(items)}):")
                for item in items[:3]:  # Limit output
                    print(f"  - {item['file']}: {item['suggestion']}")
        else:
            print("✅ Code looks good!")
        print()
        
        # 4. TODOs
        print("📝 TODOs & NOTES")
        print("-" * 80)
        todos = self.check_todos(files)
        if todos:
            for todo in todos:
                print(f"  [{todo['type']}] {todo['file']}: {todo['message']}")
        else:
            print("✅ No TODOs found")
        print()
        
        # 5. Large Methods
        print("📏 LARGE METHODS")
        print("-" * 80)
        large_methods = self.flag_large_methods(files)
        if large_methods:
            for method in large_methods:
                print(f"  - {method['file']}: ~{method['estimated_lines']} lines")
                print(f"    {method['method']}")
        else:
            print("✅ No large methods detected")
        print()
        
        # 6. Duplicated Code
        print("🔄 DUPLICATED CODE")
        print("-" * 80)
        duplicates = self.detect_duplicated_code(files)
        if duplicates:
            for dup in duplicates[:5]:  # Limit output
                print(f"  Found in: {', '.join(dup['locations'])}")
                print(f"  {dup['block']}\n")
        else:
            print("✅ No obvious duplication detected")
        print()
        
        # 7. Release Notes
        print("📰 RELEASE NOTES")
        print("-" * 80)
        release_notes = self.generate_release_notes(pr_info, files, analysis)
        print(release_notes)
        print()
        
        # 8. Large Changes Warning
        if analysis['large_changes']:
            print("⚠️  LARGE CHANGES DETECTED")
            print("-" * 80)
            for change in analysis['large_changes']:
                print(f"  - {change['filename']}: {change['changes']} changes")
            print()
        
        print("=" * 80)
        print("✨ Review Complete!")
        print("=" * 80)


def main():
    parser = argparse.ArgumentParser(
        description='GitHub Pull Request Review Agent',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python pr_review_agent.py https://github.com/owner/repo/pull/123
  
  # With GitHub token for private repos:
  set GITHUB_TOKEN=your_token_here
  python pr_review_agent.py https://github.com/owner/repo/pull/123
        """
    )
    parser.add_argument('pr_url', help='GitHub Pull Request URL')
    parser.add_argument('--token', help='GitHub Personal Access Token (or set GITHUB_TOKEN env var)')
    
    args = parser.parse_args()
    
    # Get token from args or environment
    import os
    token = args.token or os.environ.get('GITHUB_TOKEN')
    
    agent = PRReviewAgent(github_token=token)
    
    try:
        agent.print_report(args.pr_url)
    except ValueError as e:
        print(f"❌ Error: {e}")
        sys.exit(1)
    except KeyboardInterrupt:
        print("\n\n⚠️  Review interrupted by user")
        sys.exit(0)


if __name__ == '__main__':
    main()
