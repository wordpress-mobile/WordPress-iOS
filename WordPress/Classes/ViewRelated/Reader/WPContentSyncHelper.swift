import UIKit


@objc protocol WPContentSyncHelperDelegate: NSObjectProtocol {
    func syncHelper(syncHelper:WPContentSyncHelper, syncContentWithUserInteraction userInteraction: Bool, success: ((count: Int) -> Void)?, failure: ((error: NSError) -> Void)?)
    func syncHelper(syncHelper:WPContentSyncHelper, syncMoreWithSuccess success: ((count: Int) -> Void)?, failure: ((error: NSError) -> Void)?)
    optional func syncContentEnded()
    optional func hasNoMoreContent()
}


class WPContentSyncHelper: NSObject {

    weak var delegate: WPContentSyncHelperDelegate?
    var isSyncing:Bool = false
    var isLoadingMore:Bool = false
    var hasMoreContent:Bool = true {
        didSet {
            if hasMoreContent == oldValue {
                return
            }
            if hasMoreContent == false {
                delegate?.hasNoMoreContent?()
            }
        }
    }


    // MARK: - Syncing

    func syncContent() -> Bool {
        return syncContentWithUserInteraction(false)
    }


    func syncContentWithUserInteraction() -> Bool {
        return syncContentWithUserInteraction(true)
    }


    func syncContentWithUserInteraction(userInteraction:Bool) -> Bool {
        if isSyncing {
            return false
        }

        isSyncing = true

        delegate?.syncHelper(self, syncContentWithUserInteraction: userInteraction, success: {
            [weak self] (count: Int) -> Void in
            if let weakSelf = self {
                weakSelf.hasMoreContent = (count > 0)
                weakSelf.syncContentEnded()
            }
        }, failure: {
            [weak self] (error: NSError) -> Void in
            if let weakSelf = self {
                weakSelf.syncContentEnded()
            }
        })

        return true
    }


    func syncMoreContent() -> Bool {
        if isSyncing {
            return false
        }

        isSyncing = true
        isLoadingMore = true

        delegate?.syncHelper(self, syncMoreWithSuccess: {
            [weak self] (count: Int) -> Void in
            if let weakSelf = self {
                weakSelf.hasMoreContent = (count > 0)
                weakSelf.syncContentEnded()
            }
        }, failure: {
            [weak self] (error: NSError) -> Void in
            if let weakSelf = self {
                weakSelf.syncContentEnded()
            }
        })

        return true
    }


    // MARK: - Private Methods

    private func syncContentEnded() {
        isSyncing = false
        isLoadingMore = false

        delegate?.syncContentEnded?()
    }

}
