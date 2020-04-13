import UIKit

class ReaderTabViewController: UIViewController {

    private let viewModel: ReaderTabViewModel

    init(viewModel: ReaderTabViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        self.viewModel.filterTapped = { [weak self] (fromView, completion) in
            guard let self = self else { return }
            self.viewModel.presentFilter(from: self, sourceView: fromView, completion: { [weak self] title in
                self?.dismiss(animated: true, completion: nil)
                completion(title)
            })
        }
        title = NSLocalizedString("Reader", comment: "The default title of the Reader")
        setupSearchButton()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupSearchButton() {
      navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .search,
                                                          target: self,
                                                          action: #selector(didTapSearchButton))
    }

    override func loadView() {
        view = ReaderTabView(viewModel: viewModel)
    }
}

// MARK: - Actions
extension ReaderTabViewController {
    /// Search button
    @objc private func didTapSearchButton() {
        viewModel.performSearch()
    }
}
