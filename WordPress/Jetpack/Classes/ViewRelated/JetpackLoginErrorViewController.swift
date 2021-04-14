import UIKit

class JetpackLoginErrorViewController: UIViewController {
    private let viewModel: JetpackErrorViewModel

    init(viewModel: JetpackErrorViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @IBOutlet weak var titleLabel: UILabel!

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Log the user out to prevent them being able to access the app after a restart
        AccountHelper.logOutDefaultWordPressComAccount()

        titleLabel.text = viewModel.title
    }
}
