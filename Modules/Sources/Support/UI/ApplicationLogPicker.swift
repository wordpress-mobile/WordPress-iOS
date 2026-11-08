import SwiftUI

struct ApplicationLogPicker: View {

    enum ViewState: Equatable {
        case loading
        case loaded([ApplicationLog])
        case error(String)
    }

    @EnvironmentObject
    private var dataProvider: SupportDataProvider

    @Binding
    var includeApplicationLogs: Bool

    @State
    var state: ViewState = .loading

    var body: some View {
        // Offering logs the support team will never receive is worse than not offering them at all.
        if dataProvider.canShareApplicationLogs {
            picker
        }
    }

    private var picker: some View {
        Section {
            Toggle(isOn: $includeApplicationLogs.animation(.easeInOut(duration: 0.3))) {
                Text(Localization.includeApplicationLogs)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            self.includeApplicationLogs.toggle()
                        }
                    }
            }

            if includeApplicationLogs {
                switch self.state {
                case .loading:
                    ProgressView()
                case .loaded(let logs):
                    ForEach(logs, id: \.path) { log in
                        ApplicationLogRow(log: log)
                    }
                // Reported in the footer instead: the error is drawn as a card of its own, which makes a
                // poor row of a card.
                case .error:
                    EmptyView()
                }
            }
        } header: {
            Text(Localization.applicationLogs)
        } footer: {
            VStack(alignment: .leading, spacing: 8) {
                Text(Localization.applicationLogsDescription)

                if includeApplicationLogs, case .error(let error) = self.state {
                    ErrorView(
                        title: Localization.unableToLoadApplicationLogs,
                        message: error
                    )
                }
            }
        }
        .task {
            await loadApplicationLogs()
        }
    }

    private func loadApplicationLogs() async {
        do {
            let logs = try await dataProvider.fetchApplicationLogs()
            self.state = .loaded(logs)
        } catch {
            self.state = .error(error.localizedDescription)
        }
    }
}

struct ApplicationLogRow: View {
    let log: ApplicationLog

    /// Matches the icon column the attachment rows use, and keeps it growing with the text.
    @ScaledMetric(relativeTo: .body)
    private var iconWidth: CGFloat = 24

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.text")
                .frame(width: iconWidth)
                .foregroundStyle(Color.accentColor)

            VStack(alignment: .leading, spacing: 2) {
                // A log is named for the day it covers, so the end of the name is the part worth keeping.
                Text(log.path.lastPathComponent)
                    .lineLimit(1)
                    .truncationMode(.middle)

                Text(log.modifiedAt.formatted(date: .numeric, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    struct Preview: View {
        @State var includeApplicationLogs: Bool = false
        var body: some View {
            Form {
                ApplicationLogPicker(
                    includeApplicationLogs: $includeApplicationLogs
                )
            }
            .environmentObject(SupportDataProvider.testing)
        }
    }

    return Preview()
}
