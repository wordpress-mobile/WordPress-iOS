# Right to Left Layout Support Guidelines

Supporting right to left layout is fairly simple and most of the hard work has already been done by Apple.

Here are a few tips to ensure this implementation is flawless throughout the app: 

* Avoid using `.textAlignment = .left/.right` in favor of `.natural`
* If you really need to use `.left` or `.right` you will get a lint warning. You can silence the warning and explain why is it necessary to enforce left/right text alignment.
* UIControl objects have a property `.contentHorizontalAlignment`. In this case the preferred values are `.leading / .trailing` but those are iOS11+ only. So we made a temporary `.naturalContentHorizontalAlignment` that accepts `.leading/.trailing` parameters for iOS10+.

### Be careful with horizontal scroll views. 

Instead of using a horizontal scroll view, consider using a horizontal collection view with the default flow layout, since it automatically flips and adapts to RTL layouts.

In case you need to use a scroll view, be aware that it won't automatically adapt to RTL layout and you will have to flip it yourself.

A quick way to do it is by flipping both the scroll view **and** its content view using `CGAffineTransform`
```swift
if layoutDirection == .rightToLeft {
    view.transform = CGAffineTransform(scaleX: -1, y: 1)
}
```

### Layout and custom views
As a rule of thumb, it is good to default the horizontal constraint to `leading` and `trailing` so it will always flip automatically when necessary. For views or elements that should not flip, it's fine to use `left` or `right`.

### The UITextField case:
Textfields generally will work just fine by default, even when adding a `.leftView` or a `.rightView` or both as they will be flipped automatically as needed. 
The problem arises when we want to customize the rect size for those accessory views by overriding `leftViewRectForBounds:` or `rightViewRectForBounds:`, since they always apply to the corresponding `left` or `right` side of the textfield, **independently of the interface's layout direction**.

The easiest way to counter this problem is by not overriding those methods, and instead, adding the required insets to the accessory view itself.

If the requested layout is more complex, take  this problem into account and test the RTL layout until it works :]
You can get ideas by looking at the `WPWalkthroughTextField` class.