// MARK: - WordPress Authenticator Display Images
//
public struct WordPressAuthenticatorDisplayImages {
    public let magicLink: UIImage
    public let siteAddressModalPlaceholder: UIImage

    /// Designated initializer.
    ///
    public init(magicLink: UIImage, siteAddressModalPlaceholder: UIImage) {
        self.magicLink = magicLink
        self.siteAddressModalPlaceholder = siteAddressModalPlaceholder
    }
}

public extension WordPressAuthenticatorDisplayImages {
    static var defaultImages: WordPressAuthenticatorDisplayImages {
        return WordPressAuthenticatorDisplayImages(
            magicLink: .magicLinkImage,
            siteAddressModalPlaceholder: .siteAddressModalPlaceholder
        )
    }
}
