import SwiftUI

struct RecordView: View {
    @EnvironmentObject private var env: AppEnvironment
    @StateObject private var vm: RecordingViewModel

    @State private var showSitePicker = false
    @State private var showHistory = false
    @State private var recordError: String?

    init(env: AppEnvironment) {
        _vm = StateObject(wrappedValue: RecordingViewModel(
            recorder: env.audioRecorder,
            store: env.noteStore,
            siteCatalog: env.siteCatalog,
            phoneBridge: env.phoneBridge
        ))
    }

    var body: some View {
        VStack(spacing: 8) {
            Button {
                showSitePicker = true
            } label: {
                Text(env.siteCatalog.defaultSite?.name ?? "Choose site")
                    .font(.caption)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            .buttonStyle(.plain)

            recordButton

            Button("History") { showHistory = true }
                .font(.caption)
        }
        .padding(.vertical, 4)
        .navigationDestination(isPresented: $showSitePicker) { SitePickerView() }
        .navigationDestination(isPresented: $showHistory) { HistoryView() }
        .alert("Couldn't record", isPresented: Binding(
            get: { recordError != nil },
            set: { if !$0 { recordError = nil } }
        )) {
            Button("OK") { recordError = nil }
        } message: {
            Text(recordError ?? "")
        }
    }

    @ViewBuilder
    private var recordButton: some View {
        switch vm.state {
        case .idle:
            Button {
                do {
                    try vm.startRecording()
                } catch RecordingViewModelError.noDefaultSite {
                    recordError = "Pick a site first."
                } catch {
                    recordError = "Couldn't start recording."
                }
            } label: {
                Image(systemName: "mic.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 64)
                    .foregroundStyle(.red)
            }
            .buttonStyle(.plain)
            .disabled(env.siteCatalog.defaultSiteID == nil)

        case .recording:
            Button {
                try? vm.stopRecording()
            } label: {
                Image(systemName: "stop.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 64)
                    .foregroundStyle(.red)
            }
            .buttonStyle(.plain)
        }
    }
}
