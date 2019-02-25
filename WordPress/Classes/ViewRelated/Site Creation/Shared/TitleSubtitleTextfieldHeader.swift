import UIKit
import Gridicons
import WordPressShared

// MARK: - SearchTextField

private final class SearchTextField: UITextField {

    // MARK: Properties

    private struct Constants {
        static let iconDimension    = CGFloat(18)
        static let iconInset        = CGFloat(19)
        static let clearButtonInset = CGFloat(-9)
        static let searchHeight     = CGFloat(44)
        static let textInset        = CGFloat(56)
    }

    // MARK: UIView

    init() {
        super.init(frame: .zero)
        initialize()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: UITextField

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.insetBy(dx: Constants.textInset, dy: 0)
    }

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        let textInsets = UIEdgeInsets(top: 0, left: Constants.textInset, bottom: 0, right: 0)
        return bounds.inset(by: textInsets)
    }

    override func leftViewRect(forBounds bounds: CGRect) -> CGRect {
        let iconY = (bounds.height - Constants.iconDimension) / 2
        return CGRect(x: Constants.iconInset, y: iconY, width: Constants.iconDimension, height: Constants.iconDimension)
    }

    override func rightViewRect(forBounds bounds: CGRect) -> CGRect {
        let iconX = bounds.width - Constants.iconInset - Constants.iconDimension
        let iconY = (bounds.height - Constants.iconDimension) / 2
        return CGRect(x: iconX, y: iconY, width: Constants.iconDimension, height: bounds.height)
    }

    override func clearButtonRect(forBounds bounds: CGRect) -> CGRect {
        let originalClearButtonRect = super.clearButtonRect(forBounds: bounds)
        return originalClearButtonRect.offsetBy(dx: Constants.clearButtonInset, dy: 0)
    }

    // MARK: Private behavior

    private func initialize() {
        translatesAutoresizingMaskIntoConstraints = false

        backgroundColor = .white
        clearButtonMode = .whileEditing
        font = WPStyleGuide.fontForTextStyle(.body, fontWeight: .regular)
        textColor = WPStyleGuide.darkGrey()

        autocapitalizationType = .none
        autocorrectionType = .no
        adjustsFontForContentSizeCategory = true

        let iconSize = CGSize(width: Constants.iconDimension, height: Constants.iconDimension)
        let loupeIcon = Gridicon.iconOfType(.search, withSize: iconSize).imageWithTintColor(WPStyleGuide.readerCardCellHighlightedBorderColor())?.imageFlippedForRightToLeftLayoutDirection()
        let imageView = UIImageView(image: loupeIcon)

        if traitCollection.layoutDirection == .rightToLeft {
            rightView = imageView
            rightViewMode = .always
        } else {
            leftView = imageView
            leftViewMode = .always
        }

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: Constants.searchHeight),
            ])

        addTopBorder(withColor: WPStyleGuide.greyLighten20())
        addBottomBorder(withColor: WPStyleGuide.greyLighten20())
    }
}

// MARK: - TitleSubtitleTextfieldHeader

final class TitleSubtitleTextfieldHeader: UIView {

    // MARK: Properties

    private struct Constants {
        static let spacing = CGFloat(10)
        static let bottomMargin = CGFloat(16)
    }

    private(set) lazy var titleSubtitle: TitleSubtitleHeader = {
        let returnValue = TitleSubtitleHeader(frame: .zero)
        returnValue.translatesAutoresizingMaskIntoConstraints = false

        return returnValue
    }()

    private(set) var textField: UITextField = SearchTextField()

    private lazy var stackView: UIStackView = {

        let returnValue = UIStackView(arrangedSubviews: [self.titleSubtitle, self.textField])
        returnValue.translatesAutoresizingMaskIntoConstraints = false
        returnValue.axis = .vertical
        returnValue.spacing = Constants.spacing
        NSLayoutConstraint.activate([
            textField.leadingAnchor.constraint(equalTo: returnValue.leadingAnchor),
            textField.trailingAnchor.constraint(equalTo: returnValue.trailingAnchor)
        ])

        return returnValue
    }()

    // MARK: UIView

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }

    // MARK: Private behavior

    private func setupView() {
        translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Constants.bottomMargin)
            ])

        setStyles()

        prepareForVoiceOver()
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

extension TitleSubtitleTextfieldHeader: Accessible {
    func prepareForVoiceOver() {
        titleSubtitle.prepareForVoiceOver()

        prepareSearchFieldForVoiceOver()
    }

    private func prepareSearchFieldForVoiceOver() {
        textField.accessibilityTraits = .searchField
    }
}
