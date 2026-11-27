import Foundation

struct JetpackBrandingTextProvider {
    func brandingText() -> String {
        Strings.defaultText
    }
}

private extension JetpackBrandingTextProvider {
    enum Strings {
        static let defaultText = NSLocalizedString(
            "jetpack.branding.badge_banner.title",
            value: "Jetpack powered",
            comment: "Title of the Jetpack powered badge."
        )
    }
}
