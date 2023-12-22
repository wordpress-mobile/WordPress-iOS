import UIKit

struct SiteMediaDocumentInfoViewModel {
    let image: UIImage
    let title: String?
}

final class SiteMediaDocumentInfoView: UIView {
    private let iconView = UIImageView()
    private let titleLabel = UILabel()

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

    func configureLargeStyle() {
        titleLabel.font = WPStyleGuide.fontForTextStyle(.body, fontWeight: .regular)
        titleLabel.numberOfLines = 3

        iconView.
    }

    func configure(_ viewModel: SiteMediaDocumentInfoViewModel) {
        iconView.image = viewModel.image
        titleLabel.text = viewModel.title
    }
}

extension SiteMediaDocumentInfoViewModel {
    static func make(with media: Media) -> SiteMediaDocumentInfoViewModel {
        SiteMediaDocumentInfoViewModel(image: getIcon(for: media.mediaType), title: media.filename)
    }
}

private func getIcon(for mediaType: MediaType) -> UIImage {
    switch mediaType {
    case .document, .powerpoint:
        return .gridicon(.pages)
    case .audio:
        return .gridicon(.audio)
    case .image:
        return .gridicon(.camera)
    case .video:
        return .gridicon(.videoCamera)
    @unknown default:
        return .gridicon(.pages)
    }
}
