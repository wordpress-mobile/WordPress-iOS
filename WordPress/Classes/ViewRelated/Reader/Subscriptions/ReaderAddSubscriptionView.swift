import SwiftUI

struct ReaderAddSubscriptionButton: View {
    enum Style {
        case navigation
        case compact
        case expanded
    }

    let style: Style

    @State private var isShowingPopover = false

    var body: some View {
        button.popover(isPresented: $isShowingPopover) {
            ReaderAddSubscriptionView()
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
        case .expanded:
            expanded
        }
    }

    private var expanded: some View {
        Button {
            isShowingPopover = true
        } label: {
            HStack(spacing: 16) {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(AppColor.brand, Color(.secondarySystemFill))
                    .font(.largeTitle.weight(.light))
                    .frame(width: 40)
                    .padding(.leading, 4)
                VStack(alignment: .leading) {
                    Text(Strings.addSubscription)
                        .font(.callout.weight(.medium))
                    Text(Strings.addSubscriptionSubtitle)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .lineLimit(1)
            }
            .padding(.bottom, 4)
        }
        .buttonStyle(.plain)
    }
}

private struct ReaderAddSubscriptionView: View {
    @State private var url = ""
    @FocusState private var isFocused: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            controls
            Text(Strings.addSubscriptionSubtitle)
                .font(.footnote)
                .foregroundStyle(.secondary)
            TextField("", text: $url, prompt: Text(verbatim: "example.com"))
                .keyboardType(.URL)
                .textContentType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($isFocused)
                .labelsHidden()
                .padding(.top, 12)
        }
        .padding()
        .onAppear {
            isFocused = true
        }
        .frame(width: 420)
        .interactiveDismissDisabled(!url.isEmpty)
    }

    private var controls: some View {
        HStack {
            Button(SharedStrings.Button.cancel) {
                dismiss()
            }
            Spacer()
            Text(Strings.addSubscription)
                .font(.headline)
            Spacer()
            Button(SharedStrings.Button.add) {
                // TODO: implement
            }
            .disabled(url.isEmpty)
            .font(.headline)
        }
    }
}

private enum Strings {
    static let addSubscription = NSLocalizedString("reader.subscriptions.addSubscriptionButtonTitle", value: "Add Subscription", comment: "Button title")
    static let addSubscriptionSubtitle = NSLocalizedString("reader.subscriptions.addSubscriptionButtonSubtitle", value: "Subscribe to sites, newsletters, or RSS feeds", comment: "Button subtitle")
}
