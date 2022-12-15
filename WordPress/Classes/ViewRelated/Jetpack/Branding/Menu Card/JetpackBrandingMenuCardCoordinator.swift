import Foundation

@objc
class JetpackBrandingMenuCardCoordinator: NSObject {

    struct Config {
        let description: String
        let learnMoreButtonURL: String?
    }

    static var cardConfig: Config? {
        let phase = JetpackFeaturesRemovalCoordinator.generalPhase()
        switch phase {
        case .three:
            let description = Strings.phaseThreeDescription
            let url = RemoteConfig().phaseThreeBlogPostUrl.value
            return .init(description: description, learnMoreButtonURL: url)
        default:
            return nil
        }
    }

    @objc static var shouldShowCard: Bool {
        return cardConfig != nil
    }
}

private extension JetpackBrandingMenuCardCoordinator {
    enum Strings {
        static let phaseThreeDescription = NSLocalizedString("jetpack.menuCard.description",
                                                           value: "Stats, Reader, Notifications and other features will soon move to the Jetpack mobile app.",
                                                           comment: "Description inside a menu card communicating that features are moving to the Jetpack app.")
    }
}
