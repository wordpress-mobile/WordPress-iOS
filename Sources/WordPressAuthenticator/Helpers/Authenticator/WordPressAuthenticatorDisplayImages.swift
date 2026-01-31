// MARK: - WordPress Authenticator Display Images
//
public struct WordPressAuthenticatorDisplayImages {
    public let magicLink: UIImage

    /// Designated initializer.
    ///
    public init(magicLink: UIImage) {
        self.magicLink = magicLink
    }
}

public extension WordPressAuthenticatorDisplayImages {
    static var defaultImages: WordPressAuthenticatorDisplayImages {
        return WordPressAuthenticatorDisplayImages(
            magicLink: .magicLinkImage
        )
    }
}
