import UIKit

/// A UIView with a Jetpack powered banner at the bottom of a container view
class JetpackBannerContainerView: UIView {

    private lazy var mainStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [containerView, bannerView])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        return stackView
    }()

    private lazy var containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var bannerView: UIView = {
        let jetpackBannerView = JetpackBannerView(frame: .zero)
        jetpackBannerView.translatesAutoresizingMaskIntoConstraints = false
        return jetpackBannerView
    }()

    override init(frame: CGRect) {
        super.init(frame: .zero)
        addSubview(mainStackView)
        activateConstraints()
    }

    private func activateConstraints() {
        bannerView.heightAnchor.constraint(equalToConstant: Self.jetpackBannerHeight).isActive = true
        pinSubviewToAllEdges(mainStackView)
    }

    func addViewToContainerView(_ view: UIView) {
        view.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(view)
        containerView.pinSubviewToAllEdges(view)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private static let jetpackBannerHeight: CGFloat = 44
}
