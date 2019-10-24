# Formattable Content 

Sometimes it's necessary to give a specific format to a title or a paragraph or to specific words/sentences inside them, and when the backend wants to communicate this to the client, it has a very specific way to do so. This is being used on `Notifications` and `Activity Log`.

## Content

As an example, let's use the text "[This site](https://www.wordpress.com) was created by **Author**".
When the backend wants to communicate to the client how this text should be formatted, it will give us the raw text, and a series of ranges.

```javascript
{
  "text": "This site was created by Author"  // Text to display
  "type": "site",  // Type of content, to apply a base style
  "actions": {
      "follow": false  // Actions definition for this content. The value is the state (i.e: follow false -> not followed)
  },
  "ranges": [  // Ranges to apply a specific style
      {
         "type": "site",  // Type of range to know what style to apply
         "siteID": "some_id",  // Metadata, sometimes useful to construct a URL
         "url": "https://www.wordpress.com", // Element URL, usually is an external URL.
         "indices": [  // Range of text to apply this style
            0,
            9
          ]
      },
      {
         "type": "user",
         "indices": [
            25,
            31
          ]
      }
  ],
  "meta": {
      // Metadata depending on the type of content
  }
}
```

All this information is managed by classes that conform to the [FormattableContent](https://github.com/wordpress-mobile/WordPress-iOS/blob/69031b69b0a641b46479b6fb9c2af5e83c4310dd/WordPress/Classes/Utility/FormattableContent/FormattableContent.swift) protocol:

```swift
protocol FormattableContent {
    var text: String? { get }
    var ranges: [FormattableContentRange] { get }
    var actions: [FormattableContentAction]? { get }
    var kind: FormattableContentKind { get }

    func action(id: Identifier) -> FormattableContentAction?
    func isActionEnabled(id: Identifier) -> Bool
    func isActionOn(id: Identifier) -> Bool
}
```

## Groups

Sometimes some components are composed by more than just one `content`, and a property like `body` can return an array of them.
For those cases we have the [FormattableContentGroup](https://github.com/wordpress-mobile/WordPress-iOS/blob/69031b69b0a641b46479b6fb9c2af5e83c4310dd/WordPress/Classes/Utility/FormattableContent/FormattableContentGroup.swift). It's a simple class with an array of blocks and a group `Kind`.

Sometimes one element can have different groups, like a `header` and a `body`. `Kind` is a good way to identify them with ease.

```swift
class FormattableContentGroup {
    let blocks: [FormattableContent]
    let kind: Kind

    init(blocks: [FormattableContent], kind: Kind) {
        self.blocks = blocks
        self.kind = kind
    }
}
```

## Ranges

To model the `Range` information for each content, we have the protocol [FormattableContentRange](https://github.com/wordpress-mobile/WordPress-iOS/blob/69031b69b0a641b46479b6fb9c2af5e83c4310dd/WordPress/Classes/Utility/FormattableContent/FormattableContentRange.swift):
```swift
public protocol FormattableContentRange {
    typealias Shift = Int
    var kind: FormattableRangeKind { get }
    var range: NSRange { get }

    func apply(_ styles: FormattableContentStyles, to string: NSMutableAttributedString, withShift shift: Int) -> Shift
}
```

The conforming classes/structs own the logic of applying the given style to the given attributed string. This is this way because not all ranges will apply styles in the same way. The best example is the `Noticon` range that will insert a character into the string. This is also the reason for returning a `Shift (Int)`, it being the number of characters inserted into the string.

There's a default implementation of `apply()` that should be used on any normal range and it should always return 0 unless the string length is modified in any way.

## Formatting

When the time comes to render the attributed text with all the styles, we have the helper class [FormattableContentFormatter](https://github.com/wordpress-mobile/WordPress-iOS/blob/69031b69b0a641b46479b6fb9c2af5e83c4310dd/WordPress/Classes/Utility/FormattableContent/FormattableContentFormatter.swift). Just give it a content and a style and it does the rest :]

```swift
class FormattableContentFormatter {
    func render(content: FormattableContent, with styles: FormattableContentStyles) -> NSAttributedString
}
```

It's a good idea to keep one instance of this class and use it to render any `FormattableContent` you need. It also implements catching for the generated `NSAttributedString` to avoid unnecessary overhead.

## Styles

To define how to style the content and their ranges, we have the [FormattableContentStyles](https://github.com/wordpress-mobile/WordPress-iOS/blob/69031b69b0a641b46479b6fb9c2af5e83c4310dd/WordPress/Classes/Utility/FormattableContent/FormattableContentStyles.swift) protocol that is used by the formatter:

```swift
public protocol FormattableContentStyles {
    var attributes: [NSAttributedStringKey: Any] { get } // Applied to the whole content
    var quoteStyles: [NSAttributedStringKey: Any]? { get } // Applied to quotes
    var rangeStylesMap: [FormattableRangeKind: [NSAttributedStringKey: Any]]? { get } // map from ranges to attributes
    var linksColor: UIColor? { get } // Links color
    var key: String { get } // key used for catching
}
```
The `rangeStylesMap` property is used to give attributes to a specific range kind.
[Here you can find](https://github.com/wordpress-mobile/WordPress-iOS/blob/69031b69b0a641b46479b6fb9c2af5e83c4310dd/WordPress/Classes/ViewRelated/Activity/FormattableContent/ActivityContentStyles.swift) an example of this protocol implemented for Activity Log.

## Factories
Since is not always easy to decide what content or range to init for a given endpoint response, we have a [FormattableContentFactory](https://github.com/wordpress-mobile/WordPress-iOS/blob/69031b69b0a641b46479b6fb9c2af5e83c4310dd/WordPress/Classes/Utility/FormattableContent/FormattableContentFactory.swift) protocol and a `FormattableRangesFactory` to help us with that task.


```swift
protocol FormattableRangesFactory {
    static func contentRange(from dictionary: [String: AnyObject]) -> FormattableContentRange?
}
```
Both factory protocols have extensions with helper methods to facilitate the parsing of the dictionary.

## Actions

Content can have actions associated, for example the `follow` action on a `User` content or the `Mark as spam` action on a `Comment` content. Those actions are modeled by the `FormattableCommentAction` protocol:

```swift
protocol FormattableContentAction: CustomStringConvertible {
    var identifier: Identifier { get }
    var enabled: Bool { get }
    var on: Bool { get }
    var command: FormattableContentActionCommand? { get }

    func execute(context: ActionContext)
}
```

The visual representation of the action is given by the `FormattableContentActionCommand` protocol:

```swift
protocol FormattableContentActionCommand: CustomStringConvertible {
    var identifier: Identifier { get }
    var icon: UIButton? { get }
    var on: Bool { get set }

    func execute(context: ActionContext)
}
```