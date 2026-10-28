import Foundation
import WordPressData
import WordPressShared

class JetpackBrandingMenuCardPresenter {

    struct Config {

        enum CardType {
            case compact, expanded
        }

        let description: String
        let type: CardType
    }

    // MARK: Private Variables

    private let blog: Blog?
    private let persistenceStore: UserPersistentRepository
    private let currentDateProvider: CurrentDateProvider
    private let phaseProvider: () -> JetpackFeaturesRemovalCoordinator.GeneralPhase
    private var phase: JetpackFeaturesRemovalCoordinator.GeneralPhase {
        phaseProvider()
    }

    // MARK: Initializers

    init(
        blog: Blog?,
        phaseProvider: @escaping () -> JetpackFeaturesRemovalCoordinator.GeneralPhase = {
            JetpackFeaturesRemovalCoordinator.generalPhase()
        },
        persistenceStore: UserPersistentRepository = UserDefaults.standard,
        currentDateProvider: CurrentDateProvider = DefaultCurrentDateProvider()
    ) {
        self.blog = blog
        self.persistenceStore = persistenceStore
        self.currentDateProvider = currentDateProvider
        self.phaseProvider = phaseProvider
    }

    // MARK: Public Functions

    func cardConfig() -> Config? {
        guard phase == .selfHosted else {
            return nil
        }
        return .init(description: Strings.selfHostedPhaseDescription, type: .expanded)
    }

    func shouldShowTopCard() -> Bool {
        guard isCardEnabled() else {
            return false
        }
        let jetpackFeaturesEnabled = JetpackFeaturesRemovalCoordinator.shouldShowJetpackFeatures()
        guard phase == .selfHosted, !jetpackFeaturesEnabled else {
            return false
        }
        return blog?.jetpackIsConnected ?? false
    }

    private func isCardEnabled() -> Bool {
        let showCardOnDate = showCardOnDate ?? .distantPast // If not set, then return distant past so that the condition below always succeeds
        guard shouldHideCard == false, // Card not hidden
            showCardOnDate < currentDateProvider.date()
        else { // Interval has passed if temporarily hidden
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
        [Constants.phaseAnalyticsKey: phase.rawValue]
    }
}

private extension JetpackBrandingMenuCardPresenter {

    // MARK: Dynamic Keys

    var shouldHideCardKey: String {
        "\(Constants.shouldHideCardKey)-\(phase.rawValue)"
    }

    var showCardOnDateKey: String {
        "\(Constants.showCardOnDateKey)-\(phase.rawValue)"
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
        // Keeps the `newUsers` key so existing translations still apply.
        static let selfHostedPhaseDescription = NSLocalizedString(
            "jetpack.menuCard.newUsers.title",
            value: "Unlock your site’s full potential. Get Stats, Reader, Notifications and more with Jetpack.",
            comment: "Description inside a menu card prompting users to switch to the Jetpack app."
        )
    }
}
