import UIKit

class ReaderTabViewController: UIViewController {

    private let viewModel: ReaderTabViewModel

    private let makeReaderTabView: (ReaderTabViewModel) -> ReaderTabView

    private lazy var readerTabView: ReaderTabView = {
        return makeReaderTabView(viewModel)
    }()

    init(viewModel: ReaderTabViewModel, readerTabViewFactory: @escaping (ReaderTabViewModel) -> ReaderTabView) {
        self.viewModel = viewModel
        self.makeReaderTabView = readerTabViewFactory
        super.init(nibName: nil, bundle: nil)
        self.title = ReaderTabConstants.title
        ReaderTabViewController.configureRestoration(on: self)
    }

    required init?(coder: NSCoder) {
        fatalError(ReaderTabConstants.storyBoardInitError)
    }

    func setupSearchButton() {
      navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .search,
                                                          target: WPTabBarController.sharedInstance(),
                                                          action: #selector(WPTabBarController.sharedInstance().navigateToReaderSearch))
    }

    override func loadView() {
        self.view = readerTabView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSearchButton()
    }
}


// MARK: - State Restoration
extension ReaderTabViewController: UIViewControllerRestoration {

    static func configureRestoration(on instance: ReaderTabViewController) {
        instance.restorationIdentifier = ReaderTabConstants.restorationIdentifier
        instance.restorationClass = ReaderTabViewController.self
    }

    static let encodedIndexKey = ReaderTabConstants.encodedIndexKey

    static func viewController(withRestorationIdentifierPath identifierComponents: [String],
                               coder: NSCoder) -> UIViewController? {

        let index = Int(coder.decodeInt32(forKey: ReaderTabViewController.encodedIndexKey))

        guard let controller = WPTabBarController.sharedInstance()?.readerTabViewController else {
            return nil
        }
        controller.setStartIndex(index)

        return controller
    }

    override func encodeRestorableState(with coder: NSCoder) {
        coder.encode(viewModel.selectedIndex, forKey: ReaderTabViewController.encodedIndexKey)
    }

    func setStartIndex(_ index: Int) {
        viewModel.selectedIndex = index
    }
}


// MARK: - Constants
extension ReaderTabViewController {
    private enum ReaderTabConstants {
        static let title = NSLocalizedString("Reader", comment: "The default title of the Reader")
        static let storyBoardInitError = "Storyboard instantiation not supported"
        static let restorationIdentifier = "WPReaderTabControllerRestorationID"
        static let encodedIndexKey = "WPReaderTabControllerIndexRestorationKey"
    }
}
