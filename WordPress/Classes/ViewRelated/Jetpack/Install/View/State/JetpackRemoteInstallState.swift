enum JetpackRemoteInstallState: Equatable {
    case install
    case installing
    case failure(JetpackInstallError)
    case success

    var title: String {
        switch self {
        case .install:
            return NSLocalizedString("Install Jetpack", comment: "The default Jetpack view title")
        case .installing:
            return NSLocalizedString("Installing Jetpack", comment: "The Jetpack view title used while the is installing")
        case .failure:
            return NSLocalizedString("There was a problem", comment: "The Jetpack view title used when an error occurred")
        case .success:
            return NSLocalizedString("Jetpack installed", comment: "The Jetpack view title for the success state")
        }
    }

    var message: String {
        switch self {
        case .install:
            return NSLocalizedString("Your website credentials will not be stored and are used only for the purpose of installing Jetpack.",
                                     comment: "The default Jetpack view message")
        case .installing:
            return NSLocalizedString("Installing Jetpack on your site. This can take up to a few minutes to complete.",
                                     comment: "The Jetpack view message used while the state is installing")
        case .success:
            return NSLocalizedString("Now that Jetpack is installed, we just need to get you set up. This will only take a minute.",
                                     comment: "The default Jetpack view message for the success state")
        case .failure:
            return NSLocalizedString("Jetpack could not be installed at this time.",
                                     comment: "The default Jetpack view message used when an error occurred")
        }
    }

    var buttonTitle: String {
        switch self {
        case .failure:
            return NSLocalizedString("Retry", comment: "The Jetpack view button title used when an error occurred")
        case .success:
            return NSLocalizedString("Set up", comment: "The Jetpack view button title for the success state")
        default:
            return NSLocalizedString("Continue", comment: "The default Jetpack view button title")
        }
    }

    var image: UIImage? {
        switch self {
        case .failure:
            return UIImage(named: "jetpack-install-error")
        default:
            return UIImage(named: "jetpack-install-logo")
        }
    }
}
