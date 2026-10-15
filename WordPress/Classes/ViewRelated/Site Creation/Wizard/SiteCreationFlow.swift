/// The sequence of steps a site creation run goes through.
enum SiteCreationFlow {
    /// Intent, design, address, plan, and assembly.
    case current
    /// Address, plan, and assembly. Creates a blank site. Jetpack only.
    case short

    /// The flow name sent as `site_creation_flow` on site creation events. WordPress.com stores the same name on
    /// the sites it creates; `SiteCreator` decides what the request sends.
    var name: String {
        switch self {
        case .current: "mobile"
        case .short: "mobile-blank"
        }
    }
}
