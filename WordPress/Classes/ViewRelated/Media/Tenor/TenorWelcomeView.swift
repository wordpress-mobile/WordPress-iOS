import UIKit

final class TenorWelcomeView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)

        let textLabel = UILabel()
        textLabel.font = WPStyleGuide.fontForTextStyle(.title2)
        textLabel.adjustsFontForContentSizeCategory = true
        textLabel.text = Strings.title
        textLabel.textAlignment = .center
        textLabel.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [
            UIImageView(image: UIImage(named: "media-no-results")),
            textLabel,
            UIImageView(image: UIImage(named: "tenor-attribution"))
        ])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 24
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 16, left: 32, bottom: 16, right: 32)

        let wrapper = UIStackView(arrangedSubviews: [stack])
        wrapper.alignment = .center
        addSubview(wrapper)
        wrapper.translatesAutoresizingMaskIntoConstraints = false
        pinSubviewToAllEdges(wrapper)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private enum Strings {
    static let title = NSLocalizedString("tenor.welcomeMessage", value: "Search to find GIFs to add to your Media Library!", comment: "Title for placeholder in Tenor picker")
}
