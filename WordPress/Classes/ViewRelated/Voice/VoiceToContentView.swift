import SwiftUI
import DesignSystem

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

            if [VoiceToContentViewModel.Step.welcome, .recording].contains(viewModel.step) {
                RecordButton(viewModel: viewModel)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .padding(.bottom, 30)
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
        VStack {
            if let isEligible = viewModel.isEligible, !isEligible {
                Spacer()
                notEnoughRequestsView
            }
            Spacer()
        }
    }

    private var notEnoughRequestsView: some View {
        VStack(spacing: 4) {
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
}

private struct VoiceToContentRecordingView: View {
    @ObservedObject fileprivate var viewModel: VoiceToContentViewModel

    @State private var isRecording = true

    var body: some View {
        VStack {
            Spacer()
            VStack(spacing: 8) {
                if #available(iOS 17.0, *) {
                    waveformIcon
                        .symbolEffect(.variableColor)
                } else {
                    waveformIcon
                }
            }
            Spacer()
        }
    }

    private var waveformIcon: some View {
        Image(systemName: "waveform")
            .resizable()
            .scaledToFit()
            .frame(width: 80)
            .foregroundStyle(Color(uiColor: .brand))
    }

    private var buttonDone: some View {
        VStack(spacing: 16) {
            Button(action: viewModel.buttonDoneRecordingTapped) {
                Image(systemName: "stop.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28)
                    .padding(28)
                    .background(.black)
                    .foregroundColor(.white)
                    .clipShape(Circle())
            }

            Text(Strings.done)
                .foregroundStyle(.primary)
        }
    }
}

private struct RecordButton: View {
    @ObservedObject fileprivate var viewModel: VoiceToContentViewModel

    private var isRecording: Bool { viewModel.step == .recording }

    var body: some View {
        VStack(spacing: 16) {
            Button(action: isRecording ? viewModel.buttonDoneRecordingTapped : viewModel.buttonRecordTapped) {
                if #available(iOS 17.0, *) {
                    icon
                        .contentTransition(.symbolEffect(.replace, options: .speed(4)))
                } else {
                    icon
                }
            }

            Text(Strings.done)
                .foregroundStyle(.primary)
        }
        .opacity(viewModel.isButtonRecordEnabled ? 1 : 0.5)
        .disabled(!viewModel.isButtonRecordEnabled)
    }

    private var backgroundColor: Color {
        if !isRecording {
            return viewModel.isButtonRecordEnabled ? Color(uiColor: .brand) : Color.secondary.opacity(0.5)
        }
        return .black
    }

    private var icon: some View {
        Image(systemName: isRecording ? "stop.fill" : "mic")
            .resizable()
            .scaledToFit()
            .frame(width: isRecording ? 28 : 36)
            .padding(isRecording ? 28 : 24)
            .background(backgroundColor)
            .foregroundColor(.white)
            .clipShape(Circle())
    }
}

private struct VoiceToContenProcessingView: View {
    @ObservedObject fileprivate var viewModel: VoiceToContentViewModel

    var body: some View {
        VStack {
            Spacer()

            ProgressView()
                .controlSize(.large)

            Spacer()
        }
    }
}

private enum Strings {
    static let beginRecording = NSLocalizedString("postFromAudio.beginRecording", value: "Begin recording", comment: "Button title")
    static let done = NSLocalizedString("postFromAudio.done", value: "Done", comment: "Button title")
    static let retry = NSLocalizedString("postFromAudio.retry", value: "Retry", comment: "Button title")
    static let notEnoughRequests = NSLocalizedString("postFromAudio.notEnoughRequestsMessage", value: "You don't have enough requests available to create a post from audio.", comment: "Message for 'not eligible' state view")
    static let upgrade = NSLocalizedString("postFromAudio.buttonUpgrade", value: "Upgrade for more requests", comment: "Button title")
    static let ok = NSLocalizedString("postFromAudio.ok", value: "OK", comment: "Button title")
}
