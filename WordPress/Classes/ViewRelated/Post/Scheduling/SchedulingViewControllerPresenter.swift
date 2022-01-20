import Foundation

protocol SchedulingViewControllerPresenting {
    static func present(from viewController: UIViewController, sourceView: UIView?, viewModel: PublishSettingsViewModel, updated: @escaping (Date?) -> Void, onDismiss: @escaping () -> Void)
}

class SchedulingViewControllerPresenter: SchedulingViewControllerPresenting {
    static func present(from viewController: UIViewController, sourceView: UIView?, viewModel: PublishSettingsViewModel, updated: @escaping (Date?) -> Void, onDismiss: @escaping () -> Void) {
        let schedulingViewController: SchedulingViewControllerProtocol
        if #available(iOS 14.0, *) {
            schedulingViewController = SchedulingDatePickerViewController()
        } else {
            schedulingViewController = SchedulingCalendarViewController()
        }
        schedulingViewController.coordinator = DateCoordinator(date: viewModel.date,
                                                               timeZone: viewModel.timeZone,
                                                               dateFormatter: viewModel.dateFormatter,
                                                               dateTimeFormatter: viewModel.dateTimeFormatter,
                                                               updated: updated)
        let vc = SchedulingLightNavigationController(rootViewController: schedulingViewController)
        vc.onDismiss = onDismiss

        if UIDevice.isPad() {
            vc.modalPresentationStyle = .popover
        } else {
            vc.modalPresentationStyle = .custom
            vc.transitioningDelegate = schedulingViewController
        }

        if let popoverController = vc.popoverPresentationController,
           let sourceView = sourceView {
            popoverController.sourceView = sourceView
            popoverController.sourceRect = sourceView.frame
        }

        viewController.present(vc, animated: true)
    }
}

protocol SchedulingViewControllerProtocol: UIViewController, UIViewControllerTransitioningDelegate, UIAdaptivePresentationControllerDelegate {
    var coordinator: DateCoordinator? { get set }
}

class SchedulingLightNavigationController: LightNavigationController {
    var onDismiss: (() -> Void)?

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        onDismiss?()
    }
}
