import UIKit
import Gridicons

class GutenbergLayoutPickerViewController: UIViewController {

    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var largeTitleView: UILabel!
    @IBOutlet weak var promptView: UILabel!
    @IBOutlet weak var categoryBar: UICollectionView!
    @IBOutlet weak var headerHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var footerView: UIView!
    @IBOutlet weak var createBlankPageBtn: UIButton!

    var completion: PageCoordinator.TemplateSelectionCompletion? = nil
    private var maxHeaderHeight: CGFloat! // This is set as part of viewDidLoad based on the initial value of headerHeightConstraint.constant
    private var midHeaderHeight: CGFloat! // This is set as part of viewDidLoad based on the initial value of largeTitleView position and maxHeaderHeight
    private var minHeaderHeight: CGFloat {
        return categoryBar.frame.height + 9
    }
    private var titleIsHidden: Bool = true {
        didSet {
            if oldValue != titleIsHidden {
                title = titleIsHidden ? nil : largeTitleView.text
                navigationController?.navigationBar.layoutIfNeeded() // Prevents an animation issue where the title "flies" in from the left on quick scroll
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        maxHeaderHeight = headerHeightConstraint.constant
        midHeaderHeight = maxHeaderHeight - largeTitleView.frame.maxY

        styleButtons()

        let tableFooterFrame = footerView.frame
        let bottomInset = tableFooterFrame.size.height - (UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 44)

        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: maxHeaderHeight))
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: bottomInset))

        closeButton.setImage(UIImage.gridicon(.crossSmall), for: .normal)
        largeTitleView.font = titleViewFont(withSize: largeTitleView.font.pointSize)
    }

    override func viewWillAppear(_ animated: Bool) {
        (navigationController as? GutenbergLightNavigationController)?.shadowIsHidden = true
        super.viewWillAppear(animated)
    }

    override func viewDidDisappear(_ animated: Bool) {
        (navigationController as? GutenbergLightNavigationController)?.shadowIsHidden = false
        super.viewDidDisappear(animated)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        (navigationController as? GutenbergLightNavigationController)?.shadowIsHidden = false
        super.prepare(for: segue, sender: sender)
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
            seperator = .separator
        } else {
            seperator = .lightGray
        }

        [createBlankPageBtn].forEach { (button) in
            button?.layer.borderColor = seperator.cgColor
            button?.layer.borderWidth = 1
            button?.layer.cornerRadius = 8
        }

        if #available(iOS 13.0, *) {
            closeButton.backgroundColor = UIColor { (traitCollection: UITraitCollection) -> UIColor in
                if traitCollection.userInterfaceStyle == .dark {
                    return UIColor.systemFill
                } else {
                    return UIColor.quaternarySystemFill
                }
            }
        }
    }

    private func titleViewFont(withSize pointSize: CGFloat) -> UIFont? {
        return WPStyleGuide.serifFontForTextStyle(UIFont.TextStyle.largeTitle, fontWeight: .semibold).withSize(pointSize)
    }
}

extension GutenbergLayoutPickerViewController: UITableViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let scrollOffset = scrollView.contentOffset.y
        let newHeaderViewHeight = maxHeaderHeight - scrollOffset

        if newHeaderViewHeight < minHeaderHeight {
            headerHeightConstraint.constant = minHeaderHeight
        } else {
            headerHeightConstraint.constant = newHeaderViewHeight
        }

        titleIsHidden = largeTitleView.frame.maxY > 0
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if largeTitleView.frame.midY > 0 {
            snapToHeight(scrollView, height: maxHeaderHeight)
        } else if promptView.frame.midY > 0 {
            snapToHeight(scrollView, height: midHeaderHeight)
        } else if headerHeightConstraint.constant != minHeaderHeight {
            snapToHeight(scrollView, height: minHeaderHeight)
        }
    }

    private func snapToHeight(_ scrollView: UIScrollView, height: CGFloat) {
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: .curveEaseInOut, animations: {
            scrollView.contentOffset.y = self.maxHeaderHeight - height
            self.headerHeightConstraint.constant = height
            self.headerView.layoutIfNeeded()
        }, completion: nil)

        titleIsHidden = (height >= maxHeaderHeight)
    }
}

extension GutenbergLayoutPickerViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 20 // This is a random number chossen for testing
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 318 // This is an estimated number for the height of the eventual cells. Being used for testing right now.
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        return cell
    }
}
