import UIKit
import Gridicons

class GutenbergLayoutPickerViewController: UIViewController {

    @IBOutlet weak var headerView: UIView!
//    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var categoryBar: UICollectionView!

    @IBOutlet weak var tableView: UITableView!

    @IBOutlet weak var footerView: UIView!
    @IBOutlet weak var createBlankPageBtn: UIButton!

    var completion: PageCoordinator.TemplateSelectionCompletion? = nil
    let minTitleFontSize: CGFloat = 22
    let maxTitleFontSize: CGFloat = 34
    var maxHeaderHeight: CGFloat = 285
    var minHeaderHeight: CGFloat {
        return (navigationController?.navigationBar.frame.height ?? 56) + categoryBar.frame.height + 9
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        styleButtons()

//        let tableFooterFrame = footerView.frame
//        let bottomInset = tableFooterFrame.size.height - (UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 44)
//        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: bottomInset, right: 0)
//        closeButton.setImage(UIImage.gridicon(.crossSmall), for: .normal)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                styleButtons()
            }
        }
    }

    @IBAction func closeModal(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func createBlankPage(_ sender: Any) {
        createPage(nil)
    }

    private func createPage(_ template: String?) {
        guard let completion = completion else {
            dismiss(animated: true, completion: nil)
            return
        }

        dismiss(animated: true) {
            completion(template)
        }
    }

    private func styleButtons() {
        let seperator: UIColor
        if #available(iOS 13.0, *) {
            seperator = UIColor.separator
        } else {
            seperator = UIColor(red: 0.235, green: 0.235, blue: 0.263, alpha: 0.29)
        }

        [createBlankPageBtn].forEach { (button) in
            button?.layer.borderColor = seperator.cgColor
            button?.layer.borderWidth = 1
            button?.layer.cornerRadius = 8
        }

//        if #available(iOS 13.0, *) {
//            closeButton.backgroundColor = UIColor { (traitCollection: UITraitCollection) -> UIColor in
//                if traitCollection.userInterfaceStyle == .dark {
//                    return UIColor.systemFill
//                } else {
//                    return UIColor.quaternarySystemFill
//                }
//            }
//        }
    }

    private func titleViewFont(withSize pointSize: CGFloat) -> UIFont? {
        return WPStyleGuide.serifFontForTextStyle(UIFont.TextStyle.largeTitle, fontWeight: .semibold).withSize(pointSize)
    }
}

extension GutenbergLayoutPickerViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 20
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        return cell
    }
}
