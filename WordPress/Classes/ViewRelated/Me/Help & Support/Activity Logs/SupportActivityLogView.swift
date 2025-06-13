import SwiftUI
import WordPressShared
import CocoaLumberjack

struct SupportActivityLogView: View {
    @StateObject private var viewModel = ActivityLogViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Section(footer: Text(Strings.sectionFooter)) {
                ForEach(viewModel.logFiles, id: \.filePath) { logFile in
                    NavigationLink(destination: SupportActivityDetailsView(logText: viewModel.getLogText(for: logFile), logDate: viewModel.getFormattedDate(for: logFile))) {
                        Text(index == 0 ? Strings.currentLog : viewModel.getFormattedDate(for: logFile))
                    }
                }
            }
        }
        .navigationTitle(Strings.title)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(role: .destructive) {
                    viewModel.showDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
        .alert(SharedStrings.Button.delete, isPresented: $viewModel.showDeleteConfirmation) {
            Button(SharedStrings.Button.cancel, role: .cancel) { }
            Button(Strings.confirmButton, role: .destructive) {
                viewModel.deleteOldLogs()
            }
        } message: {
            Text(Strings.deleteMessage)
        }
    }
}

private class ActivityLogViewModel: ObservableObject {
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

private enum Strings {
    static let title = NSLocalizedString("support.activityLog.navigation.title", value: "Activity Logs", comment: "Title shown in the navigation bar of the Activity Logs screen.")
    static let currentLog = NSLocalizedString("support.activityLog.list.currentLog", value: "Current", comment: "Label for the current activity log file in the list.")
    static let sectionFooter = NSLocalizedString("support.activityLog.list.sectionFooter", value: "Up to seven days worth of logs are saved.", comment: "Footer text explaining the log retention policy in the Activity Logs screen.")
    static let deleteMessage = NSLocalizedString("support.activityLog.alert.deleteMessage", value: "Clear all old activity logs?", comment: "Message shown in the alert when attempting to clear old activity logs.")
    static let confirmButton = NSLocalizedString("support.activityLog.alert.confirmButton", value: "Yes", comment: "Button title to confirm clearing old activity logs.")
}
