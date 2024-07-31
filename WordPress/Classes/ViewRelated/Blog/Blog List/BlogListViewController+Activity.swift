import Foundation
import WordPressAuthenticator
import ViewLayer
import SwiftUI

extension BlogListViewController: SearchableActivityConvertable {
    @objc func showLoginForSelfHostedSite() {
        setEditing(false, animated: false)
//        WordPressAuthenticator.showLoginForSelfHostedSite(self)

        guard let navigationController = self.navigationController else {
            return
        }

        LoginClient.displaySelfHostedLoginView(in: navigationController)
    }

    var activityType: String {
        return WPActivityType.siteList.rawValue
    }

    var activityTitle: String {
        return NSLocalizedString("My Sites", comment: "Title of the 'My Sites' tab - used for spotlight indexing on iOS.")
    }

    var activityKeywords: Set<String>? {
        let keyWordString = NSLocalizedString("wordpress, sites, site, blogs, blog", comment: "This is a comma separated list of keywords used for spotlight indexing of the 'My Sites' tab.")
        let keywordArray = keyWordString.arrayOfTags()

        guard !keywordArray.isEmpty else {
            return nil
        }

        return Set(keywordArray)
    }

    @objc func createUserActivity() {
        registerUserActivity()
    }
}
