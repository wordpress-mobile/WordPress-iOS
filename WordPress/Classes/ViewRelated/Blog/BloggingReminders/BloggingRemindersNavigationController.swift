import UIKit
import WordPressUI

final class BloggingRemindersNavigationController: UINavigationController {
    private let onDismiss: (() -> Void)?

    required init(rootViewController: UIViewController, onDismiss: (() -> Void)? = nil) {
        self.onDismiss = onDismiss

        super.init(rootViewController: rootViewController)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        if isBeingDismissedDirectlyOrByAncestor() {
            onDismiss?()
        }
    }
}
