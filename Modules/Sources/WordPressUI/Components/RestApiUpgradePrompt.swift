import SwiftUI

public struct RestApiUpgradePrompt: View {

    private let localizedFeatureName: String
    private var didTapGetStarted: () -> Void

    public init(localizedFeatureName: String, didTapGetStarted: @escaping () -> Void) {
        self.localizedFeatureName = localizedFeatureName
        self.didTapGetStarted = didTapGetStarted
    }

    public var body: some View {
        EmptyStateView(
            label: {
                Text(Strings.title)
            },
            description: {
                Text(Strings.description(localizedFeatureName: localizedFeatureName))
            },
            actions: {
                Button(Strings.getStarted, action: didTapGetStarted)
                    .buttonStyle(.borderedProminent)
            }
        )
    }

    private enum Strings {
        static var title: String {
            NSLocalizedString("applicationPasswordRequired.title", value: "Application Password Required", comment: "Title for the prompt to upgrade to Application Passwords")
        }

        static func description(localizedFeatureName: String) -> String {
            let format = NSLocalizedString("applicationPasswordRequired.description", value: "Application passwords are a more secure way to connect to your self-hosted site, and enable support for features like %@.", comment: "Description for the prompt to upgrade to Application Passwords. The first argument is the name of the feature that requires Application Passwords.")
            return String(format: format, localizedFeatureName)
        }

        static var getStarted: String {
            NSLocalizedString("applicationPasswordRequired.getStartedButton", value: "Get Started", comment: "Title for the button to authenticate with Application Passwords")
        }
    }
}

#Preview {
    RestApiUpgradePrompt(localizedFeatureName: "User Management") {
        debugPrint("Tapped Get Started")
    }
}
