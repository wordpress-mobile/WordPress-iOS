enum JetpackPlugin: String {
    case search     = "jetpack-search"
    case backup     = "jetpack-backup"
    case protect    = "jetpack-protect"
    case videoPress = "jetpack-videopress"
    case social     = "jetpack-social"
    case boost      = "jetpack-boost"
    case multiple

    var displayName: String {
        switch self {
        case .search:
            return "Jetpack Search"
        case .backup:
            return "Jetpack VaultPress Backup"
        case .protect:
            return "Jetpack Protect"
        case .videoPress:
            return "Jetpack VideoPress"
        case .social:
            return "Jetpack Social"
        case .boost:
            return "Jetpack Boost"
        case .multiple:
            return ""
        }
    }
}
