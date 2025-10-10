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

            stateView
        }
    }

    @ViewBuilder
    private var stateView: some View {
        switch viewModel.state {
        case .default:
            EmptyView()
        case .loading:
            ProgressView()
                .tint(Color.secondary)
        case let .uploading(title, details, progress, onInfoTapped):
            let content = HStack(spacing: 10) {
                if let progress {
                    MediaUploadProgressView(progress: progress)
                        .frame(width: Constants.accessoryViewWidth)
                } else {
                    ProgressView()
                        .foregroundStyle(.secondary)
                        .frame(width: Constants.accessoryViewWidth)
                }
                makeDetailsView(title: title, details: details)
                Spacer()
                if onInfoTapped != nil {
                    chevronUpView
                }
            }.padding(.horizontal)

            if let onInfoTapped {
                Button(action: onInfoTapped) { content }
            } else {
                content
            }
        case let .failed(title, details, onInfoTapped):
            let content = HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(Color.red)
                    .frame(width: Constants.accessoryViewWidth)
                makeDetailsView(title: title, details: details)
                Spacer()
                if onInfoTapped != nil {
                    chevronUpView
                }
            }.padding(.horizontal)

            if let onInfoTapped {
                Button(action: onInfoTapped) { content }
            } else {
                content
            }
        }
    }

    private func makeDetailsView(title: String, details: String?) -> some View {
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
        .tint(.primary)
        .lineLimit(1)
    }

    private var chevronUpView: some View {
        Image(systemName: "chevron.forward")
            .font(.subheadline.weight(.semibold))
            .tint(Color.secondary)
    }

    private var isDisabled: Bool {
        switch viewModel.state {
        case .default: false
        case .loading, .uploading, .failed: true
        }
    }
}

private enum Constants {
    static let accessoryViewWidth: CGFloat = 20
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
    case uploading(title: String, details: String, progress: Double?, onInfoTapped: (() -> Void)? = nil)
    case failed(title: String, details: String? = nil, onInfoTapped: (() -> Void)? = nil)
}

#Preview {
    VStack(spacing: 16) {
        PublishButton(viewModel: .init(title: "Publish", state: .default) {})
        PublishButton(viewModel: .init(title: "Publish", state: .loading) {})
        PublishButton(viewModel: .init(title: "Publish", state: .uploading(title: "Uploading media...", details: "2 items remaining", progress: 0.2)) {})
        PublishButton(viewModel: .init(title: "Publish", state: .failed(title: "Failed to upload media")) {})
        PublishButton(viewModel: .init(title: "Publish", state: .failed(title: "Failed to upload media", details: "Not connected to Internet", onInfoTapped: {})) {})
    }
    .padding()
}
