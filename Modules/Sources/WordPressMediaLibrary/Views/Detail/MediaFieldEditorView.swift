import SwiftUI

struct MediaFieldEditorView: View {
    let field: MediaEditableField
    @State var value: String
    let onCommit: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section {
                switch field {
                case .title, .altText:
                    TextField(field.placeholder, text: $value, axis: .vertical)
                        .lineLimit(1...4)
                case .caption, .description:
                    TextEditor(text: $value)
                        .frame(minHeight: 200)
                }
            } footer: {
                Text(field.hint)
            }
        }
        .navigationTitle(field.localizedTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(Strings.commonDone) {
                    onCommit(value)
                    dismiss()
                }
            }
        }
        // Commit on back button and swipe-back too, matching the V1 editor's
        // save-on-exit behavior. A cancelled interactive swipe never reaches
        // the disappearance callback, so it neither commits nor loses the
        // typed value. After Done this is a no-op (commitField skips
        // unchanged values).
        .onDisappear {
            onCommit(value)
        }
    }
}
