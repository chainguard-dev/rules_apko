# Apko Update Scripts

This directory contains scripts for managing apko dependency updates.

## Scripts

### `mirror_apko.sh`
Script for mirroring apko releases with rollback capability, and optional PR creation.

**Usage:**
```bash
# Update without creating PR
./scripts/mirror_apko.sh [repository] [tool]

# Update and create PR (requires gh CLI)
./scripts/mirror_apko.sh chainguard-dev/apko apko true
```

## Automation

### GitHub Actions Workflow
The `.github/workflows/update-apko.yml` workflow runs daily at 10:00 UTC to:

1. Check for new apko releases
2. Compare with current version
3. Run the mirror script if update is needed
4. Create PR with update
5. Run basic validation tests

**Manual trigger:**
```bash
# Trigger via GitHub CLI
gh workflow run update-apko.yml

# Trigger with force update
gh workflow run update-apko.yml -f force_update=true
```

**Workflow features:**
- **Smart PR management**: Automatically closes outdated PRs when newer versions are available
- **Version comparison**: Uses semantic versioning to determine if updates are needed
- **Prevents duplicates**: Won't create PR if exact version already exists
- **Seamless transitions**: Closes old PRs with explanatory comments before creating new ones
- **Detailed summaries**: Provides comprehensive workflow output with action details
- **Validation**: Runs basic tests after updates to ensure correctness

### PR Management Logic

The workflow implements intelligent PR management to ensure only current version updates remain open:

**Decision Matrix:**
| Scenario | Existing PR | Latest Version | Action | Result |
|----------|-------------|----------------|--------|---------|
| No PRs | None | v0.29.9 | Create | New PR created |
| Exact match | v0.29.9 | v0.29.9 | Skip | Comment on existing PR |
| Outdated PR | v0.29.8 | v0.29.9 | Close & Create | Close old, create new |
| Newer PR exists | v0.30.0 | v0.29.9 | Skip | No action (existing is newer) |

**Process:**
1. **Detection**: Searches for existing apko update PRs using title pattern matching
2. **Version extraction**: Uses regex to extract version from PR titles
3. **Comparison**: Employs semantic versioning (`sort -V`) to compare versions
4. **Action**: Based on comparison, decides to skip, create, or close-and-create
5. **Cleanup**: Automatically closes outdated PRs with explanatory comments

## Supporting Files

### `filter_apko.jq`
JSON transformation filter that processes GitHub Releases API data into the structure needed for Bazel version files.

**Purpose:**
- Transforms GitHub API JSON response into structured version data
- Filters out non-tarball assets (keeps only `.tar.gz` files)
- Extracts platform identifiers from filenames
- Creates nested JSON with version keys and platform mappings

**Input Example:**
```json
[{
  "tag_name": "v0.29.9",
  "assets": [{
    "name": "apko_0.29.9_darwin_amd64.tar.gz",
    "browser_download_url": "https://github.com/chainguard-dev/apko/releases/download/v0.29.9/apko_0.29.9_darwin_amd64.tar.gz"
  }]
}]
```

**Output Example:**
```json
{
  "v0.29.9": {
    "darwin_amd64": "apko_0.29.9_darwin_amd64.tar.gz",
    "linux_amd64": "apko_0.29.9_linux_amd64.tar.gz"
  }
}
```

**Integration:**
The mirror script uses this filter with `jq -f filter_apko.jq` to process GitHub API responses, then replaces the filenames with SHA256 integrity hashes from the checksums.txt file.

## Edge Cases Handled

1. **Network failures**: Retry with exponential backoff for API calls and downloads
2. **Missing checksums**: Skip release with warning if checksums.txt is unavailable
3. **Git conflicts**: Clean working directory validation before PR creation
4. **Invalid JSON**: Validation of GitHub API responses before processing
5. **Multiple open PRs**: Smart detection and consolidation of apko update PRs
6. **Version rollbacks**: Handles cases where existing PR has newer version than latest release
7. **Malformed PR titles**: Graceful fallback when version extraction fails from PR titles
8. **CI failures**: Basic validation tests run after updates in workflow
9. **Rate limiting**: Uses built-in GitHub CLI retry mechanisms for API calls
10. **Concurrent runs**: Workflow design prevents race conditions between scheduled runs

## Requirements

- `jq` - JSON processing
- `xxd` - Binary data processing  
- `curl` - HTTP requests
- `gh` (optional) - GitHub CLI for PR creation
- Git repository with clean working directory

## Security

The scripts validate all external data and use secure practices:
- No execution of downloaded code
- Validation of JSON structure before processing
- Secure handling of git operations
- Read-only API access (no authentication required for public repos)
- Proper quoting and escaping of shell variables
