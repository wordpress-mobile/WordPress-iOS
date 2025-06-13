import SwiftUI
import WordPressShared
import CocoaLumberjack

struct SupportActivityLogView: View {
    @StateObject private var viewModel = ActivityLogViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Section(header: Text(Strings.sectionHeader),
                    footer: Text(Strings.sectionFooter)) {
                ForEach(viewModel.logFiles.indices, id: \.self) { index in
                    let logFile = viewModel.logFiles[index]
                    NavigationLink(destination: ActivityLogDetailView(
                        logText: viewModel.getLogText(for: logFile),
                        dateString: viewModel.getFormattedDate(for: logFile))) {
                            Text(index == 0 ? Strings.currentLog : viewModel.getFormattedDate(for: logFile))
                        }
                }
            }

            Section {
                Button(action: {
                    viewModel.showDeleteConfirmation = true
                }) {
                    Text(Strings.clearLogsButton)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .navigationTitle(Strings.title)
        .alert(Strings.deleteTitle, isPresented: $viewModel.showDeleteConfirmation) {
            Button(Strings.cancelButton, role: .cancel) { }
            Button(Strings.confirmButton, role: .destructive) {
                viewModel.deleteOldLogs()
            }
        } message: {
            Text(Strings.deleteMessage)
        }
    }
}

class ActivityLogViewModel: ObservableObject {
    @Published var logFiles: [DDLogFileInfo] = []
    @Published var showDeleteConfirmation = false

    private let fileLogger: DDFileLogger
    private let dateFormatter: DateFormatter

    init() {
        self.fileLogger = WPLogger.shared().fileLogger
        self.dateFormatter = DateFormatter()
        self.dateFormatter.dateStyle = .medium
        self.dateFormatter.doesRelativeDateFormatting = true
        self.dateFormatter.timeStyle = .short

        loadLogFiles()
    }

    func loadLogFiles() {
        logFiles = fileLogger.logFileManager.sortedLogFileInfos
    }

    func getFormattedDate(for logFile: DDLogFileInfo) -> String {
        logFile.creationDate.map(dateFormatter.string) ?? ""
    }

    func getLogText(for logFile: DDLogFileInfo) -> String {
        guard let logData = try? Data(contentsOf: URL(fileURLWithPath: logFile.filePath)),
              let logText = String(data: logData, encoding: .utf8) else {
            return ""
        }
        return logText
    }

    func deleteOldLogs() {
        WPLogger.shared().deleteArchivedLogs()
        loadLogFiles()
    }
}

struct ActivityLogDetailView: View {
    let logText: String
    let dateString: String

    var body: some View {
        ScrollView {
            Text(logText)
                .font(.system(.body, design: .monospaced))
                .padding()
        }
        .navigationTitle(dateString)
    }
}

private enum Strings {
    static let title = NSLocalizedString("support.activityLog.navigation.title", value: "Activity Logs", comment: "Title shown in the navigation bar of the Activity Logs screen.")
    static let backButton = NSLocalizedString("support.activityLog.navigation.backButton", value: "Logs", comment: "Title shown in the back button of the Activity Logs screen.")
    static let currentLog = NSLocalizedString("support.activityLog.list.currentLog", value: "Current", comment: "Label for the current activity log file in the list.")
    static let sectionHeader = NSLocalizedString("support.activityLog.list.sectionHeader", value: "Log Files By Created Date", comment: "Header text for the section containing log files in the Activity Logs screen.")
    static let sectionFooter = NSLocalizedString("support.activityLog.list.sectionFooter", value: "Up to seven days worth of logs are saved.", comment: "Footer text explaining the log retention policy in the Activity Logs screen.")
    static let clearLogsButton = NSLocalizedString("support.activityLog.list.clearLogsButton", value: "Clear Old Activity Logs", comment: "Button title to clear old activity logs.")
    static let deleteTitle = NSLocalizedString("support.activityLog.alert.deleteTitle", value: "Delete", comment: "Title of the alert shown when attempting to clear old activity logs.")
    static let deleteMessage = NSLocalizedString("support.activityLog.alert.deleteMessage", value: "Clear all old activity logs?", comment: "Message shown in the alert when attempting to clear old activity logs.")
    static let confirmButton = NSLocalizedString("support.activityLog.alert.confirmButton", value: "Yes", comment: "Button title to confirm clearing old activity logs.")
    static let cancelButton = NSLocalizedString("support.activityLog.alert.cancelButton", value: "No", comment: "Button title to cancel clearing old activity logs.")
}
