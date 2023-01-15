import Foundation

class JetpackBrandingMenuCardPresenter {

    struct Config {

        enum CardType {
            case compact, expanded
        }

        let description: String
        let learnMoreButtonURL: String?
        let type: CardType
    }

    // MARK: Private Variables

    private let blog: Blog?
    private let remoteConfigStore: RemoteConfigStore
    private let persistenceStore: UserPersistentRepository
    private let currentDateProvider: CurrentDateProvider
    private let featureFlagStore: RemoteFeatureFlagStore
    private var phase: JetpackFeaturesRemovalCoordinator.GeneralPhase {
        return JetpackFeaturesRemovalCoordinator.generalPhase(featureFlagStore: featureFlagStore)
    }

    // MARK: Initializers

    init(blog: Blog?,
         remoteConfigStore: RemoteConfigStore = RemoteConfigStore(),
         featureFlagStore: RemoteFeatureFlagStore = RemoteFeatureFlagStore(),
         persistenceStore: UserPersistentRepository = UserDefaults.standard,
         currentDateProvider: CurrentDateProvider = DefaultCurrentDateProvider()) {
        self.blog = blog
        self.remoteConfigStore = remoteConfigStore
        self.persistenceStore = persistenceStore
        self.currentDateProvider = currentDateProvider
        self.featureFlagStore = featureFlagStore
    }

    // MARK: Public Functions

    func cardConfig() -> Config? {
        switch phase {
        case .three:
            let description = Strings.phaseThreeDescription
            let url = RemoteConfig(store: remoteConfigStore).phaseThreeBlogPostUrl.value
            return .init(description: description, learnMoreButtonURL: url, type: .expanded)
        case .four:
            let description = Strings.phaseFourTitle
            return .init(description: description, learnMoreButtonURL: nil, type: .compact)
        case .newUsers:
            let description = Strings.newUsersPhaseDescription
            let url = RemoteConfig(store: remoteConfigStore).phaseNewUsersBlogPostUrl.value
            return .init(description: description, learnMoreButtonURL: url, type: .expanded)
        case .selfHosted:
            let description = Strings.selfHostedPhaseDescription
            let url = RemoteConfig(store: remoteConfigStore).phaseSelfHostedBlogPostUrl.value
            return .init(description: description, learnMoreButtonURL: url, type: .expanded)
        default:
            return nil
        }
    }

    func shouldShowTopCard() -> Bool {
        guard isCardEnabled() else {
            return false
        }
        switch phase {
        case .three:
            return true
        case .selfHosted:
            return blog?.jetpackIsConnected ?? false
        default:
            return false
        }
    }

    func shouldShowBottomCard() -> Bool {
        guard isCardEnabled() else {
            return false
        }
        switch phase {
        case .four:
            fallthrough
        case .newUsers:
            return true
        default:
            return false
        }
    }

    private func isCardEnabled() -> Bool {
        let showCardOnDate = showCardOnDate ?? .distantPast // If not set, then return distant past so that the condition below always succeeds
        guard shouldHideCard == false, // Card not hidden
              showCardOnDate < currentDateProvider.date() else { // Interval has passed if temporarily hidden
            return false
        }
        return true
    }

    func remindLaterTapped() {
        let now = currentDateProvider.date()
        let duration = Constants.remindLaterDurationInDays * Constants.secondsInDay
        let newDate = now.addingTimeInterval(TimeInterval(duration))
        showCardOnDate = newDate
        trackRemindMeLaterTapped()
    }

    func hideThisTapped() {
        shouldHideCard = true
        trackHideThisTapped()
    }
}

// MARK: Analytics

extension JetpackBrandingMenuCardPresenter {

    func trackCardShown() {
        WPAnalytics.track(.jetpackBrandingMenuCardDisplayed, properties: analyticsProperties)
    }

    func trackLinkTapped() {
        WPAnalytics.track(.jetpackBrandingMenuCardLinkTapped, properties: analyticsProperties)
    }

    func trackCardTapped() {
        WPAnalytics.track(.jetpackBrandingMenuCardTapped, properties: analyticsProperties)
    }

    func trackContextualMenuAccessed() {
        WPAnalytics.track(.jetpackBrandingMenuCardContextualMenuAccessed, properties: analyticsProperties)
    }

    func trackHideThisTapped() {
        WPAnalytics.track(.jetpackBrandingMenuCardHidden, properties: analyticsProperties)
    }

    func trackRemindMeLaterTapped() {
        WPAnalytics.track(.jetpackBrandingMenuCardRemindLater, properties: analyticsProperties)
    }

    private var analyticsProperties: [String: String] {
        let phase = JetpackFeaturesRemovalCoordinator.generalPhase(featureFlagStore: featureFlagStore)
        return [Constants.phaseAnalyticsKey: phase.rawValue]
    }
}

private extension JetpackBrandingMenuCardPresenter {

    // MARK: Dynamic Keys

    var shouldHideCardKey: String {
        return "\(Constants.shouldHideCardKey)-\(phase.rawValue)"
    }

    var showCardOnDateKey: String {
        return "\(Constants.showCardOnDateKey)-\(phase.rawValue)"
    }

    // MARK: Persistence Variables

    var shouldHideCard: Bool {
        get {
            persistenceStore.bool(forKey: shouldHideCardKey)
        }

        set {
            persistenceStore.set(newValue, forKey: shouldHideCardKey)
        }
    }

    var showCardOnDate: Date? {
        get {
            persistenceStore.object(forKey: showCardOnDateKey) as? Date
        }

        set {
            persistenceStore.set(newValue, forKey: showCardOnDateKey)
        }
    }
}

private extension JetpackBrandingMenuCardPresenter {
    enum Constants {
        static let secondsInDay = 86_400
        static let remindLaterDurationInDays = 4
        static let shouldHideCardKey = "JetpackBrandingShouldHideCardKey"
        static let showCardOnDateKey = "JetpackBrandingShowCardOnDateKey"
        static let phaseAnalyticsKey = "phase"
    }

    enum Strings {
        static let phaseThreeDescription = NSLocalizedString("jetpack.menuCard.description",
                                                           value: "Stats, Reader, Notifications and other features will move to the Jetpack mobile app soon.",
                                                           comment: "Description inside a menu card communicating that features are moving to the Jetpack app.")
        static let phaseFourTitle = NSLocalizedString("jetpack.menuCard.phaseFour.title",
                                                           value: "Switch to Jetpack",
                                                           comment: "Title of a button prompting users to switch to the Jetpack app.")
        static let newUsersPhaseDescription = NSLocalizedString("jetpack.menuCard.newUsers.title",
                                                                value: "Unlock your site’s full potential. Get Stats, Reader, Notifications and more with Jetpack.",
                                                                comment: "Description inside a menu card prompting users to switch to the Jetpack app.")
        static let selfHostedPhaseDescription = newUsersPhaseDescription
    }
}
