import SwiftUI
import UIKit

final class MilestoneHostingController<Content: View>: UIHostingController<Content> {
    private let notification: Notification
    private let milestoneCoordinator: MilestoneCoordinator
    private lazy var arrowConfigurator: NotificationDetailsArrowConfigurator = {
        NotificationDetailsArrowConfigurator(
            nextAction: milestoneCoordinator.shouldShowNext ? nextAction : nil,
            previousAction: milestoneCoordinator.shouldShowPrevious ? previousAction : nil
        )
    }()

    init(rootView: Content, milestoneCoordinator: MilestoneCoordinator, notification: Notification) {
        self.notification = notification
        self.milestoneCoordinator = milestoneCoordinator
        super.init(rootView: rootView)
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        makeNavigationBarTransparent()
        setupConstraints()
        configureNavBarButtons()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NotificationSyncMediator()?.markAsRead(notification)
    }

    private func makeNavigationBarTransparent() {
        if let navigationController = navigationController {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithTransparentBackground()
            appearance.backgroundColor = .clear
            appearance.shadowColor = .clear
            navigationController.navigationBar.isTranslucent = true
            navigationItem.standardAppearance = appearance
            navigationItem.scrollEdgeAppearance = appearance
            navigationItem.compactAppearance = appearance
        }
    }

    private func setupConstraints() {
        guard let superview = view.superview else { return }

        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: superview.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: superview.trailingAnchor),
            view.topAnchor.constraint(equalTo: superview.topAnchor),
            view.bottomAnchor.constraint(equalTo: superview.bottomAnchor)
        ])
    }

    private func configureNavBarButtons() {
        var barButtonItems: [UIBarButtonItem] = []

        if splitViewControllerIsHorizontallyCompact {
            barButtonItems.append(arrowConfigurator.makeNavigationButtons())
        }

        navigationItem.setRightBarButtonItems(barButtonItems, animated: false)
    }

    private func previousAction() {
        milestoneCoordinator.previousNotificationTapped(current: notification)
    }

    private func nextAction() {
        milestoneCoordinator.nextNotificationTapped(current: notification)
    }
}
