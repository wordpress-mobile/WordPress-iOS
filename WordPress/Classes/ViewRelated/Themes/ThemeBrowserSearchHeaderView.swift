import UIKit

class ThemeBrowserSearchHeaderView: UICollectionReusableView {

    // MARK: - Constants

    static let reuseIdentifier = "ThemeBrowserSearchHeaderView"

    private var searchWrapperView: UIView!

    var searchBar: UISearchBar? = nil {
        didSet {
            if let searchBar = searchBar where searchBar != oldValue {
                searchWrapperView.addSubview(searchBar)
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit() {
        searchWrapperView = SearchWrapperView()
        searchWrapperView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(searchWrapperView)
        pinSubviewToAllEdges(searchWrapperView)
    }
}
