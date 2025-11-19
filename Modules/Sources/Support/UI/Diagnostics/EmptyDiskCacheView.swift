import SwiftUI
import WordPressCoreProtocols

struct EmptyDiskCacheView: View {

    @EnvironmentObject
    private var dataProvider: SupportDataProvider

    enum ViewState: Equatable {
        case loading
        case loaded(usage: DiskCacheUsage)
        case clearing(progress: Double, result: String)
        case error(Error)

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

        static func == (lhs: EmptyDiskCacheView.ViewState, rhs: EmptyDiskCacheView.ViewState) -> Bool {
            switch(lhs, rhs) {
                case (.loading, .loading):
                return true
            case (.loaded(let lhsUsage), .loaded(let rhsUsage)):
                return lhsUsage == rhsUsage
            case (.clearing(let lhsProgress, let lhsResult), .clearing(let rhsProgress, let rhsResult)):
                return lhsProgress == rhsProgress && lhsResult == rhsResult
            case (.error, .error):
                return true
            default:
                return false
            }
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
                    Task { await clearDiskCache() }
                } label: {
                    Label(self.state.isClearingCache ? Localization.clearing : Localization.clearDiskCache, systemImage: self.state.isClearingCache ? "hourglass" : "trash")
                }
                .buttonStyle(.borderedProminent)
                .disabled(self.state.buttonIsDisabled)

                // Progress bar under the button
                VStack(alignment: .leading, spacing: 6) {
                    switch self.state {
                    case .loading:
                        ProgressView(Localization.loadingDiskUsage)
                    case .loaded(let usage):
                        if usage.isEmpty {
                            Text(Localization.cacheIsEmpty)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        } else {
                            Text(String.localizedStringWithFormat(Localization.cacheFiles, usage.fileCount, usage.formattedDiskUsage))
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    case .clearing(let progress, let status):
                        ProgressView(value: progress)
                            .progressViewStyle(.linear)
                            .tint(.accentColor)
                            .opacity(progress > 0 ? 1 : 0)

                        Text(status)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        HStack {
                            Spacer()
                                Text("\(Int(progress * 100))%")
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.secondary)
                        }
                    case .error(let error):
                        Text(error.localizedDescription)
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
            self.state = .error(error)
        }
    }

    // Simulated async cache clearing with progress updates.
    private func clearDiskCache() async {
        guard case .loaded(let usage) = state else {
            return
        }

        self.dataProvider.userDid(.emptyDiskCache(bytesSaved: usage.byteCount))

        self.state = .clearing(progress: 0, result: "")

        do {
            try await Task.runForAtLeast(.seconds(1.5)) {
                try await dataProvider.clearDiskCache { progress in
                    await MainActor.run {
                        withAnimation {
                            self.state = .clearing(progress: progress.progress, result: Localization.working)
                        }
                    }
                }
            }

            withAnimation {
                self.state = .clearing(progress: 1.0, result: Localization.complete)
            }
        } catch {
            withAnimation {
                self.state = .error(error)
            }
        }
    }
}

#Preview {
    EmptyDiskCacheView().environmentObject(SupportDataProvider.testing)
}
