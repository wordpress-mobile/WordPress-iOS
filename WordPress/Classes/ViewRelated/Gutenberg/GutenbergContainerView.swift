import UIKit

class GutenbergContainerView: UIView, NibLoadable {

    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var separatorView: UIView!
    @IBOutlet weak var editorContainerView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        configureTitleTextField()
        configureSeparatorView()
    }

    func configureTitleTextField() {
        titleTextField.borderStyle = .none
        titleTextField.heightAnchor.constraint(equalToConstant: Size.titleTextFieldHeight).isActive = true
        titleTextField.font = Fonts.title
        titleTextField.textColor = Colors.title
        titleTextField.backgroundColor = Colors.background
        titleTextField.placeholder = NSLocalizedString("Title", comment: "Placeholder for the post title.")
        let leftView = UIView()
        leftView.translatesAutoresizingMaskIntoConstraints = false
        leftView.heightAnchor.constraint(equalToConstant: Size.titleTextFieldHeight).isActive = true
        leftView.widthAnchor.constraint(equalToConstant: Size.titleTextFieldLeftPadding).isActive = true
        leftView.backgroundColor = Colors.background
        titleTextField.leftView = leftView
        titleTextField.leftViewMode = .always
    }

    func configureSeparatorView() {
        separatorView.backgroundColor = Colors.separator
    }
}

private extension GutenbergContainerView {

    enum Colors {
        static let title = UIColor.darkText
        static let separator = WPStyleGuide.greyLighten30()
        static let background = UIColor.white
    }

    enum Fonts {
        static let title = WPFontManager.notoBoldFont(ofSize: 24.0)
    }

    enum Size {
        static let titleTextFieldHeight: CGFloat = 50.0
        static let titleTextFieldLeftPadding: CGFloat = 10.0
        static let titleTextFieldBottomSeparatorHeight: CGFloat = 1.0
    }
}
