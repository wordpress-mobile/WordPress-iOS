import SwiftUI

public struct RestApiUpgradePrompt: View {

    private let localizedFeatureName: String
    private var didTapGetStarted: () -> Void

    public init(localizedFeatureName: String, didTapGetStarted: @escaping () -> Void) {
        self.localizedFeatureName = localizedFeatureName
        self.didTapGetStarted = didTapGetStarted
    }

    public var body: some View {
        VStack {
            let scrollView = ScrollView {
                VStack(alignment: .leading) {
                    Text(Strings.title)
                        .font(.largeTitle)
                        .fontWeight(.semibold)
                        .padding(.bottom)

                    Text(Strings.description(localizedFeatureName: localizedFeatureName))
                        .font(.body)
                }.padding()
            }

            if #available(iOS 16.4, *) {
                scrollView.scrollBounceBehavior(.basedOnSize, axes: [.vertical])
            }

            Spacer()
            VStack {
                Button(action: didTapGetStarted, label: {
                    HStack {
                        Spacer()
                        Text(Strings.getStarted)
                            .font(.headline)
                            .padding(4)
                        Spacer()
                    }
                }).buttonStyle(.borderedProminent)
            }.padding()
        }
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
