# Accessibility Guidelines

This is a short recap of the most important points for a successful implementation of the accessibility features provided by iOS. For a more in depth guideline, you can go to:

- [Dynamic type guideline](https://github.com/wordpress-mobile/WordPress-iOS/wiki/Dynamic-type-guideline)
- [VoiceOver guideline](https://github.com/wordpress-mobile/WordPress-iOS/wiki/VoiceOver-guideline)

We also have a fast guide on [how to use VoiceOver](https://github.com/wordpress-mobile/WordPress-iOS/wiki/Using-VoiceOver)

## Dynamic type
-   Avoid constraining the height of a  `UILabel`,  `UIButton`, or any view that has a  `UILabel`  or a  `UIButton`  as a child view.
-   In cases where a minimum height is necessary, use a constraint relation`greaterThanOrEqualTo`.
-   In most cases for  `UIButton`  instances, setting  `.contentEdgeInsets`  top and bottom will be enough to get a minimum height.
-   Using  `UIStackView`  makes it easier to create layouts that grow automatically with dynamic type.
-   If you need insets in  `UIStackView`, you can use `stackView.layoutMargins` instead of setting height constraints.
- Get fonts from `WPStyleGuide+DynamicType`.
- Don't forget to set `adjustsFontForContentSizeCategory = true`.
- If you need a font with a special weight or trait (i.e. `italic`), remember to refresh the fonts when the user changes the content size category.

### For table views:
1.  Follow the self-sizing cell rules for layout and setup.
2.  Use dynamic fonts.
3.  Set  `adjustsFontForContentSizeCategory = true`  in labels and buttons.
4.  Everything should be working already!

Be careful with [static tables.](https://github.com/wordpress-mobile/WordPress-iOS/wiki/Dynamic-type-guideline#the-static-tableview-case)

## VoiceOver

- To test the new (or modified) UI with VoiceOver is the best we can do to ensure a good adoption of this feature.
- Add accessibility labels to elements with not enough text-based information (i.e a button with just a number or an image).
- For complex UI elements that represent one unit of information, make that unit a single VoiceOver element with a label that explains its content as we would explain it to another person.