import UIKit

class UnifiedPrologueIntroContentView: UIView {
    init() {
        super.init(frame: .zero)

        configureStackViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureStackViews() {
        let topStackView = UIStackView()
        topStackView.translatesAutoresizingMaskIntoConstraints = false
        topStackView.axis = .horizontal
        topStackView.spacing = Metrics.innerStackSpacing
        topStackView.alignment = .center
        topStackView.addArrangedSubviews(makeImageViews(for: ["introWebsite1", "introWebsite2", "introWebsite3"]))

        let bottomStackView = UIStackView()
        bottomStackView.translatesAutoresizingMaskIntoConstraints = false
        bottomStackView.axis = .horizontal
        bottomStackView.spacing = Metrics.innerStackSpacing
        bottomStackView.alignment = .top
        bottomStackView.addArrangedSubviews(makeImageViews(for: ["introWebsite4", "introWebsite5", "introWebsite6", "introWebsite7"]))

        let outerStackView = UIStackView()
        outerStackView.translatesAutoresizingMaskIntoConstraints = false
        outerStackView.axis = .vertical
        outerStackView.spacing = Metrics.outerStackSpacing

        outerStackView.addArrangedSubviews([topStackView, bottomStackView])
        addSubview(outerStackView)
        pinSubviewToAllEdges(outerStackView)
    }

    private func makeImageViews(for assets: [String]) -> [UIImageView] {
        let images = assets.map({ UIImage(named: $0) })
        let imageViews = images.map({ UIImageView(image: $0) })

        imageViews.forEach({ imageView in
                            imageView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
            imageView.layer.shadowColor = Appearance.shadowColor.cgColor
            imageView.layer.shadowOpacity = Appearance.shadowOpacity
            imageView.layer.shadowRadius = Appearance.shadowRadius
            imageView.layer.shadowOffset = .zero
        })

        return imageViews
    }

    enum Metrics {
        static let innerStackSpacing: CGFloat = 16.0
        static let outerStackSpacing: CGFloat = 8.0
    }

    enum Appearance {
        static let shadowColor: UIColor = .black
        static let shadowOpacity: Float = 0.20
        static let shadowRadius: CGFloat = 4.0
    }
}
