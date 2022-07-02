import UIKit

/// A view that contains an actionable Jetpack powered banner
class JetpackBannerView: UIView {

    private lazy var bannerView: UIView = {
        let jetpackBannerView = UIView()
        jetpackBannerView.translatesAutoresizingMaskIntoConstraints = false

        jetpackBannerView.backgroundColor = Appearance.jetpackBackgroundColor
        jetpackBannerView.addSubview(jetpackButton)
        return jetpackBannerView
    }()

    private lazy var jetpackButton: UIButton = {
        let jetpackButton = UIButton()
        jetpackButton.translatesAutoresizingMaskIntoConstraints = false
        jetpackButton.setTitle(Appearance.jetpackBannerTitle, for: .normal)
        jetpackButton.tintColor = .muriel(color: .jetpackGreen, .shade40)
        jetpackButton.setTitleColor(UIColor(light: .black, dark: .white), for: .normal)
        jetpackButton.titleLabel?.font = Appearance.jetpackButtonFont
        jetpackButton.titleLabel?.adjustsFontForContentSizeCategory = true
        jetpackButton.titleLabel?.minimumScaleFactor = Appearance.jetpackFontMinimumScaleFactor
        jetpackButton.titleLabel?.adjustsFontSizeToFitWidth = true
        jetpackButton.setImage(.gridicon(.plans, size: Appearance.jetpackIconSize), for: .normal)
        jetpackButton.imageEdgeInsets = Appearance.jetpackIconInsets

        // sets the background of the jp logo to white
        if let imageView = jetpackButton.imageView {
            let view = UIView()
            view.backgroundColor = .white
            view.translatesAutoresizingMaskIntoConstraints = false
            jetpackButton.insertSubview(view, belowSubview: imageView)
            view.layer.cornerRadius = Appearance.jetpackIconBackgroundSize / 2
            view.clipsToBounds = true

            NSLayoutConstraint.activate([
                view.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
                view.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),
                view.heightAnchor.constraint(equalToConstant: Appearance.jetpackIconBackgroundSize),
                view.widthAnchor.constraint(equalToConstant: Appearance.jetpackIconBackgroundSize)
            ])
        }
        // TODO: Remove this line when adding an action to the banner
        jetpackButton.isUserInteractionEnabled = false
        return jetpackButton
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        backgroundColor = Appearance.jetpackBackgroundColor
        addSubview(jetpackButton)
        pinSubviewToAllEdges(jetpackButton)
    }

    private enum Appearance {
        static let jetpackBackgroundColor = UIColor(light: .muriel(color: .jetpackGreen, .shade0),
                                                    dark: .muriel(color: .jetpackGreen, .shade90))
        static let jetpackBannerTitle = NSLocalizedString("Jetpack powered",
                                                          comment: "Title of the Jetpack powered banner.")
        static let jetpackIconSize = CGSize(width: 28, height: 28)
        static let jetpackIconInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 10)
        static let jetpackButtonFont = WPStyleGuide.fontForTextStyle(.body, fontWeight: .regular)
        static let jetpackFontMinimumScaleFactor: CGFloat = 0.75
        static let jetpackIconBackgroundSize: CGFloat = 22
    }
}
