@testable import WordPressAuthenticator

extension WordPressAuthenticator {

    static func initializeForTesting() {
        WordPressAuthenticator.initialize(
            configuration: WordPressAuthenticatorConfiguration(
                wpcomClientId: "a",
                wpcomSecret: "b",
                wpcomScheme: "c",
                wpcomTermsOfServiceURL: URL(string: "https://w.org")!,
                googleLoginClientId: "e",
                googleLoginServerClientId: "f",
                googleLoginScheme: "g",
                userAgent: "h"
            ),
            style: WordPressAuthenticatorStyle(
                primaryNormalBackgroundColor: .red,
                primaryNormalBorderColor: .none,
                primaryHighlightBackgroundColor: .orange,
                primaryHighlightBorderColor: .none,
                secondaryNormalBackgroundColor: .yellow,
                secondaryNormalBorderColor: .green,
                secondaryHighlightBackgroundColor: .blue,
                secondaryHighlightBorderColor: .systemIndigo,
                disabledBackgroundColor: .purple,
                disabledBorderColor: .red,
                primaryTitleColor: .orange,
                secondaryTitleColor: .yellow,
                disabledTitleColor: .green,
                disabledButtonActivityIndicatorColor: .blue,
                textButtonColor: .systemIndigo,
                textButtonHighlightColor: .purple,
                instructionColor: .red,
                subheadlineColor: .orange,
                placeholderColor: .yellow,
                viewControllerBackgroundColor: .green,
                textFieldBackgroundColor: .blue,
                navBarImage: UIImage(),
                navBarBadgeColor: .systemIndigo,
                navBarBackgroundColor: .purple
            ),
            unifiedStyle: .none,
            displayImages: WordPressAuthenticatorDisplayImages(
                magicLink: UIImage(),
                siteAddressModalPlaceholder: UIImage()
            ),
            displayStrings: WordPressAuthenticatorDisplayStrings()
        )
    }
}
