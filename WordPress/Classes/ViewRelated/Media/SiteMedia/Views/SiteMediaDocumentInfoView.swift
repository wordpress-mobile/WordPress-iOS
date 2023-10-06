import UIKit

final class SiteMediaDocumentInfoView: UIView {
    let iconView = UIImageView()
    let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        iconView.tintColor = .label

        titleLabel.font = .systemFont(ofSize: 12)
        titleLabel.textColor = .label
        titleLabel.lineBreakMode = .byTruncatingMiddle

        let stackView = UIStackView(arrangedSubviews: [iconView, titleLabel])
        stackView.alignment = .center
        stackView.axis = .vertical
        stackView.spacing = 4

        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        pinSubviewToAllEdges(stackView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(_ viewModel: SiteMediaCollectionCellViewModel) {
        switch viewModel.mediaType {
        case .document, .powerpoint:
            iconView.image = .gridicon(.pages)
            titleLabel.text = viewModel.filename
        case .audio:
            iconView.image = .gridicon(.audio)
            titleLabel.text = viewModel.filename
        default:
            break
        }
    }
}
