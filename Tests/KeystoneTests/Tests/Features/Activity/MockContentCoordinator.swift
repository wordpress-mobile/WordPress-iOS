
@testable import WordPress

class MockContentCoordinator: ContentCoordinator {

    var readerWasDisplayed = false
    var readerPostID: NSNumber?
    var readerSiteID: NSNumber?
    func displayReaderWithPostId(_ postID: NSNumber?, siteID: NSNumber?) throws {
        readerWasDisplayed = true
        readerPostID = postID
        readerSiteID = siteID
    }

    var commentsWasDisplayed = false
    var commentPostID: NSNumber?
    var commentSiteID: NSNumber?
    func displayCommentsWithPostId(_ postID: NSNumber?, siteID: NSNumber?, commentID: NSNumber?, source: ReaderCommentsSource) throws {
        commentsWasDisplayed = true
        commentPostID = postID
        commentSiteID = siteID
    }

    func displayStatsWithSiteID(_ siteID: NSNumber?, url: URL? = nil) throws {

    }

    func displayFollowersWithSiteID(_ siteID: NSNumber?, expirationTime: TimeInterval) throws {

    }

    func displayBackupWithSiteID(_ siteID: NSNumber?) throws {

    }

    func displayScanWithSiteID(_ siteID: NSNumber?) throws {

    }

    var streamWasDisplayed = false
    var streamSiteID: NSNumber?
    func displayStreamWithSiteID(_ siteID: NSNumber?) throws {
        streamWasDisplayed = true
        streamSiteID = siteID
    }

    func displayWebViewWithURL(_ url: URL, source: String) {

    }

    func displayFullscreenImage(_ image: UIImage) {

    }

    func displayPlugin(withSlug pluginSlug: String, on siteSlug: String) throws {

    }
}
