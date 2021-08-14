import UIKit

class TimeSelectionViewController: UIViewController {

    var preferredWidth: CGFloat?

    private let scheduledTime: Date

    private let tracker: BloggingRemindersTracker

    private var onDismiss: ((Date) -> Void)?

    private lazy var timeSelectionView: TimeSelectionView = {
        let view = TimeSelectionView(selectedTime: scheduledTime)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    init(scheduledTime: Date, tracker: BloggingRemindersTracker, onDismiss: ((Date) -> Void)? = nil) {
        self.scheduledTime = scheduledTime
        self.tracker = tracker
        self.onDismiss = onDismiss
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

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
        if isMovingFromParent {
            onDismiss?(timeSelectionView.getDate())
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        // If a parent VC is being dismissed, and this is the last view shown in its navigation controller, we'll assume
        // the flow was interrupted.
        if isBeingDismissedDirectlyOrByAncestor() && navigationController?.viewControllers.last == self {
            tracker.flowDismissed(source: .timePicker)
        }
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
