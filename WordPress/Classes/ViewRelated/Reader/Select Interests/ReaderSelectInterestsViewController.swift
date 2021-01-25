import UIKit

class ReaderSelectInterestsViewController: UIViewController {
    private struct Constants {
        static let reuseIdentifier = ReaderInterestsCollectionViewCell.classNameWithoutNamespaces()
        static let interestsLabelMargin: CGFloat = 10

        static let cellCornerRadius: CGFloat = 8
        static let cellSpacing: CGFloat = 6
        static let cellHeight: CGFloat = 40
        static let animationDuration: TimeInterval = 0.2
        static let isCentered: Bool = true
    }

    private struct Strings {
        static let title: String = NSLocalizedString("Discover and follow blogs you love", comment: "Reader select interests title label text")
        static let subtitle: String = NSLocalizedString("Choose your interests", comment: "Reader select interests subtitle label text")
        static let nextButtonDisabled: String = NSLocalizedString("Select a few to continue", comment: "Reader select interests next button disabled title text")
        static let nextButtonEnabled: String = NSLocalizedString("Done", comment: "Reader select interests next button enabled title text")
        static let loading: String = NSLocalizedString("Finding blogs and stories you’ll love...", comment: "Label displayed to the user while loading their selected interests")
        static let tryAgainNoticeTitle = NSLocalizedString("Something went wrong. Please try again.", comment: "Error message shown when the app fails to save user selected interests")
        static let tryAgainButtonTitle = NSLocalizedString("Try Again", comment: "Try to load the list of interests again.")
    }

    // MARK: - IBOutlets
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subTitleLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var buttonContainerView: UIView!
    @IBOutlet weak var nextButton: FancyButton!
    @IBOutlet weak var contentContainerView: UIView!

    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var loadingLabel: UILabel!
    @IBOutlet weak var loadingView: UIStackView!

    @IBOutlet weak var bottomSpaceHeightConstraint: NSLayoutConstraint!

    // MARK: - Data
    private let dataSource: ReaderInterestsDataSource = ReaderInterestsDataSource()
    private let coordinator: ReaderSelectInterestsCoordinator = ReaderSelectInterestsCoordinator()

    private let noResultsViewController = NoResultsViewController.controller()

    var didSaveInterests: (() -> Void)? = nil

    override func viewDidLoad() {
        super.viewDidLoad()

        dataSource.delegate = self

        configureI18N()
        configureCollectionView()
        configureNoResultsViewController()
        applyStyles()
        updateNextButtonState()
        refreshData()

        // If the view is being presented overCurrentContext take into account tab bar height
        if modalPresentationStyle == .overCurrentContext {
            bottomSpaceHeightConstraint.constant = presentingViewController?.tabBarController?.tabBar.bounds.size.height ?? 0
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        resetSelectedInterests()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        WPAnalytics.trackReader(.selectInterestsShown)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        // If this view was presented over current context and it's disappearing
        // it means that the user switched tabs. Keeping it in the view hierarchy cause
        // weird black screens, so we dismiss it to avoid that.
        if modalPresentationStyle == .overCurrentContext {
            dismiss(animated: false)
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        guard let layout = collectionView.collectionViewLayout as? ReaderInterestsCollectionViewFlowLayout else {
            return
        }

        layout.invalidateLayout()
    }

    // MARK: - IBAction's
    @IBAction func nextButtonTapped(_ sender: Any) {
        saveSelectedInterests()
    }

    // MARK: - Display logic
    func userIsFollowingTopics(completion: @escaping (Bool) -> Void) {
        coordinator.isFollowingInterests(completion: completion)
    }

    // MARK: - Private: Configuration
    private func configureCollectionView() {
        let nib = UINib(nibName: String(describing: ReaderInterestsCollectionViewCell.self), bundle: nil)
        collectionView.register(nib, forCellWithReuseIdentifier: Constants.reuseIdentifier)

        guard let layout = collectionView.collectionViewLayout as? ReaderInterestsCollectionViewFlowLayout else {
            return
        }

        layout.itemSpacing = Constants.cellSpacing
        layout.cellHeight = Constants.cellHeight
        layout.isCentered = Constants.isCentered
    }

    private func configureNoResultsViewController() {
        noResultsViewController.delegate = self
    }

    private func applyStyles() {
        let styleGuide = ReaderInterestsStyleGuide.self
        styleGuide.applyTitleLabelStyles(label: titleLabel)
        styleGuide.applySubtitleLabelStyles(label: subTitleLabel)
        styleGuide.applyNextButtonStyle(button: nextButton)

        buttonContainerView.backgroundColor = ReaderInterestsStyleGuide.buttonContainerViewBackgroundColor

        styleGuide.applyLoadingLabelStyles(label: loadingLabel)
        styleGuide.applyActivityIndicatorStyles(indicator: activityIndicatorView)

    }

    private func configureI18N() {
        titleLabel.text = Strings.title
        subTitleLabel.text = Strings.subtitle
        nextButton.setTitle(Strings.nextButtonDisabled, for: .disabled)
        nextButton.setTitle(Strings.nextButtonEnabled, for: .normal)

        loadingLabel.text = Strings.loading
    }

    // MARK: - Private: Data
    private func refreshData() {
        startLoading(hideLabel: true)

        dataSource.reload()
    }

    private func resetSelectedInterests() {
        dataSource.reset()
        refreshData()
    }

    private func reloadData() {
        collectionView.reloadData()
        stopLoading()
    }

    private func saveSelectedInterests() {
        startLoading()
        announceLoadingTopics()

        let selectedInterests = dataSource.selectedInterests.map { $0.interest }

        coordinator.saveInterests(interests: selectedInterests) { [weak self] success in
            guard success else {
                self?.stopLoading()
                self?.displayNotice(title: Strings.tryAgainNoticeTitle)
                return
            }

            self?.trackEvents(with: selectedInterests)
            self?.stopLoading()
            self?.didSaveInterests?()
        }
    }

    private func trackEvents(with selectedInterests: [RemoteReaderInterest]) {
        selectedInterests.forEach {
            WPAnalytics.track(.readerTagFollowed, withProperties: ["tag": $0.slug, "source": "discover"])
        }

        WPAnalytics.trackReader(.selectInterestsPicked, properties: ["quantity": selectedInterests.count])
    }

    // MARK: - Private: UI Helpers
    private func updateNextButtonState() {
        nextButton.isEnabled = dataSource.selectedInterests.count > 0
    }

    private func startLoading(hideLabel: Bool = false) {
        loadingLabel.isHidden = hideLabel

        loadingView.alpha = 0
        loadingView.isHidden = false

        activityIndicatorView.startAnimating()

        contentContainerView.alpha = 0
        loadingView.alpha = 1
    }

    private func stopLoading() {
        activityIndicatorView.stopAnimating()

        UIView.animate(withDuration: Constants.animationDuration, animations: {
            self.contentContainerView.alpha = 1
            self.loadingView.alpha = 0
        }) { _ in
            self.loadingView.isHidden = true
        }
    }

    private func announceLoadingTopics() {
        UIAccessibility.post(notification: .screenChanged, argument: self.loadingLabel)
    }
}

// MARK: - UICollectionViewDataSource
extension ReaderSelectInterestsViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Constants.reuseIdentifier,
                                                          for: indexPath) as? ReaderInterestsCollectionViewCell else {
            fatalError("Expected a ReaderInterestsCollectionViewCell for identifier: \(Constants.reuseIdentifier)")
        }

        let interest: ReaderInterestViewModel = dataSource.interest(for: indexPath.row)

        ReaderInterestsStyleGuide.applyCellLabelStyle(label: cell.label,
                                                      isSelected: interest.isSelected)

        cell.layer.cornerRadius = Constants.cellCornerRadius
        cell.label.text = interest.title
        cell.label.accessibilityTraits = interest.isSelected ? [.selected, .button] : .button

        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension ReaderSelectInterestsViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        dataSource.interest(for: indexPath.row).toggleSelected()
        updateNextButtonState()

        UIView.animate(withDuration: 0) {
            collectionView.reloadItems(at: [indexPath])
        }
    }
}

// MARK: - UICollectionViewFlowLayout
extension ReaderSelectInterestsViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let interest: ReaderInterestViewModel = dataSource.interest(for: indexPath.row)

        let attributes: [NSAttributedString.Key: Any] = [
            .font: ReaderInterestsStyleGuide.cellLabelTitleFont
        ]

        let title: NSString = interest.title as NSString

        var size = title.size(withAttributes: attributes)
        size.width += (Constants.interestsLabelMargin * 2)

        return size
    }
}

// MARK: - ReaderInterestsDataDelegate
extension ReaderSelectInterestsViewController: ReaderInterestsDataDelegate {
    func readerInterestsDidUpdate(_ dataSource: ReaderInterestsDataSource) {
        if dataSource.count > 0 {
            hideLoadingView()
            reloadData()
        } else {
            displayLoadingViewWithWebAction(title: "")
        }
    }
}

// MARK: - NoResultsViewController
extension ReaderSelectInterestsViewController: NoResultsViewControllerDelegate {
    func actionButtonPressed() {
        refreshData()
    }
}

extension ReaderSelectInterestsViewController {
    func displayLoadingViewWithWebAction(title: String, accessoryView: UIView? = nil) {
        noResultsViewController.configure(title: title,
                                          buttonTitle: Strings.tryAgainButtonTitle,
                                          accessoryView: accessoryView)
        showLoadingView()
    }

    func showLoadingView() {
        hideLoadingView()
        addChild(noResultsViewController)
        view.addSubview(withFadeAnimation: noResultsViewController.view)
        noResultsViewController.didMove(toParent: self)
    }

    func hideLoadingView() {
        noResultsViewController.removeFromView()
    }
}
