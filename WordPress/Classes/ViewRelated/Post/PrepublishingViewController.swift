import UIKit
import WordPressAuthenticator

private struct PrepublishingOption {
    let id: PrepublishingIdentifier
    let title: String
}

private enum PrepublishingIdentifier {
    case schedule
    case visibility
    case tags
}

class PrepublishingViewController: UITableViewController {
    let post: Post

    private lazy var publishSettingsViewModel: PublishSettingsViewModel = {
        return PublishSettingsViewModel(post: post)
    }()

    private lazy var presentedVC: DrawerPresentationController? = {
        return (navigationController as? PrepublishingNavigationController)?.presentedVC
    }()

    private let completion: (AbstractPost) -> ()

    private let options: [PrepublishingOption] = [
        PrepublishingOption(id: .schedule, title: NSLocalizedString("Publish", comment: "Label for Publish")),
        PrepublishingOption(id: .visibility, title: NSLocalizedString("Visibility", comment: "Label for Visibility")),
        PrepublishingOption(id: .tags, title: NSLocalizedString("Tags", comment: "Label for Tags"))
    ]

    let publishButton: NUXButton = {
        let nuxButton = NUXButton()
        nuxButton.isPrimary = true
        nuxButton.setTitle(NSLocalizedString("Publish Now", comment: "Label for a button that publishes the post"), for: .normal)

        return nuxButton
    }()

    init(post: Post, completion: @escaping (AbstractPost) -> ()) {
        self.post = post
        self.completion = completion
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = Constants.title

        setupPublishButton()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: WPTableViewCell = {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: Constants.reuseIdentifier) as? WPTableViewCell else {
                return WPTableViewCell.init(style: .value1, reuseIdentifier: Constants.reuseIdentifier)
            }
            return cell
        }()

        cell.preservesSuperviewLayoutMargins = false
        cell.separatorInset = .zero
        cell.layoutMargins = .zero

        cell.accessoryType = .disclosureIndicator
        cell.textLabel?.text = options[indexPath.row].title

        switch options[indexPath.row].id {
        case .tags:
            configureTagCell(cell)
        case .visibility:
            configureVisibilityCell(cell)
        case .schedule:
            configureScheduleCell(cell)
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch options[indexPath.row].id {
        case .tags:
            didTapTagCell()
        case .visibility:
            didTapVisibilityCell()
        case .schedule:
            didTapSchedule()
        }
    }

    // MARK: - Tags

    private func configureTagCell(_ cell: WPTableViewCell) {
        cell.detailTextLabel?.text = post.tags
    }

    private func didTapTagCell() {
        let tagPickerViewController = PostTagPickerViewController(tags: post.tags ?? "", blog: post.blog)

        tagPickerViewController.onValueChanged = { [weak self] tags in
            if !tags.isEmpty {
                WPAnalytics.track(.prepublishingTagsAdded)
            }

            self?.post.tags = tags
            self?.tableView.reloadData()
        }

        navigationController?.pushViewController(tagPickerViewController, animated: true)
    }

    // MARK: - Visibility

    private func configureVisibilityCell(_ cell: WPTableViewCell) {
        cell.detailTextLabel?.text = post.titleForVisibility
    }

    private func didTapVisibilityCell() {
        let visbilitySelectorViewController = PostVisibilitySelectorViewController(post)

        visbilitySelectorViewController.completion = { [weak self] option in
            self?.tableView.reloadData()

            // If tue user selects password protected, prompt for a password
            if option == AbstractPost.passwordProtectedLabel {
                self?.showPasswordAlert()
            } else {
                self?.navigationController?.popViewController(animated: true)
            }
        }

        navigationController?.pushViewController(visbilitySelectorViewController, animated: true)
    }

    // MARK: - Schedule

    func configureScheduleCell(_ cell: WPTableViewCell) {
        cell.detailTextLabel?.text = publishSettingsViewModel.detailString
    }

    func didTapSchedule() {
        presentedVC?.transition(to: .hidden)
        SchedulingCalendarViewController.present(from: self, viewModel: publishSettingsViewModel) { [weak self] date in
            self?.publishSettingsViewModel.setDate(date)
            self?.tableView.reloadData()
            self?.presentedVC?.transition(to: .collapsed)
        }
    }

    // MARK: - Publish Button

    private func setupPublishButton() {
        let footer = UIView(frame: Constants.footerFrame)
        footer.addSubview(publishButton)
        footer.pinSubviewToSafeArea(publishButton, insets: Constants.nuxButtonInsets)
        publishButton.translatesAutoresizingMaskIntoConstraints = false
        tableView.tableFooterView = footer
        publishButton.addTarget(self, action: #selector(publish(_:)), for: .touchUpInside)
    }

    @objc func publish(_ sender: UIButton) {
        navigationController?.dismiss(animated: true) {
            self.completion(self.post)
        }
    }

    // MARK: - Password Prompt

    private func showPasswordAlert() {
        let passwordAlertController = PasswordAlertController(onSubmit: { [weak self] password in
            guard let password = password, !password.isEmpty else {
                self?.cancelPasswordProtectedPost()
                return
            }

            self?.post.password = password
            self?.navigationController?.popViewController(animated: true)
        }, onCancel: { [weak self] in
            self?.cancelPasswordProtectedPost()
        })

        passwordAlertController.show(from: self)
    }

    private func cancelPasswordProtectedPost() {
        post.status = .publish
        post.password = nil
        tableView.reloadData()
    }

    private enum Constants {
        static let reuseIdentifier = "wpTableViewCell"
        static let nuxButtonInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
        static let footerFrame = CGRect(x: 0, y: 0, width: 100, height: 40)
        static let title = NSLocalizedString("Publishing To", comment: "Label that describes in which blog the user is publishing to")
    }
}
