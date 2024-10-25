import SwiftUI

struct ReaderTagsAddTagView: View {
    @State private var tag = ""
    @State private var isSubmitting = false
    @State private var isShowingSuccessView = false
    @State private var displayedError: Error?
    @FocusState private var isFocused: Bool
    @Environment(\.dismiss) private var dismiss

    var trimmedTags: String {
        tag.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            Text(Strings.details)
                .font(.footnote)
                .foregroundStyle(.secondary)
            textField
            if let displayedError {
                Text(displayedError.localizedDescription)
                    .font(.callout)
                    .foregroundStyle(.red)
                    .lineLimit(2)
            }
        }
        .padding()
        .frame(maxHeight: .infinity, alignment: .top)
        .onAppear {
            isFocused = true
        }
        .onChange(of: tag) { _ in
            displayedError = nil
        }
        .interactiveDismissDisabled(!trimmedTags.isEmpty)
    }

    private var textField: some View {
        TextField("", text: $tag, prompt: Text(Strings.placeholder))
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .focused($isFocused)
            .labelsHidden()
            .padding(.top, 12)
            .disabled(isSubmitting)
            .onSubmit(onSubmitTapped)
    }

    private var header: some View {
        HStack {
            Button(SharedStrings.Button.cancel) {
                dismiss()
            }
            Spacer()
            Text(Strings.title)
                .font(.headline)
            Spacer()
            ZStack {
                buttonSubmit
                Button(SharedStrings.Button.add, action: {})
                    .hidden() // Sets the static width
            }
            .font(.headline)
        }
        .frame(height: 20)
    }

    @ViewBuilder
    private var buttonSubmit: some View {
        if isSubmitting {
            ProgressView()
        } else if isShowingSuccessView {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        } else {
            Button(SharedStrings.Button.add, action: onSubmitTapped)
                .disabled(trimmedTags.isEmpty)
        }
    }

    private func onSubmitTapped() {
        isSubmitting = true
        displayedError = nil
        Task { @MainActor in
            do {
                try await ReaderTagsHelper().followTag(trimmedTags)
                isShowingSuccessView = true
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
                    dismiss()
                }
            } catch {
                displayedError = error
            }
            isSubmitting = false
        }
    }
}

private enum Strings {
    static let title = NSLocalizedString("reader.tags.addTag.title", value: "Add Tag", comment: "Navigation title")
    static let details = NSLocalizedString("reader.tags.addTag.details", value: "You can enter any arbitrary tag name", comment: "Navigation title")
    static let placeholder = NSLocalizedString("reader.tags.addTag.placeholder", value: "Tag", comment: "Placeholder for text field")
}
