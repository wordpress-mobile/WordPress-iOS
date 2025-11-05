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
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Toggle(isOn: $includeApplicationLogs.animation(.easeInOut(duration: 0.3))) {
                    Text(Localization.includeApplicationLogs)
                        .font(.body)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                self.includeApplicationLogs.toggle()
                            }
                        }
                }

                Text(Localization.applicationLogsDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }.padding(4)
        } header: {
            HStack {
                Text(Localization.applicationLogs)
                Text(Localization.optional)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        } footer: {
            if includeApplicationLogs {
                switch self.state {
                case .loading: ProgressView()
                case .loaded(let logs):
                    applicationLogList(logs)
                case .error(let error):
                    ErrorView(
                        title: Localization.unableToLoadApplicationLogs,
                        message: error
                    )
                }
            }
        }.task {
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

    @ViewBuilder
    func applicationLogList(_ applicationLogs: [ApplicationLog]) -> some View {
        // Show a brief list of logs
        VStack(alignment: .leading, spacing: 8) {
            Text(Localization.logFilesToUpload)
            ForEach(applicationLogs, id: \.path) { log in
                ApplicationLogRow(log: log)
            }
        }
        .padding(.vertical)
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
    }
}

struct ApplicationLogRow: View {
    let log: ApplicationLog

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: "doc.text")
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(log.path.lastPathComponent)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text(formatDate(log.modifiedAt))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color.clear)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
        )
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
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
            }.environmentObject(SupportDataProvider.testing)

        }
    }

    return Preview()
}
