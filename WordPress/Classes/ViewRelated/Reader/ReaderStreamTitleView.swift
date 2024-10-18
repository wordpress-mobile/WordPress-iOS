import UIKit

/// A Reader stream header with a large title and a description.
final class ReaderStreamTitleView: UIView {
    let titleLabel = UILabel()
    let detailsLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        titleLabel.font = UIFont.preferredFont(forTextStyle: .largeTitle).withWeight(.bold)
        detailsLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        detailsLabel.textColor = .secondaryLabel
        detailsLabel.numberOfLines = 0

        let stackView = UIStackView(axis: .vertical, alignment: .leading, [titleLabel, detailsLabel])
        addSubview(stackView)
        stackView.pinEdges()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
