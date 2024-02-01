import SwiftUI
import DesignSystem

struct NoAtomicLogsView: View {
    enum State {
        case error((() -> Void))
        case empty
    }

    let state: State

    var body: some View {
        switch state {
        case .error(let retryAction):
            VStack(spacing: Length.Padding.double) {
                Text(Strings.error)
                DSButton(title: Strings.retry, style: .init(emphasis: .primary, size: .small)) {
                    retryAction()
                }
            }
        case .empty:
            Text(Strings.empty)
        }
    }
}

private enum Strings {
    static let empty = NSLocalizedString("noLogs.empty", value: "No log entries within this time range", comment: "A no results message displayed on the atomic logs screen.")
    static let error = NSLocalizedString("noLogs.error", value: "An error occurred", comment: "A generic error message displayed on the atomic logs screen.")
    static let retry = NSLocalizedString("noLogs.retry", value: "Retry", comment: "Button title for the retry button on the atomic logs screen.")
}
