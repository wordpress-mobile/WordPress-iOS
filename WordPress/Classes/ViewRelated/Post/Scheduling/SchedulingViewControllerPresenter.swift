import Foundation
import UIKit

class PresentableSchedulingViewControllerProvider {
    static func viewController(sourceView: UIView?,
                               sourceRect: CGRect?,
                               viewModel: PublishSettingsViewModel,
                               updated: @escaping (Date?) -> Void,
                               onDismiss: (() -> Void)?) -> UINavigationController {
        let schedulingViewController = schedulingViewController(with: viewModel, updated: updated)
        return wrappedSchedulingViewController(schedulingViewController,
                                               sourceView: sourceView,
                                               sourceRect: sourceRect,
                                               onDismiss: onDismiss)
    }

    static func wrappedSchedulingViewController(_ schedulingViewController: SchedulingDatePickerViewController,
                                                sourceView: UIView?,
                                                sourceRect: CGRect?,
                                                onDismiss: (() -> Void)?) -> SchedulingLightNavigationController {
        let vc = SchedulingLightNavigationController(rootViewController: schedulingViewController)
        vc.onDismiss = onDismiss

        if UIDevice.isPad() {
            vc.modalPresentationStyle = .popover
            if let popoverController = vc.popoverPresentationController,
               let sourceView = sourceView {
                popoverController.sourceView = sourceView
                popoverController.sourceRect = sourceRect ?? sourceView.frame
            }
        }
        return vc
    }

    static func schedulingViewController(with viewModel: PublishSettingsViewModel, updated: @escaping (Date?) -> Void) -> SchedulingDatePickerViewController {
        let schedulingViewController = SchedulingDatePickerViewController()
        schedulingViewController.coordinator = DateCoordinator(date: viewModel.date,
                                                               timeZone: viewModel.timeZone,
                                                               dateFormatter: viewModel.dateFormatter,
                                                               dateTimeFormatter: viewModel.dateTimeFormatter,
                                                               updated: updated)
        return schedulingViewController
    }
}

class SchedulingLightNavigationController: LightNavigationController {
    var onDismiss: (() -> Void)?

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        onDismiss?()
    }
}
