import UIKit

class DashboardFailureCardCell: UICollectionViewCell, Reusable, BlogDashboardCardConfigurable {
    override init(frame: CGRect) {
        super.init(frame: frame)
        let label = UILabel()
        label.text = "Failed to load"
        label.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(label)
        contentView.pinSubviewToAllEdges(label)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(blog: Blog, viewController: BlogDashboardViewController?, apiResponse: BlogDashboardRemoteEntity?) {

    }
}
