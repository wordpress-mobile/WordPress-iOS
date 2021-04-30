import Foundation

extension SchedulingCalendarViewController {
    static func present(from viewController: UIViewController, sourceView: UIView?, viewModel: PublishSettingsViewModel, updated: @escaping (Date?) -> Void, onDismiss: @escaping () -> Void) {
        let schedulingCalendarViewController = SchedulingCalendarViewController()
        schedulingCalendarViewController.coordinator = DateCoordinator(date: viewModel.date, timeZone: viewModel.timeZone, dateFormatter: viewModel.dateFormatter, dateTimeFormatter: viewModel.dateTimeFormatter, updated: updated)
        let vc = SchedulingLightNavigationController(rootViewController: schedulingCalendarViewController)
        vc.onDismiss = onDismiss

        if UIDevice.isPad() {
            vc.modalPresentationStyle = .popover
        } else {
            vc.modalPresentationStyle = .custom
            vc.transitioningDelegate = schedulingCalendarViewController
        }

        if let popoverController = vc.popoverPresentationController,
            let sourceView = sourceView {
            popoverController.sourceView = sourceView
            popoverController.sourceRect = sourceView.frame
        }

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

class SchedulingLightNavigationController: LightNavigationController {
    var onDismiss: (() -> Void)?

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        onDismiss?()
    }
}
