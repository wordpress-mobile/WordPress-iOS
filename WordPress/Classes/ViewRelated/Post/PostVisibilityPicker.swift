import SwiftUI
import WordPressUI

struct PostVisibilityPicker: View {
    @State private var selection: Selection
    @State private var previousSelection: Selection
    @State private var isDismissing = false
    @FocusState private var isPasswordFieldFocused: Bool

    struct Selection {
        var type: PostVisibility
        var password = ""

        init(post: AbstractPost) {
            self.type = PostVisibility(post: post)
            self.password = post.password ?? ""
        }
    }

    private let onSubmit: (Selection) -> Void

    static var title: String { Strings.title }

    init(selection: Selection, onSubmit: @escaping (Selection) -> Void) {
        self._selection = State(initialValue: selection)
        self._previousSelection = State(initialValue: selection)
        self.onSubmit = onSubmit
    }

    var body: some View {
        Form {
            ForEach(PostVisibility.allCases, content: makeRow)
        }
        .disabled(isDismissing)
        .navigationTitle(Strings.title)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(isPasswordFieldFocused)
        .toolbar {
            if isPasswordFieldFocused {
                ToolbarItem(placement: .cancellationAction) {
                    Button(SharedStrings.Button.cancel) {
                        withAnimation {
                            selection = previousSelection
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(SharedStrings.Button.done) {
                        buttonSavePasswordTapped()
                    }
                    .disabled(selection.password.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    @ViewBuilder
    private func makeRow(for visibility: PostVisibility) -> some View {
        Button(action: { didSelectVisibility(visibility) }) {
            HStack {
                VStack(alignment: .leading) {
                    Text(visibility.localizedTitle)
                    Text(visibility.localizedDetails)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .opacity(visibility != .protected && isPasswordFieldFocused ? 0.4 : 1)
                }
                Spacer()
                Image(systemName: "checkmark")
                    .tint(Color(uiColor: UIAppColor.primary))
                    .opacity((selection.type == visibility && !isPasswordFieldFocused) ? 1 : 0)
            }
        }
        .tint(.primary)
        .disabled(isPasswordFieldFocused && visibility != .protected)

        if visibility == .protected, selection.type == .protected {
            enterPasswordRows
        }
    }

    private func didSelectVisibility(_ visibility: PostVisibility) {
        withAnimation {
            previousSelection = selection
            selection.type = visibility
            selection.password = ""
            if visibility == .protected {
                isPasswordFieldFocused = true
            } else {
                onSubmit(selection)
            }
        }
    }

    @ViewBuilder
    private var enterPasswordRows: some View {
        PasswordField(password: $selection.password, isFocused: isPasswordFieldFocused)
            .focused($isPasswordFieldFocused)
            .onSubmit(buttonSavePasswordTapped)
    }

    private func buttonSavePasswordTapped() {
        withAnimation {
            isPasswordFieldFocused = false
            selection.password = selection.password.trimmingCharacters(in: .whitespaces)

            if !selection.password.isEmpty {
                isDismissing = true
                // Let the keyboard dismiss first to avoid janky animation
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(550)) {
                    onSubmit(selection)
                }
            } else {
                selection = previousSelection
            }
        }
    }
}

private struct PasswordField: View {
    @Binding var password: String
    @State var isSecure = true
    let isFocused: Bool

    var body: some View {
        HStack {
            textField
            if isFocused && !password.isEmpty {
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

private enum Strings {
    static let title = NSLocalizedString("postVisibilityPicker.navigationTitle", value: "Visibility", comment: "Navigation bar title for the Post Visibility picker")
    static let cancel = NSLocalizedString("postVisibilityPicker.cancel", value: "Cancel", comment: "Button cancel")
    static let save = NSLocalizedString("postVisibilityPicker.save", value: "Save", comment: "Button save")
    static let password = NSLocalizedString("postVisibilityPicker.password", value: "Password", comment: "Password placeholder text")
}
