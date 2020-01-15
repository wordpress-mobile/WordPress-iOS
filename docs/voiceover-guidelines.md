# VoiceOver Guidelines

#### Table of Contents

- [Getting Started](#getting-started)
- [Guidelines](#guidelines)
	- [Basics](#basics)
    - [Grouping Elements](#grouping-elements)
    - [Spoken Order](#spoken-order)
    - [Appearing and Disappearing Elements](#appearing-disappearing)
- [Auditing](#auditing)
- [Further Reading](#further-reading)

## <a name="getting-started"></a>Getting Started

If you haven't worked with VoiceOver before, we recommend going through the following resources before reading further. 

- [Using VoiceOver](using-voiceover.md)

## <a name="guidelines"></a>Guidelines

### <a name="basics"></a>Basics

Providing support for VoiceOver is quite straightforward. For most cases, providing only three attributes should be enough:

* `accessibilityLabel`: A short, localized word or phrase that succinctly describes the control or view, but does not identify the element’s type.
* `accessibilityTraits`: A combination of one or more individual traits, each of which describes a single aspect of an element’s state, behavior, or usage
* `accessibilityHint`: A brief, localized phrase that describes the results of an action on an element

As an example, for a Share button, the recommended attributes would be:

```swift
button.accessibilityLabel = "Share"
button.accessibilityTraits = .button
button.accessibilityHint = "Opens the sharing sheet."
```

However, it is important to provide [helpful and accurate attributes](https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/iPhoneAccessibility/Making_Application_Accessible/Making_Application_Accessible.html#//apple_ref/doc/uid/TP40008785-CH102-SW6). The strings used for the attributes should also be [localized](https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPInternational/InternationalizingYourCode/InternationalizingYourCode.html#//apple_ref/doc/uid/10000171i-CH4-SW1).

#### <a namme="labels"></a>Labels

For a regular control or view, Apple recommends that labels should:

- Describe the element briefly.
- Not include the type of control or view.
- Begin with a capitalized word.
- Not end with a period.
- Be localized.

Beginning with a capitalized word and not ending with a period helps VoiceOver read the label with the appropiate inflection.

#### <a name="traits"></a>Traits

The traits attribute contains one or more individual traits that, taken together, describe the behavior of an accessible user interface element. Because some individual traits can be combined to describe a single element, the element’s behavior can be precisely characterized.

#### <a name="hints"></a>Hints

Apple recommends that hints should:

- Briefly describe the results. What is going to happen after interacting with this control or view?
- Begin with a verb and ignore the subject.
- Begin with a capitalized word.
- End with a period.
- Do not include the name or the type of control or view.
- Be localized.

### <a name="grouping-elements"></a>Grouping Elements

If a group of elements represent a single unit of information, consider grouping them into one accessibility element. This helps reduce clutter and makes your app easier to understand and navigate. 

Take the following custom `UITableViewCell` as an example. It has at least 5 accessible elements. 

<img src="images/voiceover-guidelines/group-elements-before.png" width="320">

Since there are potentially more cells like this in the table, it would be very easy for a VoiceOver user to lose context. To improve this, we can:

- Group the elements together by concatenating the information in the `UITableViewCell`'s `accessibilityLabel`.
- And make the child elements inaccessible by setting their `isAccessibilityElement` to `false`.

```swift
class CustomCell: UITableViewCell {
    override var accessibilityLabel: String? {
        get {
            let format = "Post by %@, from %@. %@. %@. %@. Excerpt. %@."
            return String(format: format,
                          author,
                          blogName,
                          datePublished,
                          isFollowing ? "Following" : "",
                          title,
                          excerpt)
        }
        set { }
    }
}
```

When selecting the cell, VoiceOver would then speak something like this:

```
Post by Carolyn Wells, from Discover. 6 days ago. Following. 
Around the World with WordPress: Jamaica. 
Excerpt. Today, we’re highlighting five sites from the island paradise of Jamaica.
```

- Prefer to place the most important elements first. The VoiceOver user can prefer to skip if they've already listened to what they need. This is why we placed the `excerpt` last in the example.
- Don't forget the periods when concatenating. They make VoiceOver pause which helps in comprehension.
- The `"Excerpt".` static text in the example is used as a separator and _signals_ that a very long text will be read by VoiceOver.

### <a name="spoken-order"></a>Spoken Order

Some column-based data is contained inside of stack views. VoiceOver may not speak the data in the desired order. For example, this tableview cell has nested stack views. 

- The vertical stack view is the parent and multiple horizontal stack views are children. 
- Two labels are contained inside of each horizontal stack view. One for the title (e.g. Subtotal) and one for the value (e.g. $999.99).

![](images/voiceover-guidelines.png)

The reading order is expected to be spoken as `"Subtotal: nine hundred ninety-nine dollars and ninety nine cents"`. In this case, however, VoiceOver defaults to reading the first item in each horizontal stack view, followed by the second. VoiceOver would speak `"Subtotal - Discount - Shipping - Taxes"`, followed by the values `"$999.99, -$601.00, $0.01, $333.33"`. This makes the information difficult to comprehend.

Use `.accessibilityElements` on the parent view to list the desired reading order of the subviews.

```swift
contentView.accessibilityElements = [subtotalTitleLabel, 
			             subtotalValueLabel, 
			             discountTitleLabel, 
			             discountValueLabel,
			             shippingTitleLabel,
			             shippingValueLabel,
			             taxesTitleLabel,
			             taxesValueLabel]
``` 

This also works for buttons, images, and views.

### <a name="appearing-disappearing"></a>Appearing and Disappearing Elements

If you have a UI element that is shown after an event happens, consider notifying VoiceOver that a new UI element is visible on the screen. 

An example of this is a custom snackbar.

<img src="images/voiceover-guidelines/announce-elements-notice.gif" width="320">

A blind user may never discover that a snackbar was shown in the screen unless they accidentally move their finger over it. To make the user aware of it, we can send a notification to VoiceOver using [`UIAccessibility.post`](https://developer.apple.com/documentation/uikit/uiaccessibility/1615194-post) with [`.layoutChanged`](https://developer.apple.com/documentation/uikit/uiaccessibility/notification/1620186-layoutchanged).

```swift
let snackBarView = createSnackBarView()
presentSnackBar(snackBarView)

UIAccessibility.post(notification: .layoutChanged, argument: snackBarView)
```

This notifies VoiceOver that a new view, `snackBarView`, has appeared and it should _select_ it. VoiceOver will then read its `accessibilityLabel`.

Once the element disappears, we should send another notification but with a `nil` argument. This makes VoiceOver immediately select a different element on the screen.

```swift
UIAccessibility.post(notification: .layoutChanged, argument: nil)
```

### Prefer Disabling Instead of Hiding Elements

A common UI pattern is hiding elements, such as buttons, until users are able to use them. 

<img src="images/voiceover-guidelines/hidden-button.gif" width="320">

This is not ideal for vision accessibility. VoiceOver users, especially first-time users, may try to understand how to interact with your UI by navigating through all the elements on the screen. If an important button, such as the **Insert button** example above, is initially hidden, they may never discover it. This can make comprehension difficult.

Consider making the element visible, but disabled, instead. 

```swift
func viewDidLoad() {
    /// Allow VoiceOver users to discover the Insert button. But don't let them use it yet.
    insertButton.isEnabled = false
}

func onImageSelected() {
    /// Enable the Insert button when an image was selected.
    insertButton.isEnabled = true
}
```

If a `UIControl`'s `isEnabled` property is set to `false`, UIKit would, by default, automatically add the [`.notEnabled` accessibility trait](https://developer.apple.com/documentation/uikit/uiaccessibility/uiaccessibilitytraits/1620208-notenabled). This would make VoiceOver read the button as `”dimmed”`, which sufficiently informs the user that the `UIControl` is present but cannot be used yet.

## <a name="auditing"></a>Auditing

## <a name="further-reading"></a>Further Reading