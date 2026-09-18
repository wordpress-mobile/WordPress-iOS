import Foundation

/// How much of each row the redesigned posts list shows.
///
/// `condensed` drops the excerpt, the metrics and the hero image. Dropping the
/// metrics also stops them being fetched, so a condensed list makes no
/// per-post stats requests.
enum CustomPostListDensity: String, CaseIterable {
    case comfortable
    case condensed

    var isCondensed: Bool {
        self == .condensed
    }

    var toggled: Self {
        isCondensed ? .comfortable : .condensed
    }

    /// The icon for the toggle button. It shows the density the tap switches
    /// *to*, which is what the accessibility label says.
    var toggleSystemImage: String {
        isCondensed ? "rectangle.expand.vertical" : "rectangle.compress.vertical"
    }

    var toggleAccessibilityLabel: String {
        isCondensed ? Strings.showComfortable : Strings.showCondensed
    }

    // Persisted by hand rather than through `@AppStorage`: a `withAnimation` around an
    // `@AppStorage` write does not animate, because the change reaches the view through
    // UserDefaults outside the animation's transaction. Global rather than per site: a
    // user who wants a dense list wants it everywhere.
    static var stored: Self {
        UserDefaults.standard.string(forKey: storageKey).flatMap(Self.init(rawValue:)) ?? .comfortable
    }

    func store() {
        UserDefaults.standard.set(rawValue, forKey: Self.storageKey)
    }

    private static let storageKey = "custom_post_list_density"
}

private enum Strings {
    static let showCondensed = NSLocalizedString(
        "customPostList.density.showCondensed",
        value: "Show condensed list",
        comment: "Accessibility label for the button that switches the posts list to its condensed density"
    )
    static let showComfortable = NSLocalizedString(
        "customPostList.density.showComfortable",
        value: "Show expanded list",
        comment: "Accessibility label for the button that switches the posts list back to its comfortable density"
    )
}
