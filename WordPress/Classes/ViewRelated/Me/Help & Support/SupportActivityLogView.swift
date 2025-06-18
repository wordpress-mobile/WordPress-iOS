import SwiftUI
import WordPressShared
import CocoaLumberjack

struct SupportActivityLogView: View {
    @StateObject private var viewModel = ActivityLogViewModel()

    @State private var isShowingDeleteConfirmation = false

    var body: some View {
        List {
            Section(footer: Text(Strings.sectionFooter)) {
                ForEach(viewModel.logFiles, id: \.filePath) { logFile in
                    NavigationLink(destination: SupportActivityDetailsView(logFile: logFile)) {
                        Text(viewModel.getFormattedDate(for: logFile))
                    }
                }
            }
            if !viewModel.logFiles.isEmpty {
                Section {
                    Button(role: .destructive) {
                        isShowingDeleteConfirmation = true
                    } label: {
                        Label(Strings.deleteTitle, systemImage: "trash")
                            .foregroundStyle(.red)
                    }
                }
            }
        }
        .navigationTitle(Strings.title)
        .alert(Strings.deleteTitle, isPresented: $isShowingDeleteConfirmation) {
            Button(SharedStrings.Button.cancel, role: .cancel) { }
            Button(Strings.deleteTitle, role: .destructive) {
                viewModel.buttonDeleteLogsTapped()
            }
        } message: {
            Text(Strings.deleteMessage)
        }
    }
}

private class ActivityLogViewModel: ObservableObject {
    @Published private(set) var logFiles: [DDLogFileInfo] = []

    private let fileLogger: DDFileLogger
    private let dateFormatter: DateFormatter

    init() {
        fileLogger = WPLogger.shared().fileLogger

        dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.doesRelativeDateFormatting = true
        dateFormatter.timeStyle = .short

        logFiles = fileLogger.logFileManager.sortedLogFileInfos
    }

    func getFormattedDate(for logFile: DDLogFileInfo) -> String {
        if logFile === logFiles.first {
            return Strings.currentLog
        }
        guard let creationDate = logFile.creationDate else {
            return "–"
        }
        return dateFormatter.string(from: creationDate)
    }

    func buttonDeleteLogsTapped() {
        WPLogger.shared().deleteArchivedLogs()
        logFiles = []
    }
}

private enum Strings {
    static let title = NSLocalizedString("support.activityLogs.navigationTitle", value: "Activity Logs", comment: "Title shown in the navigation bar of the Activity Logs screen.")
    static let currentLog = NSLocalizedString("support.activityLogs.currentLogTilte", value: "Current", comment: "Label for the current activity log file in the list.")
    static let sectionFooter = NSLocalizedString("support.activityLogs.sectionFooter", value: "Up to seven days worth of logs are saved.", comment: "Footer text explaining the log retention policy in the Activity Logs screen.")
    static let deleteTitle = NSLocalizedString("support.activityLogs.deleteLogsAlert.title", value: "Delete Logs", comment: "Title shown in the alert when attempting to clear old activity logs.")
    static let deleteMessage = NSLocalizedString("support.activityLogs.deleteLogsAlert.message", value: "Are you sure you want to delete all activity logs?", comment: "Message shown in the alert when attempting to clear old activity logs.")
}
