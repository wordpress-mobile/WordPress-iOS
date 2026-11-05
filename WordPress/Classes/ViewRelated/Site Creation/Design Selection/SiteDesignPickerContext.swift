/// Where the design list and preview screens are shown.
enum SiteDesignPickerContext {
    /// The design step of site creation. `createsSite` is `true` when choosing a design ends the flow.
    case siteCreation(createsSite: Bool)
    /// The starter design picker opened from the Dashboard design card, which applies a design to an existing site.
    case dashboard

    /// The `source` property of the design events.
    var analyticsSource: String {
        switch self {
        case .siteCreation: "site_creation"
        case .dashboard: "dashboard"
        }
    }
}
