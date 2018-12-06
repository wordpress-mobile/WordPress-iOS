import UIKit
import Gridicons
import WordPressShared

// MARK: - SearchTextField

private final class SearchTextField: UITextField {

    // MARK: Properties

    private struct Constants {
        static let iconDimension    = CGFloat(18)
        static let iconInset        = CGFloat(19)
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

    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.insetBy(dx: Constants.textInset, dy: 0)
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

    // MARK: Private behavior

    private func initialize() {
        translatesAutoresizingMaskIntoConstraints = false

        backgroundColor = .white
        clearButtonMode = .whileEditing
        font = WPStyleGuide.fixedFont(for: .headline)
        textColor = WPStyleGuide.darkGrey()

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
    }
}

// MARK: - TitleSubtitleTextfieldHeader

final class TitleSubtitleTextfieldHeader: UIView {

    // MARK: Properties

    private struct Constants {
        static let spacing = CGFloat(10)
        static let animationDuration = TimeInterval(0.40)
        static let animationDelay = TimeInterval(0.0)
        static let animationDamping = CGFloat(0.9)
        static let animationSpring = CGFloat(1.0)
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

        setupTextField()
        setStyles()
    }

    private func setupTextField() {
        textField.delegate = self
        textField.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)

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

extension TitleSubtitleTextfieldHeader: UITextFieldDelegate {
    @objc
    func textFieldChanged(sender: UITextField) {
        if let searchTerm = sender.text, searchTerm.isEmpty {
            showTitleSubtitle()
        } else {
            hideTitleSubtitle()
        }
    }

    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        showTitleSubtitle()
        return true
    }

    private func hideTitleSubtitle() {
        guard titleIsHidden() == false else {
            return
        }

        updateTitleSubtitle(visibility: true)
    }

    private func showTitleSubtitle() {
        guard titleIsHidden() == true else {
            return
        }
        updateTitleSubtitle(visibility: false)
    }

    private func titleIsHidden() -> Bool {
        return stackView.arrangedSubviews.first?.isHidden ?? true
    }

    private func updateTitleSubtitle(visibility: Bool) {
        UIView.animate(withDuration: Constants.animationDuration,
                       delay: Constants.animationDelay,
                       usingSpringWithDamping: Constants.animationDamping,
                       initialSpringVelocity: Constants.animationSpring,
                       options: [],
                       animations: { [weak self] in
                        self?.stackView.arrangedSubviews.first?.isHidden = visibility
            }, completion: nil)
    }
}
