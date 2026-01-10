# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Curated "awesome list" of freelancer recruitment and placement websites in Germany. Content-only repository with automated link checking.

## Commands

### Link Checking (lychee)

```bash
# Run link check locally (requires lychee installed)
lychee --config lychee.toml **/*.md

# Install lychee
brew install lychee
```

Link check runs automatically on push/PR and daily at 03:00 UTC via GitHub Actions.

### Configuration

- `lychee.toml` - Link checker config (exclusions, redirect handling)
- Excludes domains with SSL/bot issues (malt.de, projekt-broker.com)
- Accepts 301/302 redirects as valid

## Content Structure

`readme.md` contains all listings organized by:
1. **Top 10 by market share** - Based on Lünendonk-Studie
2. **More recruiters** - Alphabetical, tagged with 🧭 Recruiter
3. **Portals (DACH-focused)** - Tagged with 🛒 Portal
4. **International portals**
5. **Uncategorized** - Tagged with ❓ Misc

## Maintenance Notes

- When a site redirects permanently to another already-listed site, remove the redundant entry
- Check if redirect targets are already in the list before adding notes like "(now X)"
