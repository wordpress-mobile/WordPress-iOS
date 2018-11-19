import UIKit
import Gridicons

final class TitleSubtitleTextfieldHeader: UIView {
    private lazy var titleSubtitle: TitleSubtitleHeader = {
        let returnValue = TitleSubtitleHeader(frame: .zero)
        returnValue.translatesAutoresizingMaskIntoConstraints = false

        return returnValue
    }()

    lazy var textField: UITextField = {
        let returnValue = UITextField(frame: .zero)
        returnValue.translatesAutoresizingMaskIntoConstraints = false
        returnValue.leftViewMode = .always
        returnValue.backgroundColor = .white

        let loupeIcon = Gridicon.iconOfType(.search)
        let imageView = UIImageView(image: loupeIcon)
        returnValue.leftView = imageView

        return returnValue
    }()

    private lazy var stackView: UIStackView = {
        let returnValue = UIStackView(arrangedSubviews: [self.titleSubtitle, self.textField])
        returnValue.translatesAutoresizingMaskIntoConstraints = false
        returnValue.axis = .vertical
        returnValue.spacing = TitleSubtitleHeader.Margins.spacing
        returnValue.isLayoutMarginsRelativeArrangement = true

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
        translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: readableContentGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: readableContentGuide.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -1 * TitleSubtitleHeader.Margins.verticalMargin)])

        setStyles()
    }

    private func setStyles() {
        backgroundColor = WPStyleGuide.greyLighten30()
    }

    func setTitle(_ text: String) {
        titleSubtitle.setTitle(text)
    }

    func setSubtitle(_ text: String) {
        titleSubtitle.setSubtitle(text)
    }
}
