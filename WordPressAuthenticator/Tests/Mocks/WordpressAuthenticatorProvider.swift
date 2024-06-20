@testable import WordPressAuthenticator

@objc
public class WordpressAuthenticatorProvider: NSObject {
    static func wordPressAuthenticatorConfiguration() -> WordPressAuthenticatorConfiguration {
        return WordPressAuthenticatorConfiguration(wpcomClientId: "23456",
                                                   wpcomSecret: "arfv35dj57l3g2323",
                                                   wpcomScheme: "https",
                                                   wpcomTermsOfServiceURL: URL(string: "https://wordpress.com/tos/")!,
                                                   googleLoginClientId: "",
                                                   googleLoginServerClientId: "",
                                                   googleLoginScheme: "com.googleuserconsent.apps",
                                                   userAgent: "")
    }

    static func wordPressAuthenticatorStyle(_ style: AuthenticatorStyleType) -> WordPressAuthenticatorStyle {
        var wpAuthStyle: WordPressAuthenticatorStyle!

        switch style {
        case .random:
            wpAuthStyle = WordPressAuthenticatorStyle(
                primaryNormalBackgroundColor: UIColor.random(),
                primaryNormalBorderColor: UIColor.random(),
                primaryHighlightBackgroundColor: UIColor.random(),
                primaryHighlightBorderColor: UIColor.random(),
                secondaryNormalBackgroundColor: UIColor.random(),
                secondaryNormalBorderColor: UIColor.random(),
                secondaryHighlightBackgroundColor: UIColor.random(),
                secondaryHighlightBorderColor: UIColor.random(),
                disabledBackgroundColor: UIColor.random(),
                disabledBorderColor: UIColor.random(),
                primaryTitleColor: UIColor.random(),
                secondaryTitleColor: UIColor.random(),
                disabledTitleColor: UIColor.random(),
                disabledButtonActivityIndicatorColor: UIColor.random(),
                textButtonColor: UIColor.random(),
                textButtonHighlightColor: UIColor.random(),
                instructionColor: UIColor.random(),
                subheadlineColor: UIColor.random(),
                placeholderColor: UIColor.random(),
                viewControllerBackgroundColor: UIColor.random(),
                textFieldBackgroundColor: UIColor.random(),
                navBarImage: UIImage(color: UIColor.random()),
                navBarBadgeColor: UIColor.random(),
                navBarBackgroundColor: UIColor.random()
            )
            return wpAuthStyle
        }
    }

    static func wordPressAuthenticatorUnifiedStyle(_ style: AuthenticatorStyleType) -> WordPressAuthenticatorUnifiedStyle {
        var wpUnifiedAuthStyle: WordPressAuthenticatorUnifiedStyle!

        switch style {
        case .random:
            wpUnifiedAuthStyle = WordPressAuthenticatorUnifiedStyle(
                borderColor: UIColor.random(),
                errorColor: UIColor.random(),
                textColor: UIColor.random(),
                textSubtleColor: UIColor.random(),
                textButtonColor: UIColor.random(),
                textButtonHighlightColor: UIColor.random(),
                viewControllerBackgroundColor: UIColor.random(),
                navBarBackgroundColor: UIColor.random(),
                navButtonTextColor: UIColor.random(),
                navTitleTextColor: UIColor.random()
            )
            return wpUnifiedAuthStyle
        }
    }

    static func getWordpressAuthenticator() -> WordPressAuthenticator {
        return WordPressAuthenticator(
            configuration: wordPressAuthenticatorConfiguration(),
            style: wordPressAuthenticatorStyle(.random),
            unifiedStyle: wordPressAuthenticatorUnifiedStyle(.random),
            displayImages: WordPressAuthenticatorDisplayImages.defaultImages,
            displayStrings: WordPressAuthenticatorDisplayStrings.defaultStrings)
    }

    @objc(initializeWordPressAuthenticator)
    public static func initializeWordPressAuthenticator() {
        WordPressAuthenticator.initialize(
            configuration: wordPressAuthenticatorConfiguration(),
            style: wordPressAuthenticatorStyle(.random),
            unifiedStyle: wordPressAuthenticatorUnifiedStyle(.random),
            displayImages: WordPressAuthenticatorDisplayImages.defaultImages,
            displayStrings: WordPressAuthenticatorDisplayStrings.defaultStrings)
    }
}

enum AuthenticatorStyleType {
    case random
}

extension CGFloat {
    static func random() -> CGFloat {
        return CGFloat(arc4random()) / CGFloat(UInt32.max)
    }
}

extension UIColor {
    static func random() -> UIColor {
        return UIColor(
            red: .random(),
            green: .random(),
            blue: .random(),
            alpha: 1.0
        )
    }
}
