import UIKit
import Gridicons
import WordPressShared

// MARK: - SearchTextField

private final class SearchTextField: UITextField {

    // MARK: Properties

    private struct Constants {
        static let iconDimension            = CGFloat(18)
        static let clearButtonDimension     = CGFloat(16)
        static let leftIconInset            = CGFloat(19)
        static let rightIconInset           = CGFloat(24)
        static let searchHeight             = CGFloat(44)
        static let textInset                = CGFloat(56)
    }

    private lazy var clearButton: UIButton = {
        let image = UIImage(named: "icon-clear-textfield")?.imageWithTintColor(WPStyleGuide.greyLighten20())
        let button = UIButton(frame: .zero)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(image, for: .normal)
        button.contentMode = .scaleAspectFit
        button.addTarget(self, action: #selector(clear), for: .touchUpInside)


        return button
    }()

    private lazy var loupe: UIImageView = {
        let iconSize = CGSize(width: Constants.iconDimension, height: Constants.iconDimension)
        let loupeIcon = Gridicon.iconOfType(.search, withSize: iconSize).imageWithTintColor(WPStyleGuide.readerCardCellHighlightedBorderColor())?.imageFlippedForRightToLeftLayoutDirection()
        let imageView = UIImageView(image: loupeIcon)
        imageView.contentMode = .scaleAspectFit

        return imageView
    }()


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

    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.insetBy(dx: Constants.textInset, dy: 0)
    }

    override func leftViewRect(forBounds bounds: CGRect) -> CGRect {
        let iconDimension = leftIconDimension()
        let iconInset = leftIconInset()
        let iconY = (bounds.height - iconDimension) / 2
        return CGRect(x: iconInset, y: iconY, width: iconDimension, height: iconDimension)
    }

    override func rightViewRect(forBounds bounds: CGRect) -> CGRect {
        let iconDimension = rightIconDimension()
        let iconInset = rightIconInset()

        let iconX = bounds.width - iconInset - Constants.iconDimension
        let iconY = (bounds.height - iconDimension) / 2

        return CGRect(x: iconX, y: iconY, width: iconDimension, height: iconDimension)
    }

    private func rightIconDimension() -> CGFloat {
        return traitCollection.layoutDirection == .leftToRight ? Constants.clearButtonDimension : Constants.iconDimension
    }

    private func rightIconInset() -> CGFloat {
        return traitCollection.layoutDirection == .leftToRight ? Constants.rightIconInset : Constants.leftIconInset
    }

    private func leftIconDimension() -> CGFloat {
        return traitCollection.layoutDirection == .leftToRight ? Constants.iconDimension : Constants.clearButtonDimension
    }

    private func leftIconInset() -> CGFloat {
        return traitCollection.layoutDirection == .leftToRight ? Constants.leftIconInset : Constants.rightIconInset
    }

    // MARK: Private behavior

    private func initialize() {
        translatesAutoresizingMaskIntoConstraints = false

        backgroundColor = .white
        clearButtonMode = .whileEditing
        font = WPStyleGuide.fixedFont(for: .headline)
        textColor = WPStyleGuide.darkGrey()

        if traitCollection.layoutDirection == .rightToLeft {
            rightView = loupe
            rightViewMode = .always
            leftView = clearButton
            leftViewMode = .whileEditing
        } else {
            leftView = loupe
            leftViewMode = .always
            rightView = clearButton
            rightViewMode = .whileEditing
        }

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: Constants.searchHeight)
        ])

        addTopBorder(withColor: WPStyleGuide.greyLighten20())
        addBottomBorder(withColor: WPStyleGuide.greyLighten20())
    }

    @objc
    func clear(sender: AnyObject) {
        text = ""
        sendActions(for: .editingChanged)
    }
}

// MARK: - TitleSubtitleTextfieldHeader

final class TitleSubtitleTextfieldHeader: UIView {

    // MARK: Properties

    private struct Constants {
        static let spacing = CGFloat(10)
    }

    private lazy var titleSubtitle: TitleSubtitleHeader = {
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
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -TitleSubtitleHeader.Margins.verticalMargin)
        ])

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
