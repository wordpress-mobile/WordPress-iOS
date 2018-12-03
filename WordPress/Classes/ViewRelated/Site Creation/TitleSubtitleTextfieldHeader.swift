import UIKit
import Gridicons
import WordPressShared

final class TitleSubtitleTextfieldHeader: UIView {
    private struct Animation {
        static let duration: TimeInterval = 0.40
        static let delay: TimeInterval = 0.0
        static let damping: CGFloat = 0.9
        static let spring: CGFloat = 1.0
    }

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
        returnValue.clearButtonMode = .whileEditing
        returnValue.font = WPStyleGuide.fixedFont(for: .headline)
        returnValue.textColor = WPStyleGuide.darkGrey()

        returnValue.delegate = self

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
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -1 * TitleSubtitleHeader.Margins.bottomMargin)])

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

    func hideTitleSubtitle() {
        updateTitleSubtitle(visibility: true)
    }

    func showTitleSubtitle() {
        updateTitleSubtitle(visibility: false)
    }

    private func updateTitleSubtitle(visibility: Bool) {
        //stackView.arrangedSubviews.first?.isHidden = visibility

        UIView.animate(withDuration: Animation.duration,
                       delay: Animation.delay,
                       usingSpringWithDamping: Animation.damping,
                       initialSpringVelocity: Animation.spring,
                       options: [],
                       animations: { [weak self] in
                            self?.stackView.arrangedSubviews.first?.isHidden = visibility
        }, completion: nil)
    }
}

extension TitleSubtitleTextfieldHeader: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        hideTitleSubtitle()
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        showTitleSubtitle()
    }
}
