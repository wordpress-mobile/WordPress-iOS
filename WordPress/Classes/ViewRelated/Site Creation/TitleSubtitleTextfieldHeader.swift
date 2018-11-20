import UIKit
import Gridicons

final class TitleSubtitleTextfieldHeader: UIView {
    private struct Animation {
        static let duration: TimeInterval = 0.40
        static let delay: TimeInterval = 0.0
        static let damping: CGFloat = 0.9
        static let spring: CGFloat = 1.0
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
        returnValue.backgroundColor = .white

        returnValue.delegate = self

        let loupeIcon = Gridicon.iconOfType(.search)
        let imageView = UIImageView(image: loupeIcon)
        returnValue.leftView = imageView

        return returnValue
    }()

    private lazy var stackView: UIStackView = {
        let returnValue = UIStackView(arrangedSubviews: [self.titleSubtitle, self.textField])
        returnValue.translatesAutoresizingMaskIntoConstraints = false
        returnValue.axis = .vertical
        returnValue.spacing = 20
        returnValue.isLayoutMarginsRelativeArrangement = true
        returnValue.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 20, right: 0)

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
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)])

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
