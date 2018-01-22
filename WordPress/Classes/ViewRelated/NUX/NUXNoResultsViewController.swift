import UIKit

@objc protocol NUXNoResultsViewControllerDelegate {
    func actionButtonPressed()
}

@objc class NUXNoResultsViewController: UIViewController {

    // MARK: - Properties

    @objc weak var delegate: NUXNoResultsViewControllerDelegate?
    @IBOutlet weak var noResultsImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subTitleLabel: UILabel!
    @IBOutlet weak var actionButton: LoginButton!

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()

        WPStyleGuide.configureColors(for: view, andTableView: nil)
    }

    @objc func configureView(title: String, buttonTitle: String, subTitle: String? = nil) {
        titleLabel.text = title
        subTitleLabel.text = subTitle
        actionButton?.setTitle(buttonTitle, for: UIControlState())
        actionButton?.setTitle(buttonTitle, for: .highlighted)
        actionButton?.titleLabel?.adjustsFontForContentSizeCategory = true
        actionButton?.accessibilityIdentifier = buttonTitle + " Button"
    }

    // MARK: - Button Handling

    @IBAction func actionButtonPressed(_ sender: Any) {
        delegate?.actionButtonPressed()
    }

}
