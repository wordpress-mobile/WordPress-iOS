# Best Practices

## Coding Style Guide

We like to have a consistent coding style in the WordPress for iOS app, and to help us achieve this we’ve drafted a [style guide](coding-style-guide.md) outlining preferred code formatting and language idioms.

It’s a good idea to check the style guide from time to time as we update it to account for new improvements in the Swift language or in the iOS SDK.

## Use the Core Data Stack APIs

WordPress for iOS wraps Core Data access in `CoreDataStack`, `CoreDataStackSwift`, and `ContextManager`. New code should use these project APIs instead of creating, storing, or saving raw `NSManagedObjectContext` instances. The wrappers centralize background contexts, save behavior, merge policy, permanent object ID handling, and save error reporting.

Use these APIs by default:

- Inject `CoreDataStackSwift` into new Swift services, repositories, and view models. Default the dependency to `ContextManager.shared` at the composition boundary.
- Use `CoreDataStack` when a type must remain Objective-C-compatible.
- Use `ContextManager.shared` directly only at composition boundaries, in legacy code, or in small UI integration points where dependency injection would add noise.
- Do not call `newDerivedContext()` in new code. It is deprecated and exists for legacy callers. Use `performQuery` or `performAndSave` instead.
- Do not create `NSManagedObjectContext` manually for app data. If a test needs an isolated store, use the project testing helpers for `ContextManager`.

### Reading Core Data

Prefer `performQuery` for Core Data reads outside UI-bound objects such as fetched-results controllers, SwiftUI fetch requests, and main-context view state.

```swift
let siteName = coreDataStack.performQuery { context in
    try? Blog.lookup(withID: siteID, in: context)?.settings?.name
}
```

Return plain values, value types, identifiers, or object IDs from `performQuery`. Prefer `TaggedManagedObjectID<Model>` over a bare `NSManagedObjectID` when the model type is known. Do not return `NSManagedObject` instances from a query closure. Managed objects are tied to the context and queue that produced them, so using them after the closure returns can reintroduce Core Data concurrency bugs.

### Writing Core Data

Use `performAndSave` for writes. In new Swift async code, prefer the throwing async overload:

```swift
try await coreDataStack.performAndSave { context in
    let blog = try context.existingObject(with: blogID)
    blog.settings?.name = newName
}
```

For callback-based code, use the completion overload and choose the queue where the completion should run:

```swift
coreDataStack.performAndSave({ context in
    let blog = try context.existingObject(with: blogID)
    blog.settings?.name = newName
}, completion: { result in
    // Update UI or continue the workflow after the save finishes.
}, on: .main)
```

The throwing overload saves only when the closure succeeds. If the closure throws, the changes made in that background context are discarded. Do not call `context.save()` inside a `performAndSave` closure; the stack saves and reports errors consistently after the closure returns.

Avoid the synchronous `performAndSave { ... }` overload in new Swift code. Prefer the async overload, or the completion overload when follow-up work needs to run after the save completes.

If existing UI code edits `mainContext` directly, save through the stack with `save(_:)` or `saveContextAndWait(_:)` instead of calling `context.save()` directly. Prefer nonblocking saves unless the caller genuinely needs to wait for persistence before continuing.

### Core Data Concurrency

Do not capture an `NSManagedObject`, such as `Blog` or `WPAccount`, and use it from a different queue, task, or escaping closure. Touching its properties outside its context's queue violates Core Data's concurrency model.

When a model reference needs to cross a concurrency boundary, store a `TaggedManagedObjectID<Model>` instead of the managed object. Inject a `CoreDataStack` or `CoreDataStackSwift` into the type that performs the work, then resolve the ID inside `performQuery` for reads or `performAndSave` for writes.

```swift
let blogID = TaggedManagedObjectID(blog)

let siteName = try await coreDataStack.performQuery { [blogID] context in
    let blog = try context.existingObject(with: blogID)
    return blog.settings?.name
}
```

Likewise, do not pass managed objects returned from a background context into UI code. Return values that are safe to cross context boundaries, then resolve object IDs in `mainContext` if UI code needs managed objects.

### Testing Core Data Code

Use an isolated `ContextManager` for tests instead of the production singleton:

```swift
let contextManager = ContextManager.forTesting()
contextManager.useAsSharedInstance(untilTestFinished: self)
```

Prefer injecting that test stack into the type under test. Override `ContextManager.shared` only when the code under test cannot accept an injected `CoreDataStack` dependency.

### Share Extension Data

The share extension uses its own shared-store stack. Keep share-extension Core Data code on that stack and do not mix objects or contexts between the main app stack and the share-extension stack.

## Follow Apple’s Human Interface Guidelines

Apple maintains an [iOS Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/ios/overview/themes/) document that “describes the guidelines and principles that help you design a superlative user interface and user experience for your iOS app.” Any new UI elements you create when contributing to the app should follow Apple’s guide.

## Follow WordPress Mobile’s Design Guidelines

We’ve set up a page that outlines the design philosophy for all WordPress Mobile Apps [here](https://make.wordpress.org/mobile/handbook/pathways/design/), make sure you read through it as well.
