import SwiftUI
import WordPressUI

struct PostSettingsPasswordEntryView: View {
    let password: String

    @State private var input = ""
    @State private var isSecure = true

    @Environment(\.dismiss) private var dismiss

    var onSave: (String) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        SecureTextField(text: $input, isSecure: isSecure, placeholder: Strings.placeholder)
                            .fixedSize(horizontal: false, vertical: true)

                        Button {
                            isSecure.toggle()
                        } label: {
                            Image(systemName: isSecure ? "eye" : "eye.slash")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(isSecure ? Strings.showPassword : Strings.hidePassword)
                    }
                } footer: {
                    Text(Strings.instructions)
                }
            }
            .navigationTitle(Strings.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button.make(role: .cancel) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button.make(role: .confirm) {
                        onSave(input)
                        dismiss()
                    }
                    .disabled(input.isEmpty)
                }
            }
        }
        .onAppear {
            input = password
        }
    }
}

private enum Strings {
    static let title = NSLocalizedString("postSettings.passwordEntry.navigationTitle", value: "Enter Password", comment: "Navigation title for password entry screen")
    static let placeholder = NSLocalizedString("postSettings.passwordEntry.placeholder", value: "Enter password", comment: "Placeholder for password field")
    static let instructions = NSLocalizedString("postSettings.passwordEntry.instructions", value: "Enter a password to protect this post. Only users with the password will be able to view it.", comment: "Instructions for password entry")
    static let showPassword = NSLocalizedString("postSettings.passwordEntry.showPassword", value: "Show password", comment: "Accessibility label for show password button")
    static let hidePassword = NSLocalizedString("postSettings.passwordEntry.hidePassword", value: "Hide password", comment: "Accessibility label for hide password button")
}
