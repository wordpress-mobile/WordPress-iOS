import Foundation
import UIKit
import SwiftUI
import DesignSystem

struct ApplicationPasswordReAuthenticationView: View {
    let blog: Blog
    let presenter: UIViewController

    @Environment(\.dismiss) private var dismiss
    @State private var error: String?

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "key.slash")
                    .font(.system(size: 50))
                    .foregroundColor(.gray)

                Text(Strings.title)
                    .font(.headline)

                Text(Strings.description)
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

                            // Automatically dismiss this view upon a successful re-authentication.
                            dismiss()
                        } catch {
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
    }
}

private enum Strings {
    static let title: String = NSLocalizedString("login.appPasswordReAuth.title", value: "Invalid application password", comment: "Title shown when the application password is invalid")
    static let description: String = NSLocalizedString("login.appPasswordReAuth.description", value: "The application password assigned to the app no longer exists in your profile.\nPlease sign in again to create a new application password for the app to use.", comment: "Description explaining why the user needs to re-authenticate")
    static let signInButton: String = NSLocalizedString("login.appPasswordReAuth.signInButton", value: "Sign In", comment: "Button to start the re-authentication process")
    static let cancelButton: String = NSLocalizedString("login.appPasswordReAuth.cancelButton", value: "Cancel", comment: "Button to dismiss the re-authentication view")
}
