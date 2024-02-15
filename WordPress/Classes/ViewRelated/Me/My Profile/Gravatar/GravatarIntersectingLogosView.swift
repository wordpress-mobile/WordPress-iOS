import Foundation

class GravatarIntersectingLogosView: UIView {

    private enum Constants {
        static let wordpressLogo = UIImage(named: "wordpress-circular")
        static let jetpackLogo = UIImage(named: "jetpack-circular")
        static let gravatarLogo = UIImage(named: "gravatar-circular")
        static let intersectionAmount: CGFloat = 12.0
        static let logoSize: CGSize = .init(width: 30, height: 30)
    }

    private lazy var appLogoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = appLogo
        imageView.contentMode = .scaleAspectFit
        imageView.widthAnchor.constraint(equalToConstant: Constants.logoSize.width).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: Constants.logoSize.height).isActive = true
        return imageView
    }()

    private lazy var gravatarLogoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = Constants.gravatarLogo
        imageView.contentMode = .scaleAspectFit
        imageView.widthAnchor.constraint(equalToConstant: Constants.logoSize.width).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: Constants.logoSize.height).isActive = true
        return imageView
    }()

    private var appLogo: UIImage? {
        return AppConfiguration.isJetpack ? Constants.jetpackLogo : Constants.wordpressLogo
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(appLogoImageView)
        addSubview(gravatarLogoImageView)
        bringSubviewToFront(gravatarLogoImageView)
        NSLayoutConstraint.activate([
            appLogoImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            appLogoImageView.topAnchor.constraint(equalTo: topAnchor),
            appLogoImageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            gravatarLogoImageView.leadingAnchor.constraint(equalTo: appLogoImageView.trailingAnchor, constant: -Constants.intersectionAmount),
            gravatarLogoImageView.topAnchor.constraint(equalTo: topAnchor),
            gravatarLogoImageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            gravatarLogoImageView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
