import Foundation

public class HomepageSettingsServiceRemote: ServiceRemoteWordPressComREST {

    /**
     Sets the homepage type for the specified site.
     - Parameters:
        - type: The type of homepage to use: blog posts (.posts), or static pages (.page).
        - siteID: The ID of the site to update
        - postsPageID: The ID of the page to use as the blog page if the homepage type is .page
        - homePageID: The ID of the page to use as the homepage is the homepage type is .pag
        - success: Completion block called after the settings have been successfully updated
        - failure: Failure block called if settings were not successfully updated
     */
    public func setHomepageType(type: RemoteHomepageType, for siteID: Int, withPostsPageID postsPageID: Int? = nil, homePageID: Int? = nil, success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        let endpoint = "sites/\(siteID)/homepage"
        let path = self.path(forEndpoint: endpoint, withVersion: ._1_1)

        var parameters: [String: AnyObject] = [Keys.isPageOnFront: type.isPageOnFront as AnyObject]

        if let homePageID = homePageID {
            parameters[Keys.pageOnFrontID] = homePageID as AnyObject
        }

        if let postsPageID = postsPageID {
            parameters[Keys.pageForPostsID] = postsPageID as AnyObject
        }

        wordPressComRESTAPI.post(path, parameters: parameters,
                                success: { _, _ in
            success()
        }, failure: { error, _ in
            failure(error)
        })
    }

    private enum Keys {
        static let isPageOnFront = "is_page_on_front"
        static let pageOnFrontID = "page_on_front_id"
        static let pageForPostsID = "page_for_posts_id"
    }
}
