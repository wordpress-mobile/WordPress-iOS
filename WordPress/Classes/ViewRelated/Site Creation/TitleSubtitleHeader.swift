import UIKit

final class TitleSubtitleHeader: UIView {
    private lazy var title: UILabel = {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        //label.text = headerData.title
        label.textAlignment = .center
        label.numberOfLines = 0

        return label
    }()

    private lazy var subtitle: UILabel = {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        //label.text = headerData.subtitle
        label.textAlignment = .center
        label.numberOfLines = 0

        return label
    }()

    private let stackView: UIStackView = {
        let returnValue = UIStackView(arrangedSubviews: [self.title, self.subtitle])
        returnValue.axis = .vertical
        returnValue.spacing = 20

        return returnValue
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }

    private func setupView() {
        addSubview(stackView)
    }

    override func layoutSubviews() {

    }
//    override var intrinsicContentSize: CGSize {
//        return CGSize(width: UIView.noIntrinsicMetric, height: UIView.noIntrinsicMetric)
//    }
}
