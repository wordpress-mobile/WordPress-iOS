import Foundation

extension NoResultsViewController {
    struct Model {
        let titleText: String
        let subtitleText: String?
        let buttonText: String?
        var imageName: String?
        let accessoryView: UIView?

        init(title: String, subtitle: String? = nil, buttonText: String? = nil, imageName: String? = nil, accessoryView: UIView? = nil) {
            self.titleText = title
            self.subtitleText = subtitle
            self.buttonText = buttonText
            self.imageName = imageName
            self.accessoryView = accessoryView
        }
    }

    func bindViewModel(_ viewModel: Model) {
        configure(title: viewModel.titleText, buttonTitle: viewModel.buttonText, subtitle: viewModel.subtitleText, image: viewModel.imageName, accessoryView: viewModel.accessoryView)
    }
}
