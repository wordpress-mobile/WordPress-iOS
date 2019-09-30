extension JetpackInstallError {

    /// If the error is blocking,
    /// use the webview as fallback to install Jetpack
    var isBlockingError: Bool {
        switch self.type {
        case .loginFailure, .siteIsJetpack, .unknown:
            return false
        default:
            return true
        }
    }
}
