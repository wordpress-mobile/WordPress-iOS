
import UIKit

// MARK: - BottomSheetDemoViewController

class BottomSheetDemoViewController: UINavigationController {

    // MARK: Properties

    private struct Constants {
        static let topInset = CGFloat(88)
    }

    private let resultsViewController = LocationResultsTableViewController()

    // MARK: UIViewController

    init() {
        super.init(rootViewController: resultsViewController)
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
}

// MARK: - Private behavior

private extension BottomSheetDemoViewController {

    func setupView() {
        let preferredHeight = view.bounds.height - Constants.topInset
        preferredContentSize = CGSize(width: view.bounds.width, height: preferredHeight)

        navigationBar.barTintColor = .white
        navigationBar.isTranslucent = false

        navigationBar.titleTextAttributes = [.foregroundColor: UIColor.black]

        navigationBar.setBackgroundImage(nil, for: .default)
        navigationBar.shadowImage = nil
    }
}
