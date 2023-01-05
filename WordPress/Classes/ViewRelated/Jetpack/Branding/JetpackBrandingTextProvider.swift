import Foundation

struct JetpackBrandingTextProvider {

    // MARK: Private Variables

    // MARK: Initializer

    init() {}

    // MARK: Public Functions

    func brandingText() -> String {
        return Strings.defaultText
    }
}

private extension JetpackBrandingTextProvider {
    enum Strings {
        static let defaultText = NSLocalizedString("jetpack.branding.badge_banner.title",
                                                   value: "Jetpack powered",
                                                   comment: "Title of the Jetpack powered badge.")
    }
}
