import UIKit

struct WhatIsNewViewAppearance {
    // main view
    let mainContentInsets: UIEdgeInsets

    // title
    let headlineFont: UIFont
    let headlineAlignment: NSTextAlignment
    let titleVersionSpacing: CGFloat

    // version label
    let subHeadlineFont: UIFont

    // table view
    let headerViewInsets: UIEdgeInsets
    let estimatedRowHeight: CGFloat
    let tableViewContentInsets: UIEdgeInsets

    // continue button
    let continueButtonHeight: CGFloat
    let continueButtonFont: UIFont
    let continueButtonInsets: UIEdgeInsets
    let material: UIBlurEffect.Style

    // back button
    let backButtonTintColor: UIColor
    let backButtonInset: CGFloat

    // disclaimer label
    let disclaimerBackgroundColor: UIColor
    let disclaimerLabelInsets: UIEdgeInsets
    let disclaimerFont: UIFont
    let disclaimerViewHeight: CGFloat
    let disclaimerViewCornerRadius: CGFloat
    let disclaimerTitleSpacing: CGFloat

    static var standard: WhatIsNewViewAppearance {
        // main view
        let mainContentInsets = UIEdgeInsets(top: 0, left: 48, bottom: 0, right: 48)

        // title
        var headlineFont: UIFont
        if let serifHeadlineDescriptor = UIFontDescriptor
                .preferredFontDescriptor(withTextStyle: .headline)
                .withDesign(.serif) {

            headlineFont = UIFont(descriptor: serifHeadlineDescriptor, size: 34)
        }
        headlineFont = UIFont(descriptor: .preferredFontDescriptor(withTextStyle: .headline), size: 34)

        let headlineAlignment = NSTextAlignment.left
        let titleVersionSpacing: CGFloat = 16

        // version label
        let subHeadlineFont = UIFont(descriptor: UIFontDescriptor
                .preferredFontDescriptor(withTextStyle: .subheadline), size: 15)

        // table view
        let headerViewInsets = UIEdgeInsets(top: 80, left: 0, bottom: 32, right: 0)
        let estimatedRowHeight: CGFloat = 72 // image height + vertical spacing
        // bottom spacing is button height (48) + vertical button insets ( 2 * 16) + vertical spacing before "Find out more" (32)
        let tableViewContentInsets = UIEdgeInsets(top: 0, left: 0, bottom: 112, right: 0)

        // continue button
        let continueButtonHeight: CGFloat = 48
        let continueButtonFont = UIFont.systemFont(ofSize: 22, weight: .medium)
        let continueButtonInsets = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        let material: UIBlurEffect.Style = .systemChromeMaterial

        // back button
        let backButtonTintColor = UIColor.darkGray
        let backButtonInset: CGFloat = 16
        // disclaimer label
        let disclaimerBackgroundColor = UIColor(light: .muriel(name: .pink, .shade40),
                                                dark: .muriel(name: .pink, .shade50))
        let disclaimerLabelInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
        let disclaimerFont = WPStyleGuide.fontForTextStyle(.footnote, fontWeight: .semibold)
        let disclaimerViewHeight: CGFloat = 24
        let disclaimerViewCornerRadius: CGFloat = 4
        let disclaimerTitleSpacing: CGFloat = 16
        return WhatIsNewViewAppearance(mainContentInsets: mainContentInsets,
                                       headlineFont: headlineFont,
                                       headlineAlignment: headlineAlignment,
                                       titleVersionSpacing: titleVersionSpacing,
                                       subHeadlineFont: subHeadlineFont,
                                       headerViewInsets: headerViewInsets,
                                       estimatedRowHeight: estimatedRowHeight,
                                       tableViewContentInsets: tableViewContentInsets,
                                       continueButtonHeight: continueButtonHeight,
                                       continueButtonFont: continueButtonFont,
                                       continueButtonInsets: continueButtonInsets,
                                       material: material,
                                       backButtonTintColor: backButtonTintColor,
                                       backButtonInset: backButtonInset,
                                       disclaimerBackgroundColor: disclaimerBackgroundColor,
                                       disclaimerLabelInsets: disclaimerLabelInsets,
                                       disclaimerFont: disclaimerFont,
                                       disclaimerViewHeight: disclaimerViewHeight,
                                       disclaimerViewCornerRadius: disclaimerViewCornerRadius,
                                       disclaimerTitleSpacing: disclaimerTitleSpacing)
    }

    static var dashboardCustom: Self {
        // main view
        let mainContentInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)

        // title
        let headlineFont = WPStyleGuide.serifFontForTextStyle(.title1, fontWeight: .bold)
        let headlineAlignment = NSTextAlignment.center
        let titleVersionSpacing: CGFloat = 16

        // version label
        let subHeadlineFont = UIFont(descriptor: UIFontDescriptor
                .preferredFontDescriptor(withTextStyle: .subheadline), size: 15)

        // table view
        let headerViewInsets = UIEdgeInsets(top: 88, left: 0, bottom: 24, right: 0)
        let estimatedRowHeight: CGFloat = 195 // image height + vertical spacing + bottom inset
        // bottom spacing is button height (48) + vertical button insets ( 2 * 16) + vertical spacing before "Find out more" (32)
        let tableViewContentInsets = UIEdgeInsets(top: 0, left: 0, bottom: 112, right: 0)

        // continue button
        let continueButtonHeight: CGFloat = 48
        let continueButtonFont = UIFont.systemFont(ofSize: 22, weight: .medium)
        let continueButtonInsets = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        let material: UIBlurEffect.Style = .regular

        // back button
        let backButtonTintColor = UIColor.darkGray
        let backButtonInset: CGFloat = 16

        // disclaimer label
        let disclaimerBackgroundColor = UIColor(light: .muriel(name: .pink, .shade40),
                                                dark: .muriel(name: .pink, .shade50))
        let disclaimerLabelInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
        let disclaimerFont = WPStyleGuide.fontForTextStyle(.footnote, fontWeight: .semibold)
        let disclaimerViewHeight: CGFloat = 24
        let disclaimerViewCornerRadius: CGFloat = 4
        let disclaimerTitleSpacing: CGFloat = 16
        return WhatIsNewViewAppearance(mainContentInsets: mainContentInsets,
                                       headlineFont: headlineFont,
                                       headlineAlignment: headlineAlignment,
                                       titleVersionSpacing: titleVersionSpacing,
                                       subHeadlineFont: subHeadlineFont,
                                       headerViewInsets: headerViewInsets,
                                       estimatedRowHeight: estimatedRowHeight,
                                       tableViewContentInsets: tableViewContentInsets,
                                       continueButtonHeight: continueButtonHeight,
                                       continueButtonFont: continueButtonFont,
                                       continueButtonInsets: continueButtonInsets,
                                       material: material,
                                       backButtonTintColor: backButtonTintColor,
                                       backButtonInset: backButtonInset,
                                       disclaimerBackgroundColor: disclaimerBackgroundColor,
                                       disclaimerLabelInsets: disclaimerLabelInsets,
                                       disclaimerFont: disclaimerFont,
                                       disclaimerViewHeight: disclaimerViewHeight,
                                       disclaimerViewCornerRadius: disclaimerViewCornerRadius,
                                       disclaimerTitleSpacing: disclaimerTitleSpacing)
    }
}
