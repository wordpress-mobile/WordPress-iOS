import UIKit
import Gridicons
import Gutenberg

class GutenbergLayoutSection: CategorySection {
    var section: PageTemplateCategory
    var layouts: [PageTemplateLayout]
    var scrollOffset: CGPoint
    
    var title: String { section.title }
    var emoji: String? { section.emoji }
    var categorySlug: String { section.slug }
    var description: String? { section.desc }
    var thumbnails: [Thumbnail] {
        // TODO: pass device different modes
        layouts.map { Thumbnail(urlDesktop: $0.preview, urlTablet: $0.preview, urlMobile: $0.preview, slug: $0.slug) }
    }

    init(_ section: PageTemplateCategory) {
        let layouts = Array(section.layouts ?? []).sorted()
        self.section = section
        self.layouts = layouts
        self.scrollOffset = .zero
    }
}

class GutenbergLayoutPickerViewController: FilterableCategoriesViewController {
    internal var sections: [GutenbergLayoutSection] = []
    internal override var categorySections: [CategorySection] { get { sections }}
    lazy var resultsController: NSFetchedResultsController<PageTemplateCategory> = {
        let resultsController = PageLayoutService.resultsController(forBlog: blog, delegate: self)
        sections = makeSectionData(with: resultsController)
        return resultsController
    }()
    
    let completion: PageCoordinator.TemplateSelectionCompletion
    let blog: Blog
    
    init(blog: Blog, completion: @escaping PageCoordinator.TemplateSelectionCompletion) {
        self.blog = blog
        self.completion = completion
        
        super.init(
            mainTitle: NSLocalizedString("Choose a Layout", comment: "Title for the screen to pick a template for a page"),
            prompt: NSLocalizedString("Get started by choosing from a wide variety of pre-made page layouts. Or just start with a blank page.", comment: "Prompt for the screen to pick a template for a page"),
            primaryActionTitle: NSLocalizedString("Create Page", comment: "Title for button to make a page with the contents of the selected layout"),
            secondaryActionTitle: NSLocalizedString("Preview", comment: "Title for button to preview a selected layout"),
            defaultActionTitle: NSLocalizedString("Create Blank Page", comment: "Title for button to make a blank page"),
            backButtonTitle: NSLocalizedString("Choose layout", comment: "Shortened version of the main title to be used in back navigation")
        )
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        fetchLayouts()
    }

    private func presentPreview() {
        guard let sectionIndex = selectedItem?.section, let position = selectedItem?.item else { return }
        let layout = sections[sectionIndex].layouts[position]
        let destination = LayoutPreviewViewController(layout: layout, completion: completion)
        LayoutPickerAnalyticsEvent.templatePreview(slug: layout.slug)
        navigationController?.pushViewController(destination, animated: true)
    }
    
    private func createPage(layout: PageTemplateLayout?) {
        dismiss(animated: true) {
            self.completion(layout)
        }
    }
    
    private func fetchLayouts() {
        isLoading = resultsController.isEmpty()
        let expectedThumbnailSize = CategorySectionTableViewCell.expectedThumbnailSize
        PageLayoutService.fetchLayouts(forBlog: blog, withThumbnailSize: expectedThumbnailSize) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.dismissNoResultsController()
                case .failure(let error):
                    self?.handleErrors(error)
                }
            }
        }
    }
    
    private func handleErrors(_ error: Error) {
        guard resultsController.isEmpty() else { return }
        isLoading = false
        let titleText = NSLocalizedString("Unable to load this content right now.", comment: "Informing the user that a network request failed becuase the device wasn't able to establish a network connection.")
        let subtitleText = NSLocalizedString("Check your network connection and try again or create a blank page.", comment: "Default subtitle for no-results when there is no connection with a prompt to create a new page instead.")
        displayNoResultsController(title: titleText, subtitle: subtitleText, resultsDelegate: self)
    }
    
    private func makeSectionData(with controller: NSFetchedResultsController<PageTemplateCategory>?) -> [GutenbergLayoutSection] {
        return controller?.fetchedObjects?.map({ (category) -> GutenbergLayoutSection in
            return GutenbergLayoutSection(category)
        }) ?? []
    }

    
    // MARK: - Footer Actions
    override func defaultActionSelected(_ sender: Any) {
        createPage(layout: nil)
    }
    
    override func primaryActionSelected(_ sender: Any) {
        guard let sectionIndex = selectedItem?.section, let position = selectedItem?.item else {
            createPage(layout: nil)
            return
        }
        
        let layout = sections[sectionIndex].layouts[position]
        LayoutPickerAnalyticsEvent.templateApplied(slug: layout.slug)
        createPage(layout: layout)
    }
    
    override func secondaryActionSelected(_ sender: Any) {
        presentPreview()
    }
}






extension GutenbergLayoutPickerViewController: NSFetchedResultsControllerDelegate {
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        sections = makeSectionData(with: resultsController)
        isLoading = resultsController.isEmpty()
        contentSizeWillChange()
        tableView.reloadData()
    }
}

extension GutenbergLayoutPickerViewController: NoResultsViewControllerDelegate {
    func actionButtonPressed() {
        fetchLayouts()
    }
}
