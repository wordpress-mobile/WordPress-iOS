import Foundation

@objc public extension ReaderCommentsViewController {
    func shouldShowSuggestions(for siteID: NSNumber?) -> Bool {
        guard let siteID = siteID, let blog = Blog.lookup(withID: siteID, in: ContextManager.shared.mainContext) else { return false }
        return SuggestionService.shared.shouldShowSuggestions(for: blog)
    }

    func showNotificationSheet(notificationsEnabled: Bool, sourceBarButtonItem: UIBarButtonItem?) {
        // TODO: Assign self as delegate.
        let sheetViewController = ReaderCommentsNotificationSheetViewController(isNotificationEnabled: notificationsEnabled)
        let bottomSheet = BottomSheetViewController(childViewController: sheetViewController, customHeaderSpacing: 20)
        bottomSheet.show(from: self, sourceBarButtonItem: sourceBarButtonItem)
    }
}
