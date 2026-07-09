import AppIntents

/// The widget configuration intent that lets the user pick which site a stats widget shows.
///
/// Replaces the SiriKit intent of the same name that was generated from `Sites.intentdefinition`.
/// `intentClassName` and the `site` parameter name must not change: the system uses them to
/// migrate widget configurations created with the SiriKit intent, and a mismatch silently resets
/// users' widgets to the default site.
///
/// The localization keys are the app-bundle names of the identifiers Xcode generated for the
/// legacy `.intentdefinition` ("gpCwrM", "ILcGmf"): GlotPress uploads them under the
/// `ios-widget.` prefix, and the downloaded translations land in the app's
/// `Localizable.strings` under those prefixed keys.
///
/// The keys must resolve in two bundles, because the OS picks a different one depending on
/// version (verified on simulators): iOS 26 resolves the widget configuration UI's strings
/// against the app bundle (whose GlotPress-managed `Localizable.strings` carries the prefixed
/// keys in every locale), while iOS 17 resolves against the widget extension bundle, which
/// ships static copies of the same prefixed keys in
/// `Sources/JetpackStatsWidgets/Resources/<locale>.lproj/Localizable.strings`.
/// A nested SPM package resource bundle is never consulted, so the strings cannot live in
/// this package.
public struct SelectSiteIntent: WidgetConfigurationIntent, CustomIntentMigratedAppIntent {
    public static let intentClassName = "SelectSiteIntent"

    public static let title = LocalizedStringResource("ios-widget.gpCwrM", defaultValue: "Select Site")

    // The legacy intent was ineligible for Siri suggestions; keep this
    // configuration-only intent out of Shortcuts and Spotlight the same way.
    public static let isDiscoverable = false

    @Parameter(title: LocalizedStringResource("ios-widget.ILcGmf", defaultValue: "Site"))
    public var site: SiteEntity?

    public init() {}
}
