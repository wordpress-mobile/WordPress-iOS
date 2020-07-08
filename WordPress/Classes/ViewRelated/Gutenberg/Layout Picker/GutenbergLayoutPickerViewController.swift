import UIKit
import Gridicons

class GutenbergLayoutPickerViewController: UIViewController {

    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var titleView: UILabel!
    @IBOutlet weak var categoryBar: UICollectionView!
    @IBOutlet weak var headerHeightConstraint: NSLayoutConstraint!

    @IBOutlet weak var tableView: UITableView!

    @IBOutlet weak var footerView: UIView!
    @IBOutlet weak var createBlankPageBtn: UIButton!

    let minTitleFontSize: CGFloat = 22
    let maxTitleFontSize: CGFloat = 34
    var maxHeaderHeight: CGFloat = 285
    var minHeaderHeight: CGFloat {
        return (navigationController?.navigationBar.frame.height ?? 56) + categoryBar.frame.height + 9
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        styleButtons()
        maxHeaderHeight = headerHeightConstraint.constant

        let tableFooterFrame = footerView.frame
        let bottomInset = tableFooterFrame.size.height - (UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 44)
        tableView.contentInset = UIEdgeInsets(top: headerHeightConstraint.constant, left: 0, bottom: bottomInset, right: 0)

        closeButton.setImage(UIImage.gridicon(.crossSmall), for: .normal)
    }

    override func viewWillAppear(_ animated: Bool) {
        navigationController?.isNavigationBarHidden = true
        super.viewWillAppear(animated)
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

    }
}

extension GutenbergLayoutPickerViewController: UITableViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let scrollOffset = scrollView.contentOffset.y
        let newHeaderViewHeight = headerHeightConstraint.constant - scrollOffset

        if newHeaderViewHeight > maxHeaderHeight {
            headerHeightConstraint.constant = maxHeaderHeight
            titleView.font = titleViewFont(withSize: maxTitleFontSize)
        } else if newHeaderViewHeight < minHeaderHeight {
            headerHeightConstraint.constant = minHeaderHeight
            titleView.font = titleViewFont(withSize: minTitleFontSize)
        } else {
            headerHeightConstraint.constant = newHeaderViewHeight
            if !Feature.enabled(.gutenbergSnappyLayoutPicker) {
                // Resets the scroll offset to account for the shift in the header size. which provides a more "smooth" collapse of the header.
                // Removing this line can provide more of a "snap" to the collapsed position while still animating.
                scrollView.contentOffset.y = 0
            }

            let pointSize =  maxTitleFontSize * newHeaderViewHeight/maxHeaderHeight
            titleView.font = titleViewFont(withSize: max(minTitleFontSize, pointSize))
        }
    }

    private func titleViewFont(withSize pointSize: CGFloat) -> UIFont? {
        return WPStyleGuide.serifFontForTextStyle(UIFont.TextStyle.largeTitle, fontWeight: .semibold).withSize(pointSize)
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
