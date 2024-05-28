import SwiftUI
import DesignSystem

// TODO: Add localization
struct VoiceToContentView: View {
    @StateObject var viewModel: VoiceToContentViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        contents
            .onAppear(perform: viewModel.onViewAppeared)
            .tint(Color(uiColor: .brand))
            .alert(viewModel.errorAlertMessage ?? "", isPresented: $viewModel.isShowingErrorAlert, actions: {
                Button(Strings.ok, action: buttonCancelTapped)
            })
    }

    @ViewBuilder
    private var contents: some View {
        VStack {
            headerView

            if case .failed(let message, let onRetry) = viewModel.loadingState {
                VStack(spacing: 32) {
                    Text(message)
                        .lineLimit(3)
                        .foregroundStyle(.secondary)
                    DSButton(title: Strings.retry, style: .init(emphasis: .secondary, size: .medium), action: onRetry)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                switch viewModel.step {
                case .welcome:
                    VoiceToContentWelcomeView(viewModel: viewModel)
                case .recording:
                    VoiceToContentRecordingView(viewModel: viewModel)
                case .processing:
                    VoiceToContenProcessingView(viewModel: viewModel)
                }
            }
        }
        .padding(22)
        .padding(.vertical, 4)
    }

    private var headerView: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 12) {
                Text(viewModel.title)
                    .font(.title3.weight(.bold))
                HStack(spacing: 5) {
                    Text(viewModel.subtitle)
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                    if case .welcome = viewModel.step, case .loading = viewModel.loadingState {
                        ProgressView()
                            .tint(.secondary)
                            .controlSize(.small)
                    }
                }
            }
            Spacer()
            Button(action: buttonCancelTapped) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary, Color(uiColor: .secondarySystemFill))
            }
            .buttonStyle(.plain)
        }
    }

    private func buttonCancelTapped() {
        viewModel.buttonCancelTapped()
        dismiss()
    }
}

private struct VoiceToContentWelcomeView: View {
    @ObservedObject fileprivate var viewModel: VoiceToContentViewModel

    var body: some View {
        VStack(spacing: 16) {
            if let isEligible = viewModel.isEligible, !isEligible {
                Spacer()
                notEnoughRequestsView
            }
            Spacer()
            buttonRecord
        }
    }

    private var notEnoughRequestsView: some View {
        VStack(spacing: 6) {
            Text(Strings.notEnoughRequests)
                .multilineTextAlignment(.center)
            Button(action: viewModel.buttonUpgradeTapped) {
                HStack {
                    Text(Strings.upgrade)
                    Image("icon-post-actionbar-view")
                }
            }
        }.frame(maxWidth: 320)
    }

    private var buttonRecord: some View {
        VStack(spacing: 16) {
            Button(action: viewModel.buttonRecordTapped) {
                Image(systemName: "mic")
                    .font(Font.system(size: 26, weight: .medium))
                    .tint(Color(uiColor: .white))
                    .frame(width: 80, height: 80)
                    .background(viewModel.isButtonRecordEnabled ? Color(uiColor: .brand) : Color.secondary.opacity(0.5))
                    .clipShape(Circle())
            }

            Text("Tap the button to begin recording")
                .foregroundStyle(.secondary)
        }
        .opacity(viewModel.isButtonRecordEnabled ? 1 : 0.3)
        .disabled(!viewModel.isButtonRecordEnabled)
    }
}

private struct VoiceToContentRecordingView: View {
    @ObservedObject fileprivate var viewModel: VoiceToContentViewModel

    @State private var isRecording = true

    var body: some View {
        VStack(spacing: 34) {

            Spacer()

            VStack(spacing: 8) {
                // Fallback on earlier versions
                if #available(iOS 17.0, *) {
                    Image(systemName: "waveform")
                        .font(.system(size: 80, weight: .medium))
                        .foregroundStyle(Color(uiColor: .brand))
                        .symbolEffect(.variableColor, isActive: true)
                }
            }

            Button(action: viewModel.buttonDoneRecordingTapped) {
                Text("Done")
            }
            .buttonStyle(.borderedProminent)

            Spacer()
        }
    }
}

private struct VoiceToContenProcessingView: View {
    @ObservedObject fileprivate var viewModel: VoiceToContentViewModel

    var body: some View {
        VStack {
            Spacer()
            ProgressView()
            Spacer()
        }
    }
}

private enum Strings {
    static let retry = NSLocalizedString("postFromAudio.retry", value: "Retry", comment: "Button title")
    static let notEnoughRequests = NSLocalizedString("postFromAudio.notEnoughRequestsMessage", value: "You don't have enough requests available to create a post from audio.", comment: "Message for 'not eligible' state view")
    static let upgrade = NSLocalizedString("postFromAudio.buttonUpgrade", value: "Upgrade for more requests", comment: "Button title")
    static let ok = NSLocalizedString("postFromAudio.ok", value: "OK", comment: "Button title")
}
