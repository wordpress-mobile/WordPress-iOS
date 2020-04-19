class ReaderTagsTableViewController: UIViewController {

    private let style: UITableView.Style

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: style)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()

    private var tableViewHandler: ReaderTagsTableViewHandler?

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
        let handler = ReaderTagsTableViewHandler(tableView: tableView)
        handler.delegate = self
        tableViewHandler = handler
    }
}

class ReaderTagsTableViewHandler: WPTableViewHandler {

    func adjusted(indexPath: IndexPath) -> IndexPath? {
        guard indexPath.row > 0 else {
            return nil
        }
        return IndexPath(row: indexPath.row - 1, section: indexPath.section)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return super.tableView(tableView, numberOfRowsInSection: section) + 1
    }
}

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

        guard let indexPath = tableViewHandler?.adjusted(indexPath: indexPath) else {
            cell.textLabel?.text = NSLocalizedString("Add a Tag", comment: "Title of a feature to add a new tag to the tags subscribed by the user.")
            cell.accessoryView = UIImageView(image: UIImage.gridicon(.plusSmall))
            return
        }

        guard let topic = tableViewHandler?.resultsController.object(at: indexPath) as? ReaderTagTopic else {
            return
        }

        cell.textLabel?.text = topic.title

        let button = UIButton.closeAccessoryButton()
        button.addTarget(self, action: #selector(tappedAccessory(_:)), for: .touchUpInside)
        cell.accessoryView = button
        cell.selectionStyle = .none
    }
}

extension ReaderTagsTableViewController {
    @objc func tappedAccessory(_ sender: UIButton) {
        if let point = sender.superview?.convert(sender.center, to: tableView),
            let indexPath = tableView.indexPathForRow(at: point) {
            tableView.delegate?.tableView?(tableView, accessoryButtonTappedForRowWith: indexPath)
        }
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

// Close Accessory Button
extension UIButton {

    enum Constants {
        static let size = CGSize(width: 40, height: 40)
        static let image = UIImage.gridicon(.crossSmall)
        static let tintColor = MurielColor(name: .gray, shade: .shade10)
        static let insets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: -8) // To better align with the plus sign accessory view
    }

    static func closeAccessoryButton() -> UIButton {
        let button = UIButton(frame: CGRect(origin: .zero, size: Constants.size))
        button.setImage(Constants.image, for: .normal)
        button.imageEdgeInsets = Constants.insets
        button.imageView?.tintColor = UIColor.muriel(color: Constants.tintColor)
        return button
    }
}
