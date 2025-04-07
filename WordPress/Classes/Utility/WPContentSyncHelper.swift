import UIKit

@objc public protocol WPContentSyncHelperDelegate: NSObjectProtocol {
    func syncHelper(_ syncHelper: WPContentSyncHelper, syncContentWithUserInteraction userInteraction: Bool, success: ((_ hasMore: Bool) -> Void)?, failure: ((_ error: NSError) -> Void)?)
    func syncHelper(_ syncHelper: WPContentSyncHelper, syncMoreWithSuccess success: ((_ hasMore: Bool) -> Void)?, failure: ((_ error: NSError) -> Void)?)
    @objc optional func syncContentStart(_ syncHelper: WPContentSyncHelper)
    @objc optional func syncContentEnded(_ syncHelper: WPContentSyncHelper)
    @objc optional func syncContentFailed(_ syncHelper: WPContentSyncHelper)
    @objc optional func hasNoMoreContent(_ syncHelper: WPContentSyncHelper)
}

public class WPContentSyncHelper: NSObject {

    @objc public weak var delegate: WPContentSyncHelperDelegate?
    @objc public var isSyncing: Bool = false {
        didSet {
            if isSyncing {
                delegate?.syncContentStart?(self)
            }
        }
    }
    @objc public var isLoadingMore: Bool = false
    @objc public var hasMoreContent: Bool = true {
        didSet {
            if hasMoreContent == oldValue {
                return
            }
            if hasMoreContent == false {
                delegate?.hasNoMoreContent?(self)
            }
        }
    }

    // MARK: - Syncing

    @objc @discardableResult
    public func syncContent() -> Bool {
        return syncContentWithUserInteraction(false)
    }

    @objc @discardableResult
    public func syncContentWithUserInteraction() -> Bool {
        return syncContentWithUserInteraction(true)
    }

    @objc @discardableResult
    public func syncContentWithUserInteraction(_ userInteraction: Bool) -> Bool {
        guard !isSyncing else {
            return false
        }

        isSyncing = true

        delegate?.syncHelper(self, syncContentWithUserInteraction: userInteraction, success: {
            [weak self] (hasMore: Bool) -> Void in
            self?.hasMoreContent = hasMore
            self?.syncContentEnded()
        }, failure: {
            [weak self] (error: NSError) -> Void in
            self?.syncContentEnded(error: true)
        })

        return true
    }

    @objc @discardableResult
    public func syncMoreContent() -> Bool {
        guard !isSyncing else {
            return false
        }

        isSyncing = true
        isLoadingMore = true

        delegate?.syncHelper(self, syncMoreWithSuccess: {
            [weak self] (hasMore: Bool) in
            self?.hasMoreContent = hasMore
            self?.syncContentEnded()
        }, failure: {
            [weak self] (error: NSError) in
            DDLogInfo("Error syncing more: \(error)")
            self?.syncContentEnded(error: true)
        })

        return true
    }

    @objc public func backgroundSync(success: (() -> Void)?, failure: ((_ error: NSError?) -> Void)?) {
        guard !isSyncing else {
            success?()
            return
        }

        isSyncing = true

        delegate?.syncHelper(self, syncContentWithUserInteraction: false, success: {
            [weak self] (hasMore: Bool) -> Void in
            self?.hasMoreContent = hasMore
            self?.syncContentEnded()
            success?()
        }, failure: {
            [weak self] (error: NSError) -> Void in
            self?.syncContentEnded()
            failure?(error)
        })
    }

    @objc public func syncContentEnded(error: Bool = false) {
        isSyncing = false
        isLoadingMore = false

        if error {
            delegate?.syncContentFailed?(self)
        } else {
            delegate?.syncContentEnded?(self)
        }
    }

}
