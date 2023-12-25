enum DashboardDynamicCardAnalyticsEvent {

    case cardShown(id: String)
    case cardHideTapped(id: String)
    case cardTapped(id: String, url: String)
    case cardCtaTapped(id: String, url: String)

    var name: String {
        switch self {
        case .cardShown: return "dynamic_dashboard_card_shown"
        case .cardHideTapped: return "dynamic_dashboard_card_hide_tapped"
        case .cardTapped: return "dynamic_dashboard_card_tapped"
        case .cardCtaTapped: return "dynamic_dashboard_card_cta_tapped"
        }
    }

    var properties: [String: String] {
        switch self {
        case .cardShown(let id), .cardHideTapped(let id):
            return [Keys.id: id]
        case .cardTapped(let id, let url), .cardCtaTapped(let id, let url):
            return [Keys.id: id, Keys.url: url]
        }
    }

    private enum Keys {
        static let id = "id"
        static let url = "url"
    }
}
