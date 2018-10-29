import UIKit

final class SiteCreationWizardTitle: UIViewController {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!

    private let data: SiteCreationHeaderData

    init(data: SiteCreationHeaderData) {
        self.data = data
        super.init(nibName: String(describing: type(of: self)), bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        populateTitle()
        populateSubtitle()
    }

    private func populateTitle() {
        titleLabel.text = data.title
    }

    private func populateSubtitle() {
        subtitleLabel.text = data.subtitle
    }
}
