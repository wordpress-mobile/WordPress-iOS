import UIKit
import Gridicons

class GutenbergLayoutPickerViewController: UIViewController {

    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var headerBar: UIView!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var titleView: UILabel!
    @IBOutlet weak var largeTitleView: UILabel!
    @IBOutlet weak var promptView: UILabel!
    @IBOutlet weak var categoryBar: UICollectionView!
    @IBOutlet weak var headerHeightConstraint: NSLayoutConstraint!

    @IBOutlet weak var tableView: UITableView!

    @IBOutlet weak var footerView: UIView!
    @IBOutlet weak var createBlankPageBtn: UIButton!

    var completion: PageCoordinator.TemplateSelectionCompletion? = nil
    let minTitleFontSize: CGFloat = 17
    let maxTitleFontSize: CGFloat = 34
    var maxHeaderHeight: CGFloat = 260
    var midHeaderHeight: CGFloat = 215
    var minHeaderHeight: CGFloat {
        return headerBar.frame.height + categoryBar.frame.height + 9
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        styleButtons()
        maxHeaderHeight = headerHeightConstraint.constant

        let tableFooterFrame = footerView.frame
        let bottomInset = tableFooterFrame.size.height - (UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 44)

        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: maxHeaderHeight))
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: bottomInset))

        closeButton.setImage(UIImage.gridicon(.crossSmall), for: .normal)
        largeTitleView.font = titleViewFont(withSize: maxTitleFontSize)
        titleView.font = titleViewFont(withSize: minTitleFontSize)

        //        midHeaderHeight = maxHeaderHeight - promptView.frame.minY
    }

    override func viewWillAppear(_ animated: Bool) {
        navigationController?.isNavigationBarHidden = true
        super.viewWillAppear(animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func viewDidDisappear(_ animated: Bool) {
        navigationController?.isNavigationBarHidden = false
        super.viewDidDisappear(animated)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        navigationController?.isNavigationBarHidden = false
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
            seperator = UIColor.separator
        } else {
            seperator = UIColor(red: 0.235, green: 0.235, blue: 0.263, alpha: 0.29)
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

        if newHeaderViewHeight > maxHeaderHeight {
            headerHeightConstraint.constant = maxHeaderHeight
        } else if newHeaderViewHeight < minHeaderHeight {
            headerHeightConstraint.constant = minHeaderHeight
        } else {
            headerHeightConstraint.constant = newHeaderViewHeight
        }

        titleView.isHidden = largeTitleView.frame.maxY > headerBar.frame.height
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        let scrollComparisonPoint = headerBar.frame.maxY

        if largeTitleView.frame.midY > scrollComparisonPoint {
            snapToHeight(scrollView, height: maxHeaderHeight)
        } else if promptView.frame.midY > scrollComparisonPoint {
            snapToHeight(scrollView, height: midHeaderHeight)
        } else if headerHeightConstraint.constant != minHeaderHeight {
            snapToHeight(scrollView, height: minHeaderHeight)
        }
    }

    private func snapToHeight(_ scrollView: UIScrollView, height: CGFloat) {
        scrollView.contentOffset.y = maxHeaderHeight - height
        headerHeightConstraint.constant = height
        titleView.isHidden = (height >= maxHeaderHeight)
    }
}

extension GutenbergLayoutPickerViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 20
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 318
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        return cell
    }
}
