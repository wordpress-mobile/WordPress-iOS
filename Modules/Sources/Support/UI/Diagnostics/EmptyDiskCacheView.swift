import SwiftUI
import WordPressCore

struct EmptyDiskCacheView: View {

    @EnvironmentObject
    private var dataProvider: SupportDataProvider

    enum ViewState: Equatable {
        case loading
        case loaded(usage: DiskCache.DiskCacheUsage)
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

    private let cache = DiskCache()

    var body: some View {
        // Clear Disk Cache card
        DiagnosticCard(
            title: "Clear Disk Cache",
            subtitle: "Remove temporary files to free up space or resolve problems.",
            systemImage: "externaldrive.badge.xmark"
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Button {
                    Task { await clearDiskCache() }
                } label: {
                    Label(self.state.isClearingCache ? "Clearing…" : "Clear Disk Cache", systemImage: self.state.isClearingCache ? "hourglass" : "trash")
                }
                .buttonStyle(.borderedProminent)
                .disabled(self.state.buttonIsDisabled)

                // Progress bar under the button
                VStack(alignment: .leading, spacing: 6) {
                    switch self.state {
                    case .loading:
                        ProgressView("Loading Disk Usage")
                    case .loaded(let usage):
                        if usage.isEmpty {
                            Text("Cache is empty")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("^[\(usage.fileCount) cache files](inflect: true) (\(usage.formattedDiskUsage))")
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
            let usage = try await cache.diskUsage()
            await MainActor.run {
                self.state = .loaded(usage: usage)
            }
        } catch {
            await MainActor.run {
                self.state = .error(error)
            }
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
            try await cache.removeAll { count, total in
                let progress: Double

                if count > 0 && total > 0 {
                    progress = Double(count) / Double(total)
                } else {
                    progress = 0
                }

                await MainActor.run {
                    withAnimation {
                        self.state = .clearing(progress: progress, result: "Working")
                    }
                }
            }

            await MainActor.run {
                withAnimation {
                    self.state = .clearing(progress: 1.0, result: "Complete")
                }
            }
        } catch {
            await MainActor.run {
                withAnimation {
                    self.state = .error(error)
                }
            }
        }
    }
}

#Preview {
    EmptyDiskCacheView()
}
