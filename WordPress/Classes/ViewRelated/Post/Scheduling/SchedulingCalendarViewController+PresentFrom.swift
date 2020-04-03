import Foundation

extension SchedulingCalendarViewController {
    static func present(from viewController: UIViewController, viewModel: PublishSettingsViewModel, updated: @escaping (Date?) -> Void, onDismiss: @escaping () -> Void) {
        let schedulingCalendarViewController = SchedulingCalendarViewController()
        schedulingCalendarViewController.coordinator = DateCoordinator(date: viewModel.date, timeZone: viewModel.timeZone, dateFormatter: viewModel.dateFormatter, dateTimeFormatter: viewModel.dateTimeFormatter, updated: updated, onDismiss: onDismiss)
        let vc = LightNavigationController(rootViewController: schedulingCalendarViewController)
        vc.modalPresentationStyle = .custom
        vc.transitioningDelegate = schedulingCalendarViewController
        viewController.present(vc, animated: true)
    }
}

extension SchedulingCalendarViewController: UIViewControllerTransitioningDelegate, UIAdaptivePresentationControllerDelegate {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        let presentationController = HalfScreenPresentationController(presentedViewController: presented, presenting: presenting)
        presentationController.delegate = self
        return presentationController
    }

    func adaptivePresentationStyle(for: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return traitCollection.verticalSizeClass == .compact ? .overFullScreen : .none
    }
}
