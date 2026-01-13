import SwiftUI
import WordPressData
import WordPressUI

struct PostVisibilityPicker: View {
    @State private var selection: Selection
    @State private var isShowingPasswordEntry = false
    @Environment(\.dismiss) private var dismiss

    struct Selection {
        let type: PostVisibility
        let password: String

        init(type: PostVisibility, password: String = "") {
            self.type = type
            self.password = password
        }

        init(settings: PostSettings) {
            self.type = PostVisibility(status: settings.status, password: settings.password)
            self.password = settings.password ?? ""
        }
    }

    private let onSubmit: (Selection) -> Void

    static var title: String { Strings.title }

    init(selection: Selection, onSubmit: @escaping (Selection) -> Void) {
        self._selection = State(initialValue: selection)
        self.onSubmit = onSubmit
    }

    var body: some View {
        Form {
            ForEach(PostVisibility.allCases, content: makeRow)
        }
        .navigationTitle(Strings.title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isShowingPasswordEntry) {
            PostSettingsPasswordEntryView(password: selection.password) {
                dismissWithSelection(.init(type: .protected, password: $0))
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
                }
                Spacer()
                Image(systemName: "checkmark")
                    .tint(Color(uiColor: UIAppColor.primary))
                    .opacity(selection.type == visibility ? 1 : 0)
            }
        }
        .tint(.primary)

        if visibility == .protected && !selection.password.isEmpty {
            passwordRow
        }
    }

    private func didSelectVisibility(_ visibility: PostVisibility) {
        withAnimation {
            if visibility == .protected {
                isShowingPasswordEntry = true
            } else {
                dismissWithSelection(Selection(type: visibility))
            }
        }
    }

    private func dismissWithSelection(_ selection: Selection) {
        self.selection = selection
        onSubmit(selection)
        dismiss()
    }

    @ViewBuilder
    private var passwordRow: some View {
        Button {
            isShowingPasswordEntry = true
        } label: {
            PostSettingsPasswordRow(password: selection.password)
        }
        .buttonStyle(.plain)
    }
}

private enum Strings {
    static let title = NSLocalizedString("postVisibilityPicker.navigationTitle", value: "Visibility", comment: "Navigation bar title for the Post Visibility picker")
}
