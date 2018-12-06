import UIKit

class PostingActivityViewController: UIViewController, StoryboardLoadable {

    // MARK: - StoryboardLoadable Protocol

    static var defaultStoryboardName = "PostingActivityViewController"

    // MARK: - Properties

    @IBOutlet weak var legendView: UIView!

    // MARK: - Init

    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Posting Activity", comment: "Title for stats Posting Activity view.")
        addLegend()
    }

}

// MARK: - Private Extension

private extension PostingActivityViewController {

    func addLegend() {
        let legend = PostingActivityLegend.loadFromNib()
        legendView.addSubview(legend)
    }

}
