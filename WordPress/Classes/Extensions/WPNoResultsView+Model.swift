import Foundation
import WordPressShared

extension WPNoResultsView {
    struct Model {
        let title: String
        let message: String?
        let accessoryView: UIView?
        let buttonTitle: String?

        init(title: String, message: String? = nil, accessoryView: UIView? = nil, buttonTitle: String? = nil) {
            self.title = title
            self.message = message
            self.accessoryView = accessoryView
            self.buttonTitle = buttonTitle
        }
    }

    func bindViewModel(viewModel: Model) {
        titleText = viewModel.title
        messageText = viewModel.message
        accessoryView = viewModel.accessoryView
        buttonTitle = viewModel.buttonTitle
    }
}
