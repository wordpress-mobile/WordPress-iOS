import Foundation

final class MySiteOverlaysCoordinator {

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

    /// Presents an overlay on the specified view controller if conditions are met.
    /// This method ensures that only one overlay is presented at a time by sequentially
    /// checking and presenting overlays from various coordinators. Once an overlay is presented,
    /// the respective coordinator is cleared to prevent multiple overlays from showing concurrently.
    ///
    /// The method checks for the following overlays in order of priority:
    /// 1. Compliance Coordinator: Presents compliance-related content if required.
    /// 2. In-App Feedback Coordinator: Presents in-app feedback if no compliance overlay is needed.
    ///
    /// - Parameter viewController: The UIViewController instance on which to potentially present an overlay.
    @MainActor func presentOverlayIfNeeded(in viewController: UIViewController) async {
        if let complianceCoordinator, await complianceCoordinator.presentIfNeeded() {
            self.complianceCoordinator = nil
        } else if let inAppFeedbackCoordinator, inAppFeedbackCoordinator.presentIfNeeded(in: viewController) {
            self.inAppFeedbackCoordinator = nil
        }
    }
}
