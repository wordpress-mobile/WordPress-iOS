import Foundation
import CoreData
import Simperium
import WordPressShared



/// Setup Helpers
///
extension NotificationDetailsViewController
{
    func setupNavigationBar() {
        // Don't show the notification title in the next-view's back button
        navigationItem.backBarButtonItem = UIBarButtonItem(title: String(),
                                                           style: .Plain,
                                                           target: nil,
                                                           action: nil)
    }

    func setupMainView() {
        view.backgroundColor = WPStyleGuide.itsEverywhereGrey()
    }

    func setupTableView() {
        tableView.separatorStyle            = .None
        tableView.keyboardDismissMode       = .Interactive
        tableView.backgroundColor           = WPStyleGuide.greyLighten30()
        tableView.accessibilityIdentifier   = NSLocalizedString("Notification Details Table", comment: "Notifications Details Accessibility Identifier")
        tableView.backgroundColor           = WPStyleGuide.itsEverywhereGrey()
    }

    func setupTableViewCells() {
        let cellClassNames: [NoteBlockTableViewCell.Type] = [
            NoteBlockHeaderTableViewCell.self,
            NoteBlockTextTableViewCell.self,
            NoteBlockActionsTableViewCell.self,
            NoteBlockCommentTableViewCell.self,
            NoteBlockImageTableViewCell.self,
            NoteBlockUserTableViewCell.self
        ]

        for cellClass in cellClassNames {
            let classname = cellClass.classNameWithoutNamespaces()
            let nib = UINib(nibName: classname, bundle: NSBundle.mainBundle())

            tableView.registerNib(nib, forCellReuseIdentifier: cellClass.reuseIdentifier())
            tableView.registerNib(nib, forCellReuseIdentifier: cellClass.layoutIdentifier())
        }
    }

    func setupMediaDownloader() {
        // TODO: Nuke this method as soon as the Header is 100% Swift
        mediaDownloader = NotificationMediaDownloader()
    }

    func setupReplyTextView() {
        let replyTextView = ReplyTextView(width: view.frame.width)
        replyTextView.placeholder = NSLocalizedString("Write a reply…", comment: "Placeholder text for inline compose view")
        replyTextView.replyText = NSLocalizedString("Reply", comment: "").uppercaseString
        replyTextView.accessibilityIdentifier = NSLocalizedString("Reply Text", comment: "Notifications Reply Accessibility Identifier")
        replyTextView.delegate = self
        replyTextView.onReply = { [weak self] content in
            guard let block = self?.note.blockGroupOfType(.Comment)?.blockOfType(.Comment) else {
                return
            }
            self?.sendReplyWithBlock(block, content: content)
        }

        self.replyTextView = replyTextView
    }

    func setupSuggestionsView() {
        suggestionsTableView = SuggestionsTableView()
        suggestionsTableView.siteID = note.metaSiteID
        suggestionsTableView.suggestionsDelegate = self
        suggestionsTableView.translatesAutoresizingMaskIntoConstraints = false
    }

    func setupKeyboardManager() {
        precondition(replyTextView != nil)
        precondition(bottomLayoutConstraint != nil)

        keyboardManager = KeyboardDismissHelper(parentView: view,
                                                scrollView: tableView,
                                                dismissableControl: replyTextView,
                                                bottomLayoutConstraint: bottomLayoutConstraint)
    }

    func setupNotificationListeners() {
        let nc = NSNotificationCenter.defaultCenter()
        nc.addObserver(self,
                       selector: #selector(notificationWasUpdated),
                       name: NSManagedObjectContextObjectsDidChangeNotification,
                       object: note.managedObjectContext)
    }
}



/// Reply View Helpers
///
extension NotificationDetailsViewController
{
    func attachReplyViewIfNeeded() {
        guard shouldAttachReplyView else {
            replyTextView.removeFromSuperview()
            return
        }

        stackView.addArrangedSubview(replyTextView)
    }

    var shouldAttachReplyView: Bool {
        // Attach the Reply component only if the noficiation has a comment, and it can be replied-to
        //
        guard let block = note.blockGroupOfType(.Comment)?.blockOfType(.Comment) else {
            return false
        }

        return block.isActionOn(NoteActionReplyKey) && !WPDeviceIdentification.isiPad()
    }
}



/// Suggestions View Helpers
///
extension NotificationDetailsViewController
{
    // TODO: This should be private
    func attachSuggestionsViewIfNeeded() {
        guard shouldAttachSuggestionsView else {
            suggestionsTableView.removeFromSuperview()
            return
        }

        view.addSubview(suggestionsTableView)

        NSLayoutConstraint.activateConstraints([
            suggestionsTableView.leadingAnchor.constraintEqualToAnchor(view.leadingAnchor),
            suggestionsTableView.trailingAnchor.constraintEqualToAnchor(view.trailingAnchor),
            suggestionsTableView.topAnchor.constraintEqualToAnchor(view.topAnchor),
            suggestionsTableView.bottomAnchor.constraintEqualToAnchor(replyTextView.topAnchor)
        ])
    }

    private  var shouldAttachSuggestionsView: Bool {
        guard let siteID = note.metaSiteID else {
            return false
        }

        let suggestionsService = SuggestionService()
        return shouldAttachReplyView && suggestionsService.shouldShowSuggestionsForSiteID(siteID)
    }
}


/// Edition Helpers
///
extension NotificationDetailsViewController
{
    // TODO: This should be Private once ready
    func attachEditActionIfNeeded() {
        guard shouldAttachEditAction else {
            return
        }

        let title = NSLocalizedString("Edit", comment: "Verb, start editing")
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: title,
                                                            style: .Plain,
                                                            target: self,
                                                            action: #selector(editButtonWasPressed))
    }

    private var shouldAttachEditAction: Bool {
        let block = note.blockGroupOfType(.Comment)?.blockOfType(.Comment)
        return block?.isActionOn(NoteActionEditKey) ?? false
    }

    @IBAction func editButtonWasPressed() {
        guard let block = note.blockGroupOfType(.Comment)?.blockOfType(.Comment) else {
            return
        }

        if block.isActionOn(NoteActionEditKey) {
            editCommentWithBlock(block)
        }
    }
}



/// Style Helpers
///
extension NotificationDetailsViewController
{
    // TODO: This should be private once ready
    func adjustLayoutConstraintsIfNeeded() {
        // Badge Notifications should be centered, and display no cell separators
        let shouldCenterVertically = note.isBadge

        topLayoutConstraint.active = !shouldCenterVertically
        bottomLayoutConstraint.active = !shouldCenterVertically
        centerLayoutConstraint.active = shouldCenterVertically

        // Lock Scrolling for Badge Notifications
        tableView.scrollEnabled = !shouldCenterVertically
    }
}



/// Notification Helpers
///
extension NotificationDetailsViewController
{
    func notificationWasUpdated(notification: NSNotification) {
        let updated   = notification.userInfo?[NSUpdatedObjectsKey]   as? Set<NSManagedObject> ?? Set()
        let refreshed = notification.userInfo?[NSRefreshedObjectsKey] as? Set<NSManagedObject> ?? Set()
        let deleted   = notification.userInfo?[NSDeletedObjectsKey]   as? Set<NSManagedObject> ?? Set()

        // Reload the table, if *our* notification got updated
        if updated.contains(note) || refreshed.contains(note) {
            reloadData()
        }

        // Dismiss this ViewController if *our* notification... just got deleted
        if deleted.contains(note) {
            navigationController?.popToRootViewControllerAnimated(true)
        }
    }
}



/// UITextViewDelegate
///
extension NotificationDetailsViewController: ReplyTextViewDelegate
{
    public func textViewDidBeginEditing(textView: UITextView) {
        tableGesturesRecognizer.enabled = true
    }

    public func textViewDidEndEditing(textView: UITextView) {
        tableGesturesRecognizer.enabled = false
    }

    public func textView(textView: UITextView, didTypeWord word: String) {
        suggestionsTableView.showSuggestionsForWord(word)
    }
}



/// UIScrollViewDelegate
///
extension NotificationDetailsViewController: UIScrollViewDelegate
{
    public func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        keyboardManager.scrollViewWillBeginDragging(scrollView)
    }

    public func scrollViewDidScroll(scrollView: UIScrollView) {
        keyboardManager.scrollViewDidScroll(scrollView)
    }

    public func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        keyboardManager.scrollViewWillEndDragging(scrollView, withVelocity: velocity)
    }
}



/// SuggestionsTableViewDelegate
///
extension NotificationDetailsViewController: SuggestionsTableViewDelegate
{
    public func suggestionsTableView(suggestionsTableView: SuggestionsTableView, didSelectSuggestion suggestion: String?, forSearchText text: String) {
        replyTextView.replaceTextAtCaret(text, withText: suggestion)
        suggestionsTableView.showSuggestionsForWord(String())
    }
}



/// Gestures Recognizer Delegate
///
extension NotificationDetailsViewController: UIGestureRecognizerDelegate
{
    @IBAction public func dismissKeyboardIfNeeded(sender: AnyObject) {
        view.endEditing(true)
    }

    public func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Note: the tableViewGestureRecognizer may compete with another GestureRecognizer. Make sure it doesn't get cancelled
        return true
    }
}
