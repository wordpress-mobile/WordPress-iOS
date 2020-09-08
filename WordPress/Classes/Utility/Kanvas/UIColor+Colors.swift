import UIKit

extension UIColor {

    public func rgba() -> UIColor {
        return UIColor(red: CIColor(color: self).red, green: CIColor(color: self).green, blue: CIColor(color: self).blue, alpha: CIColor(color: self).alpha)
    }

    // MARK: - Brand Colors ( Late 2018 )
    @objc public static var tumblrDeepBlue: UIColor { return UIColor(hex: 0x001935) }
    @objc public static var tumblrBrightBlue: UIColor { return UIColor(hex: 0x00B8FF) }
    @objc public static var tumblrBrightRed: UIColor { return UIColor(hex: 0xFF492F) }
    @objc public static var tumblrBrightYellow: UIColor { return UIColor(hex: 0xE8D73A) }
    @objc public static var tumblrBrightGreen: UIColor { return UIColor(hex: 0x00CF35) }
    @objc public static var tumblrBrightPink: UIColor { return UIColor(hex: 0xFF62CE) }
    @objc public static var tumblrBrightPurple: UIColor { return UIColor(hex: 0x7C5CFF) }
    @objc public static var tumblrBrightOrange: UIColor { return UIColor(hex: 0xFF8A00) }

    /// Returns a white color
    @objc public static var tumblrWhite: UIColor { return .white }
    /// Returns a 97% white
    @objc public static var tumblrWhite97: UIColor { return UIColor(hex: 0xf7f7f7) }
    /// Returns a 95% white
    @objc public static var tumblrWhite95: UIColor { return UIColor(hex: 0xf3f3f3) }
    /// Returns a 92% white
    @objc public static var tumblrWhite92: UIColor { return UIColor(hex: 0xebebeb) }
    /// Returns a 85% white
    @objc public static var tumblrWhite85: UIColor { return UIColor(hex: 0xd9d9d9) }
    /// Returns a 75% white
    @objc public static var tumblrWhite75: UIColor { return UIColor(hex: 0xc0c0c0) }
    /// Returns a 65% white
    @objc public static var tumblrWhite65: UIColor { return UIColor(hex: 0xa6a6a6) }
    /// Returns a 50% white
    @objc public static var tumblrWhite50: UIColor { return UIColor(hex: 0x808080) }
    /// Returns a 40% white
    @objc public static var tumblrWhite40: UIColor { return UIColor(hex: 0x676767) }
    /// Returns a 25% white
    @objc public static var tumblrWhite25: UIColor { return UIColor(hex: 0x404040) }


    /// Returns a transparent 30% black
    @objc public static var tumblrBlack30Transparent: UIColor { return tumblrBlack.withAlphaComponent(0.3) }
    /// Returns a transparent 50% black
    @objc public static var tumblrBlack50Transparent: UIColor { return tumblrBlack.withAlphaComponent(0.5) }
    /// Returns a transparent 30% white
    @objc public static var tumblrWhite30Transparent: UIColor { return tumblrWhite.withAlphaComponent(0.3) }
    /// Returns a transparent 50% white
    @objc public static var tumblrWhite50Transparent: UIColor { return tumblrWhite.withAlphaComponent(0.5) }
    /// Returns a transparent 60% white
    @objc public static var tumblrWhite60Transparent: UIColor { return tumblrWhite.withAlphaComponent(0.6) }
    /// Returns a transparent 65% white
    @objc public static var tumblrWhite65Transparent: UIColor { return tumblrWhite.withAlphaComponent(0.65) }
    /// Returns a transparent 85% white
    @objc public static var tumblrWhite85Transparent: UIColor { return tumblrWhite.withAlphaComponent(0.85) }

    /// Returns a black color
    @objc public static var tumblrBlack: UIColor { return .black }
    /// Returns a 95% black
    @objc public static var tumblrBlack95: UIColor { return UIColor(hex: 0x0d0d0d) }
    /// Returns a 85% black
    @objc public static var tumblrBlack85: UIColor { return UIColor(hex: 0x262626) }
    /// Returns a 75% black
    @objc public static var tumblrBlack75: UIColor { return UIColor(hex: 0x404040) }
    /// Returns a 65% black
    @objc public static var tumblrBlack65: UIColor { return UIColor(hex: 0x595959) }
    /// Returns a 40% black
    @objc public static var tumblrBlack40: UIColor { return UIColor(hex: 0x404040) }
    /// Returns a 25% black
    @objc public static var tumblrBlack25: UIColor { return UIColor(hex: 0xc0c0c0) }

    /// Returns tumblrWhite75
    @objc public static var avatarBackgroundColorWhite: UIColor { return .tumblrWhite75 }
    /// Returns tumblrWhite
    @objc public static var blueTableCellTitleLabelTextColor: UIColor { return .tumblrWhite }

    @objc public static var offWhiteCellBackgroundColor: UIColor { return .tumblrWhite95 }
    @objc public static var whiteTableCellBackgroundColor: UIColor { return .tumblrWhite }
    @objc public static var whiteTableCellDetailTextColor: UIColor { return .tumblrBlack65 }
    @objc public static var whiteTableCellTextColor: UIColor { return .tumblrBlack65 }
    @objc public static var composePostLineSeparatorColor: UIColor { return tumblrWhite85 }
    @objc public static var blueTableCellBackgroundColor: UIColor { return tumblrDeepBlue }
    @objc public static var postControlBackgroundColor: UIColor { return tumblrWhite95 }
    @objc public static var postHeaderDetailLabelTextColor: UIColor { return tumblrBlack65 }
    @objc public static var searchResultsBackgroundColor: UIColor { return tumblrWhite }

    @objc public static var lineSeparatorColor: UIColor { return tumblrWhite85 }
    @objc public static var postControlLikeTint: UIColor { return tumblrBrightRed }
    @objc public static var postHeaderBlogName: UIColor { return tumblrBlack65 }
    @objc public static var tumblrTransparentOverlay: UIColor { return tumblrBlack.withAlphaComponent(0.1) }

    // General
    @objc public static var tumblr80PercentDeepBlueColor: UIColor { return tumblrDeepBlue.withAlphaComponent(0.8) }
    @objc public static var tumblrBlueGray: UIColor { return UIColor(hex: 0x6D7987) }
    @objc public static var tumblrSelectedDeepBlue: UIColor { return UIColor(hex: 0x102945) }
    @objc public static var tumblrSelectedBrightBlue: UIColor { return UIColor(hex: 0x6DC9EC) }

    @objc public static var tumblrGray: UIColor { return .tumblrBlack75 }
    @objc public static var tumblr60PercentGray: UIColor { return tumblrGray.withAlphaComponent(0.6) }
    @objc public static var tumblr50PercentGray: UIColor { return tumblrGray.withAlphaComponent(0.5) }
    @objc public static var tumblr40PercentGray: UIColor { return tumblrGray.withAlphaComponent(0.4) }
    @objc public static var tumblr25PercentGray: UIColor { return tumblrGray.withAlphaComponent(0.25) }
    @objc public static var tumblr13PercentGray: UIColor { return tumblrGray.withAlphaComponent(0.13) }
    @objc public static var tumblr7PercentGray: UIColor { return tumblrGray.withAlphaComponent(0.07) }

    // Onboarding
    @objc public static var onboardingInactive: UIColor { return .tumblrWhite50Transparent }

    // Posts
    @objc public static var postFooterText: UIColor { return tumblrBlack65 }
    @objc public static var videoPostBackground: UIColor { return tumblrWhite65 }
    @objc public static var reblogPostControlTint: UIColor { return tumblrBrightGreen }
    @objc public static var appealBannerOrange: UIColor { return tumblrBrightOrange }
    @objc public static var appealBannerGreen: UIColor { return tumblrBrightGreen }
    @objc public static var appealBannerRed: UIColor { return tumblrBrightRed }
    @objc public static var appealBannerGray: UIColor { return tumblrBlack40 }

    // Ad Decoration View
    @objc public static var bannerAdvertisementDecorationView: UIColor { return tumblrWhite }
    @objc public static var postAdvertisementDecorationView: UIColor { return tumblrBlack.withAlphaComponent(0.65) }

    // App Install
    @objc public static var filledStar: UIColor { return tumblrBrightOrange }
    @objc public static var emptyStar: UIColor { return tumblr40PercentGray }

    // Modal Colors
    @objc public static var tumblrSuccess: UIColor { return tumblrBrightGreen }
    @objc public static var tumblrError: UIColor { return tumblrBrightRed }

    // Post Form Colors
    @objc public static var facebookBlueColor: UIColor { return UIColor(hex: 0x3b5998) }
    @objc public static var twitterBlueColor: UIColor { return UIColor(hex: 0x1da1f2) }

    // Online status indicator
    @objc public static var onlineStatusBadge: UIColor { return tumblrBrightGreen }

    // Account Screen
    @objc public static var orangeNewFeature: UIColor { return tumblrBrightOrange }

    // Group Creation
    @objc public static var groupCreationBackground: UIColor { return tumblrBrightBlue }
    @objc public static var groupCreationInputField: UIColor { return tumblrDeepBlue }

    // Trending Tags Colors
    @objc public static var trendingTagQuoteBackground: UIColor { return .tumblrBrightOrange }
    @objc public static var trendingTagChatBackground: UIColor { return .tumblrBrightBlue }
    @objc public static var trendingTagAudioBackground: UIColor { return .tumblrBrightPurple }
    @objc public static var trendingTagTextBackground: UIColor { return .tumblrWhite }
    @objc public static var trendingTagLinkBackground: UIColor { return .tumblrBrightGreen }

    // Post Type Colors
    @objc public static var quotePost: UIColor { return .tumblrBrightOrange }
    @objc public static var chatPost: UIColor { return .tumblrBrightBlue }
    @objc public static var audioPost: UIColor { return .tumblrBrightPurple }
    @objc public static var textPost: UIColor { return .tumblrBlack65 }
    @objc public static var photoPost: UIColor { return .tumblrBrightRed }
    @objc public static var linkPost: UIColor { return .tumblrBrightGreen }
    @objc public static var videoPost: UIColor { return .tumblrWhite50 }

    // MARK: - AppColorScheme
    /// This color is being used for Dark Mode Primary - hex 0x050505
    @objc public static var darkModePrimary: UIColor { return UIColor(hex: 0x050505) }
    /// This color is being used for Dark Mode Background - hex 0x222222
    @objc public static var darkModeBackground: UIColor { return UIColor(hex: 0x222222) }
    /// This color is being used for Dark Mode PrimaryTint - hex 0x1c1c1c
    @objc public static var darkModeBackgroundTint: UIColor { return UIColor(hex: 0x1c1c1c) }

    /// This color is being used for Low Contrast Background - hex 0x36465d
    @objc public static var lowContrastBackground: UIColor { return UIColor(hex: 0x36465d) }
    /// This color is being used for Low Contrast BackgroundTint - hex 0x303e53
    @objc public static var lowContrastBackgroundTint: UIColor { return UIColor(hex: 0x303e53) }
    /// This color is being used for Low Contrast Primary - hex 0x1a2735
    @objc public static var lowContrastPrimary: UIColor { return UIColor(hex: 0x1a2735) }
    /// This color is being used for Low Contrast PrimaryTint - hex 0x24313e
    @objc public static var lowContrastPrimaryTint: UIColor { return UIColor(hex: 0x24313e) }
    /// This color is being used for Low Contrast Separator - hex 0x263345
    @objc public static var lowContrastSeparator: UIColor { return UIColor(hex: 0x263345) }
    /// This color is being used for Low Contrast Main Text - hex 0xd6dade
    @objc public static var lowContrastMainText: UIColor { return UIColor(hex: 0xd6dade) }
    /// This color is being used for Low Contrast Detail Text - hex 0xb8bec6
    @objc public static var lowContrastDetailText: UIColor { return UIColor(hex: 0xb8bec6) }
}
