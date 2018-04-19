import Foundation

extension BlogDetailsViewController: SearchableActivityConvertable {
    var activityType: String {
        return WPActivityType.siteDetails.rawValue
    }

    var activityTitle: String {
        if let siteName = siteName {
            return siteName
        } else if let displayURL = displayURL {
            return displayURL
        }

        return NSLocalizedString("My Site",
                                 comment: "Generic name for the detail screen for specific site - used for spotlight indexing on iOS. Note: this is only used if we cannot determine a name chances of this being used are small.")
    }

    var activityKeywords: Set<String>? {
        let keyWordString = NSLocalizedString("wordpress, site, blog", comment: "This is a comma separated list of keywords used for spotlight indexing of the 'My Sites' tab.")
        var keywordArray = keyWordString.arrayOfTags()

        if let siteName = siteName {
            keywordArray.append(siteName)
        }

        if let displayURL = displayURL {
            keywordArray.append(displayURL)
        }

        guard !keywordArray.isEmpty else {
            return nil
        }

        return Set(keywordArray)
    }

    private var siteName: String? {
        guard let blogName = blog.settings?.name, blogName.isEmpty == false else {
            return nil
        }
        return blogName
    }

    private var displayURL: String? {
        guard let displayURL = blog.displayURL as String?, displayURL.isEmpty == false else {
            return nil
        }
        return displayURL
    }

    @objc func createUserActivity() {
        // FIXME: Store site ID in user data
        registerUserActivity()
    }
}
