import Foundation

extension SchedulingCalendarViewController {
    static func present(from viewController: UIViewController, post: AbstractPost) {
        let model = PublishSettingsViewModel(post: post)
        let schedulingCalendarViewController = SchedulingCalendarViewController()
        schedulingCalendarViewController.coordinator = DateCoordinator(date: model.date, timeZone: model.timeZone, dateFormatter: model.dateFormatter, dateTimeFormatter: model.dateTimeFormatter) { date in
            // Date picked
        }
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
