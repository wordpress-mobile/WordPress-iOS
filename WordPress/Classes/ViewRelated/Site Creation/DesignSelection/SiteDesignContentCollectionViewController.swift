import UIKit
import WordPressKit

class SiteDesignContentCollectionViewController: CollapsableHeaderViewController {
    let itemSpacing: CGFloat = 20
    let cellSize = CGSize(width: 160, height: 230)
    let restAPI = WordPressComRestApi.anonymousApi(userAgent: WPUserAgent.wordPress())
    let collectionView: UICollectionView
    let collectionViewLayout: UICollectionViewFlowLayout
    var isLoading = true

    var siteDesigns: [RemoteSiteDesign] = [] {
        didSet {
            collectionView.reloadData()
        }
    }

    /// Calculates the necessary edge margins to make sure the content is centered. The design request is to limit the number of items in a row to 3 on larger screens, so the content is also capped there.
    private static func edgeInsets(forCellSize cellSize: CGSize, itemSpacing: CGFloat) -> UIEdgeInsets {
        let screenWidth = UIScreen.main.bounds.width
        let cellsPerRow = floor(screenWidth / cellSize.width)
        let cellsPerRowCap = min(cellsPerRow, 3)
        let spacingCounts: CGFloat = (cellsPerRowCap == 3) ? 2 : 1 //If there are three rows account for 2 spacers and 1 if not.
        let contentWidth = (cellsPerRowCap * cellSize.width) + (itemSpacing * spacingCounts)
        let margin = (screenWidth - contentWidth) / 2
        return UIEdgeInsets(top: itemSpacing, left: margin, bottom: 0, right: margin)
    }

    init() {
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
    }

    override func estimatedContentSize() -> CGSize {
        guard isLoading || siteDesigns.count > 1 else { return .zero }
        let cellCount = isLoading ? 1 : siteDesigns.count
        let cellsPerRow = floor(collectionView.frame.size.width / cellSize.width)
        let rows = ceil(CGFloat(cellCount) / cellsPerRow)
        let estimatedHeight = rows * (cellSize.height + itemSpacing)
        return CGSize(width: collectionView.frame.width, height: estimatedHeight)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
    }

    private func fetchSiteDesigns() {
        let request = SiteDesignRequest(previewSize: cellSize, scale: UIScreen.main.nativeScale)
        SiteDesignServiceRemote.fetchSiteDesigns(restAPI, request: request) { [weak self] (response) in
            DispatchQueue.main.async {
                switch response {
                case .success(let result):
                    self?.isLoading = false
                    self?.siteDesigns = result
                case .failure(let error):
                    self?.handleError(error)
                }
            }
        }
    }

    override func primaryActionSelected(_ sender: Any) {
        /* ToDo */
    }

    private func handleError(_ error: Error) {
        /* ToDo */
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

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return !isLoading
    }
}
