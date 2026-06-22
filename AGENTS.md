# AGENTS.md

This file provides guidance to AI agents when working with code in this repository.

## Overview

WordPress for iOS is the official mobile app for WordPress that lets users create, manage, and publish content to their WordPress websites directly from their iPhone or iPad.

Minimum requires iOS version is iOS 17. The latest iOS version is iOS 26.

## Bootstrap

To prepare a fresh clone or worktree to build the app, run:

```sh
rake dependencies
```

This is the canonical entry point for getting the repo ready to build.

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

## Xcode Schemes
- `WordPress` builds the WordPress iOS app and runs `WordPressUnitTests.xctestplan` — default for builds and the full unit test suite. Use this scheme to run unit tests.
- `Jetpack` builds the Jetpack iOS app — switch to it for Jetpack-only work.

## Simulator Sign-In

To automatically sign in to the app on an iOS simulator, see @docs/simulator-sign-in.md.

## Libraries

### wordpress-rs

The `wordpress-rs` Swift package provides the `WordPressAPI` and `WordPressAPIInternal` modules and includes an xcframework target. Builds occasionally fail with an error like:

> File '/path/to/libwordpressFFI/wp_api_uniffi.h' has been modified since the module file '/path/to/libwordpressFFI-[random].pcm' was built.

To recover, delete all `*.pcm` files in the directory reported by the error and rebuild.

## Coding Standards
- Before writing code, read and follow the [best practice guidelines](./docs/best-practices.md).
- Follow Swift API Design Guidelines
- Use strict access control modifiers where possible
- Use four spaces (not tabs)
- Lines should not have trailing whitespace
- Follow the standard formatting practices enforced by SwiftLint
- Don't create `body` for `View` that are too long
- Use semantics text sizes like `.headline`
- Use swift-log (see the `WordPress/Classes/System/Logging.swift` file) instead of CocoaLumberjack (`DDLogError`, etc)

## Core Data Concurrency

Don't capture an `NSManagedObject` (e.g. `Blog`, `WPAccount`) across threads — touching its properties off its context's queue violates Core Data's concurrency model.

Store a `TaggedManagedObjectID<Model>` instead, inject a `CoreDataStack` (typically `ContextManager.shared`), and resolve the object inside `coreDataStack.performQuery { context in ... }` (or `performAndSave` for writes):

```swift
try await coreDataStack.performQuery { [blogID] context in
    let blog = try context.existingObject(with: blogID)
    return blog.someValue  // return value types, not the managed object
}
```

## Development Workflow
- Branch from `trunk` (main branch)
- PR target should be `trunk`
- When writing commit messages, never include references to Claude
