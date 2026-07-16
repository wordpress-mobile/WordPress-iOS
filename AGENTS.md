# AGENTS.md

This file provides guidance to AI agents when working with code in this repository.

## Overview

This repository builds the WordPress and Jetpack apps for iOS.

WordPress for iOS is the official WordPress mobile app. It lets users create, manage, and publish content on their WordPress sites from an iPhone or iPad. Jetpack for iOS includes those capabilities along with Jetpack and WordPress.com features.

Minimum requires iOS version is iOS 17. The latest iOS version is iOS 26.

## Bootstrap

Prepare a fresh clone or worktree for building with `rake dependencies`, the repository's canonical bootstrap command.

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
- Use Swift Testing for new tests.
- The WordPress scheme uses `WordPressUnitTests.xctestplan` for the full unit test suite, including tests in the `Modules` Swift package.
- Add every unit test target to `WordPressUnitTests.xctestplan`.
- Run the full suite with `xcodebuild -workspace WordPress.xcworkspace -scheme WordPress -testPlan WordPressUnitTests test`. Do not use `swift test`.
- To verify changes end-to-end on an iOS simulator, follow @docs/simulator-sign-in.md to sign in to the app.

### Important Considerations
- **Multi-site Support**: Code must handle both WordPress.com and self-hosted sites
- **Accessibility**: Use proper accessibility labels and traits
- **Localization**: follow best practices from @docs/localization.md. For how strings flow through GlotPress and the AI translation tier (the `human ?? AI ?? English` floor), see @docs/localization-pipeline.md.

## Libraries

### wordpress-rs

The `wordpress-rs` Swift package provides the `WordPressAPI` and `WordPressAPIInternal` modules and includes an xcframework target. Builds occasionally fail with an error like:

> File '/path/to/libwordpressFFI/wp_api_uniffi.h' has been modified since the module file '/path/to/libwordpressFFI-[random].pcm' was built.

To recover, delete all `*.pcm` files in the directory reported by the error and rebuild.

## Coding Standards
- Before writing code, read and follow the [best practice guidelines](./docs/best-practices.md).
- Follow Swift API Design Guidelines
- Use strict access control modifiers where possible
- Follow the standard formatting practices enforced by SwiftLint
- swift-format and SwiftLint can occasionally disagree. Make sure the final code is stable under `xcrun swift format --in-place <path>` and also passes `rake lint[<path>]`. Use `swiftlint:disable` directives as the last resort to solve the conflicts.
- Don't create `body` for `View` that are too long
- Use semantics text sizes like `.headline`
- Use swift-log (see the `WordPress/Classes/System/Logging.swift` file) instead of CocoaLumberjack (`DDLogError`, etc)

## Development Workflow
- Branch from `trunk` (main branch)
- PR target should be `trunk`
- When writing commit messages, never include references to Claude
