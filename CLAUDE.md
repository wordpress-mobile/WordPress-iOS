# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

WordPress for iOS is the official mobile app for WordPress that lets users create, manage, and publish content to their WordPress websites directly from their iPhone or iPad.

Minimum requires iOS version is iOS 16.

## Common Development Commands

### Build & Dependencies
- `rake build` - Build the app
- `xcodebuild -scheme <target> -destination 'platform=iOS Simulator,name=iPhone 16' | bundle exec xcpretty` build targets from `Modules/`.

### Testing
- `rake test` - Run all tests

### Code Quality
- `rake lint` - Check for SwiftLint errors

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

### Development Workflow
- Branch from `trunk` (main branch)
- PR target should be `trunk`
- When writing commit messages, never include references to Claude
