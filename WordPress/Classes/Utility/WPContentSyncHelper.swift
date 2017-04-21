import UIKit


@objc protocol WPContentSyncHelperDelegate: NSObjectProtocol {
    func syncHelper(_ syncHelper: WPContentSyncHelper, syncContentWithUserInteraction userInteraction: Bool, success: ((_ hasMore: Bool) -> Void)?, failure: ((_ error: NSError) -> Void)?)
    func syncHelper(_ syncHelper: WPContentSyncHelper, syncMoreWithSuccess success: ((_ hasMore: Bool) -> Void)?, failure: ((_ error: NSError) -> Void)?)
    @objc optional func syncContentEnded()
    @objc optional func syncContentFailed()
    @objc optional func hasNoMoreContent()
}


class WPContentSyncHelper: NSObject {

    weak var delegate: WPContentSyncHelperDelegate?
    var isSyncing: Bool = false
    var isLoadingMore: Bool = false
    var hasMoreContent: Bool = true {
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

    @discardableResult func syncContent() -> Bool {
        return syncContentWithUserInteraction(false)
    }


    @discardableResult func syncContentWithUserInteraction() -> Bool {
        return syncContentWithUserInteraction(true)
    }


    @discardableResult func syncContentWithUserInteraction(_ userInteraction: Bool) -> Bool {
        if isSyncing {
            return false
        }

        isSyncing = true

        delegate?.syncHelper(self, syncContentWithUserInteraction: userInteraction, success: {
            [weak self] (hasMore: Bool) -> Void in
            if let weakSelf = self {
                weakSelf.hasMoreContent = hasMore
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


    @discardableResult func syncMoreContent() -> Bool {
        if isSyncing {
            return false
        }

        isSyncing = true
        isLoadingMore = true

        delegate?.syncHelper(self, syncMoreWithSuccess: {
            [weak self] (hasMore: Bool) in
            if let weakSelf = self {
                weakSelf.hasMoreContent = hasMore
                weakSelf.syncContentEnded()
            }
        }, failure: {
            [weak self] (error: NSError) in
            DDLogSwift.logInfo("Error syncing more: \(error)")
            if let weakSelf = self {
                weakSelf.syncContentEnded(error: true)
            }
        })

        return true
    }

    func backgroundSync(success: (() -> Void)?, failure: ((_ error: NSError?) -> Void)?) {
        if isSyncing {
            success?()
            return
        }

        isSyncing = true

        delegate?.syncHelper(self, syncContentWithUserInteraction: false, success: {
                [weak self] (hasMore: Bool) -> Void in
                if let weakSelf = self {
                    weakSelf.hasMoreContent = hasMore
                    weakSelf.syncContentEnded()
                }
                success?()
            }, failure: {
                [weak self] (error: NSError) -> Void in
                if let weakSelf = self {
                    weakSelf.syncContentEnded()
                }
                failure?(error)
        })
    }

    // MARK: - Private Methods

    fileprivate func syncContentEnded(error: Bool = false) {
        isSyncing = false
        isLoadingMore = false

        if error {
            delegate?.syncContentFailed?()
        } else {
            delegate?.syncContentEnded?()
        }
    }

}
