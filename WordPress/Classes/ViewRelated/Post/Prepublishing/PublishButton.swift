import SwiftUI

struct PublishButton: View {
    @ObservedObject var viewModel: PublishButtonViewModel

    var body: some View {
        ZStack {
            Button(action: viewModel.onSubmitTapped) {
                Text(viewModel.title)
                    .font(.title3.weight(.medium))
                    .frame(maxWidth: .infinity)
                    .opacity(isDisabled ? 0 : 1)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(isDisabled)
            .buttonBorderShape(.roundedRectangle(radius: 8))
            .accessibilityIdentifier("publish")

            switch viewModel.state {
            case .default:
                EmptyView()
            case .loading:
                ProgressView()
                    .tint(Color.secondary)
            case let .uploading(title, progress):
                HStack(spacing: 10) {
                    ProgressView()
                        .tint(Color.secondary)

                    VStack(alignment: .leading) {
                        Text(title)
                            .font(.subheadline.weight(.medium))
                        if let progress {
                            Text(Strings.progress(progress))
                                .foregroundStyle(Color.secondary)
                                .font(.footnote)
                                .monospacedDigit()
                        }
                    }
                    .lineLimit(1)
                    .foregroundStyle(Color.primary)

                    Spacer()
                }
                .padding(.horizontal)
            case let .failed(title, details, onRetryTapped):
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Color.red)
                    VStack(alignment: .leading) {
                        Text(title)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.primary)
                        if let details {
                            Text(details)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .lineLimit(1)

                    Spacer()

                    if let onRetryTapped {
                        Button(Strings.retry, action: onRetryTapped)
                            .font(.subheadline)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private var isDisabled: Bool {
        switch viewModel.state {
        case .default: false
        case .loading, .uploading, .failed: true
        }
    }
}

final class PublishButtonViewModel: ObservableObject {
    @Published var title: String
    @Published var state: PublishButtonState = .default
    let onSubmitTapped: () -> Void

    init(title: String, state: PublishButtonState = .default, onSubmitTapped: @escaping () -> Void) {
        self.title = title
        self.onSubmitTapped = onSubmitTapped
        self.state = state
    }
}

enum PublishButtonState {
    case `default`
    case loading
    case uploading(title: String, progress: Progress?)
    case failed(title: String, details: String? = nil, onRetryTapped: (() -> Void)? = nil)

    struct Progress {
        let completed: Int64
        let total: Int64
    }
}

private enum Strings {
    static func progress(_ progress: PublishButtonState.Progress) -> String {
        let format = NSLocalizedString("publishButton.progress", value: "%@ of %@", comment: "Shows the download or upload progress with two parameters: preformatted completed and total bytes")
        return String(format: format, ByteCountFormatter.string(fromByteCount: progress.completed, countStyle: .file), ByteCountFormatter.string(fromByteCount: progress.total, countStyle: .file))
    }

    static let retry = NSLocalizedString("publishButton.retry", value: "Retry", comment: "Retry button title")
}

#Preview {
    VStack(spacing: 16) {
        PublishButton(viewModel: .init(title: "Publish", state: .default) {})
        PublishButton(viewModel: .init(title: "Publish", state: .loading) {})
        PublishButton(viewModel: .init(title: "Publish", state: .uploading(title: "Uploading media...", progress: .init(completed: 100, total: 2000))) {})
        PublishButton(viewModel: .init(title: "Publish", state: .failed(title: "Failed to upload media")) {})
        PublishButton(viewModel: .init(title: "Publish", state: .failed(title: "Failed to upload media", details: "Not connected to Internet", onRetryTapped: {})) {})
    }
    .padding()
}
