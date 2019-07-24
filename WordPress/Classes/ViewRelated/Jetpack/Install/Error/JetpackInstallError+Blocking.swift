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

    var message: String {
        switch self.type {
        case .loginFailure:
            return NSLocalizedString("Jetpack could not be installed at this time.",
                                     comment: "The default Jetpack view message used when a 'login failure' error occurred")
        case .siteIsJetpack:
            return NSLocalizedString("Jetpack could not be installed at this time.",
                                     comment: "The default Jetpack view message used when a 'site is Jetpack' error occurred")
        default:
            return NSLocalizedString("Jetpack could not be installed at this time.",
                                     comment: "The default Jetpack view message used when an error occurred")
        }
    }
}
