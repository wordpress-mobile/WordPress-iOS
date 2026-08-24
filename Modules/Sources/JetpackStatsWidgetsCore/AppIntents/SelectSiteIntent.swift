#if os(iOS)
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
/// iOS 18 and later resolve the widget configuration UI's strings against the app bundle,
/// whose GlotPress-managed `Localizable.strings` carries the prefixed keys in every locale
/// (verified on simulators; a nested SPM package resource bundle is never consulted).
/// iOS 17 resolves against the widget extension bundle only, with no fallback to the app
/// bundle, so it shows the English default values; we accept English there rather than
/// shipping per-locale copies in the extension.
public struct SelectSiteIntent: WidgetConfigurationIntent, CustomIntentMigratedAppIntent {
    public static let intentClassName = "SelectSiteIntent"

    public static let title = LocalizedStringResource(
        "ios-widget.gpCwrM",
        defaultValue: "Select Site",
        table: "Localizable",
        comment: "Title shown when choosing a site for a widget."
    )

    // The legacy intent was ineligible for Siri suggestions; keep this
    // configuration-only intent out of Shortcuts and Spotlight the same way.
    public static let isDiscoverable = false

    @Parameter(
        title: LocalizedStringResource(
            "ios-widget.ILcGmf",
            defaultValue: "Site",
            table: "Localizable",
            comment: "Label for the site picker when configuring a widget."
        )
    )
    public var site: SiteEntity?

    public init() {}
}
#endif
