import os
import sys
import json
import urllib.request
import urllib.error
import subprocess

CONTRIBUTORS_FILE = "CONTRIBUTORS.md"
START_MARKER = "<!-- CONTRIBUTORS_START -->"
END_MARKER = "<!-- CONTRIBUTORS_END -->"
PROJECT_LEAD = "sachinthankachan"

def fetch_github_contributors(repo, token):
    url = f"https://api.github.com/repos/{repo}/contributors?per_page=100"
    headers = {
        "Accept": "application/vnd.github.v3+json",
        "User-Agent": "MSDFAtlasStudio-ContributorsUpdater"
    }
    if token:
        headers["Authorization"] = f"Bearer {token}"
    
    req = urllib.request.Request(url, headers=headers)
    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            if resp.status == 200:
                data = json.loads(resp.read().decode("utf-8"))
                return data
    except Exception as e:
        print(f"GitHub API error: {e}", file=sys.stderr)
    return None

def fetch_git_contributors():
    try:
        res = subprocess.run(
            ["git", "log", "--format=%aN|%aE"],
            capture_output=True,
            text=True,
            check=True
        )
        lines = res.stdout.strip().split("\n")
        authors = set()
        for line in lines:
            if not line:
                continue
            parts = line.split("|")
            name = parts[0].strip()
            if name and not name.lower().endswith("[bot]"):
                authors.add(name)
        return list(authors)
    except Exception as e:
        print(f"git log error: {e}", file=sys.stderr)
    return []

def generate_markdown(contributors):
    if not contributors:
        return "* *(Contributions made via GitHub Pull Requests will be credited here)*"

    if isinstance(contributors[0], dict):
        filtered = [
            c for c in contributors
            if c.get("type") != "Bot"
            and not c.get("login", "").lower().endswith("[bot]")
            and c.get("login", "").lower() != PROJECT_LEAD.lower()
        ]
        if not filtered:
            return "* *(Contributions made via GitHub Pull Requests will be credited here)*"

        cols = 6
        lines = []
        lines.append("<table>")
        for i in range(0, len(filtered), cols):
            lines.append("  <tr>")
            chunk = filtered[i:i + cols]
            for c in chunk:
                login = c.get("login", "")
                avatar = c.get("avatar_url", f"https://github.com/{login}.png?size=80")
                html_url = c.get("html_url", f"https://github.com/{login}")
                commits = c.get("contributions", 1)
                lines.append(f'    <td align="center" valign="top" width="16%">')
                lines.append(f'      <a href="{html_url}">')
                lines.append(f'        <img src="{avatar}" width="80px;" alt="{login}"/><br />')
                lines.append(f'        <sub><b>{login}</b></sub>')
                lines.append(f'      </a><br />')
                lines.append(f'      <sub>{commits} commit{"s" if commits > 1 else ""}</sub>')
                lines.append(f'    </td>')
            lines.append("  </tr>")
        lines.append("</table>")
        return "\n".join(lines)
    else:
        filtered = [
            name for name in contributors
            if "sachin" not in name.lower() and not name.lower().endswith("[bot]")
        ]
        if not filtered:
            return "* *(Contributions made via GitHub Pull Requests will be credited here)*"
        return "\n".join([f"* **{name}**" for name in sorted(filtered)])

def main():
    repo = os.environ.get("GITHUB_REPOSITORY", "sachinthankachan/msdf-atlas-studio")
    token = os.environ.get("GITHUB_TOKEN", "")

    if not os.path.exists(CONTRIBUTORS_FILE):
        print(f"Error: {CONTRIBUTORS_FILE} not found", file=sys.stderr)
        sys.exit(1)

    with open(CONTRIBUTORS_FILE, "r", encoding="utf-8") as f:
        content = f.read()

    if START_MARKER not in content or END_MARKER not in content:
        print("Markers not found in CONTRIBUTORS.md", file=sys.stderr)
        sys.exit(1)

    gh_contributors = fetch_github_contributors(repo, token)
    if gh_contributors is not None:
        md_section = generate_markdown(gh_contributors)
    else:
        git_authors = fetch_git_contributors()
        md_section = generate_markdown(git_authors)

    before = content.split(START_MARKER)[0]
    after = content.split(END_MARKER)[1]

    new_content = before + START_MARKER + "\n\n" + md_section + "\n\n" + END_MARKER + after

    if new_content != content:
        with open(CONTRIBUTORS_FILE, "w", encoding="utf-8") as f:
            f.write(new_content)
        print("Updated CONTRIBUTORS.md successfully.")
    else:
        print("CONTRIBUTORS.md is already up to date.")

if __name__ == "__main__":
    main()
