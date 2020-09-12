import Foundation

extension NSNotification.Name {
    static let suggestionListUpdated = NSNotification.Name("SuggestionListUpdated")
}

@objc extension NSNotification {
    public static let suggestionListUpdated = NSNotification.Name.suggestionListUpdated
}

// NSCache works with classes such as NSArray, not structs such as Suggestion or [Suggestion].
public class Wrapper<T>: NSObject {
    let value: T
    init(_ value: T) {
        self.value = value
    }
}

@objc public class SuggestionService: NSObject {

    private let suggestionsCache = NSCache<NSNumber, Wrapper<[Suggestion]>>()
    private var siteIDsCurrentlyBeingRequested = [NSNumber]()

    private static let shared = SuggestionService()

    @objc public static func sharedInstance() -> SuggestionService {
        return shared
    }

    private override init() {}

    @objc public func suggestions(for siteID: NSNumber) -> [Suggestion]? {
        if let cachedSuggestions = suggestionsCache.object(forKey: siteID) {
            return cachedSuggestions.value
        }
        updateSuggestions(for: siteID)
        return nil
    }

    private func updateSuggestions(for siteID: NSNumber) {

        // if there is already a request in place for this siteID, just wait
        guard !siteIDsCurrentlyBeingRequested.contains(siteID) else { return }

        // add this siteID to currently being requested list
        siteIDsCurrentlyBeingRequested.append(siteID)

        let suggestPath = "rest/v1.1/users/suggest"
        let context = ContextManager.shared.mainContext
        let accountService = AccountService(managedObjectContext: context)
        let defaultAccount = accountService.defaultWordPressComAccount()
        let params = ["site_id": siteID]

        defaultAccount?.wordPressComRestApi.GET(suggestPath, parameters: params, success: { [weak self] responseObject, httpResponse in
            guard let `self` = self else { return }
            guard let payload = responseObject as? [String: Any] else { return }
            guard let restSuggestions = payload["suggestions"] as? [[String: Any]] else { return }

            let suggestions = restSuggestions.map { Suggestion(dictionary: $0) }
            self.suggestionsCache.setObject(Wrapper(suggestions), forKey: siteID)

            // send the siteID with the notification so it could be filtered out
            NotificationCenter.default.post(name: .suggestionListUpdated, object: siteID)

            // remove siteID from the currently being requested list
            self.siteIDsCurrentlyBeingRequested.removeAll { $0 == siteID}
        }, failure: { [weak self] error, _ in
            guard let `self` = self else { return }

            // remove siteID from the currently being requested list
            self.siteIDsCurrentlyBeingRequested.removeAll { $0 == siteID}

            DDLogVerbose("[Rest API] ! \(error.localizedDescription)")
        })
    }

    @objc func shouldShowSuggestions(for siteID: NSNumber?) -> Bool {
        guard let siteID = siteID, let appDelegate = WordPressAppDelegate.shared else {
            return false
        }

        let suggestions = suggestionsCache.object(forKey: siteID)?.value

        // if the device is offline and suggestion list is not yet retrieved

        if (!appDelegate.connectionAvailable && suggestions == nil) {
            return false
        }

        // if the suggestion list is already retrieved and there is nothing to show
        if let suggestions = suggestions, suggestions.isEmpty {
            return false
        }

        // if the site is not hosted on WordPress.com
        let context = ContextManager.shared.mainContext
        let service = BlogService(managedObjectContext: context)
        let blog = service.blog(byBlogId: siteID)
        return blog?.supports(.mentions) == true
    }
}
