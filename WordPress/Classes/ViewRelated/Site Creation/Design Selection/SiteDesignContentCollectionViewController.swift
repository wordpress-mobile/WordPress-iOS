import Gridicons
import UIKit
import WordPressKit
import WordPressShared
import WordPressUI

class SiteDesignContentCollectionViewController: CollapsableHeaderViewController {
    typealias PreviewDevice = PreviewDeviceSelectionViewController.PreviewDevice

    private let creator: SiteCreator
    private let createsSite: Bool
    private let tableView: UITableView
    private let completion: SiteDesignStep.SiteDesignSelection
    private var sectionAssembler: SiteDesignSectionLoader.Assembler?

    private var sections: [SiteDesignSection] = []

    /// Whether a design request is running, so that appearing again before it finishes doesn't start another.
    private var isFetchingDesigns = false

    /// The horizontal scroll position of each section, keyed by category slug. It's measured in thumbnails
    /// rather than points, so a row keeps its position when the thumbnail size changes.
    private var sectionHorizontalPositions: [String: CGFloat] = [:]

    private var isLoading: Bool = true {
        didSet {
            if isLoading {
                tableView.startGhostAnimation(style: GhostCellStyle.muriel)
            } else {
                tableView.stopGhostAnimation()
            }

            tableView.reloadData()
        }
    }

    private var previewViewSelectedPreviewDevice = PreviewDevice.default

    private var ghostThumbnailSize: CGSize {
        SiteDesignCategoryThumbnailSize.recommended.value(for: windowSizeClass)
    }

    /// The thumbnail sizes follow the window's horizontal size class: this screen is a page sheet, which
    /// reports a compact size class in a wide iPad window.
    private var windowSizeClass: UIUserInterfaceSizeClass {
        viewIfLoaded?.window?.traitCollection.horizontalSizeClass ?? traitCollection.horizontalSizeClass
    }

    /// The window's horizontal size class at the last layout pass, to lay out the rows again when it changes.
    private var laidOutWindowSizeClass: UIUserInterfaceSizeClass?

    // MARK: Helper Footer View
    override var allowCustomTableFooterView: Bool {
        true
    }

    override var alwaysResetHeaderOnRotation: Bool {
        true
    }

    private lazy var helperView: UIView = {
        let view = UIView(frame: Metrics.helperFrame)
        view.addSubview(helperStackView)
        view.pinSubviewToAllEdges(helperStackView)
        return view
    }()

    private lazy var helperStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [helperSeparator, helperContentView])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        return stackView
    }()

    private lazy var helperSeparator: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .separator
        return view
    }()

    private lazy var helperContentView: UIView = {
        let view = UIView()
        view.addSubview(helperContentStackView)
        view.pinSubviewToAllEdges(helperContentStackView, insets: Metrics.helperPadding)
        return view
    }()

    private lazy var helperContentStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [helperImageStackView, helperLabelStackView])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.spacing = Metrics.helperSpacing
        return stackView
    }()

    private lazy var helperImageStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [helperImageView, UIView()])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        return stackView
    }()

    private lazy var helperImageView: UIImageView = {
        let imageView = UIImageView(image: .gridicon(.infoOutline))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.tintColor = .secondaryLabel
        return imageView
    }()

    private lazy var helperLabelStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [helperLabel, UIView()])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        return stackView
    }()

    private lazy var helperLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = WPStyleGuide.fontForTextStyle(.body)
        label.numberOfLines = Metrics.helperTextNumberOfLines
        label.text = TextContent.helperText
        label.textColor = .secondaryLabel
        label.adjustsFontForContentSizeCategory = true
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = Metrics.helperTextMinimumScaleFactor
        return label
    }()

    private func activateHelperConstraints() {
        NSLayoutConstraint.activate([
            helperImageView.heightAnchor.constraint(equalToConstant: Metrics.helperImageWidth),
            helperImageView.widthAnchor.constraint(equalToConstant: Metrics.helperImageWidth),
            helperSeparator.makeHairlineConstraint(for: helperSeparator.heightAnchor)
        ])
    }

    private func setupHelperView() {
        tableView.tableFooterView = helperView
        activateHelperConstraints()

        helperSeparator.isHidden = traitCollection.preferredContentSizeCategory.isAccessibilityCategory
        helperContentView.isHidden = traitCollection.preferredContentSizeCategory.isAccessibilityCategory
    }

    let selectedPreviewDevice = PreviewDevice.mobile

    init(creator: SiteCreator, createsSite: Bool, completion: @escaping SiteDesignStep.SiteDesignSelection) {
        self.creator = creator
        self.createsSite = createsSite
        self.completion = completion
        tableView = UITableView(frame: .zero, style: .plain)

        super
            .init(
                scrollableView: tableView,
                mainTitle: TextContent.mainTitle,
                // the primary action button is never shown
                primaryActionTitle: ""
            )

        tableView.separatorStyle = .singleLine
        tableView.separatorInset = .zero
        tableView.showsVerticalScrollIndicator = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(
            CategorySectionTableViewCell.defaultNib,
            forCellReuseIdentifier: CategorySectionTableViewCell.cellReuseIdentifier
        )
        tableView.dataSource = self
        navigationItem.backButtonTitle = TextContent.backButtonTitle
        configureHeaderStyling()
        configureCloseButton()
        configureSkipButton()
        SiteCreationAnalyticsHelper.trackSiteDesignViewed(previewMode: selectedPreviewDevice)

        // The base class handles the header traits. This subclass owns only the
        // helper footer, which hides at accessibility text sizes.
        registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { (self: Self, _) in
            self.helperSeparator.isHidden = self.traitCollection.preferredContentSizeCategory.isAccessibilityCategory
            self.helperContentView.isHidden = self.traitCollection.preferredContentSizeCategory.isAccessibilityCategory
        }
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        // The page sheet's own size class doesn't change when the window is resized, but the sheet is laid
        // out again. Lay out the rows at the new thumbnail sizes when the window's size class has changed.
        guard view.window != nil else { return }
        let sizeClass = windowSizeClass
        if let laidOutWindowSizeClass, laidOutWindowSizeClass != sizeClass {
            contentSizeWillChange()
            tableView.reloadData()
        }
        laidOutWindowSizeClass = sizeClass
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Disable the button temporarily during the transition animation.
        //
        // Relates to https://linear.app/a8c/issue/CMM-1059
        //
        // The first couple of steps of the site creation process have a "Skip" button, which is
        // placed at the same position as `rightBarButtonItem`.
        // When users double-tap the "Skip" button, the first tap event is passed to the displaying
        // view controller which pushes another view controller as the next step, and the second
        // event is passed to the new step which executes the "skip" code again.
        // This means double-tapping "Skip" skips two steps at the same time, which is not handled
        // correctly by `WizardNavigation.nextStep` and causes a crash.
        //
        // Here we disable the skip button during transition to prevent the new step from receiving
        // the second tap event.
        //
        // An alternative is to fix the `WizardNavigation.nextStep` function to allow skipping
        // multiple steps at the same time. But I don't think that's a UX we want, because when
        // double-tapping the "Skip" button on screen, the user does not know what the next steps
        // are, and it does not make sense to skip them all together.
        navigationItem.rightBarButtonItem?.isEnabled = false
    }

    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        // The design request needs the scale of the screen that displays the thumbnails,
        // which is only known once the view is in a window.
        fetchSiteDesigns()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationItem.rightBarButtonItem?.isEnabled = true
    }

    private func fetchSiteDesigns() {
        if let sectionAssembler {
            showSections(sectionAssembler(creator.vertical))
            return
        }

        guard !isFetchingDesigns else {
            return
        }

        guard let scale = view.window?.windowScene?.screen.nativeScale else {
            return wpAssertionFailure(
                "SiteDesignContentCollectionViewController.fetchSiteDesigns() requires the view to be in a window"
            )
        }

        isLoading = true
        isFetchingDesigns = true

        DispatchQueue.main.async { [weak self] in
            SiteDesignSectionLoader.buildAssembler(scale: scale) { result in
                guard let self else { return }
                self.isFetchingDesigns = false

                switch result {
                case .success(let assembler):
                    self.sectionAssembler = assembler
                    self.dismissNoResultsController()
                    self.showSections(assembler(self.creator.vertical))
                    self.setupHelperView()
                case .failure(let error):
                    self.handleError(error)
                }

                self.isLoading = false
            }
        }
    }

    /// Shows a newly assembled list of sections, scrolled to the top.
    private func showSections(_ sections: [SiteDesignSection]) {
        self.sections = sections
        tableView.scrollToTop(animated: false)
        sectionHorizontalPositions.removeAll()
        contentSizeWillChange()
        tableView.reloadData()
    }

    private func configureHeaderStyling() {
        headerView.backgroundColor = .systemBackground
        hideHeaderVisualEffects()
    }

    private func configureSkipButton() {
        let skip = UIBarButtonItem(
            title: TextContent.skipButtonTitle,
            style: .plain,
            target: self,
            action: #selector(skipButtonTapped)
        )
        navigationItem.rightBarButtonItem = skip
    }

    private func configureCloseButton() {
        guard navigationController?.viewControllers.first == self else {
            return
        }

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(closeButtonTapped)
        )
    }

    @objc
    private func closeButtonTapped(_ sender: Any) {
        dismiss(animated: true)
    }

    @objc
    private func skipButtonTapped(_ sender: Any) {
        presentedViewController?.dismiss(animated: true)
        SiteCreationAnalyticsHelper.trackSiteDesignSkipped()
        completion(nil)
    }

    private func handleError(_ error: Error) {
        SiteCreationAnalyticsHelper.trackError(error)
        let titleText = TextContent.errorTitle
        let subtitleText = TextContent.errorSubtitle
        displayNoResultsController(title: titleText, subtitle: subtitleText, resultsDelegate: self)
    }

    private enum TextContent {
        static let mainTitle = NSLocalizedString(
            "Choose a theme",
            comment: "Title for the screen to pick a theme and homepage for a site."
        )
        static let backButtonTitle = NSLocalizedString(
            "Design",
            comment: "Shortened version of the main title to be used in back navigation."
        )
        static let skipButtonTitle = NSLocalizedString(
            "Skip",
            comment: "Continue without making a selection."
        )
        static let errorTitle = NSLocalizedString(
            "Unable to load this content right now.",
            comment:
                "Informing the user that a network request failed because the device wasn't able to establish a network connection."
        )
        static let errorSubtitle = NSLocalizedString(
            "Check your network connection and try again.",
            comment: "Default subtitle for no-results when there is no connection."
        )
        static let helperText = NSLocalizedString(
            "Can’t decide? You can change the theme at any time.",
            comment: "Helper text that appears at the bottom of the design screen."
        )
    }

    private enum Metrics {
        // Frame of the bottom helper: width will be automatically calucuated by assigning it to tableview.tableFooterView
        static let helperFrame = CGRect(x: 0, y: 0, width: 0, height: 90)
        static let helperImageWidth: CGFloat = 24.0
        static let helperPadding = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        static let helperSpacing: CGFloat = 16

        static let helperTextNumberOfLines = 2
        static let helperTextMinimumScaleFactor: CGFloat = 0.6
    }
}

// MARK: - NoResultsViewControllerDelegate

extension SiteDesignContentCollectionViewController: NoResultsViewControllerDelegate {

    func actionButtonPressed() {
        fetchSiteDesigns()
    }
}

// MARK: - UITableViewDataSource

extension SiteDesignContentCollectionViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        isLoading ? 1 : (sections.count)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellReuseIdentifier = CategorySectionTableViewCell.cellReuseIdentifier
        guard
            let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath)
                as? CategorySectionTableViewCell
        else {
            fatalError(
                "Expected the cell with identifier \"\(cellReuseIdentifier)\" to be a \(CategorySectionTableViewCell.self). Please make sure the table view is registering the correct nib before loading the data"
            )
        }
        cell.delegate = self
        cell.selectionStyle = UITableViewCell.SelectionStyle.none

        if isLoading {
            cell.section = nil
            cell.isGhostCell = true
            cell.ghostThumbnailSize = ghostThumbnailSize
            cell.collectionView.allowsSelection = false
        } else {
            var section = sections[indexPath.row]
            section.windowSizeClass = windowSizeClass
            cell.section = section
            cell.isGhostCell = false
            cell.collectionView.allowsSelection = true
            let position = sectionHorizontalPositions[section.categorySlug] ?? .zero
            cell.horizontalScrollOffset = position * thumbnailStride(for: section, in: cell)
        }

        cell.showsCheckMarkWhenSelected = false
        cell.layer.masksToBounds = false
        cell.clipsToBounds = false
        cell.categoryTitleFont = WPStyleGuide.serifFontForTextStyle(.title2, fontWeight: .semibold)
        return cell
    }
}

// MARK: - CategorySectionTableViewCellDelegate

extension SiteDesignContentCollectionViewController: CategorySectionTableViewCellDelegate {

    func didSelectItemAt(_ position: Int, forCell cell: CategorySectionTableViewCell, slug: String) {
        guard let sectionIndex = sections.firstIndex(where: { $0.categorySlug == slug }) else { return }
        let section = sections[sectionIndex]
        let design = section.designs[position]
        let sectionType = section.sectionType

        let previewVC = SiteDesignPreviewViewController(
            siteDesign: design,
            selectedPreviewDevice: previewViewSelectedPreviewDevice,
            createsSite: createsSite,
            sectionType: sectionType,
            onDismissWithDeviceSelected: { [weak self] device in
                self?.previewViewSelectedPreviewDevice = device
            },
            completion: completion
        )

        let navController: UINavigationController
        if #available(iOS 26, *) {
            navController = UINavigationController(rootViewController: previewVC)
        } else {
            navController = GutenbergLightNavigationController(rootViewController: previewVC)
        }
        navController.modalPresentationStyle = .pageSheet
        navigationController?
            .present(navController, animated: true) {
                // deselect so no border is shown on dismissal of the preview
                cell.deselectItems()
            }
    }

    func didDeselectItem(forCell cell: CategorySectionTableViewCell) {}

    func accessibilityElementDidBecomeFocused(forCell cell: CategorySectionTableViewCell) {
        guard UIAccessibility.isVoiceOverRunning, let cellIndexPath = tableView.indexPath(for: cell) else { return }
        tableView.scrollToRow(at: cellIndexPath, at: .middle, animated: true)
    }

    func saveHorizontalScrollPosition(forCell cell: CategorySectionTableViewCell, xPosition: CGFloat) {
        guard let cellSection = cell.section else {
            return
        }
        sectionHorizontalPositions[cellSection.categorySlug] = xPosition / thumbnailStride(for: cellSection, in: cell)
    }

    /// The width of a thumbnail in the section's row, plus the space after it.
    private func thumbnailStride(for section: CategorySection, in cell: CategorySectionTableViewCell) -> CGFloat {
        let spacing = (cell.collectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.minimumLineSpacing ?? 0
        return section.thumbnailSize.width + spacing
    }
}
