import Foundation

class AppRatingUtility: NSObject {
    var systemWideSignificantEventCountRequiredForPrompt: Int = 1
    var appReviewUrl: URL = Constants.defaultAppReviewURL

    private let defaults: UserDefaults
    private var sections = [String: Section]()
    private var allPromptingDisabled = false

    static let shared = AppRatingUtility(defaults: UserDefaults.standard)

    init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    func setVersion(_ version: String) {
        let trackingVersion = defaults.string(forKey: Key.currentVersion) ?? version
        defaults.set(version, forKey: Key.currentVersion)

        if (trackingVersion == version) {
            incrementUseCount()
        } else {
            let shouldSkipRating = shouldSkipRatingForCurrentVersion()
            resetValuesForNewVersion()
            resetReviewPromptDisabledStatus()
            if shouldSkipRating {
                checkNewVersionNeedsSkipping()
            }
        }
    }

    func checkIfAppReviewPromptsHaveBeenDisabled(success: (() -> Void)?, failure: (() -> Void)?) {
        let session = URLSession(configuration: URLSessionConfiguration.ephemeral)
        let task = session.dataTask(with: Constants.promptDisabledURL) { [weak self] data, _, error in
            guard let this = self else {
                return
            }

            guard let data = data, error == nil else {
                this.resetReviewPromptDisabledStatus()
                failure?()
                return
            }

            guard let object = try? JSONSerialization.jsonObject(with: data, options: []),
                let response = object as? [String: AnyObject] else {
                    this.resetReviewPromptDisabledStatus()
                    failure?()
                    return
            }

            this.allPromptingDisabled = (response["all-disabled"] as? NSString)?.boolValue ?? false
            for section in this.sections.keys {
                let key = "\(section)-disabled"
                let disabled = (response[key] as? NSString)?.boolValue ?? false
                this.sections[section]?.enabled = !disabled
            }

            if let urlString = response["app-review-url"] as? String,
                !urlString.isEmpty,
                let url = URL(string: urlString) {
                this.appReviewUrl = url
            }

            success?()
        }
        task.resume()
    }

    @objc(registerSection:withSignificantEventCount:)
    func register(section: String, significantEventCount count: Int) {
        sections[section] = Section(significantEventCount: count, enabled: true)
    }

    func unregisterAllSections() {
        sections.removeAll()
    }

    func incrementSignificantEvent() {
        incrementStoredValue(key: Key.significantEventCount)
    }

    @objc(incrementSignificantEventForSection:)
    func incrementSignificantEvent(section: String) {
        guard sections[section] != nil else {
            assertionFailure("Invalid section \(section)")
            return
        }
        let key = significantEventCountKey(section: section)
        incrementStoredValue(key: key)
    }

    func declinedToRateCurrentVersion() {
        defaults.set(true, forKey: Key.declinedToRateCurrentVersion)
        defaults.set(2, forKey: Key.numberOfVersionsToSkipPrompting)
    }

    func gaveFeedbackForCurrentVersion() {
        defaults.set(true, forKey: Key.gaveFeedbackForCurrentVersion)
    }

    func ratedCurrentVersion() {
        defaults.set(true, forKey: Key.ratedCurrentVersion)
    }

    func dislikedCurrentVersion() {
        incrementStoredValue(key: Key.userDislikeCount)
        defaults.set(true, forKey: Key.dislikedCurrentVersion)
        defaults.set(2, forKey: Key.numberOfVersionsToSkipPrompting)
    }

    func likedCurrentVersion() {
        incrementStoredValue(key: Key.userLikeCount)
        defaults.set(true, forKey: Key.likedCurrentVersion)
        defaults.set(1, forKey: Key.numberOfVersionsToSkipPrompting)
    }

    func shouldPromptForAppReview() -> Bool {
        if shouldSkipRatingForCurrentVersion() || allPromptingDisabled {
            return false
        }

        let events = systemWideSignificantEventCount()
        let required = systemWideSignificantEventCountRequiredForPrompt
        return events >= required
    }

    @objc(shouldPromptForAppReviewForSection:)
    func shouldPromptForAppReview(section name: String) -> Bool {
        guard let section = sections[name] else {
            assertionFailure("Invalid section \(name)")
            return false
        }

        if shouldSkipRatingForCurrentVersion() || allPromptingDisabled ||
            !section.enabled {
            return false
        }

        let key = significantEventCountKey(section: name)
        let events = defaults.integer(forKey: key)
        let required = section.significantEventCount
        return events >= required
    }

    func hasUserEverLikedApp() -> Bool {
        return defaults.integer(forKey: Key.userLikeCount) > 0
    }

    func hasUserEverDislikedApp() -> Bool {
        return defaults.integer(forKey: Key.userDislikeCount) > 0
    }

    // MARK: - Private

    private func incrementUseCount() {
        incrementStoredValue(key: Key.useCount)
    }

    private func significantEventCountKey(section: String) -> String {
        return "\(Key.significantEventCount)_\(section)"
    }

    private func resetValuesForNewVersion() {
        defaults.removeObject(forKey: Key.significantEventCount)
        defaults.removeObject(forKey: Key.ratedCurrentVersion)
        defaults.removeObject(forKey: Key.declinedToRateCurrentVersion)
        defaults.removeObject(forKey: Key.gaveFeedbackForCurrentVersion)
        defaults.removeObject(forKey: Key.dislikedCurrentVersion)
        defaults.removeObject(forKey: Key.likedCurrentVersion)
        defaults.removeObject(forKey: Key.skipRatingCurrentVersion)
        for sectionName in sections.keys {
            defaults.removeObject(forKey: significantEventCountKey(section: sectionName))
        }
    }

    private func resetReviewPromptDisabledStatus() {
        allPromptingDisabled = false
        for key in sections.keys {
            sections[key]?.enabled = true
        }
    }

    private func checkNewVersionNeedsSkipping() {
        let toSkip = defaults.integer(forKey: Key.numberOfVersionsToSkipPrompting)
        let skipped = defaults.integer(forKey: Key.numberOfVersionsSkippedPrompting)

        if toSkip > 0 {
            if skipped < toSkip {
                defaults.set(skipped + 1, forKey: Key.numberOfVersionsSkippedPrompting)
                defaults.set(true, forKey: Key.skipRatingCurrentVersion)
            } else {
                defaults.removeObject(forKey: Key.numberOfVersionsSkippedPrompting)
                defaults.removeObject(forKey: Key.numberOfVersionsToSkipPrompting)
            }
        }
    }

    private func shouldSkipRatingForCurrentVersion() -> Bool {
        let interactedWithAppReview = defaults.bool(forKey: Key.ratedCurrentVersion)
            || defaults.bool(forKey: Key.declinedToRateCurrentVersion)
            || defaults.bool(forKey: Key.gaveFeedbackForCurrentVersion)
            || defaults.bool(forKey: Key.likedCurrentVersion)
            || defaults.bool(forKey: Key.dislikedCurrentVersion)
        let skipRatingCurrentVersion = defaults.bool(forKey: Key.skipRatingCurrentVersion)
        return interactedWithAppReview || skipRatingCurrentVersion
    }

    private func incrementStoredValue(key: String) {
        var value = defaults.integer(forKey: key)
        value += 1
        defaults.set(value, forKey: key)
    }

    private func systemWideSignificantEventCount() -> Int {
        var total = defaults.integer(forKey: Key.significantEventCount)
        sections.keys.map(significantEventCountKey).forEach { key in
            total += defaults.integer(forKey: key)
        }
        return total
    }


    // MARK: - Debug

    override var debugDescription: String {
        var state = [String: Any]()
        defaults.dictionaryRepresentation()
            .filter({ key, _ in key.hasPrefix("AppRating") })
            .forEach { key, value in
                let cleanKey = (try? key.removingPrefix(pattern: "AppRatings?")) ?? key
                state[cleanKey] = defaults.object(forKey: key)
        }
        state["SystemWideSignificantEventCountRequiredForPrompt"] = systemWideSignificantEventCountRequiredForPrompt
        state["AllPromptingDisabled"] = allPromptingDisabled
        return "<AppRatingUtility state: \(state), sections: \(sections)>"
    }

    // MARK: - Subtypes

    private struct Section {
        var significantEventCount: Int
        var enabled: Bool
    }

    // MARK: - Constants

    private enum Key {
        static let currentVersion = "AppRatingCurrentVersion"

        static let significantEventCount = "AppRatingSignificantEventCount"
        static let useCount = "AppRatingUseCount"
        static let numberOfVersionsSkippedPrompting = "AppRatingsNumberOfVersionsSkippedPrompt"
        static let numberOfVersionsToSkipPrompting = "AppRatingsNumberOfVersionsToSkipPrompting"
        static let skipRatingCurrentVersion = "AppRatingsSkipRatingCurrentVersion"
        static let ratedCurrentVersion = "AppRatingRatedCurrentVersion"
        static let declinedToRateCurrentVersion = "AppRatingDeclinedToRateCurrentVersion"
        static let gaveFeedbackForCurrentVersion = "AppRatingGaveFeedbackForCurrentVersion"
        static let dislikedCurrentVersion = "AppRatingDislikedCurrentVersion"
        static let likedCurrentVersion = "AppRatingLikedCurrentVersion"
        static let userLikeCount = "AppRatingUserLikeCount"
        static let userDislikeCount = "AppRatingUserDislikeCount"
    }

    private enum Constants {
        static let defaultAppReviewURL = URL(string: "http://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id=335703880&pageNumber=0&sortOrdering=2&type=Purple+Software&mt=8")!
        static let promptDisabledURL = URL(string: "https://api.wordpress.org/iphoneapp/app-review-prompt-check/1.0/")!
    }
}
