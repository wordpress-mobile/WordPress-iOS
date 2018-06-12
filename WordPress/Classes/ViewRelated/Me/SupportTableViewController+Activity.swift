import Foundation

extension SupportTableViewController: SearchableActivityConvertable {
    var activityType: String {
        return WPActivityType.support.rawValue
    }

    var activityTitle: String {
        return NSLocalizedString("Help & Support", comment: "Title of the 'Help & Support' screen within the 'Me' tab - used for spotlight indexing on iOS.")
    }

    var activityKeywords: Set<String>? {
        let keyWordString = NSLocalizedString("wordpress, help, support, faq, questions, debug, logs, help center, contact",
                                              comment: "This is a comma separated list of keywords used for spotlight indexing of the 'Help & Support' screen within the 'Me' tab")
        let keywordArray = keyWordString.arrayOfTags()

        guard !keywordArray.isEmpty else {
            return nil
        }

        return Set(keywordArray)
    }

    func createUserActivity() {
        registerUserActivity()
    }
}
