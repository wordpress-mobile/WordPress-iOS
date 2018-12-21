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
        titleTextField.font = Fonts.title
        titleTextField.textColor = Colors.title
        titleTextField.backgroundColor = Colors.background
        titleTextField.placeholder = NSLocalizedString("Title", comment: "Placeholder for the post title.")
        titleTextField.autocapitalizationType = .sentences
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
}
