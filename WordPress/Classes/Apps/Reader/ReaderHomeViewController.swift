import UIKit
import WordPressUI

final class ReaderHomeViewController: ReaderStreamViewController {
    override var isHomeModeEnabled: Bool { true }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = SharedStrings.Reader.home
        titleView.textLabel.text = SharedStrings.Reader.home
        navigationItem.titleView = titleView
    }

    override func headerForStream(_ topic: ReaderAbstractTopic?, container: UITableViewController) -> UIView? {
        let view = ReaderHeaderView()
        view.titleView.titleLabel.text = SharedStrings.Reader.home
        view.titleView.detailsTextView.text = Strings.homeDetails
        return view
    }
}

private enum Strings {
    static let homeDetails = NSLocalizedString("reader.home.header.details", value: "Stay current with the blogs you've subscribed to.", comment: "Screen header details")
}
