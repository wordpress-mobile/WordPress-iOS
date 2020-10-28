import UIKit
import WordPressKit

class SiteDesignContentCollectionViewController: UICollectionViewController, CollapsableHeaderDataSource {
    let mainTitle = NSLocalizedString("Choose a design", comment: "Title for the screen to pick a design and homepage for a site.")
    let prompt = NSLocalizedString("Pick your favorite homepage layout. You can customize or change it later", comment: "Prompt for the screen to pick a design and homepage for a site.")
    let defaultActionTitle: String? = nil
    let primaryActionTitle = NSLocalizedString("Choose", comment: "Title for the button to progress with the selected site homepage design")
    let secondaryActionTitle = NSLocalizedString("Preview", comment: "Title for the button to preview the selected site homepage design")

    var scrollView: UIScrollView {
        return collectionView
    }

    var siteDesigns: [RemoteSiteDesign] = [] {
        didSet {
            collectionView.reloadData()
        }
    }
    var isLoading = true
    let cellSize = CGSize(width: 150, height: 230)
    let restAPI = WordPressComRestApi.anonymousApi(userAgent: WPUserAgent.wordPress())

    init() {
        super.init(nibName: "\(SiteDesignContentCollectionViewController.self)", bundle: .main)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.register(CollapsableHeaderCollectionViewCell.nib, forCellWithReuseIdentifier: CollapsableHeaderCollectionViewCell.cellReuseIdentifier)
    }

    func estimatedContentSize() -> CGSize {
        guard isLoading || siteDesigns.count > 1 else { return .zero }
        let cellCount = isLoading ? 1 : siteDesigns.count
        let cellsPerRow = floor(collectionView.frame.size.width / cellSize.width)
        let rows = ceil(CGFloat(cellCount) / cellsPerRow)
        let flowLayout = (collectionView.collectionViewLayout as? UICollectionViewFlowLayout)
        let topSpacing = (flowLayout?.sectionInset.top ?? 1)
        let lineSpacing = (flowLayout?.minimumLineSpacing ?? 01) * max(rows - 2, 0)
        let estimatedHeight = rows * cellSize.height + topSpacing + lineSpacing
        return CGSize(width: collectionView.frame.width, height: estimatedHeight)
    }

    private func fetchSiteDesigns() {
        SiteDesignServiceRemote.fetchSiteDesigns(restAPI) { [weak self] (response) in
            DispatchQueue.main.async {
                switch response {
                case .success(let result):
                    self?.siteDesigns = result
                case .failure(let error):
                    self?.handleError(error)
                }
            }
        }
    }

    private func handleError(_ error: Error) {
        /* ToDo */
    }

    // MARK: UICollectionViewDataSource
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return isLoading ? 1 : siteDesigns.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cellReuseIdentifier = CollapsableHeaderCollectionViewCell.cellReuseIdentifier
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellReuseIdentifier, for: indexPath) as? CollapsableHeaderCollectionViewCell else {
            fatalError("Expected the cell with identifier \"\(cellReuseIdentifier)\" to be a \(CollapsableHeaderCollectionViewCell.self). Please make sure the collection view is registering the correct nib before loading the data")
        }

        guard !isLoading else {
            cell.startGhostAnimation(style: GhostCellStyle.muriel)
            return cell
        }

//        let layout = layouts[indexPath.row]
//        cell.previewURL = layout.preview
//        cell.isAccessibilityElement = true
//        cell.accessibilityLabel = layout.slug

        return cell
    }

    // MARK: UICollectionViewFlowLayout
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return cellSize
    }
}

// MARK: - CollapsableHeaderDelegate
extension SiteDesignContentCollectionViewController: CollapsableHeaderDelegate {
    func primaryActionSelected() {
        /* TODO - connect to choose */
    }
}

extension SiteDesignContentCollectionViewController: UICollectionViewDelegate {

}
