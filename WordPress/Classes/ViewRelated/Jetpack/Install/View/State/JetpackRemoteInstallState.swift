enum JetpackRemoteInstallState: Equatable {
    case install
    case installing
    case failure(JetpackInstallError)
    case success

    var title: String {
        switch self {
        case .install:
            return AppLocalizedString("Install Jetpack", comment: "The default Jetpack view title")
        case .installing:
            return AppLocalizedString("Installing Jetpack", comment: "The Jetpack view title used while the is installing")
        case .failure:
            return AppLocalizedString("There was a problem", comment: "The Jetpack view title used when an error occurred")
        case .success:
            return AppLocalizedString("Jetpack installed", comment: "The Jetpack view title for the success state")
        }
    }

    var message: String {
        switch self {
        case .install:
            return AppLocalizedString("Your website credentials will not be stored and are used only for the purpose of installing Jetpack.",
                                     comment: "The default Jetpack view message")
        case .installing:
            return AppLocalizedString("Installing Jetpack on your site. This can take up to a few minutes to complete.",
                                     comment: "The Jetpack view message used while the state is installing")
        case .success:
            return AppLocalizedString("Now that Jetpack is installed, we just need to get you set up. This will only take a minute.",
                                     comment: "The default Jetpack view message for the success state")
        case .failure:
            return AppLocalizedString("Jetpack could not be installed at this time.",
                                     comment: "The default Jetpack view message used when an error occurred")
        }
    }

    var buttonTitle: String {
        switch self {
        case .failure:
            return AppLocalizedString("Retry", comment: "The Jetpack view button title used when an error occurred")
        case .success:
            return AppLocalizedString("Set up", comment: "The Jetpack view button title for the success state")
        default:
            return AppLocalizedString("Continue", comment: "The default Jetpack view button title")
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
