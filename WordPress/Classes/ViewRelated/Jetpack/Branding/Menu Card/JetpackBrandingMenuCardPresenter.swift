import Foundation

class JetpackBrandingMenuCardPresenter {

    struct Config {
        let description: String
        let learnMoreButtonURL: String?
    }

    // MARK: Private Variables

    private let remoteConfigStore: RemoteConfigStore
    private let persistenceStore: UserPersistentRepository
    private let featureFlagStore: RemoteFeatureFlagStore
    private let currentDateProvider: CurrentDateProvider

    // MARK: Initializers

    init(remoteConfigStore: RemoteConfigStore = RemoteConfigStore(),
         featureFlagStore: RemoteFeatureFlagStore = RemoteFeatureFlagStore(),
         persistenceStore: UserPersistentRepository = UserDefaults.standard,
         currentDateProvider: CurrentDateProvider = DefaultCurrentDateProvider()) {
        self.remoteConfigStore = remoteConfigStore
        self.featureFlagStore = featureFlagStore
        self.persistenceStore = persistenceStore
        self.currentDateProvider = currentDateProvider
    }

    // MARK: Public Functions

    func cardConfig() -> Config? {
        let phase = JetpackFeaturesRemovalCoordinator.generalPhase(featureFlagStore: featureFlagStore)
        switch phase {
        case .three:
            let description = Strings.phaseThreeDescription
            let url = RemoteConfig(store: remoteConfigStore).phaseThreeBlogPostUrl.value
            return .init(description: description, learnMoreButtonURL: url)
        default:
            return nil
        }
    }

    func shouldShowCard() -> Bool {
        let showCardOnDate = showCardOnDate ?? .distantPast // If not set, then return distant past so that the condition below always succeeds
        guard shouldHideCard == false, // Card not hidden
              showCardOnDate < currentDateProvider.date(), // Interval has passed if temporarily hidden
              let _ = cardConfig() else { // Card is enabled in the current phase
            return false
        }
        return true
    }

    func remindLaterTapped() {
        let now = currentDateProvider.date()
        let duration = Constants.remindLaterDurationInDays * Constants.secondsInDay
        let newDate = now.addingTimeInterval(TimeInterval(duration))
        showCardOnDate = newDate
    }

    func hideThisTapped() {
        shouldHideCard = true
    }
}

private extension JetpackBrandingMenuCardPresenter {
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

private extension JetpackBrandingMenuCardPresenter {
    enum Constants {
        static let secondsInDay = 86_400
        static let remindLaterDurationInDays = 7
        static let shouldHideCardKey = "JetpackBrandingShouldHideCardKey"
        static let showCardOnDateKey = "JetpackBrandingShowCardOnDateKey"
    }

    enum Strings {
        static let phaseThreeDescription = NSLocalizedString("jetpack.menuCard.description",
                                                           value: "Stats, Reader, Notifications and other features will move to the Jetpack mobile app soon.",
                                                           comment: "Description inside a menu card communicating that features are moving to the Jetpack app.")
    }
}
