import SwiftUI
import WordPressShared
import WordPressUI

// MARK: - ErrorStateViewController

/// This view controller manages the presentation of error views in the enhanced site creation sequence.
///
final class ErrorStateViewController: UIHostingController<AnyView> {

    // MARK: Properties

    /// The configuration of the error state view to apply.
    private let configuration: ErrorStateViewConfiguration

    // MARK: ErrorStateViewController

    init(with configuration: ErrorStateViewConfiguration) {
        self.configuration = configuration

        super.init(rootView: AnyView(ErrorStateView(configuration: configuration)))
    }

    // MARK: UIViewController

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // The hosting view overlays the site creation content, which provides its own background.
        view.backgroundColor = .clear

        trackError()
    }

    private func trackError() {
        let errorProperties: [String: AnyObject] = [
            "error_info": configuration.title as AnyObject
        ]

        WPAnalytics.track(.enhancedSiteCreationErrorShown, withProperties: errorProperties)
    }
}

// MARK: - ErrorStateView

/// Presents the various error states that can arise during the Site Creation flow.
///
/// This view is hosted by `ErrorStateViewController`.
private struct ErrorStateView: View {
    let configuration: ErrorStateViewConfiguration

    var body: some View {
        EmptyStateView {
            Label(configuration.title, systemImage: configuration.systemImage)
        } description: {
            if let subtitle = configuration.subtitle {
                Text(subtitle)
            }
        } actions: {
            if let retryActionHandler = configuration.retryActionHandler {
                Button(SharedStrings.Button.retry, action: retryActionHandler)
                    .buttonStyle(.borderedProminent)
            }
            if let contactSupportActionHandler = configuration.contactSupportActionHandler {
                Button(Strings.contactSupport, action: contactSupportActionHandler)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .topLeading) {
            if let dismissalActionHandler = configuration.dismissalActionHandler {
                Button(action: dismissalActionHandler) {
                    Image(systemName: "xmark")
                        .font(.body.weight(.semibold))
                }
                .padding()
            }
        }
    }
}

private enum Strings {
    static let contactSupport = NSLocalizedString(
        "Contact Support",
        comment: "If a user taps this label, the app will navigate to the Support view."
    )
}
