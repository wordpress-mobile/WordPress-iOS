import UIKit

class ThemeBrowserSearchHeaderView: UICollectionReusableView {

    // MARK: - Constants

    @objc static let reuseIdentifier = "ThemeBrowserSearchHeaderView"

    fileprivate var searchWrapperView: UIView!

    @objc var searchBar: UISearchBar? = nil {
        didSet {
            if let searchBar = searchBar, searchBar != oldValue {
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

    fileprivate func commonInit() {
        searchWrapperView = SearchWrapperView()
        searchWrapperView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(searchWrapperView)
        pinSubviewToAllEdges(searchWrapperView)
    }
}
