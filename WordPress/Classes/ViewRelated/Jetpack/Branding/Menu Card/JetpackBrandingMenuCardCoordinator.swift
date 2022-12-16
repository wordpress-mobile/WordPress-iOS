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

class JetpackBrandingMenuCardPresenter {

    // MARK: Private Variables

    private let remoteConfigStore: RemoteConfigStore
    private let persistenceStore: UserPersistentRepository
    private let featureFlagStore: RemoteFeatureFlagStore

    // MARK: Initializers

    init(remoteConfigStore: RemoteConfigStore = RemoteConfigStore(),
         featureFlagStore: RemoteFeatureFlagStore = RemoteFeatureFlagStore(),
         persistenceStore: UserPersistentRepository = UserDefaults.standard) {
        self.remoteConfigStore = remoteConfigStore
        self.featureFlagStore = featureFlagStore
        self.persistenceStore = persistenceStore
    }

    // MARK: Public Functions

    func shouldShowCard() -> Bool {
        return false
    }

    func remindLaterTapped() {
        let now = Date()
        let duration = Constants.remindLaterDurationInDays * Constants.secondInDay
        let newDate = now.addingTimeInterval(TimeInterval(duration))
        showCardOnDate = newDate
    }

    func hideThisTapped() {
        shouldHideCard = true
    }
}

private extension JetpackBrandingMenuCardPresenter {
    enum Constants {
        static let secondInDay = 86_400
        static let remindLaterDurationInDays = 7
        static let shouldHideCardKey = "JetpackBrandingShouldHideCardKey"
        static let showCardOnDateKey = "JetpackBrandingShowCardOnDateKey"
    }

    var shouldHideCard: Bool {
        get {
            persistenceStore.bool(forKey: Constants.shouldHideCardKey)
        }

        set {
            persistenceStore.set(newValue, forKey: Constants.shouldHideCardKey)
        }
    }

    var showCardOnDate: Date? {
        get {
            persistenceStore.object(forKey: Constants.showCardOnDateKey) as? Date
        }

        set {
            persistenceStore.set(newValue, forKey: Constants.showCardOnDateKey)
        }
    }
}
