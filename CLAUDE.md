# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

WordPress for iOS is the official mobile app for WordPress that lets users create, manage, and publish content to their WordPress websites directly from their iPhone or iPad.

Minimum requires iOS version is iOS 16.

## High-Level Architecture

### Project Structure
WordPress-iOS uses a modular architecture with the main app and separate Swift packages:

- **Main App**: `WordPress/Classes/` - core app functionality
- **Modules**: `Modules/Sources/` - Reusable Swift packages including:
  - `WordPressUI` - shared UI components
  - `WordPressFlux` - deprecated state management using Flux pattern (DO NOT USE)
  - `WordPressKit` - API client and networking
  - `WordPressShared` - Shared utilities
  - `DesignSystem` - design system

### Key Patterns
- **Architecture**: SwiftUI with MVVM for new features
- **ViewModels**: Use `@MainActor` class conforming to `ObservableObject` with `@Published` properties
- **Concurrency**: Swift async/await patterns with `@MainActor` for UI thread safety
- **Navigation**: SwiftUI NavigationStack
- **Persistence**: Core Data with `@FetchRequest` for SwiftUI integration
- **UI**: Progressive SwiftUI adoption using `UIHostingController` bridge pattern
- **Dependency Injection**: Constructor injection with protocol-based services

#### Testing Patterns
- Use Swift Testing for new tests

### Important Considerations
- **Multi-site Support**: Code must handle both WordPress.com and self-hosted sites
- **Accessibility**: Use proper accessibility labels and traits
- **Localization**: follow best practices from @docs/localization.md

## Coding Standards
- Follow Swift API Design Guidelines
- Use strict access control modifiers where possible
- Use four spaces (not tabs)
- Lines should not have trailing whitespace 
- Follow the standard formatting practices enforced by SwiftLint
- Don't create `body` for `View` that are too long
- Use semantics text sizes like `.headline`

## Development Workflow
- Branch from `trunk` (main branch)
- PR target should be `trunk`
- When writing commit messages, never include references to Claude

## Release Notes Compilation Process

### Overview
Process for compiling release notes for new iOS versions, maintaining the established tone without App Store character limits.

### Step-by-Step Process

#### 1. Study Previous Release Notes Style
Use `gh` to fetch releases and analyze professional editorialization patterns:
- **Version 25.9**: Raw added in commits `ce08612ecc324e981ef9c5898c98bb267cf29721` & `30cd7073802feb8711b2aae8bb69f41fedba1d80`, editorialized in `bc3af0d2c0c8c3dec8556bb4eff7709f3c151c0d`
- **Version 26.0**: Raw added in commits `8a9e79587924f85e6ac6756fe47d045f7db04ece` & `883acc3324abe45d0e121f3854dc84712b22b4cb`, editorialized in `2ef13c2898c5b58d09c8a3af9f109a47f0bd782c`

Commands: `gh release view 25.9`, `gh release view 26.0` (note: no 'v' prefix)

**Important**: GitHub releases only show WordPress release notes. For better Jetpack release notes, use:
```bash
gh api "repos/wordpress-mobile/WordPress-iOS/contents/WordPress/Jetpack/Resources/release_notes.txt?ref=<commit_hash>" --jq -r '.content' | base64 -d
```

#### 2. Verify Release Branch and Get Last Release Hash
- Verify current branch follows naming: `release/x.y` (where x.y = last_release + 0.1)
- Get commit hash for last release: `gh release view <last_version> --json tagName,targetCommitish`
- Confirm current branch is properly ahead of last release tag

#### 3. Identify Changes Since Last Release
Compare current release branch against last release hash using GitHub API (since local commits may not exist due to squashing/rebasing):
```bash
gh api repos/wordpress-mobile/WordPress-iOS/compare/<last_release_hash>...HEAD --jq '.commits[] | "\(.sha[0:7]) \(.commit.message | split("\n")[0])"'
```
Focus on user-facing changes from squash commit messages. **Important**: When commit messages are unclear or technical, always investigate further:
- Use `gh pr view <PR_number>` to read PR titles and descriptions
- Look for keywords indicating user-facing changes: "feat:", new functionality, UI changes, user experience
- Be especially careful with feature rollouts that may have technical-sounding commit messages but represent new user functionality
- When in doubt, investigate the PR rather than excluding potentially important features

#### 4. Compile Raw Release Notes
Create factual summary including:
- **Always check RELEASE-NOTES.txt file** (note: hyphen, not underscore) for developer-authored release notes under the version number section. These notes start with `[*]`, `[**]`, or `[***]` (stars indicate importance) and **must be included** in the raw release notes
- Only user-facing changes (exclude CI, refactoring, technical debt)  
- Prioritize: New features → Improvements → Performance enhancements
- Use positive language (avoid "bug fix", prefer "improved", "enhanced", "resolved")
- Mark changes as WordPress-specific, Jetpack-specific, or both

#### 5. User Confirmation
Present raw notes to user for:
- Accuracy verification
- WordPress vs Jetpack feature classification
- Any missing or incorrect changes
- Approval to proceed with editorialization

#### 6. Editorialization
Transform raw notes using established playful style:
- Use engaging, user-friendly language
- Reference previous release note styles from step 1
- Create separate versions for WordPress and Jetpack apps
- Focus on user benefits and experience improvements

#### 7. Update Release Notes Files
Once user confirms the editorialized release notes, **replace** the contents of the following files (discard any existing content):
- **WordPress release notes**: `WordPress/Resources/release_notes.txt`
- **Jetpack release notes**: `WordPress/Jetpack/Resources/release_notes.txt`

Document any process refinements discovered during execution.

### Content Guidelines
- **Include**: New features, UI improvements, performance enhancements, user experience changes
- **Exclude**: CI changes, code refactoring, dependency updates, internal technical changes
- **Language**: Positive sentiment, avoid "fix" terminology, focus on improvements and enhancements
- **Priority Order**: New features → Improvements → Performance → Other user-facing changes
