extension JetpackInstallError {

    /// If the error is blocking,
    /// we should use the webview to install Jetpack
    var isBlockingError: Bool {
        switch self {
        case .loginFailure, .siteIsJetpack, .unknown:
            return false
        default:
            return true
        }
    }
}
