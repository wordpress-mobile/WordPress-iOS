import UIKit
import Gridicons
import WordPressShared

final class TitleSubtitleTextfieldHeader: UIView {
    private struct Constants {
        static let iconWidth: CGFloat = 18.0
        static let searchHeight: CGFloat = 44.0
        static let searchMarging: CGFloat = 6.0
    }
    private lazy var titleSubtitle: TitleSubtitleHeader = {
        let returnValue = TitleSubtitleHeader(frame: .zero)
        returnValue.translatesAutoresizingMaskIntoConstraints = false

        return returnValue
    }()

    lazy var textField: UITextField = {
        let returnValue = UITextField(frame: .zero)
        returnValue.translatesAutoresizingMaskIntoConstraints = false
        returnValue.leftViewMode = .always

        let iconSize = CGSize(width: Constants.iconWidth, height: Constants.iconWidth)
        let loupeIcon = Gridicon.iconOfType(.search, withSize: iconSize).imageWithTintColor(WPStyleGuide.readerCardCellHighlightedBorderColor())?.imageFlippedForRightToLeftLayoutDirection()
        let imageView = UIImageView(image: loupeIcon)
        returnValue.leftView = imageView

        return returnValue
    }()

    private lazy var searchBackground: UIView = {
        let returnValue = UIView(frame: .zero)
        returnValue.translatesAutoresizingMaskIntoConstraints = false
        returnValue.backgroundColor = .white

        return returnValue
    }()

    private lazy var stackView: UIStackView = {
        let search = self.searchBackground
        search.addSubview(self.textField)
        NSLayoutConstraint.activate([
            self.textField.heightAnchor.constraint(equalToConstant: Constants.searchHeight),
            self.textField.centerYAnchor.constraint(equalTo: search.centerYAnchor),
            self.textField.leadingAnchor.constraint(equalTo: search.leadingAnchor, constant: Constants.searchMarging),
            self.textField.trailingAnchor.constraint(equalTo: search.trailingAnchor, constant: -1 * Constants.searchMarging)
            ])

        let returnValue = UIStackView(arrangedSubviews: [self.titleSubtitle, search])
        returnValue.translatesAutoresizingMaskIntoConstraints = false
        returnValue.axis = .vertical
        returnValue.spacing = TitleSubtitleHeader.Margins.spacing
        returnValue.isLayoutMarginsRelativeArrangement = true
        NSLayoutConstraint.activate([
            search.heightAnchor.constraint(equalToConstant: Constants.searchHeight),
        ])

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
