import SwiftUI

public struct LoadMoreFooterView: View {
    public enum State {
        case loading
        case failure
    }

    let state: State
    var onRetry: (() -> Void)?

    public init(_ state: State) {
        self.state = state
    }

    public func onRetry(_ closure: (() -> Void)?) -> LoadMoreFooterView {
        var copy = self
        copy.onRetry = closure
        return copy
    }

    public var body: some View {
        contentView
            .frame(maxWidth: .infinity)
            .listRowSeparator(.hidden)
    }

    @ViewBuilder
    private var contentView: some View {
        switch state {
        case .loading:
            ProgressView()
        case .failure:
            Button(action: onRetry ?? {}) {
                HStack {
                    Image(systemName: "exclamationmark.circle")
                    if onRetry != nil {
                        Text(AppLocalizedString("shared.button.retry", value: "Retry", comment: "A shared button title used in different contexts"))
                    } else {
                        Text(AppLocalizedString("shared.error.geneirc", value: "Something went wrong", comment: "A generic error message"))
                    }
                }
                .lineLimit(1)
            }
            .disabled(onRetry == nil)
        }
    }
}
