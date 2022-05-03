import UIKit
import WordPressKit

extension RemoteSiteDesign: Thumbnail {
    var urlDesktop: String? { screenshot }
    var urlTablet: String? { tabletScreenshot }
    var urlMobile: String? { mobileScreenshot}
}

class SiteDesignSection: CategorySection {
    var category: RemoteSiteDesignCategory
    var designs: [RemoteSiteDesign]

    var categorySlug: String { category.slug }
    var title: String { category.title }
    var emoji: String? { category.emoji }
    var description: String? { category.description }
    var thumbnails: [Thumbnail] { designs }
    var scrollOffset: CGPoint

    init(category: RemoteSiteDesignCategory, designs: [RemoteSiteDesign]) {
        self.category = category
        self.designs = designs
        self.scrollOffset = .zero
    }
}

class SiteDesignContentCollectionViewController: FilterableCategoriesViewController, UIPopoverPresentationControllerDelegate {
    typealias TemplateGroup = SiteDesignRequest.TemplateGroup
    private let createsSite: Bool
    private let templateGroups: [TemplateGroup] = [.stable, .singlePage]

    let completion: SiteDesignStep.SiteDesignSelection
    let restAPI = WordPressComRestApi.anonymousApi(userAgent: WPUserAgent.wordPress(), localeKey: WordPressComRestApi.LocaleKeyV2)
    var selectedIndexPath: IndexPath? = nil
    private var sections: [SiteDesignSection] = []
    internal override var categorySections: [CategorySection] { get { sections }}

    override var selectedPreviewDevice: PreviewDevice {
        get { .mobile }
        set { /* no op */ }
    }

    private lazy var previewViewSelectedPreviewDevice = PreviewDevice.default

    var siteDesigns = RemoteSiteDesigns() {
        didSet {
            if oldValue.categories.count == 0 {
                scrollableView.setContentOffset(.zero, animated: false)
            }
            sections = siteDesigns.categories.map { category in
                SiteDesignSection(category: category, designs: siteDesigns.designs.filter { design in design.categories.map({$0.slug}).contains(category.slug)
                })
            }
            NSLog("sections: %@", String(describing: sections))
            contentSizeWillChange()
            tableView.reloadData()
        }
    }

    var selectedDesign: RemoteSiteDesign? {
        guard let sectionIndex = selectedItem?.section, let position = selectedItem?.item else { return nil }
        return sections[sectionIndex].designs[position]
    }

    init(createsSite: Bool, _ completion: @escaping SiteDesignStep.SiteDesignSelection) {
        self.completion = completion
        self.createsSite = createsSite

        super.init(
            analyticsLocation: "site_creation",
            mainTitle: TextContent.mainTitle,
            primaryActionTitle: createsSite ? TextContent.createSiteButton : TextContent.chooseButton,
            secondaryActionTitle: TextContent.previewButton,
            showsFilterBar: false
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.backButtonTitle = TextContent.backButtonTitle
        fetchSiteDesigns()
        configureCloseButton()
        configureSkipButton()
        SiteCreationAnalyticsHelper.trackSiteDesignViewed(previewMode: selectedPreviewDevice)
    }

    private func fetchSiteDesigns() {
        isLoading = true
        let thumbnailSize = CategorySectionTableViewCell.expectedThumbnailSize
        let request = SiteDesignRequest(withThumbnailSize: thumbnailSize, withGroups: templateGroups)
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

    @objc func skipButtonTapped(_ sender: Any) {
        presentedViewController?.dismiss(animated: true)
        SiteCreationAnalyticsHelper.trackSiteDesignSkipped()
        completion(nil)
    }

    override func primaryActionSelected(_ sender: Any) {
        guard let design = selectedDesign else {
            completion(nil)
            return
        }
        SiteCreationAnalyticsHelper.trackSiteDesignSelected(design)
        completion(design)
    }

    override func secondaryActionSelected(_ sender: Any) {
        guard let design = selectedDesign else { return }

        let previewVC = SiteDesignPreviewViewController(
            siteDesign: design,
            selectedPreviewDevice: previewViewSelectedPreviewDevice,
            createsSite: createsSite,
            onDismissWithDeviceSelected: { [weak self] device in
                self?.previewViewSelectedPreviewDevice = device
            },
            completion: completion
        )

        let navController = GutenbergLightNavigationController(rootViewController: previewVC)
        navController.modalPresentationStyle = .pageSheet
        navigationController?.present(navController, animated: true)
    }

    private func handleError(_ error: Error) {
        SiteCreationAnalyticsHelper.trackError(error)
        let titleText = TextContent.errorTitle
        let subtitleText = TextContent.errorSubtitle
        displayNoResultsController(title: titleText, subtitle: subtitleText, resultsDelegate: self)
    }

    private enum TextContent {
        static let mainTitle = NSLocalizedString("Choose a theme", comment: "Title for the screen to pick a theme and homepage for a site.")
        static let createSiteButton = NSLocalizedString("Create Site", comment: "Title for the button to progress with creating the site with the selected design.")
        static let chooseButton = NSLocalizedString("Choose", comment: "Title for the button to progress with the selected site homepage design.")
        static let previewButton = NSLocalizedString("Preview", comment: "Title for button to preview a selected homepage design.")
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
