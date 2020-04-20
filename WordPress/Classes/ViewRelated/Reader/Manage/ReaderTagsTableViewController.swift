class ReaderTagsTableViewController: UIViewController {

    private let style: UITableView.Style

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: style)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()

    private var tableViewHandler: OffsetTableViewHandler?

    init(style: UITableView.Style) {
        self.style = style
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(tableView)
        view.pinSubviewToAllEdges(tableView)

        setupTableHandler()
    }

    private func setupTableHandler() {
        let handler = OffsetTableViewHandler(tableView: tableView)
        handler.delegate = self
        tableViewHandler = handler
    }
}

// MARK: - WPTableViewHandlerDelegate

extension ReaderTagsTableViewController: WPTableViewHandlerDelegate {

    func managedObjectContext() -> NSManagedObjectContext {
        return ContextManager.sharedInstance().mainContext
    }

    func fetchRequest() -> NSFetchRequest<NSFetchRequestResult> {
        return ReaderTagTopic.tagsFetchRequest
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableViewHandler?.adjusted(indexPath: indexPath) == nil else { return }
        tableView.deselectSelectedRowWithAnimation(true)
        showAddTag()
    }

    func configureCell(_ cell: UITableViewCell, at indexPath: IndexPath) {
        let topic = tableViewHandler?.object(at: indexPath) as? ReaderTagTopic
        configure(cell: cell, for: topic)
    }
}

// MARK: - Actions

extension ReaderTagsTableViewController {
    @objc func tappedAccessory(_ sender: UIButton) {
        guard let point = sender.superview?.convert(sender.center, to: tableView),
            let indexPath = tableView.indexPathForRow(at: point),
            let adjustIndexPath = tableViewHandler?.adjusted(indexPath: indexPath),
            let topic = tableViewHandler?.resultsController.object(at: adjustIndexPath) as? ReaderTagTopic else { return }
        unfollowTagTopic(topic)
    }

    /// Presents a new view controller for subscribing to a new tag.
    private func showAddTag() {
        let placeholder = NSLocalizedString("Add any tag", comment: "Placeholder text. A call to action for the user to type any tag to which they would like to subscribe.")
        let controller = SettingsTextViewController(text: nil, placeholder: placeholder, hint: nil)
        controller.title = NSLocalizedString("Add a Tag", comment: "Title of a feature to add a new tag to the tags subscribed by the user.")
        controller.onValueChanged = { value in
            if value.trim().count > 0 {
                self.followTagNamed(value.trim())
            }
        }
        controller.mode = .lowerCaseText
        controller.displaysActionButton = true
        controller.actionText = NSLocalizedString("Add Tag", comment: "Button Title. Tapping subscribes the user to a new tag.")
        controller.onActionPress = {
            self.dismissModal()
        }

        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(ReaderTagsTableViewController.dismissModal))
        controller.navigationItem.leftBarButtonItem = cancelButton

        let navController = UINavigationController(rootViewController: controller)
        navController.modalPresentationStyle = .formSheet

        show(navController, sender: nil)
    }

    @objc func dismissModal() {
        dismiss(animated: true)
    }

    /// Follow a new tag with the specified tag name.
    ///
    /// - Parameters:
    ///     - tagName: The name of the tag to follow.
    private func followTagNamed(_ tagName: String) {
        let service = ReaderTopicService(managedObjectContext: ContextManager.sharedInstance().mainContext)

        let generator = UINotificationFeedbackGenerator()
        generator.prepare()

        service.followTagNamed(tagName, withSuccess: { [weak self] in
            generator.notificationOccurred(.success)

            // A successful follow makes the new tag the currentTopic.
            if let tag = service.currentTopic as? ReaderTagTopic {
                self?.scrollToTag(tag)
            }
        }, failure: { (error) in
            DDLogError("Could not follow tag named \(tagName) : \(String(describing: error))")

            generator.notificationOccurred(.error)

            let title = NSLocalizedString("Could Not Follow Tag", comment: "Title of a prompt informing the user there was a probem unsubscribing from a tag in the reader.")
            let message = error?.localizedDescription
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addCancelActionWithTitle(NSLocalizedString("OK", comment: "Button title. An acknowledgement of the message displayed in a prompt."))
            alert.presentFromRootViewController()
        })
    }

    /// Tells the ReaderTopicService to unfollow the specified topic.
    ///
    /// - Parameters:
    ///     - topic: The tag topic that is to be unfollowed.
    ///
    private func unfollowTagTopic(_ topic: ReaderTagTopic) {
        let service = ReaderTopicService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        service.unfollowTag(topic, withSuccess: nil) { (error) in
            DDLogError("Could not unfollow topic \(topic), \(String(describing: error))")

            let title = NSLocalizedString("Could Not Remove Tag", comment: "Title of a prompt informing the user there was a probem unsubscribing from a tag in the reader.")
            let message = error?.localizedDescription
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addCancelActionWithTitle(NSLocalizedString("OK", comment: "Button title. An acknowledgement of the message displayed in a prompt."))
            alert.presentFromRootViewController()
        }
    }

    /// Scrolls the tableView so the specified tag is in view.
    ///
    /// - Paramters:
    ///     - tag: The tag to scroll into view.
    private func scrollToTag(_ tag: ReaderTagTopic) {
        guard let indexPath = tableViewHandler?.resultsController.indexPath(forObject: tag) else {
            return
        }

        tableView.flashRowAtIndexPath(indexPath, scrollPosition: .middle, completion: {
            if !self.splitViewControllerIsHorizontallyCompact {
                self.tableView(self.tableView, didSelectRowAt: indexPath)
            }
        })
    }
}
