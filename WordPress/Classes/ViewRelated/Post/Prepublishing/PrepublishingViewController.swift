import UIKit
import WordPressAuthenticator
import Combine
import WordPressUI
import SwiftUI

enum PrepublishingIdentifier {
    case title
    case schedule
    case visibility
    case tags
    case categories
    case autoSharing

    static var defaultIdentifiers: [PrepublishingIdentifier] {
        if RemoteFeatureFlag.jetpackSocialImprovements.enabled() {
            return [.visibility, .schedule, .tags, .categories, .autoSharing]
        }
        return [.visibility, .schedule, .tags, .categories]
    }
}

enum PrepublishingSheetResult {
    /// The user confirms that they want to publish (legacy behavior).
    ///
    /// - note: Deprecated (kahu-offline-mode)
    case confirmed
    /// The sheet published the post (new behavior)
    case published
    /// The user cancelled.
    case cancelled
}

final class PrepublishingViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    let post: Post
    let identifiers: [PrepublishingIdentifier]
    let coreDataStack: CoreDataStackSwift
    let persistentStore: UserPersistentRepository

    lazy var postBlogID: Int? = {
        coreDataStack.performQuery { [postObjectID = post.objectID] context in
            guard let post = (try? context.existingObject(with: postObjectID)) as? Post else {
                return nil
            }
            return post.blog.dotComID?.intValue
        }
    }()

    /// The list of `PrepublishingIdentifier`s that have been filtered for display.
    var filteredIdentifiers: [PrepublishingIdentifier] {
        options.map { $0.id }
    }

    private lazy var publishSettingsViewModel = PublishSettingsViewModel(post: post)

    private var completion: ((PrepublishingSheetResult) -> ())?

    /// The data source for the table rows, based on the filtered `identifiers`.
    private var options = [PrepublishingOption]()

    private var didTapPublish = false

    private let headerView = PrepublishingHeaderView()
    let tableView = UITableView(frame: .zero, style: .plain)
    private let footerSeparator = UIView()

    private weak var titleField: UITextField?

    private lazy var publishButtonViewModel = PublishButtonViewModel(title: "Publish") { [weak self] in
        self?.buttonPublishTapped()
    }

    /// Determines whether the text has been first responder already. If it has, don't force it back on the user unless it's been selected by them.
    private var hasSelectedText: Bool = false

    private var cancellables = Set<AnyCancellable>()
    @Published private var keyboardShown: Bool = false

    private weak var mediaPollingTimer: Timer?

    init(post: Post,
         identifiers: [PrepublishingIdentifier],
         completion: @escaping (PrepublishingSheetResult) -> (),
         coreDataStack: CoreDataStackSwift = ContextManager.shared,
         persistentStore: UserPersistentRepository = UserPersistentStoreFactory.instance()) {
        self.post = post
        self.identifiers = identifiers
        self.completion = completion
        self.coreDataStack = coreDataStack
        self.persistentStore = persistentStore
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func presentAsSheet(from presentingViewController: UIViewController) {
        let navigationController = UINavigationController(rootViewController: self)
        if UIDevice.isPad() {
            navigationController.modalPresentationStyle = .formSheet
        } else {
            if let sheetController = navigationController.sheetPresentationController {
                if #available(iOS 16, *) {
                    sheetController.detents = [.custom { _ in 510 }, .large()]
                } else {
                    sheetController.detents = [.medium(), .large()]
                }
                sheetController.prefersGrabberVisible = true
                sheetController.preferredCornerRadius = 16
                navigationController.additionalSafeAreaInsets = UIEdgeInsets(top: 8, left: 0, bottom: 0, right: 0)
            }
        }
        presentingViewController.present(navigationController, animated: true)
    }

    func refreshOptions() {
        options = identifiers.compactMap { identifier -> PrepublishingOption? in
            switch identifier {
            case .autoSharing:
                // skip the social cell if the post's blog is not eligible for auto-sharing.
                guard canDisplaySocialRow() else {
                    return nil
                }
                break
            default:
                break
            }
            return .init(identifier: identifier)
        }
    }

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()

        refreshOptions()

        configureHeader()
        configureTableView()
        configureKeyboardToggle()
        WPStyleGuide.applyBorderStyle(footerSeparator)

        title = ""

        let stackView = UIStackView(arrangedSubviews: [
            headerView,
            tableView,
            footerSeparator,
            setupPublishButton()
        ])
        stackView.axis = .vertical

        view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.pinSubviewToSafeArea(stackView)

        view.backgroundColor = .systemBackground
    }

    private func configureHeader() {
        headerView.closeButton.addAction(.init(handler: { [weak self] _ in
            self?.presentingViewController?.dismiss(animated: true)
        }), for: .touchUpInside)
        headerView.configure(post.blog)
    }

    private func configureTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
    }

    private func setupPublishButton() -> UIView {
        let footerView = UIView()

        let hostingViewController = UIHostingController(rootView: PublishButton(viewModel: publishButtonViewModel).tint(Color(uiColor: .primary)))
        addChild(hostingViewController)

        footerView.addSubview(hostingViewController.view)
        hostingViewController.view.translatesAutoresizingMaskIntoConstraints = false
        footerView.pinSubviewToSafeArea(hostingViewController.view, insets: Constants.nuxButtonInsets)

        updatePublishButtonLabel()

        if FeatureFlag.offlineMode.enabled {
            updatePublishButtonState()
            mediaPollingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                self?.updatePublishButtonState()
            }
        }

        return footerView
    }

    /// Toggles `keyboardShown` as the keyboard notifications come in
    private func configureKeyboardToggle() {
        NotificationCenter.default.publisher(for: UIResponder.keyboardDidShowNotification)
            .sink { [weak self] _ in self?.keyboardShown = true }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIResponder.keyboardDidHideNotification)
            .sink { [weak self] _ in self?.keyboardShown = false }
            .store(in: &cancellables)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        footerSeparator.isHidden = tableView.contentSize.height < tableView.bounds.height
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.setNavigationBarHidden(true, animated: animated)

        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPath, animated: true)
        }

        // Setting titleField first resonder alongside our transition to avoid layout issues.
        transitionCoordinator?.animateAlongsideTransition(in: nil, animation: { [weak self] _ in
            if self?.hasSelectedText == false {
                self?.titleField?.becomeFirstResponder()
                self?.hasSelectedText = true
            }
        })
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        let isPushingViewController = navigationController?.viewControllers.count ?? 0 > 1
        if isPushingViewController {
            navigationController?.setNavigationBarHidden(false, animated: animated)
        }

        if (isBeingDismissed || parent?.isBeingDismissed == true) && !didTapPublish {
            if post.status == .publishPrivate, let originalStatus = post.original?.status {
                post.status = originalStatus
            }
            getCompletion()?(.cancelled)
        }
    }

    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        options.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let option = options[indexPath.row]
        let cell = dequeueCell(for: option.type, indexPath: indexPath)

        switch option.type {
        case .textField:
            if let cell = cell as? WPTextFieldTableViewCell {
                setupTextFieldCell(cell)
            }
        case .value:
            cell.accessoryType = .disclosureIndicator
            cell.textLabel?.text = option.title
        default:
            break
        }

        switch option.id {
        case .title:
            if let cell = cell as? WPTextFieldTableViewCell {
                configureTitleCell(cell)
            }
        case .tags:
            configureTagCell(cell)
        case .visibility:
            configureVisibilityCell(cell)
        case .schedule:
            configureScheduleCell(cell)
        case .categories:
            configureCategoriesCell(cell)
        case .autoSharing:
            configureSocialCell(cell)
        }

        return cell
    }

    private func dequeueCell(for type: PrepublishingCellType, indexPath: IndexPath) -> WPTableViewCell {
        switch type {
        case .textField:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: Constants.textFieldReuseIdentifier) as? WPTextFieldTableViewCell else {
                return WPTextFieldTableViewCell.init(style: .default, reuseIdentifier: Constants.textFieldReuseIdentifier)
            }
            return cell
        case .value:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: Constants.reuseIdentifier) as? WPTableViewCell else {
                return WPTableViewCell.init(style: .value1, reuseIdentifier: Constants.reuseIdentifier)
            }
            return cell
        case .customContainer:
            return WPTableViewCell()
        }
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch options[indexPath.row].id {
        case .tags:
            didTapTagCell()
        case .visibility:
            didTapVisibilityCell()
        case .schedule:
            didTapSchedule(indexPath)
        case .categories:
            didTapCategoriesCell()
        case .autoSharing:
            didTapAutoSharingCell()
        default:
            break
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        headerView.separator.alpha = max(0, min(1, scrollView.contentOffset.y / 60))
    }

    // MARK: – Misc

    func reloadData() {
        refreshOptions()
        tableView.reloadData()
    }

    private func setupTextFieldCell(_ cell: WPTextFieldTableViewCell) {
        WPStyleGuide.configureTableViewTextCell(cell)
        cell.delegate = self
    }

    /// Returns the completion closure and sets it to nil to make sure the screen
    /// only calls it once.
    private func getCompletion() -> ((PrepublishingSheetResult) -> Void)? {
        let completion = self.completion
        self.completion = nil
        return completion
    }

    // MARK: - Title

    private func configureTitleCell(_ cell: WPTextFieldTableViewCell) {
        cell.textField.text = post.postTitle
        cell.textField.adjustsFontForContentSizeCategory = true
        cell.textField.font = .preferredFont(forTextStyle: .body)
        cell.textField.textColor = .text
        cell.textField.placeholder = Strings.postTitle
        cell.textField.heightAnchor.constraint(equalToConstant: 40).isActive = true
        cell.textField.autocorrectionType = .yes
        cell.textField.autocapitalizationType = .sentences
        titleField = cell.textField
    }

    // MARK: - Tags

    private func configureTagCell(_ cell: WPTableViewCell) {
        cell.detailTextLabel?.text = post.tags
    }

    private func didTapTagCell() {
        let tagPickerViewController = PostTagPickerViewController(tags: post.tags ?? "", blog: post.blog)

        tagPickerViewController.onValueChanged = { [weak self] tags in
            WPAnalytics.track(.editorPostTagsChanged, properties: Constants.analyticsDefaultProperty)

            self?.post.tags = tags
            self?.reloadData()
        }

        navigationController?.pushViewController(tagPickerViewController, animated: true)
    }

    private func configureCategoriesCell(_ cell: WPTableViewCell) {
        cell.detailTextLabel?.text = Array(post.categories ?? [])
            .map { $0.categoryName }
            .joined(separator: ",")
    }

    private func didTapCategoriesCell() {
        let categoriesViewController = PostCategoriesViewController(blog: post.blog, currentSelection: Array(post.categories ?? []), selectionMode: .post)
        categoriesViewController.delegate = self
        categoriesViewController.onCategoriesChanged = { [weak self] in
            self?.tableView.reloadData()
        }
        navigationController?.pushViewController(categoriesViewController, animated: true)
    }

    // MARK: - Visibility

    private func configureVisibilityCell(_ cell: WPTableViewCell) {
        cell.detailTextLabel?.text = post.titleForVisibility
    }

    private func didTapVisibilityCell() {
        let visbilitySelectorViewController = PostVisibilitySelectorViewController(post)

        visbilitySelectorViewController.completion = { [weak self] option in
            self?.reloadData()
            self?.updatePublishButtonLabel()

            WPAnalytics.track(.editorPostVisibilityChanged, properties: Constants.analyticsDefaultProperty)

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
        cell.textLabel?.text = Strings.publishDate
        cell.detailTextLabel?.text = publishSettingsViewModel.detailString
        post.status == .publishPrivate ? cell.disable() : cell.enable()
    }

    func didTapSchedule(_ indexPath: IndexPath) {
        let viewController = SchedulingDatePickerViewController.make(viewModel: publishSettingsViewModel) { [weak self] date in
            WPAnalytics.track(.editorPostScheduledChanged, properties: Constants.analyticsDefaultProperty)
            self?.publishSettingsViewModel.setDate(date)
            self?.reloadData()
            self?.updatePublishButtonLabel()
        }
        navigationController?.pushViewController(viewController, animated: true)
    }

    // MARK: - Publish Button

    private func updatePublishButtonState() {
        if let state = PublishButtonState.uploadingState(for: post) {
            publishButtonViewModel.state = state
        } else {
            if case .loading = publishButtonViewModel.state {
                // Do nothing
            } else {
                publishButtonViewModel.state = .default
            }
        }
    }

    private func updatePublishButtonLabel() {
        publishButtonViewModel.title = post.isScheduled() ? Strings.schedule : Strings.publish
    }

    private func buttonPublishTapped() {
        didTapPublish = true

        if FeatureFlag.offlineMode.enabled {
            publishPost()
        } else {
            let completion = getCompletion()
            navigationController?.dismiss(animated: true) {
                WPAnalytics.track(.editorPostPublishNowTapped)
                completion?(.confirmed)
            }
        }
    }

    private func publishPost() {
        publishButtonViewModel.state = .loading
        Task {
            do {
                try await PostCoordinator.shared._publish(post)
                getCompletion()?(.published)
            } catch {
                publishButtonViewModel.state = .default
            }
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
        reloadData()
    }

    // MARK: - Accessibility

    fileprivate enum Constants {
        static let reuseIdentifier = "wpTableViewCell"
        static let textFieldReuseIdentifier = "wpTextFieldCell"
        static let nuxButtonInsets = UIEdgeInsets(top: 16, left: 20, bottom: 16, right: 20)
        static let analyticsDefaultProperty = ["via": "prepublishing_nudges"]
    }
}

extension PrepublishingViewController: WPTextFieldTableViewCellDelegate {
    func cellWants(toSelectNextField cell: WPTextFieldTableViewCell!) {

    }

    func cellTextDidChange(_ cell: WPTextFieldTableViewCell!) {
        WPAnalytics.track(.editorPostTitleChanged, properties: Constants.analyticsDefaultProperty)
        post.postTitle = cell.textField.text
    }
}

extension PrepublishingViewController: PostCategoriesViewControllerDelegate {
    func postCategoriesViewController(_ controller: PostCategoriesViewController, didUpdateSelectedCategories categories: NSSet) {
        WPAnalytics.track(.editorPostCategoryChanged, properties: ["via": "prepublishing_nudges"])

        // Save changes.
        guard let categories = categories as? Set<PostCategory> else {
             return
        }
        post.categories = categories
        post.save()
    }
}

private struct PrepublishingOption {
    let id: PrepublishingIdentifier
    let title: String
    let type: PrepublishingCellType
}

private enum PrepublishingCellType {
    case value
    case textField
    case customContainer
}

private extension PrepublishingOption {
    init(identifier: PrepublishingIdentifier) {
        switch identifier {
        case .title:
            self.init(id: .title, title: Strings.postTitle, type: .textField)
        case .schedule:
            self.init(id: .schedule, title: Strings.publishDate, type: .value)
        case .categories:
            self.init(id: .categories, title: Strings.categories, type: .value)
        case .visibility:
            self.init(id: .visibility, title: Strings.visibility, type: .value)
        case .tags:
            self.init(id: .tags, title: Strings.tags, type: .value)
        case .autoSharing:
            self.init(id: .autoSharing, title: Strings.jetpackSocial, type: .customContainer)
        }
    }
}

private enum Strings {
    static let publish = NSLocalizedString("prepublishing.publish", value: "Publish", comment: "Primary button label in the pre-publishing sheet")
    static let schedule = NSLocalizedString("prepublishing.schedule", value: "Schedule", comment: "Primary button label in the pre-publishing shee")
    static let publishDate = NSLocalizedString("prepublishing.publishDate", value: "Publish Date", comment: "Label for a cell in the pre-publishing sheet")
    static let postTitle = NSLocalizedString("prepublishing.postTitle", value: "Title", comment: "Placeholder for a cell in the pre-publishing sheet")
    static let visibility = NSLocalizedString("prepublishing.visibility", value: "Visibility", comment: "Label for a cell in the pre-publishing sheet")
    static let categories = NSLocalizedString("prepublishing.categories", value: "Categories", comment: "Label for a cell in the pre-publishing sheet")
    static let tags = NSLocalizedString("prepublishing.tags", value: "Tags", comment: "Label for a cell in the pre-publishing sheet")
    static let jetpackSocial = NSLocalizedString("prepublishing.jetpackSocial", value: "Jetpack Social", comment: "Label for a cell in the pre-publishing sheet")
}
