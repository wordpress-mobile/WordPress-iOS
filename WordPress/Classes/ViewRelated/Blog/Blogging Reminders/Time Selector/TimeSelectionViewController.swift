import UIKit

class TimeSelectionViewController: UIViewController {

    var preferredWidth: CGFloat?

    private lazy var timeSelectionView: TimeSelectionView = {
        let view = TimeSelectionView(selectedTime: "10:00 AM")
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    override func loadView() {
        let mainView = timeSelectionView
        if let width = preferredWidth {
            mainView.widthAnchor.constraint(equalToConstant: width).isActive = true
        }
        self.view = mainView
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        calculatePreferredSize()
    }

    private func calculatePreferredSize() {
        let targetSize = CGSize(width: view.bounds.width,
          height: UIView.layoutFittingCompressedSize.height)
        preferredContentSize = view.systemLayoutSizeFitting(targetSize)
        navigationController?.preferredContentSize = preferredContentSize
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
}

// MARK: - DrawerPresentable
extension TimeSelectionViewController: DrawerPresentable {
    var collapsedHeight: DrawerHeight {
        return .intrinsicHeight
    }
}

extension TimeSelectionViewController: ChildDrawerPositionable {
    var preferredDrawerPosition: DrawerPosition {
        return .collapsed
    }
}
