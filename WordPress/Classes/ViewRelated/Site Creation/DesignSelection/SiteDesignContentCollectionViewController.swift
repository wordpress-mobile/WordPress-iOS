import UIKit
import WordPressKit

class SiteDesignContentCollectionViewController: CollapsableHeaderViewController {
    var siteDesigns: [RemoteSiteDesign] = [] {
        didSet {
            collectionView.reloadData()
        }
    }
    var isLoading = true
    let cellSize = CGSize(width: 150, height: 230)
    let restAPI = WordPressComRestApi.anonymousApi(userAgent: WPUserAgent.wordPress())
    let collectionView: UICollectionView
    let collectionViewLayout: UICollectionViewFlowLayout

    init() {
        collectionViewLayout = UICollectionViewFlowLayout()
        collectionViewLayout.sectionInset = UIEdgeInsets(top: 20, left: 20, bottom: 0, right: 20)
        collectionViewLayout.minimumLineSpacing = 10
        collectionViewLayout.minimumInteritemSpacing = 10
        collectionViewLayout.itemSize = cellSize
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
        collectionView.showsVerticalScrollIndicator = false

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
        collectionView.delegate = self
        collectionView.dataSource = self
    }

    override func estimatedContentSize() -> CGSize {
        guard isLoading || siteDesigns.count > 1 else { return .zero }
        let cellCount = isLoading ? 1 : siteDesigns.count
        let cellsPerRow = floor(collectionView.frame.size.width / cellSize.width)
        let rows = ceil(CGFloat(cellCount) / cellsPerRow)
        let topSpacing = collectionViewLayout.sectionInset.top
        let lineSpacing = collectionViewLayout.minimumLineSpacing * max(rows - 2, 0)
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

//        let layout = layouts[indexPath.row]
//        cell.previewURL = layout.preview
//        cell.isAccessibilityElement = true
//        cell.accessibilityLabel = layout.slug

        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension SiteDesignContentCollectionViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return !isLoading
    }
}
