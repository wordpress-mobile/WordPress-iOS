import UIKit

class JetpackBannerView: UIView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()

    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    override var intrinsicContentSize: CGSize {
        return isHidden ? CGSize.zero : super.intrinsicContentSize
    }

    func setup() {

        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = Appearance.jetpackBackgroundColor

        let jetpackButton = makeJetpackButton()
        addSubview(jetpackButton)

        pinSubviewToAllEdges(jetpackButton)
    }

    private func makeJetpackButton() -> UIButton {
        let jetpackButton = UIButton()
        jetpackButton.isUserInteractionEnabled = false
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

        return jetpackButton
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
