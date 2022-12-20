import Foundation

class JetpackOverlayFrequencyTracker {

    private let frequencyConfig: FrequencyConfig
    private let phaseString: String
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
            let sourceKey = "\(Constants.lastDateKeyPrefix)-\(source.rawValue)-\(phaseString)"
            return persistenceStore.object(forKey: sourceKey) as? Date
        }
        set {
            let sourceKey = "\(Constants.lastDateKeyPrefix)-\(source.rawValue)-\(phaseString)"
            persistenceStore.set(newValue, forKey: sourceKey)
        }
    }

    init(frequencyConfig: FrequencyConfig = .defaultConfig,
         phaseString: String = "",
         source: JetpackFeaturesRemovalCoordinator.OverlaySource,
         persistenceStore: UserPersistentRepository = UserDefaults.standard) {
        self.frequencyConfig = frequencyConfig
        self.phaseString = phaseString
        self.source = source
        self.persistenceStore = persistenceStore
    }

    func shouldShow() -> Bool {
        switch source {
        case .stats:
            fallthrough
        case .notifications:
            fallthrough
        case .reader:
            return frequenciesPassed()
        case .card:
            return true
        case .login:
            fallthrough
        case .appOpen:
            return lastSavedSourceDate == nil
        }
    }

    func track() {
        let date = Date()
        lastSavedSourceDate = date
        lastSavedGenericDate = date
    }

    private func frequenciesPassed() -> Bool {
        guard let lastSavedGenericDate = lastSavedGenericDate else {
            return true // First overlay ever
        }
        let secondsSinceLastSavedGenericDate = -lastSavedGenericDate.timeIntervalSinceNow
        let generalFreqPassed = secondsSinceLastSavedGenericDate > frequencyConfig.generalInSeconds
        if generalFreqPassed == false {
            return false // An overlay was shown recently so we can't show one now
        }

        guard let lastSavedSourceDate = lastSavedSourceDate else {
            return true // This specific overlay was never shown, so we can show it
        }

        let secondsSinceLastSavedSourceDate = -lastSavedSourceDate.timeIntervalSinceNow
        let featureSpecificFreqPassed = secondsSinceLastSavedSourceDate > frequencyConfig.featureSpecificInSeconds
        // Check if this specific overlay was shown recently
        return featureSpecificFreqPassed
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
