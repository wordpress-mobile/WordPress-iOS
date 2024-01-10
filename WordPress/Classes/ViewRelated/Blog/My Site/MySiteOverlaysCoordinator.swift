import Foundation

class MySiteOverlaysCoordinator {

    // MARK: - Dependencies

    private var complianceCoordinator: CompliancePopoverCoordinator?
    private var inAppFeedbackCoordinator: InAppFeedbackPromptPresenting?

    // MARK: - Init

    init(complianceCoordinator: CompliancePopoverCoordinator = .init(),
         inAppFeedbackCoordinator: InAppFeedbackPromptPresenting = InAppFeedbackPromptCoordinator()) {
        self.complianceCoordinator = complianceCoordinator
        self.inAppFeedbackCoordinator = inAppFeedbackCoordinator
    }

    // MARK: - API

    func presentOverlayIfNeeded(in viewController: UIViewController) async {
        if let complianceCoordinator, await complianceCoordinator.presentIfNeeded() {
            self.complianceCoordinator = nil
        } else if let inAppFeedbackCoordinator, inAppFeedbackCoordinator.showPromptIfNeeded(in: viewController) {
            self.inAppFeedbackCoordinator = nil
        }
    }
}
