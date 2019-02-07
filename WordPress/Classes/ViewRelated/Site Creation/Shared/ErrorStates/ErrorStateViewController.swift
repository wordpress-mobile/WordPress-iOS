
import UIKit

// MARK: - ErrorStateViewController

/// This view controller manages the presentation of error views in the enhanced site creation sequence.
///
final class ErrorStateViewController: UIViewController {

    // MARK: Properties

    /// The configuration of the error state view to apply.
    private let configuration: ErrorStateViewConfiguration

    /// The content view serves as the root view of this view controller.
    private let contentView: ErrorStateView

    // MARK: ErrorStateViewController

    init(with configuration: ErrorStateViewConfiguration) {
        self.configuration = configuration
        self.contentView = ErrorStateView(with: configuration)

        super.init(nibName: nil, bundle: nil)
    }

    // MARK: UIViewController

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        super.loadView()
        view = contentView
        trackError()
    }

    private func trackError() {
        let errorProperties: [String: AnyObject] = [
            "error_info": configuration.title as AnyObject
        ]

        WPAnalytics.track(.enhancedSiteCreationErrorShown, withProperties: errorProperties)
    }
}
