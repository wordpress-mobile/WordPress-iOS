import Foundation
import UIKit

protocol PresentableSchedulingViewControllerProviding {
    static func viewController(sourceView: UIView?,
                               sourceRect: CGRect?,
                               viewModel: PublishSettingsViewModel,
                               transitioningDelegate: UIViewControllerTransitioningDelegate?,
                               updated: @escaping (Date?) -> Void,
                               onDismiss: (() -> Void)?) -> UINavigationController
}

class PresentableSchedulingViewControllerProvider: PresentableSchedulingViewControllerProviding {
    static func viewController(sourceView: UIView?,
                               sourceRect: CGRect?,
                               viewModel: PublishSettingsViewModel,
                               transitioningDelegate: UIViewControllerTransitioningDelegate?,
                               updated: @escaping (Date?) -> Void,
                               onDismiss: (() -> Void)?) -> UINavigationController {
        let schedulingViewController = schedulingViewController(with: viewModel, updated: updated)
        return wrappedSchedulingViewController(schedulingViewController,
                                               sourceView: sourceView,
                                               sourceRect: sourceRect,
                                               transitioningDelegate: transitioningDelegate,
                                               onDismiss: onDismiss)
    }

    static func wrappedSchedulingViewController(_ schedulingViewController: SchedulingViewControllerProtocol,
                                                sourceView: UIView?,
                                                sourceRect: CGRect?,
                                                transitioningDelegate: UIViewControllerTransitioningDelegate?,
                                                onDismiss: (() -> Void)?) -> SchedulingLightNavigationController {
        let vc = SchedulingLightNavigationController(rootViewController: schedulingViewController)
        vc.onDismiss = onDismiss

        if UIDevice.isPad() {
            vc.modalPresentationStyle = .popover
        } else {
            vc.modalPresentationStyle = .custom
            vc.transitioningDelegate = transitioningDelegate ?? schedulingViewController
        }

        if let popoverController = vc.popoverPresentationController,
           let sourceView = sourceView {
            popoverController.sourceView = sourceView
            popoverController.sourceRect = sourceRect ?? sourceView.frame
        }
        return vc
    }

    static func schedulingViewController(with viewModel: PublishSettingsViewModel, updated: @escaping (Date?) -> Void) -> SchedulingViewControllerProtocol {
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
        return schedulingViewController
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
