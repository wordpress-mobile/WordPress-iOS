import Foundation


class PageContentSyncHelper: WPContentSyncHelper {
    override func syncContentEnded(error: Bool) {
        isSyncing = false
        isLoadingMore = false

        if error {
            delegate?.syncContentFailed?(self)
            return
        }

        if hasMoreContent {
            syncMoreContent()
        } else {
            delegate?.syncContentEnded?(self)
        }
    }
}
