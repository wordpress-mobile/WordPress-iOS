import SwiftUI
import AVFoundation

// TODO: Add localization
struct VoiceToContentView: View {
    @StateObject var viewModel: VoiceToContentViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            contents
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel", action: buttonCancelTapped)
                    }
                }
        }
        .tint(Color(uiColor: .brand))
        // TODO: Add proper error handing
        .alert(viewModel.errorMessage ?? "", isPresented: $viewModel.isShowingError, actions: {
            Button("OK", action: buttonCancelTapped)
        })
    }

    @ViewBuilder
    private var contents: some View {
        switch viewModel.state {
        case .welcome:
            VoiceToContentWelcomeView(viewModel: viewModel)
        case .recording:
            VoiceToContentRecordingView(viewModel: viewModel)
        case .processing:
            VoiceToContenProcessingView(viewModel: viewModel)
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
        VStack(spacing: 34) {
            VStack(spacing: 16) {
                Text("Post from Audio")
                    .font(.title.weight(.medium))
                Text("Requests available: 42")
            }

            VStack {
                if let error = viewModel.errorMessage {
                    // TODO: Add error handling
                    Text(error)
                        .foregroundStyle(.red)
                } else {
                    // TODO: Display these dynamically
                    Text("File size limit: 25 MB")
                    Text("Recording time limit: 5 minutes")
                }
            }.foregroundStyle(.secondary)

            Button(action: viewModel.buttonRecordTapped) {
                Image(systemName: "mic")
                    .font(Font.system(size: 26, weight: .medium))
                    .tint(Color(uiColor: .white))
                    .frame(width: 80, height: 80)
                    .background(Color(uiColor: .brand))
                    .clipShape(Circle())
            }

            Text("Tap the button to begin recording")
                    .foregroundStyle(.secondary)

            Spacer()
        }
    }
}

private struct VoiceToContentRecordingView: View {
    @ObservedObject fileprivate var viewModel: VoiceToContentViewModel

    @State private var isRecording = true

    var body: some View {
        VStack(spacing: 34) {
            VStack(spacing: 16) {
                Text("Recording...")
                    .font(.title.weight(.medium))
            }

            VStack(spacing: 8) {
                if #available(iOS 16.1, *) {
                    Text(viewModel.duration)
                        .fontDesign(.monospaced)
                        .contentTransition(.numericText())
                }

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

    @State private var isRecording = true

    var body: some View {
        VStack(spacing: 34) {
            VStack(spacing: 16) {
                Text("Processing...")
                    .font(.title.weight(.medium))
            }

            Spacer()
            ProgressView()
            Spacer()
        }
    }
}
