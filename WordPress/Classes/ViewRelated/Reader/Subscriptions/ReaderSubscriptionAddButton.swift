import SwiftUI

struct ReaderSubscriptionAddButton: View {
    enum Style {
        case navigation
        case compact
    }

    let style: Style

    @State private var isShowingPopover = false

    var body: some View {
        button.popover(isPresented: $isShowingPopover) {
            ReaderSubscriptionAddView()
        }
    }

    @ViewBuilder
    private var button: some View {
        switch style {
        case .navigation:
            Button {
                isShowingPopover = true
            } label: {
                Image(systemName: "plus")
            }
        case .compact:
            Button(Strings.addSubscription) {
                isShowingPopover = true
            }.buttonStyle(.primary)
        }
    }
}

private struct ReaderSubscriptionAddView: View {
    @State private var siteURL = ""
    @State private var isSubmitting = false
    @State private var isShowingSuccessView = false
    @State private var displayedError: Error?
    @FocusState private var isFocused: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            Text(Strings.addSubscriptionSubtitle)
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
        .onAppear {
            isFocused = true
        }
        .onChange(of: siteURL) { _ in
            displayedError = nil
        }
        .frame(width: 420)
        .interactiveDismissDisabled(!siteURL.isEmpty)
    }

    private var textField: some View {
        TextField("", text: $siteURL, prompt: Text(verbatim: "example.com"))
            .keyboardType(.URL)
            .textContentType(.URL)
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
            Text(Strings.addSubscription)
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
                .disabled(siteURL.isEmpty)
        }
    }

    private func onSubmitTapped() {
        isSubmitting = true
        displayedError = nil
        Task { @MainActor in
            do {
                try await ReaderSubscriptionHelper().followSite(withURL: siteURL)
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
    static let addSubscription = NSLocalizedString("reader.subscriptions.addSubscriptionButtonTitle", value: "Add Subscription", comment: "Button title")
    static let addSubscriptionSubtitle = NSLocalizedString("reader.subscriptions.addSubscriptionButtonSubtitle", value: "Subscribe to sites, newsletters, or RSS feeds", comment: "Button subtitle")
}
