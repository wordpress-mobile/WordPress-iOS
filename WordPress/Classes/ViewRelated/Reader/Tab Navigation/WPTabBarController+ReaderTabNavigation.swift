import UIKit

extension WPTabBarController {

    @objc func makeReaderTabViewController() -> ReaderTabViewController {
        let viewModel = ReaderTabViewModel()
        return ReaderTabViewController(viewModel: viewModel)
    }
}
