import UIKit

class LayoutPreviewViewController: UIViewController {

    @IBOutlet weak var createPageBtn: UIButton!
    @IBOutlet weak var previewContainer: UIView!

    var completion: PageCoordinator.TemplateSelectionCompletion? = nil
    var layout: GutenbergSelectedLayout?

    var accentColor: UIColor {
        if #available(iOS 13.0, *) {
            return UIColor { (traitCollection: UITraitCollection) -> UIColor in
                if traitCollection.userInterfaceStyle == .dark {
                    return UIColor.muriel(color: .accent, .shade40)
                } else {
                    return UIColor.muriel(color: .accent, .shade50)
                }
            }
        } else {
            return UIColor.muriel(color: .accent, .shade50)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        styleButtons()
    }

    private func styleButtons() {
        createPageBtn.titleLabel?.font = WPStyleGuide.fontForTextStyle(.body, fontWeight: .medium)
        createPageBtn.backgroundColor = accentColor
        createPageBtn.layer.cornerRadius = 8
    }
}
