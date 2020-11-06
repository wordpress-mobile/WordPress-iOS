import UIKit
import WordPressKit

class SiteDesignContentCollectionViewController: CollapsableHeaderViewController {
    let completion: SiteDesignStep.SiteDesignSelection
    let itemSpacing: CGFloat = 20
    let cellSize = CGSize(width: 160, height: 230)
    let restAPI = WordPressComRestApi.anonymousApi(userAgent: WPUserAgent.wordPress())
    let collectionView: UICollectionView
    let collectionViewLayout: UICollectionViewFlowLayout
    var isLoading = true
    var selectedIndexPath: IndexPath? = nil
    var siteDesigns: [RemoteSiteDesign] = [] {
        didSet {
            contentSizeWillChange()
            collectionView.reloadData()
        }
    }

    /// Calculates the necessary edge margins to make sure the content is centered. The design request is to limit the number of items in a row to 3 on larger screens, so the content is also capped there.
    private static func edgeInsets(forCellSize cellSize: CGSize, itemSpacing: CGFloat, screenSize: CGSize = UIScreen.main.bounds.size) -> UIEdgeInsets {
        let screenWidth = screenSize.width
        let cellsPerRow = floor(screenWidth / cellSize.width)
        let cellsPerRowCap = min(cellsPerRow, 3)
        let spacingCounts: CGFloat = (cellsPerRowCap == 3) ? 2 : 1 //If there are three rows account for 2 spacers and 1 if not.
        let contentWidth = (cellsPerRowCap * cellSize.width) + (itemSpacing * spacingCounts)
        let margin = (screenWidth - contentWidth) / 2
        return UIEdgeInsets(top: itemSpacing, left: margin, bottom: itemSpacing, right: margin)
    }

    init(_ completion: @escaping SiteDesignStep.SiteDesignSelection) {
        self.completion = completion
        collectionViewLayout = UICollectionViewFlowLayout()
        collectionViewLayout.sectionInset = SiteDesignContentCollectionViewController.edgeInsets(forCellSize: cellSize, itemSpacing: itemSpacing)
        collectionViewLayout.minimumLineSpacing = itemSpacing
        collectionViewLayout.minimumInteritemSpacing = itemSpacing
        collectionViewLayout.itemSize = cellSize

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
        collectionView.showsVerticalScrollIndicator = false
        collectionView.backgroundColor = .basicBackground
        collectionView.contentInsetAdjustmentBehavior = .never

        super.init(scrollableView: collectionView,
                   mainTitle: NSLocalizedString("Choose a design", comment: "Title for the screen to pick a design and homepage for a site."),
                   prompt: NSLocalizedString("Pick your favorite homepage layout. You can customize or change it later", comment: "Prompt for the screen to pick a design and homepage for a site."),
                   primaryActionTitle: NSLocalizedString("Choose", comment: "Title for the button to progress with the selected site homepage design"),
                   hasFilterBar: false)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.register(CollapsableHeaderCollectionViewCell.nib, forCellWithReuseIdentifier: CollapsableHeaderCollectionViewCell.cellReuseIdentifier)
        collectionView.dataSource = self
        fetchSiteDesigns()
        configureCloseButton()
        configureSkipButton()
    }

    override func estimatedContentSize() -> CGSize {
        guard isLoading || siteDesigns.count > 1 else { return .zero }
        let cellCount = isLoading ? 1 : siteDesigns.count
        let cellsPerRow = floor(collectionView.frame.size.width / cellSize.width)
        let rows = ceil(CGFloat(cellCount) / cellsPerRow)
        let estimatedHeight = rows * (cellSize.height + itemSpacing)
        return CGSize(width: collectionView.frame.width, height: estimatedHeight)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        let newEdgeInsets = SiteDesignContentCollectionViewController.edgeInsets(forCellSize: cellSize, itemSpacing: itemSpacing, screenSize: size)
        coordinator.animate { (_) in
            self.collectionViewLayout.sectionInset = newEdgeInsets
        }
    }

    private func fetchSiteDesigns() {
        isLoading = true
        let request = SiteDesignRequest(previewSize: cellSize, scale: UIScreen.main.nativeScale)
        SiteDesignServiceRemote.fetchSiteDesigns(restAPI, request: request) { [weak self] (response) in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch response {
                case .success(let result):
                    self?.dismissNoResultsController()
                    self?.siteDesigns = result
                case .failure(let error):
                    self?.handleError(error)
                }
            }
        }
    }

    private func configureSkipButton() {
        let skip = UIBarButtonItem(title: NSLocalizedString("Skip", comment: "Continue without making a selection"), style: .done, target: self, action: #selector(skipButtonTapped))
        navigationItem.rightBarButtonItem = skip
    }

    private func configureCloseButton() {
        let closeButton = UIBarButtonItem(image: .gridicon(.cross), style: .plain, target: self, action: #selector(closeButtonTapped))
        closeButton.title = NSLocalizedString("Close", comment: "Dismisses the current screen")
        navigationItem.leftBarButtonItem = closeButton
    }

    @objc func skipButtonTapped(_ sender: Any) {
        completion(nil)
    }

    @objc func closeButtonTapped(_ sender: Any) {
        dismiss(animated: true)
    }

    override func primaryActionSelected(_ sender: Any) {
        guard let selectedIndexPath = selectedIndexPath else {
            completion(nil)
            return
        }
        let design = siteDesigns[selectedIndexPath.row]
        completion(design)
    }

    private func handleError(_ error: Error) {
        let titleText = NSLocalizedString("Unable to load this content right now.", comment: "Informing the user that a network request failed becuase the device wasn't able to establish a network connection.")
        let subtitleText = NSLocalizedString("Check your network connection and try again or create a blank page.", comment: "Default subtitle for no-results when there is no connection with a prompt to create a new page instead.")
        displayNoResultsController(title: titleText, subtitle: subtitleText, resultsDelegate: self)
    }
}

// MARK: - UICollectionViewDataSource
extension SiteDesignContentCollectionViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return isLoading ? 1 : siteDesigns.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cellReuseIdentifier = CollapsableHeaderCollectionViewCell.cellReuseIdentifier
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellReuseIdentifier, for: indexPath) as? CollapsableHeaderCollectionViewCell else {
            fatalError("Expected the cell with identifier \"\(cellReuseIdentifier)\" to be a \(CollapsableHeaderCollectionViewCell.self). Please make sure the collection view is registering the correct nib before loading the data")
        }

        guard !isLoading else {
            cell.startGhostAnimation(style: GhostCellStyle.muriel)
            return cell
        }

        let siteDesign = siteDesigns[indexPath.row]
        cell.previewURL = siteDesign.screenshot
        cell.isAccessibilityElement = true
        cell.accessibilityLabel = siteDesign.title

        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension SiteDesignContentCollectionViewController: UICollectionViewDelegate {
    private func deselectItem(_ indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        collectionView(collectionView, didDeselectItemAt: indexPath)
    }

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        guard !isLoading else { return false }

        if collectionView.cellForItem(at: indexPath)?.isSelected ?? false {
            deselectItem(indexPath)
            return false
        }

        if selectedIndexPath == nil {
            itemSelectionChanged(true)
        }
        selectedIndexPath = indexPath

        return true
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        guard selectedIndexPath == indexPath else { return }
        selectedIndexPath = nil
        itemSelectionChanged(false)
    }
}

// MARK: - NoResultsViewControllerDelegate
extension SiteDesignContentCollectionViewController: NoResultsViewControllerDelegate {
    func actionButtonPressed() {
        fetchSiteDesigns()
    }
}
