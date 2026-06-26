# Localization

Use `NSLocalizedString()` for all user-facing text. During release, strings are automatically extracted and uploaded to GlotPress for translation. The developes do not need to edit `Localizable.strings`.

## Key Rules

1. **Use reverse-DNS keys**: `"editor.post.buttonTitle"` not `"Post"`
2. **Always add meaningful comments**: Describe context and placeholders
3. **Use positional placeholders**: `%1$@`, `%2$d` not just `%@`, `%d`
4. **No variables in NSLocalizedString**: All parameters must be string literals
5. **Use String.localizedStringWithFormat**: Don't use string interpolation

## Examples

### Basic Usage
```swift
private enum Strings {
    static let title = NSLocalizedString(
        "settings.screen.title",
        value: "Settings",
        comment: "Title for the settings screen"
    )
    
    static let saveButton = NSLocalizedString(
        "settings.save.button",
        value: "Save Changes",
        comment: "Button to save settings changes"
    )
}

// Usage
Text(Strings.title)
Button(Strings.saveButton) { /* action */ }
```

### With Placeholders
```swift
private enum Strings {
    static let welcomeMessage = NSLocalizedString(
        "dashboard.welcome.message",
        value: "Welcome back, %1$@!",
        comment: "Welcome message on dashboard. %1$@ is the user's name."
    )
    
    static let postCount = NSLocalizedString(
        "dashboard.post.count",
        value: "You have %1$d posts in %2$@",
        comment: "Post count message. %1$d is number of posts, %2$@ is site name."
    )
}

// Usage
let welcome = String.localizedStringWithFormat(Strings.welcomeMessage, userName)
let count = String.localizedStringWithFormat(Strings.postCount, postCount, siteName)
```

### Pluralization
```swift
private enum Strings {
    static let postCountSingular = NSLocalizedString(
        "posts.count.singular",
        value: "%1$d post",
        comment: "Number of posts (singular). %1$d is the count."
    )
    
    static let postCountPlural = NSLocalizedString(
        "posts.count.plural", 
        value: "%1$d posts",
        comment: "Number of posts (plural). %1$d is the count."
    )
}

// Usage
let template = count == 1 ? Strings.postCountSingular : Strings.postCountPlural
let text = String.localizedStringWithFormat(template, count)
```

### Shared Strings
Use `SharedStrings` (@WordPress/Classes/Utility/SharedStrings.swift) for common UI elements like "Cancel", "Done", "Save".

### Numbers
```swift
let localizedCount = NumberFormatter.localizedString(from: NSNumber(value: count), number: .none)
```

## Non-localizable text

A SwiftUI `Text("literal")` uses `LocalizedStringKey`, so in **shipping code** the literal is **automatically extracted for translation**. For strings that must *not* be translated — glyphs and symbols (`Text("·")`), brand names (`Text("WordPress.com")`), and pure interpolations (`Text("@\(username)")`) — use `Text(verbatim:)` so the string is excluded:

```swift
Text(verbatim: "·")                 // divider glyph — not translatable
Text(verbatim: "WordPress.com")     // brand name — not translatable
```

### Previews and `#if DEBUG` are excluded automatically — don't wrap them

You do **not** need `Text(verbatim:)` for placeholder strings in `#Preview`, `PreviewProvider`, or `#if DEBUG` blocks, and you don't need to flag them in review. The extraction tooling excludes them on its own:

- `xcstringstool extract` tags every extracted string with the compile gate it sits under — its `visibility`. Shipping code carries none (`visibility: nil`); a preview literal comes out as `visibility: "preview"`, and a `#if DEBUG` literal as `visibility: defined(DEBUG)`.
- `xcstringstool sync` — the step that builds `Localizable.xcstrings` — admits **only** unconditional strings (`visibility: nil`). Anything carrying a `visibility` (preview, `#if DEBUG`, or a combination of the two) is dropped before it can reach the catalog or GlotPress.

So a plain `Text("Sample Card")` inside a `#Preview` is fine as-is — it is not a localization leak, and wrapping it in `verbatim:` only adds noise. If you spot a translatable literal in a preview during review, you can leave it: `sync` already excludes it.

## Organization Pattern

Organize strings using private enums within each view or view model:

```swift
struct PostEditorView: View {    
    var body: some View {
        NavigationView {
            TextEditor(text: $postContent)
                .placeholder(Strings.placeholder)
                .navigationTitle(Strings.title)
        }
    }
}

private enum Strings {
    static let title = NSLocalizedString("editor.title", value: "New Post", comment: "Editor screen title")
    static let placeholder = NSLocalizedString("editor.placeholder", value: "Start writing...", comment: "Editor text placeholder")
}

#Preview {
    PostEditorView()
}
```

## Testing

Test with long words and special characters to ensure UI layouts work across languages.
