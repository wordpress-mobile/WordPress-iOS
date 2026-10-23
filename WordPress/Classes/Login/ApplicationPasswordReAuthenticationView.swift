import Foundation
import UIKit
import SwiftUI
import DesignSystem
import WordPressData
import WordPressShared

struct ApplicationPasswordReAuthenticationView: View {
    /// Why the app needs the user to sign in again.
    enum Reason {
        /// The site rejected the saved application password.
        case invalid
        /// No application password is saved on this device, e.g. after a backup is restored to a new device.
        case missing
    }

    let blog: Blog
    let presenter: UIViewController
    let reason: Reason

    @Environment(\.dismiss) private var dismiss
    @State private var error: String?

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "key.slash")
                    .font(.system(size: 50))
                    .foregroundColor(.gray)

                Text(reason.title)
                    .font(.headline)

                Text(reason.description)
                    .font(.body)
                    .frame(maxWidth: .infinity)

                DSButton(
                    title: Strings.signInButton,
                    style: DSButtonStyle(emphasis: .primary, size: .large),
                    isLoading: .constant(false)
                ) {
                    self.error = nil

                    Task { @MainActor in
                        do {
                            let _ = try await SelfHostedSiteAuthenticator()
                                .signIn(
                                    site: blog.getUrl().absoluteString,
                                    from: presenter,
                                    context: .reauthentication(TaggedManagedObjectID(blog), username: blog.getUsername())
                                )

                            WPAnalytics.track(
                                .applicationPasswordCreated,
                                properties: ["source": "reauth", "success": "true"],
                                blog: blog
                            )

                            // Automatically dismiss this view upon a successful re-authentication.
                            dismiss()
                        } catch {
                            WPAnalytics.track(
                                .applicationPasswordCreated,
                                properties: [
                                    "source": "reauth",
                                    "success": "false",
                                    "error": "\(type(of: error))"
                                ] as [String: Any],
                                blog: blog
                            )
                            self.error = error.localizedDescription
                        }
                    }
                }

                if let error {
                    Text(error)
                        .font(.body)
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                }

                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(Strings.cancelButton) {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            WPAnalytics.track(
                .applicationPasswordReauthPrompted,
                properties: ["reason": reason.analyticsValue] as [String: Any],
                blog: blog
            )
        }
    }
}

private extension ApplicationPasswordReAuthenticationView.Reason {
    var title: String {
        switch self {
        case .invalid: Strings.title
        case .missing: Strings.missingTitle
        }
    }

    var description: String {
        switch self {
        case .invalid: Strings.description
        case .missing: Strings.missingDescription
        }
    }

    var analyticsValue: String {
        switch self {
        case .invalid: "invalid"
        case .missing: "missing"
        }
    }
}

private enum Strings {
    static let title: String = NSLocalizedString("login.appPasswordReAuth.title", value: "Invalid application password", comment: "Title shown when the application password is invalid")
    static let description: String = NSLocalizedString("login.appPasswordReAuth.description", value: "The application password assigned to the app no longer exists in your profile.\nPlease sign in again to create a new application password for the app to use.", comment: "Description explaining why the user needs to re-authenticate")
    static let missingTitle: String = NSLocalizedString(
        "login.appPasswordReAuth.missing.title",
        value: "Sign in again",
        comment: "Title shown when the app has no application password for a site on this device"
    )
    static let missingDescription: String = NSLocalizedString(
        "login.appPasswordReAuth.missing.description",
        value:
            "This device doesn't have the application password the app uses for this site. This can happen after moving to a new device.\nPlease sign in again to create a new application password for the app to use.",
        comment:
            "Description explaining why the user needs to sign in again when the app has no application password for a site on this device"
    )
    static let signInButton: String = NSLocalizedString("login.appPasswordReAuth.signInButton", value: "Sign In", comment: "Button to start the re-authentication process")
    static let cancelButton: String = NSLocalizedString("login.appPasswordReAuth.cancelButton", value: "Cancel", comment: "Button to dismiss the re-authentication view")
}
