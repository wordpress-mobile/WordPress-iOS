# Localization

## Technical consideraations

During development, using [`NSLocalizedString()`](https://developer.apple.com/documentation/foundation/nslocalizedstring) in the code should be enough. You shouldn't need to touch the `Localizable.strings` files manually.

During the release process, `NSLocalizedString` statements are scanned and stored in the `Localizable.strings` file. The file is then uploaded to [GlotPress](https://translate.wordpress.org/projects/apps/ios/) for translation. Before the release build is finalized, all the translations are grabbed from GlotPress and saved back to the `Localizable.strings` files.

### Use unique reverse-DNS naming style Keys

Use unique reverse-DNS naming style for keys of localized strings (instead of using the English copy as key). This allows to avoid issues where the same word in English could need different translations based on context, or very long keys causing issues with some translation services.

```swift
// Do
let postBtnTitle = NSLocalizedString("editor.post.buttonTitle", value: "Post", comment: "Verb. Action to publish a post")
let postType = NSLocalizedString("reader.post.title", value: "Post", comment: "Noun. Describes when an entry is a blog post (and not story or page)"
```

```swift
// Don't
let postBtnTitle = NSLocalizedString("Post", comment: "Verb. Action to publish a post")
let postType = NSLocalizedString("Post", comment: "Noun. Describes when an entry is a blog post (and not story or page)"
```

### Always add Comments

Always add a meaningful comment. If possible, describe where and how the string will be used. If there are placeholders, describe what each placeholder is. 

```swift
// Do
let succeededMessage = String(format: NSLocalizedString(
    "reader.post.follow.successTitle",
    value: "Following %1$@",
    comment: "Notice title when following a site succeeds. %1$@ is a placeholder for the site name."
), siteName)
```

```swift
// Don't
let succeededMessage = String(format: NSLocalizedString(
    "reader.post.follow.successTitle",
    value: "Following %1$@",
    comment: ""
), siteName)
```

Comments help give more context to translators.

### Use positional placeholders

Use the `%n$x` format (with `n` being an integer for the parameter position/index in the arguments to `String(format:)`, and `x` being one of the type specifiers like `@` or `d`); in particular, don't use just `%x` (the one without explicit positional index) for positional placeholders. This way, translators will not risk of messing up the parameter resolution order when translating the copy in locales where the order of the words in the sentence might be different than the one in English.

```swift
// Do
let alertWarning = String(format: NSLocalizedString(
    "login.email.locationWarning",
    value: "Are you trying to log in to %1$@ near %2$@?",
    comment: "Login location warning alert. %1$@ is an account name and %2$@ is a location name."
), accountName, locationName)
```

```swift
// Don't
let alertWarning = String(format: NSLocalizedString(
    "login.email.locationWarning",
    value: "Are you trying to log in to %@ near %@?",
    comment: "Login location warning alert."
), accountName, locationName)
```

### Do not use Variables

Do not use variables as the argument of `NSLocalizedString()` (neither for the key, the value or the comment). The string key, value and comment will not be automatically picked up by the `genstrings` tool which expects string literals.

```swift
// Do
let myText = NSLocalizedString("some.place.title", value: "This is the text I want to translate.", comment: "Put a meaningful comment here.")
myTextLabel?.text = myText
```

```swift
// Don't
let myText = "This is the text I want to translate."
myTextLabel?.text = NSLocalizedString("some.place.title", value: myText, comment: "Put a meaningful comment here.")
let myKey = "some.place.title"
myTextLabel?.text = NSLocalizedString(myKey, value: "This is the text I want to translate.", comment: "Put a meaningful comment here.")
let comment = "Put a meaningful comment here."
myTextLabel?.text = NSLocalizedString("some.place.title", value: "This is the text I want to translate.", comment: comment)
```

### Do not use Interpolated Strings

Interpolated strings are harder to understand by translators and they may end up translating/changing the variable name, causing a crash.

Use [`String.localizedStringWithFormat`](https://developer.apple.com/documentation/swift/string/1414192-localizedstringwithformat) instead.

```swift
// Do
let year = 2019
let template = NSLocalizedString("mysite.copyrightNotice.title", value: "© %d Acme, Inc.", comment: "Copyright Notice")
let str = String.localizeStringWithFormat(template, year)
```

```swift
// Don't
let year = 2019
let str = NSLocalizedString("mysite.copyrightNotice.title", value: "© \(year) Acme, Inc.", comment: "Copyright Notice")
```

### Multiline Strings

For readability, you can split the string and concatenate the parts using the plus (`+`) symbol. 

```swift
// Okay
NSLocalizedString(
    "some.place.concatenatedDescription",
    value: "Take some long text here " +
    "and then concatenate it using the '+' symbol."
    comment: "You can even use this form of concatenation " +
        "for extra-long comments that take the time to explain " +
        "lots of details to help our translators make accurate translations."
)
```

Do not use extended delimiters (e.g. triple quotes). They are not automatically picked up.

```swift
// Don't
NSLocalizedString(
    "some.place.tripleQuotedDescription",
    """Triple-quoted text, when used in NSLocalizedString, is Not OK. Our scripts break when you use this."""
    comment: """Triple-quoted text, when used in NSLocalizedString, is Not OK."""
)
```

### Pluralization

GlotPress currently does not support pluralization using the [`.stringsdict` file](https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPInternational/LocalizingYourApp/LocalizingYourApp.html#//apple_ref/doc/uid/10000171i-CH5-SW10). So, right now, you have to support plurals manually by having separate localized strings.

This is not an ideal situation, and in the future we're hoping to properly support real pluralization with `.stringdict` files, which takes into account the complexity of different locales having different pluralization rules (sometimes way more complex than the simple singular/plural rule that English has, e.g. like [in Irish](https://unicode-org.github.io/cldr-staging/charts/latest/supplemental/language_plural_rules.html#ga)).

In the meantime, we sadly have to make-do with the simplistic solution of providing two different localized strings and doing the pluralization decision by code, even if that will lead to some inexact pluralization in some locales.
```swift
struct PostCountLabels {
    static let singular = NSLocalizedString("reader.post.title" ,value: "%d Post", comment: "Number of posts displayed in Posting Activity when a day is selected. %d will contain the actual number (singular).")
    static let plural = NSLocalizedString("reader.postList.title", value: "%d Posts", comment: "Number of posts displayed in Posting Activity when a day is selected. %d will contain the actual number (plural).")
}

let postCountText = (count == 1 ? PostCountLabels.singular : PostCountLabels.plural)
```

### Numbers

Localize numbers whenever possible. 

```swift
let localizedCount = NumberFormatter.localizedString(from: NSNumber(value: count), number: .none)
```

## Testing considerations

Test changes that include localized content by using large words or with letters/accents not frequently used in English.