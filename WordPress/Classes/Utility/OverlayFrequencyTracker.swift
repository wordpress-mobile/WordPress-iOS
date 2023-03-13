import Foundation

protocol OverlaySource {
    var key: String { get }
    var frequencyType: OverlayFrequencyTracker.FrequencyType { get }
}

class OverlayFrequencyTracker {

    private let source: OverlaySource
    private let type: OverlayType
    private let frequencyConfig: FrequencyConfig
    private let phaseString: String?
    private let persistenceStore: UserPersistentRepository

    private var sourceDateKey: String {
        guard let phaseString = phaseString else {
            return "\(type.rawValue)\(Constants.lastDateKeyPrefix)-\(source.key)"
        }
        return "\(type.rawValue)\(Constants.lastDateKeyPrefix)-\(source.key)-\(phaseString)"
    }

    private var lastSavedGenericDate: Date? {
        get {
            let key = "\(type.rawValue)\(Constants.lastDateKeyPrefix)"
            return persistenceStore.object(forKey: key) as? Date
        }
        set {
            let key = "\(type.rawValue)\(Constants.lastDateKeyPrefix)"
            persistenceStore.set(newValue, forKey: key)
        }
    }

    private var lastSavedSourceDate: Date? {
        get {
            return persistenceStore.object(forKey: sourceDateKey) as? Date
        }
        set {
            persistenceStore.set(newValue, forKey: sourceDateKey)
        }
    }

    init(source: OverlaySource,
         type: OverlayType,
         frequencyConfig: FrequencyConfig = .defaultConfig,
         phaseString: String? = nil,
         persistenceStore: UserPersistentRepository = UserDefaults.standard) {
        self.source = source
        self.type = type
        self.frequencyConfig = frequencyConfig
        self.phaseString = phaseString
        self.persistenceStore = persistenceStore
    }

    func shouldShow(forced: Bool) -> Bool {
        if forced {
            return true
        }
        switch source.frequencyType {
        case .showOnce:
            return lastSavedSourceDate == nil
        case .alwaysShow:
            return true
        case .respectFrequencyConfig:
            return frequenciesPassed()
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

extension OverlayFrequencyTracker {

    enum FrequencyType {
        case showOnce
        case alwaysShow
        case respectFrequencyConfig
    }

    enum OverlayType: String {
        case featuresRemoval = "" // Empty string to make sure the generated keys are backwards compatible
        case blaze
    }

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
