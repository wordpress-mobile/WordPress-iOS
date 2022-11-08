import Foundation

class JetpackOverlayFrequencyTracker {

    private let frequencyConfig: FrequencyConfig
    private let source: JetpackFeaturesRemovalCoordinator.OverlaySource
    private let persistenceStore: UserPersistentRepository

    private var lastSavedGenericDate: Date? {
        get {
            let key = Constants.lastDateKeyPrefix
            return persistenceStore.object(forKey: key) as? Date
        }
        set {
            let key = Constants.lastDateKeyPrefix
            persistenceStore.set(newValue, forKey: key)
        }
    }

    private var lastSavedSourceDate: Date? {
        get {
            let sourceKey = "\(Constants.lastDateKeyPrefix)-\(source.rawValue)"
            return persistenceStore.object(forKey: sourceKey) as? Date
        }
        set {
            let sourceKey = "\(Constants.lastDateKeyPrefix)-\(source.rawValue)"
            persistenceStore.set(newValue, forKey: sourceKey)
        }
    }

    init(frequencyConfig: FrequencyConfig = .defaultConfig,
         source: JetpackFeaturesRemovalCoordinator.OverlaySource,
         persistenceStore: UserPersistentRepository = UserDefaults.standard) {
        self.frequencyConfig = frequencyConfig
        self.source = source
        self.persistenceStore = persistenceStore
    }

    func shouldShow() -> Bool {
        guard let lastSavedGenericDate = lastSavedGenericDate,
              let lastSavedSourceDate = lastSavedSourceDate else {
            return true
        }

        switch source {
        case .stats:
            fallthrough
        case .notifications:
            fallthrough
        case .reader:
            // Check frequencies for features
            return frequenciesPassed(lastSavedGenericDate: lastSavedGenericDate,
                                     lastSavedSourceDate: lastSavedSourceDate)
        case .card:
            return true // Always show for card
        case .login:
            fallthrough
        case .appOpen:
            return false // Show once for login and app open
        }
    }

    func track() {
        let date = Date()
        lastSavedSourceDate = date
        lastSavedGenericDate = date
    }

    private func frequenciesPassed(lastSavedGenericDate: Date, lastSavedSourceDate: Date) -> Bool {
        let secondsSinceLastSavedSourceDate = lastSavedSourceDate.timeIntervalSinceNow
        let secondsSinceLastSavedGenericDate = lastSavedGenericDate.timeIntervalSinceNow
        let featureSpecificFreqPassed = secondsSinceLastSavedSourceDate > frequencyConfig.featureSpecificInSeconds
        let generalFreqPassed = secondsSinceLastSavedGenericDate > frequencyConfig.generalInSeconds
        return generalFreqPassed && featureSpecificFreqPassed
    }
}

extension JetpackOverlayFrequencyTracker {
    struct FrequencyConfig {
        // MARK: Instance Variables
        let featureSpecificInDays: Int
        let generalInDays: Int

        // MARK: Static Variables
        static let defaultConfig = FrequencyConfig(featureSpecificInDays: 0, generalInDays: 0)
        private static let secondsInDay: TimeInterval = 86_400

        // MARK: Computed Variables
        var featureSpecificInSeconds: TimeInterval {
            return TimeInterval(featureSpecificInDays) * Self.secondsInDay
        }

        var generalInSeconds: TimeInterval {
            return TimeInterval(generalInDays) * Self.secondsInDay
        }
    }

    enum Constants {
        static let lastDateKeyPrefix = "JetpackOverlayLastDate"
    }
}
