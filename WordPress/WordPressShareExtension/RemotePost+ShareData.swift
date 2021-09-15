import Foundation
import WordPressKit

extension RemotePost {

    /// Create a new Remote Post from the data provided by the Share and Action extensions.
    /// - Parameters:
    ///   - shareData: The data from which to create the Remote Post
    ///   - siteID: Site ID the post will be uploaded to
    convenience init(shareData: ShareData, siteID: Int) {
        self.init(siteID: NSNumber(value: siteID),
                  status: shareData.postStatus.rawValue,
                  title: shareData.title,
                  content: shareData.contentBody)

        switch shareData.postType {
        case .post:
            type = "post"
            if let remoteTags = shareData.tags {
                tags = remoteTags.arrayOfTags()
            }

            if let remoteCategories = RemotePostCategory.remotePostCategoriesFromString(shareData.selectedCategoriesIDString) {
                categories = remoteCategories
            }
        case .page:
            type = "page"
        }
    }
}
