import UIKit


@objc protocol WPContentSyncHelperDelegate: NSObjectProtocol {
    func syncHelper(syncHelper:WPContentSyncHelper, syncContentWithUserInteraction userInteraction: Bool, success:((count: Int)->Void)!, failure:((error:NSError)->Void)!);
    func syncHelper(syncHelper:WPContentSyncHelper, syncMoreWithSuccess success:((count: Int)->Void)!, failure:((error:NSError)->Void)!);
    optional func syncContentEnded();
    optional func hasNoMoreContent();
}


class WPContentSyncHelper: NSObject {

    weak var delegate: WPContentSyncHelperDelegate?;
    var isSyncing:Bool = false;
    var isLoadingMore:Bool = false;
    var hasMoreContent:Bool = true {
        didSet {
            if (hasMoreContent == oldValue) {
                return;
            }

            if (!hasMoreContent && self.delegate!.respondsToSelector(Selector("hasNoMoreContent"))) {
                self.delegate!.hasNoMoreContent!();
            }
        }
    };


    // MARK: - Syncing

    func syncContent() -> Bool {
        return self.syncContentWithUserInteraction(false);
    }


    func syncContentWithUserInteraction() -> Bool {
        return self.syncContentWithUserInteraction(true);
    }


    func syncContentWithUserInteraction(userInteraction:Bool) -> Bool {
        if (self.isSyncing) {
            return false;
        }

        self.isSyncing = true;
        self.delegate?.syncHelper(self, syncContentWithUserInteraction: userInteraction, success: { (count) -> Void in
            self.hasMoreContent = (count > 0);
            self.syncContentEnded();
        }, failure: { (error) -> Void in
            self.syncContentEnded();
        });

        return true;
    }


    func syncMoreContent() -> Bool {
        if (self.isSyncing) {
            return false;
        }

        self.isSyncing = true;
        self.isLoadingMore = true;
        self.delegate?.syncHelper(self, syncMoreWithSuccess: { (count) -> Void in
            self.isLoadingMore = false;
            self.hasMoreContent = (count > 0);
            self.syncContentEnded();
        }, failure: { (error) -> Void in
            self.syncContentEnded();
        });

        return true;
    }


    // MARK: - Private Methods

    private func syncContentEnded() {
        self.isSyncing = false;
        self.isLoadingMore = false;

        if (self.delegate!.respondsToSelector(Selector("syncContentEnded"))) {
            self.delegate!.syncContentEnded!();
        }
    }

}
