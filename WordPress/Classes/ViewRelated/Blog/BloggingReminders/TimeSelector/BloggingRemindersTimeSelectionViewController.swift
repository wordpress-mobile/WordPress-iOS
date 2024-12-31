import UIKit
import WordPressUI

final class BloggingRemindersTimeSelectionViewController: UIViewController {

    var preferredWidth: CGFloat?

    private let scheduledTime: Date

    private let tracker: BloggingRemindersTracker

    private var onDismiss: ((Date) -> Void)?

    private lazy var timeSelectionView: BloggingRemindersTimeSelectionView = {
        let view = BloggingRemindersTimeSelectionView(selectedTime: scheduledTime)
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

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
