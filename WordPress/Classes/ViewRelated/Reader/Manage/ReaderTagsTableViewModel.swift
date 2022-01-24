class ReaderTagsTableViewModel: NSObject {

    private let tableViewHandler: OffsetTableViewHandler
    private let context: NSManagedObjectContext
    private weak var tableView: UITableView?
    private weak var presentingViewController: UIViewController?

    init(tableView: UITableView,
         presenting viewController: UIViewController,
         context: NSManagedObjectContext = ContextManager.sharedInstance().mainContext) {
        let handler = OffsetTableViewHandler(tableView: tableView)
        tableViewHandler = handler
        presentingViewController = viewController
        self.tableView = tableView
        self.context = context
        super.init()
        handler.delegate = self

        tableView.register(ReaderTagsFooter.defaultNib, forHeaderFooterViewReuseIdentifier: ReaderTagsFooter.defaultReuseID)
    }
}

// MARK: - WPTableViewHandler

extension ReaderTagsTableViewModel: WPTableViewHandlerDelegate {
    func managedObjectContext() -> NSManagedObjectContext {
        return context
    }

    func fetchRequest() -> NSFetchRequest<NSFetchRequestResult> {
        return ReaderTagTopic.tagsFetchRequest
    }

    /// Disable highlighting for all rows but "Add a Topic" this allows the rows to be "flashed" but not show taps
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        let adjustedPath = tableViewHandler.adjusted(indexPath: indexPath)
        return adjustedPath == nil
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectSelectedRowWithAnimation(true)
        guard tableViewHandler.adjusted(indexPath: indexPath) == nil else {
            return
        }
        showAddTag()
    }

    func configureCell(_ cell: UITableViewCell, at indexPath: IndexPath) {
        let topic = tableViewHandler.object(at: indexPath) as? ReaderTagTopic
        configure(cell: cell, for: topic)
    }

    // MARK: - Discover more topics footer

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        guard section == 0 else {
            return CGFloat.leastNormalMagnitude
        }
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard section == 0,
              let footer = tableView.dequeueReusableHeaderFooterView(withIdentifier: ReaderTagsFooter.defaultReuseID) as? ReaderTagsFooter else {
            return nil
        }

        let title = NSLocalizedString("Discover more topics", comment: "Button title. Tapping shows the Follow Topics screen.")
        footer.actionButton.setTitle(title, for: .normal)

        footer.actionButtonHandler = { [weak self] in
            self?.showSelectInterests()
        }

        return footer
    }
}

// MARK: - Actions

extension ReaderTagsTableViewModel {
    @objc func tappedAccessory(_ sender: UIButton) {
        guard let point = sender.superview?.convert(sender.center, to: tableView),
            let indexPath = tableView?.indexPathForRow(at: point),
            let adjustIndexPath = tableViewHandler.adjusted(indexPath: indexPath),
            let topic = tableViewHandler.resultsController.object(at: adjustIndexPath) as? ReaderTagTopic else {
                return
        }

        unfollow(topic)
        NotificationCenter.default.post(name: .ReaderTopicUnfollowed,
                                        object: nil,
                                        userInfo: [ReaderNotificationKeys.topic: topic])
    }

    /// Presents a new view controller for subscribing to a new tag.
    private func showAddTag() {

        let placeholder = NSLocalizedString("Add any topic", comment: "Placeholder text. A call to action for the user to type any topic to which they would like to subscribe.")
        let controller = SettingsTextViewController(text: nil, placeholder: placeholder, hint: nil)
        controller.title = NSLocalizedString("Add a Topic", comment: "Title of a feature to add a new topic to the topics subscribed by the user.")
        controller.onValueChanged = { [weak self] value in
            self?.follow(tagName: value)
        }
        controller.mode = .lowerCaseText
        controller.displaysActionButton = true
        controller.actionText = NSLocalizedString("Add Topic", comment: "Button Title. Tapping subscribes the user to a new topic.")
        controller.onActionPress = { [weak self] in
            self?.dismissModal()
        }

        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(dismissModal))
        controller.navigationItem.leftBarButtonItem = cancelButton

        let navController = UINavigationController(rootViewController: controller)
        navController.modalPresentationStyle = .formSheet

        presentingViewController?.present(navController, animated: true, completion: nil)
    }

    /// Presents a new view controller for selecting topics to follow.
    private func showSelectInterests() {
        let configuration = ReaderSelectInterestsConfiguration(
            title: NSLocalizedString("Follow topics", comment: "Screen title. Reader select interests title label text."),
            subtitle: nil,
            buttonTitle: nil,
            loading: NSLocalizedString("Following new topics...", comment: "Label displayed to the user while loading their selected interests")
        )

        let topics = tableViewHandler.resultsController.fetchedObjects as? [ReaderTagTopic] ?? []

        let controller = ReaderSelectInterestsViewController(configuration: configuration,
                                                             topics: topics)

        controller.didSaveInterests = { [weak self] _ in
            self?.dismissModal()
        }

        let navController = UINavigationController(rootViewController: controller)
        navController.modalPresentationStyle = .formSheet

        presentingViewController?.present(navController, animated: true, completion: nil)
    }

    @objc func dismissModal() {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }

    /// Follow a new tag with the specified tag name.
    ///
    /// - Parameters:
    ///     - tagName: The name of the tag to follow.
    private func follow(tagName: String) {

        let tagName = tagName.trim()
        guard !tagName.isEmpty() else {
            return
        }

        let service = ReaderTopicService(managedObjectContext: context)

        let generator = UINotificationFeedbackGenerator()
        generator.prepare()

        service.followTagNamed(tagName, withSuccess: { [weak self] in
            generator.notificationOccurred(.success)

            // A successful follow makes the new tag the currentTopic.
            if let tag = service.currentTopic as? ReaderTagTopic {
                self?.scrollToTag(tag)
            }
        }, failure: { (error) in
            DDLogError("Could not follow topic named \(tagName) : \(String(describing: error))")

            generator.notificationOccurred(.error)

            let title = NSLocalizedString("Could Not Follow Topic", comment: "Title of a prompt informing the user there was a probem unsubscribing from a topic in the reader.")
            let message = error?.localizedDescription
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addCancelActionWithTitle(NSLocalizedString("OK", comment: "Button title. An acknowledgement of the message displayed in a prompt."))
            alert.presentFromRootViewController()
        }, source: "manage")
    }

    /// Tells the ReaderTopicService to unfollow the specified topic.
    ///
    /// - Parameters:
    ///     - topic: The tag topic that is to be unfollowed.
    private func unfollow(_ topic: ReaderTagTopic) {
        let service = ReaderTopicService(managedObjectContext: context)
        service.unfollowTag(topic, withSuccess: nil) { (error) in
            DDLogError("Could not unfollow topic \(topic), \(String(describing: error))")

            let title = NSLocalizedString("Could Not Remove Topic", comment: "Title of a prompt informing the user there was a probem unsubscribing from a topic in the reader.")
            let message = error?.localizedDescription
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addCancelActionWithTitle(NSLocalizedString("OK", comment: "Button title. An acknowledgement of the message displayed in a prompt."))
            alert.presentFromRootViewController()
        }
    }

    /// Scrolls the tableView so the specified tag is in view and flashes that row
    ///
    /// - Parameters:
    ///     - tag: The tag to scroll into view.
    private func scrollToTag(_ tag: ReaderTagTopic) {
        guard let indexPath = tableViewHandler.resultsController.indexPath(forObject: tag) else {
            return
        }
        tableView?.flashRowAtIndexPath(tableViewHandler.adjustedToTable(indexPath: indexPath), scrollPosition: .middle, completion: {})
    }
}
