
import UIKit

// MARK: - BottomSheetDemoViewController

class BottomSheetDemoViewController: UINavigationController {

    private let resultsViewController = LocationResultsTableViewController()

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
        let topInset = CGFloat(88)
        let preferredHeight = view.bounds.height - topInset
        preferredContentSize = CGSize(width: view.bounds.width, height: preferredHeight)

        navigationBar.isTranslucent = false
        navigationBar.barTintColor = .white

        navigationBar.titleTextAttributes = [.foregroundColor: UIColor.black]

        navigationBar.setBackgroundImage(nil, for: .default)
        navigationBar.shadowImage = nil
    }
}
