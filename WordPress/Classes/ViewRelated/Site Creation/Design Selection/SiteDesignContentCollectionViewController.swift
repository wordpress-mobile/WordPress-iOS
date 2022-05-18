import UIKit
import WordPressKit

class SiteDesignContentCollectionViewController: CollapsableHeaderViewController {
    typealias TemplateGroup = SiteDesignRequest.TemplateGroup
    typealias PreviewDevice = PreviewDeviceSelectionViewController.PreviewDevice

    private let createsSite: Bool
    private let templateGroups: [TemplateGroup] = [.stable, .singlePage]
    private let tableView: UITableView
    private let completion: SiteDesignStep.SiteDesignSelection
    private let restAPI = WordPressComRestApi.anonymousApi(
        userAgent: WPUserAgent.wordPress(),
        localeKey: WordPressComRestApi.LocaleKeyV2
    )
    private var sections: [SiteDesignSection] = []
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
    private var siteDesigns = RemoteSiteDesigns() {
        didSet {
            if oldValue.categories.count == 0 {
                scrollableView.setContentOffset(.zero, animated: false)
            }
            sections = siteDesigns.categories.map { category in
                SiteDesignSection(
                    category: category,
                    designs: siteDesigns.designs.filter { design in design.categories.map({$0.slug}).contains(category.slug) },
                    thumbnailSize: SiteDesignCategoryThumbnailSize.category.value
                )
            }
            contentSizeWillChange()
            tableView.reloadData()
        }
    }

    private var ghostThumbnailSize: CGSize {
        return SiteDesignCategoryThumbnailSize.category.value
    }

    let selectedPreviewDevice = PreviewDevice.mobile

    init(createsSite: Bool, _ completion: @escaping SiteDesignStep.SiteDesignSelection) {
        self.completion = completion
        self.createsSite = createsSite
        tableView = UITableView(frame: .zero, style: .plain)

        super.init(
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
        tableView.register(CategorySectionTableViewCell.nib, forCellReuseIdentifier: CategorySectionTableViewCell.cellReuseIdentifier)
        tableView.dataSource = self
        navigationItem.backButtonTitle = TextContent.backButtonTitle
        fetchSiteDesigns()
        configureCloseButton()
        configureSkipButton()
        SiteCreationAnalyticsHelper.trackSiteDesignViewed(previewMode: selectedPreviewDevice)
    }

    private func fetchSiteDesigns() {
        isLoading = true
        let request = SiteDesignRequest(
            withThumbnailSize: SiteDesignCategoryThumbnailSize.category.value,
            withGroups: templateGroups
        )
        SiteDesignServiceRemote.fetchSiteDesigns(restAPI, request: request) { [weak self] (response) in
            DispatchQueue.main.async {
                switch response {
                case .success(let result):
                    self?.dismissNoResultsController()
                    self?.siteDesigns = result
                case .failure(let error):
                    self?.handleError(error)
                }
                self?.isLoading = false
            }
        }
    }

    private func configureSkipButton() {
        let skip = UIBarButtonItem(title: TextContent.skipButtonTitle, style: .done, target: self, action: #selector(skipButtonTapped))
        navigationItem.rightBarButtonItem = skip
    }

    private func configureCloseButton() {
        guard navigationController?.viewControllers.first == self else {
            return
        }

        navigationItem.leftBarButtonItem = UIBarButtonItem(title: TextContent.cancelButtonTitle, style: .done, target: self, action: #selector(closeButtonTapped))
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
        static let mainTitle = NSLocalizedString("Choose a theme", comment: "Title for the screen to pick a theme and homepage for a site.")
        static let backButtonTitle = NSLocalizedString("Design", comment: "Shortened version of the main title to be used in back navigation.")
        static let skipButtonTitle = NSLocalizedString("Skip", comment: "Continue without making a selection.")
        static let cancelButtonTitle = NSLocalizedString("Cancel", comment: "Cancel site creation.")
        static let errorTitle = NSLocalizedString("Unable to load this content right now.", comment: "Informing the user that a network request failed becuase the device wasn't able to establish a network connection.")
        static let errorSubtitle = NSLocalizedString("Check your network connection and try again.", comment: "Default subtitle for no-results when there is no connection.")
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
        return isLoading ? 1 : (sections.count)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellReuseIdentifier = CategorySectionTableViewCell.cellReuseIdentifier
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath) as? CategorySectionTableViewCell else {
            fatalError("Expected the cell with identifier \"\(cellReuseIdentifier)\" to be a \(CategorySectionTableViewCell.self). Please make sure the table view is registering the correct nib before loading the data")
        }
        cell.delegate = self
        cell.selectionStyle = UITableViewCell.SelectionStyle.none
        cell.section = isLoading ? nil : sections[indexPath.row]
        cell.isGhostCell = isLoading
        cell.ghostThumbnailSize = ghostThumbnailSize
        cell.showsCheckMarkWhenSelected = false
        cell.layer.masksToBounds = false
        cell.clipsToBounds = false
        cell.collectionView.allowsSelection = !isLoading
        return cell
    }
}

// MARK: - CategorySectionTableViewCellDelegate

extension SiteDesignContentCollectionViewController: CategorySectionTableViewCellDelegate {

    func didSelectItemAt(_ position: Int, forCell cell: CategorySectionTableViewCell, slug: String) {
        guard let sectionIndex = sections.firstIndex(where: { $0.categorySlug == slug }) else { return }
        let design = sections[sectionIndex].designs[position]

        let previewVC = SiteDesignPreviewViewController(
            siteDesign: design,
            selectedPreviewDevice: previewViewSelectedPreviewDevice,
            createsSite: createsSite,
            onDismissWithDeviceSelected: { [weak self] device in
                self?.previewViewSelectedPreviewDevice = device
                cell.deselectItems()
            },
            completion: completion
        )

        let navController = GutenbergLightNavigationController(rootViewController: previewVC)
        navController.modalPresentationStyle = .pageSheet
        navigationController?.present(navController, animated: true)
    }

    func didDeselectItem(forCell cell: CategorySectionTableViewCell) {}

    func accessibilityElementDidBecomeFocused(forCell cell: CategorySectionTableViewCell) {
        guard UIAccessibility.isVoiceOverRunning, let cellIndexPath = tableView.indexPath(for: cell) else { return }
        tableView.scrollToRow(at: cellIndexPath, at: .middle, animated: true)
    }
}
