import SwiftUI
import WordPressCoreProtocols

struct EmptyDiskCacheView: View {

    @EnvironmentObject
    private var dataProvider: SupportDataProvider

    enum ViewState: Equatable {
        case loading
        case loaded(usage: DiskCacheUsage)
        case clearing(progress: Double, result: String, task: Task<Void, Never>)
        case error(String)

        var isClearingCache: Bool {
            if case .clearing = self {
                return true
            }

            return false
        }

        var buttonIsDisabled: Bool {
            if isClearingCache {
                return true
            }

            guard case .loaded(let usage) = self else {
                return true
            }

            return usage.isEmpty
        }

        var task: Task<Void, Never>? {
            guard case .clearing(_, _, let task) = self else {
                return nil
            }

            return task
        }

        var buttonText: String {
            isClearingCache ? Localization.clearing : Localization.clearDiskCache
        }

        var buttonImage: String {
            isClearingCache ? "hourglass" : "trash"
        }

        var primaryStatusText: String {
            if case .loaded(let usage) = self {
                if usage.isEmpty {
                    return Localization.cacheIsEmpty
                } else {
                    return String
                        .localizedStringWithFormat(Localization.cacheFiles, usage.fileCount, usage.formattedDiskUsage)
                        .applyingNumericMorphology(for: usage.fileCount)
                }
            }

            return ""
        }

        var secondaryStatusText: String {
            if case .clearing(let progress, _, _) = self {
                return formatter.string(from: progress as NSNumber) ?? ""
            }

            return ""
        }

        var progressBarProgress: CGFloat {
            guard case .clearing(let progress, _, _) = self else {
                return 0
            }

            return progress
        }

        var progressBarOpacity: CGFloat {
            if case .clearing = self {
                return 1.0
            }

            return 0
        }

        private var formatter: NumberFormatter {
            let formatter = NumberFormatter()
            formatter.numberStyle = .percent
            formatter.maximumFractionDigits = 0
            return formatter
        }
    }

    @State
    var state: ViewState = .loading

    var body: some View {
        // Clear Disk Cache card
        DiagnosticCard(
            title: Localization.clearDiskCache,
            subtitle: Localization.clearDiskCacheDescription,
            systemImage: "externaldrive.badge.xmark"
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Button {
                    clearDiskCache()
                } label: {
                    Label(self.state.buttonText, systemImage: self.state.buttonImage)
                }
                .buttonStyle(.borderedProminent)
                .disabled(self.state.buttonIsDisabled)

                // Progress bar under the button
                VStack(alignment: .leading, spacing: 6) {
                    if case .loading = state {
                        ProgressView(Localization.loadingDiskUsage)
                    } else {
                        ProgressView(value: self.state.progressBarProgress)
                            .progressViewStyle(.linear)
                            .tint(.accentColor)
                            .opacity(self.state.progressBarOpacity)

                        HStack {
                            Text("^[\(self.state.primaryStatusText)](inflect: true)")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Spacer()

                            Text(self.state.secondaryStatusText)
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.secondary)
                                    .opacity(self.state.progressBarOpacity)
                        }
                    }
                }
            }
            .task(self.fetchDiskCacheUsage)
        }
    }

    private func fetchDiskCacheUsage() async {
        do {
            let usage = try await dataProvider.fetchDiskCacheUsage()
            self.state = .loaded(usage: usage)
        } catch {
            self.state = .error(error.localizedDescription)
        }
    }

    // Simulated async cache clearing with progress updates.
    private func clearDiskCache() {
        guard case .loaded(let usage) = state else {
            return
        }

        self.dataProvider.userDid(.emptyDiskCache(bytesSaved: usage.byteCount))
        self.state = .clearing(progress: 0, result: "", task: self.clearDiskCacheTask)
    }

    private var clearDiskCacheTask: Task<Void, Never> {
        Task {
            guard case .clearing(_, _, let task) = state else {
                return
            }
            do {
                try await Task.runForAtLeast(.seconds(1.0)) {
                    // If the process takes less than a second, show the progress bar and percent for at least that long
                    try await dataProvider.clearDiskCache { @MainActor progress in
                        withAnimation {
                            self.state = .clearing(
                                progress: progress.progress,
                                result: Localization.working,
                                task: task
                            )
                        }
                    }

                    await MainActor.run {
                        withAnimation {
                            self.state = .clearing(
                                progress: 1.0,
                                result: Localization.complete,
                                task: task
                            )
                        }
                    }
                }

                let usage = try await dataProvider.fetchDiskCacheUsage()

                withAnimation {
                    self.state = .loaded(usage: usage)
                }
            } catch {
                withAnimation {
                    self.state = .error(error.localizedDescription)
                }
            }
        }
    }
}

#Preview {
    EmptyDiskCacheView().environmentObject(SupportDataProvider.testing)
}
