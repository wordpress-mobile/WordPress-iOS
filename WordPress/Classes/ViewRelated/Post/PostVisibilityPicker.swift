import SwiftUI

struct PostVisibilityPicker: View {
    @State private var selection: PostVisibility = .public
    @State private var password = ""
    @State private var isEnteringPassword = false
    @State private var isDismissing = false

    struct Selection {
        var visibility: PostVisibility
        var password: String?
    }

    private let onSubmit: (Selection) -> Void

    static var title: String { Strings.title }

    init(visibility: PostVisibility, onSubmit: @escaping (Selection) -> Void) {
        self._selection = State(initialValue: visibility)
        self.onSubmit = onSubmit
    }

    var body: some View {
        Form {
            ForEach(PostVisibility.allCases, content: makeRow)
        }
        .disabled(isDismissing)
        .navigationTitle(Strings.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func makeRow(for visibility: PostVisibility) -> some View {
        Button(action: {
            withAnimation {
                if visibility == .protected {
                    isEnteringPassword = true
                } else {
                    selection = visibility
                    onSubmit(Selection(visibility: visibility, password: nil))
                }
            }
        }, label: {
            HStack {
                VStack(alignment: .leading) {
                    Text(visibility.localizedTitle)
                    Text(visibility.localizedDetails)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .opacity(isEnteringPassword ? 0.5 : 1)
                }
                Spacer()
                Image(systemName: "checkmark")
                    .tint(Color(uiColor: .primary))
                    .opacity((selection == visibility && !isEnteringPassword) ? 1 : 0)
            }
        })
        .tint(.primary)
        .disabled(isEnteringPassword && visibility != .protected)

        if visibility == .protected, isEnteringPassword {
            enterPasswordRows
        }
    }

    @ViewBuilder
    private var enterPasswordRows: some View {
        PasswordField(password: $password)
            .onSubmit(savePassword)

        HStack {
            Button(Strings.cancel) {
                withAnimation {
                    password = ""
                    isEnteringPassword = false
                }
            }
            .keyboardShortcut(.cancelAction)
            Spacer()
            Button(Strings.save, action: savePassword)
                .font(.body.weight(.medium))
                .disabled(password.isEmpty)
        }
        .buttonStyle(.plain)
        .foregroundStyle(Color(uiColor: .brand))
    }

    private func savePassword() {
        withAnimation {
            selection = .protected
            isEnteringPassword = false
            isDismissing = true
            // Let the keyboard dismiss first to avoid janky animation
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(550)) {
                onSubmit(Selection(visibility: .protected, password: password))
            }
        }
    }
}

private struct PasswordField: View {
    @Binding var password: String
    @State var isSecure = true
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack {
            textField
                .focused($isFocused)
            if !password.isEmpty {
                Button(action: { password = "" }) {
                    Image(systemName: "xmark.circle")
                        .foregroundStyle(.secondary)
                }.padding(.trailing, 4)
            }
            Button(action: { isSecure.toggle() }) {
                Image(systemName: isSecure ? "eye" : "eye.slash")
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
        .onAppear { isFocused = true }
    }
    @ViewBuilder
    private var textField: some View {
        if isSecure {
            SecureField(Strings.password, text: $password)
        } else {
            TextField(Strings.password, text: $password)
        }
    }
}

enum PostVisibility: Identifiable, CaseIterable {
    case `public`
    case `private`
    case protected

    init(status: AbstractPost.Status, password: String?) {
        if password != nil {
            self = .protected
        } else if status == .publishPrivate {
            self = .private
        } else {
            self = .public
        }
    }

    var id: PostVisibility { self }

    var localizedTitle: String {
        switch self {
        case .public: NSLocalizedString("postVisibility.public.title", value: "Public", comment: "Title for a 'Public' (default) privacy setting")
        case .protected: NSLocalizedString("postVisibility.protected.title", value: "Password protected", comment: "Title for a 'Password Protected' privacy setting")
        case .private: NSLocalizedString("postVisibility.private.title", value: "Private", comment: "Title for a 'Private' privacy setting")
        }
    }

    var localizedDetails: String {
        switch self {
        case .public: NSLocalizedString("postVisibility.public.details", value: "Visible to everyone", comment: "Details for a 'Public' (default) privacy setting")
        case .protected: NSLocalizedString("postVisibility.protected.details", value: "Visibile to everyone but requires a password", comment: "Details for a 'Password Protected' privacy setting")
        case .private: NSLocalizedString("postVisibility.private.details", value: "Only visible to site admins and editors", comment: "Details for a 'Private' privacy setting")
        }
    }

}

private enum Strings {
    static let title = NSLocalizedString("postVisibilityPicker.navigationTitle", value: "Visibility", comment: "Navigation bar title for the Post Visibility picker")
    static let cancel = NSLocalizedString("postVisibilityPicker.cancel", value: "Cancel", comment: "Button cancel")
    static let save = NSLocalizedString("postVisibilityPicker.save", value: "Save", comment: "Button save")
    static let password = NSLocalizedString("postVisibilityPicker.password", value: "Password", comment: "Password placeholder text")
}
