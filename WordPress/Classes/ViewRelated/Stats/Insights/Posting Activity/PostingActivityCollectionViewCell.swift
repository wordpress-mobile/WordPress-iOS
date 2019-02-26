import UIKit

class PostingActivityCollectionViewCell: UICollectionViewCell {

    // MARK: - Properties

    static let reuseIdentifier = "PostingActivityCollectionViewCell"

    // MARK: - Configure

    func configure(withData monthData: [PostingStreakEvent], postingActivityDayDelegate: PostingActivityDayDelegate? = nil) {
        let monthView = PostingActivityMonth.loadFromNib()
        monthView.configure(monthData: monthData, postingActivityDayDelegate: postingActivityDayDelegate)
        monthView.frame.size = frame.size
        addSubview(monthView)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        subviews.forEach({ $0.removeFromSuperview()})
    }

}
