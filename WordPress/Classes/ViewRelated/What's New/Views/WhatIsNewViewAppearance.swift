
struct WhatIsNewViewAppearance {
    // main view
    let mainContentInsets: UIEdgeInsets

    // title
    let headlineFont: UIFont
    let titleVersionSpacing: CGFloat

    // version label
    let subHeadlineFont: UIFont
    let versionTableviewSpacing: CGFloat

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

        let titleVersionSpacing: CGFloat = 16

        // version label
        let subHeadlineFont = UIFont(descriptor: UIFontDescriptor
                .preferredFontDescriptor(withTextStyle: .subheadline), size: 15)
        let versionTableviewSpacing: CGFloat = 32

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
        return WhatIsNewViewAppearance(mainContentInsets: mainContentInsets,
                                       headlineFont: headlineFont,
                                       titleVersionSpacing: titleVersionSpacing,
                                       subHeadlineFont: subHeadlineFont,
                                       versionTableviewSpacing: versionTableviewSpacing,
                                       headerViewInsets: headerViewInsets,
                                       estimatedRowHeight: estimatedRowHeight,
                                       tableViewContentInsets: tableViewContentInsets,
                                       continueButtonHeight: continueButtonHeight,
                                       continueButtonFont: continueButtonFont,
                                       continueButtonInsets: continueButtonInsets,
                                       material: material,
                                       backButtonTintColor: backButtonTintColor,
                                       backButtonInset: backButtonInset)
    }

    static var dashboardCustom: Self {
        // main view
        let mainContentInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)

        // title
        var headlineFont: UIFont
        if let serifHeadlineDescriptor = UIFontDescriptor
                .preferredFontDescriptor(withTextStyle: .headline)
                .withDesign(.serif) {

            headlineFont = UIFont(descriptor: serifHeadlineDescriptor, size: 34)
        }
        headlineFont = UIFont(descriptor: .preferredFontDescriptor(withTextStyle: .headline), size: 34)

        let titleVersionSpacing: CGFloat = 16

        // version label
        let subHeadlineFont = UIFont(descriptor: UIFontDescriptor
                .preferredFontDescriptor(withTextStyle: .subheadline), size: 15)
        let versionTableviewSpacing: CGFloat = 32

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
        return WhatIsNewViewAppearance(mainContentInsets: mainContentInsets,
                                       headlineFont: headlineFont,
                                       titleVersionSpacing: titleVersionSpacing,
                                       subHeadlineFont: subHeadlineFont,
                                       versionTableviewSpacing: versionTableviewSpacing,
                                       headerViewInsets: headerViewInsets,
                                       estimatedRowHeight: estimatedRowHeight,
                                       tableViewContentInsets: tableViewContentInsets,
                                       continueButtonHeight: continueButtonHeight,
                                       continueButtonFont: continueButtonFont,
                                       continueButtonInsets: continueButtonInsets,
                                       material: material,
                                       backButtonTintColor: backButtonTintColor,
                                       backButtonInset: backButtonInset)
    }
}
