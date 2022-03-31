import UIKit

class SiteIntentViewController: CollapsableHeaderViewController {
    private let selection: SiteIntentStep.SiteIntentSelection
    private let tableView: UITableView

    private var selectedVertical: SiteIntentVertical? {
        didSet {
            itemSelectionChanged(selectedVertical != nil)
        }
    }

    private var availableVerticals: [SiteIntentVertical] = SiteIntentData.defaultVerticals {
        didSet {
            contentSizeWillChange()
        }
    }

    private let searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        WPStyleGuide.configureSearchBar(searchBar)
        searchBar.setImage(UIImage(), for: .search, state: .normal)
        searchBar.backgroundColor = .clear
        searchBar.searchTextField.returnKeyType = .search
        return searchBar
    }()

    private lazy var continueButton: UIButton = {
        let button = FancyButton()
        button.isPrimary = true
        button.translatesAutoresizingMaskIntoConstraints = false
        button.titleLabel?.font = WPStyleGuide.fontForTextStyle(.body, fontWeight: .semibold)
        button.setTitle(Strings.continueButtonTitle, for: .normal)
        button.addTarget(self, action: #selector(navigateToNextStep), for: .touchUpInside)
        return button
    }()

    override var seperatorStyle: SeperatorStyle {
        return .hidden
    }

    init(_ selection: @escaping SiteIntentStep.SiteIntentSelection) {
        self.selection = selection
        tableView = UITableView(frame: .zero, style: .plain)

        super.init(
            scrollableView: tableView,
            mainTitle: Strings.mainTitle,
            navigationBarTitle: Strings.navigationBarTitle,
            prompt: Strings.prompt,
            primaryActionTitle: Strings.primaryAction,
            accessoryView: searchBar
        )

        tableView.dataSource = self
        searchBar.delegate = self
    }

    // MARK: UIViewController

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var keyboardSize: CGRect?

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigationBar()
        configureTable()

        largeTitleView.numberOfLines = Metrics.largeTitleLines
        SiteCreationAnalyticsHelper.trackSiteIntentViewed()
        observeKeyboard()
    }

    override func viewDidLayoutSubviews() {
        searchBar.placeholder = Strings.searchTextFieldPlaceholder
    }

    override func estimatedContentSize() -> CGSize {

        let visibleCells = CGFloat(availableVerticals.count)
        let height = visibleCells * IntentCell.estimatedSize.height
        return CGSize(width: view.frame.width, height: height)
    }

    // MARK: UI Setup

    private func configureNavigationBar() {
        // Title
        navigationItem.backButtonTitle = Strings.backButtonTitle
        // Skip button
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: Strings.skipButtonTitle,
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(skipButtonTapped))
        // Cancel button
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: Strings.cancelButtonTitle,
                                                           style: .done,
                                                           target: self,
                                                           action: #selector(closeButtonTapped))
    }

    private func configureTable() {
        let cellName = IntentCell.cellReuseIdentifier()
        let nib = UINib(nibName: cellName, bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: cellName)
        tableView.register(InlineErrorRetryTableViewCell.self, forCellReuseIdentifier: InlineErrorRetryTableViewCell.cellReuseIdentifier())
        tableView.cellLayoutMarginsFollowReadableWidth = true
        tableView.backgroundColor = .basicBackground
    }

    // MARK: Actions

    @objc
    private func skipButtonTapped(_ sender: Any) {
        SiteCreationAnalyticsHelper.trackSiteIntentSkipped()
        selection(nil)
    }

    @objc
    private func closeButtonTapped(_ sender: Any) {
        SiteCreationAnalyticsHelper.trackSiteIntentCanceled()
        dismiss(animated: true)
    }
}

// MARK: Constants
extension SiteIntentViewController {

    private enum Strings {
        static let mainTitle = NSLocalizedString("What's your website about?",
                                                 comment: "Select the site's intent. Title")
        static let navigationBarTitle = NSLocalizedString("Site Topic",
                                                          comment: "Title of the navigation bar, shown when the large title is hidden.")
        static let prompt = NSLocalizedString("Choose a topic from the list below or type your own",
                                              comment: "Select the site's intent. Subtitle")
        static let primaryAction = NSLocalizedString("Continue",
                                                     comment: "Button to progress to the next step")
        static let backButtonTitle = NSLocalizedString("Topic",
                                                       comment: "Shortened version of the main title to be used in back navigation")
        static let skipButtonTitle = NSLocalizedString("Skip",
                                                       comment: "Continue without making a selection")
        static let cancelButtonTitle = NSLocalizedString("Cancel",
                                                         comment: "Cancel site creation")
        static let searchTextFieldPlaceholder = NSLocalizedString("Eg. Fashion, Poetry, Politics", comment: "Placeholder text for the search field int the Site Intent screen.")
        static let continueButtonTitle = NSLocalizedString("Continue", comment: "Title of the continue button for the Site Intent screen.")
    }

    private enum Metrics {
        static let largeTitleLines = 2
        static let continueButtonPadding: CGFloat = 16
        static let continueButtonBottomOffset: CGFloat = 12
        static let continueButtonHeight: CGFloat = 44
    }
}

// MARK: UITableViewDataSource

extension SiteIntentViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return availableVerticals.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return configureIntentCell(tableView, cellForRowAt: indexPath)
    }

    func configureIntentCell(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: IntentCell.cellReuseIdentifier()) as? IntentCell else {
            assertionFailure("This is a programming error - IntentCell has not been properly registered!")
            return UITableViewCell()
        }

        let vertical = availableVerticals[indexPath.row]
        cell.model = vertical
        return cell
    }
}

// MARK: UITableViewDelegate

extension SiteIntentViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let vertical = availableVerticals[indexPath.row]

        SiteCreationAnalyticsHelper.trackSiteIntentSelected(vertical)
        selection(vertical)
    }
}

extension SiteIntentViewController: UISearchBarDelegate {
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        availableVerticals = SiteIntentData.verticals
        tableView.reloadData()
        tableView.scrollToView(searchBar.searchTextField, animated: true)
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        guard !searchText.isEmpty else {
            availableVerticals = SiteIntentData.verticals
            tableView.reloadData()
            return
        }

        let filteredVerticals = availableVerticals.filter {
            $0.localizedTitle.lowercased().contains(searchText.lowercased())
        }
    }
}

// MARK: Continue button
private extension SiteIntentViewController {

    /// Adds obsrvers to detect if the keyboard is present
    func observeKeyboard() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillShow),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillHide),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
    }

    /// stores the keyboard size when it shows up
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            self.keyboardSize = keyboardSize
        }
    }

    /// resets the keyboard size to nil when it hides
    @objc func keyboardWillHide(notification: NSNotification) {
        keyboardSize = nil
    }

    /// Continue button action
    @objc func navigateToNextStep() {
        selection(nil)
    }

    /// Adds or removes the continue button on top of the keyboard as needed
    func handleContinueButton(_ listIsEmpty: Bool) {

        guard let size = keyboardSize, listIsEmpty else {
            continueButton.removeFromSuperview()
            searchBar.searchTextField.enablesReturnKeyAutomatically = true
            return
        }

        view.addSubview(continueButton)
        NSLayoutConstraint.activate([
            continueButton.bottomAnchor.constraint(equalTo: view.bottomAnchor,
                                                   constant: -(size.height + Metrics.continueButtonBottomOffset)),
            continueButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Metrics.continueButtonPadding),
            continueButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Metrics.continueButtonPadding),
            continueButton.heightAnchor.constraint(equalToConstant: Metrics.continueButtonHeight)
        ])
        searchBar.searchTextField.enablesReturnKeyAutomatically = true
    }
}
