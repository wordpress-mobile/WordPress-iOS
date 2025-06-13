import SwiftUI
import WordPressShared
import CocoaLumberjack

struct ActivityLogView: View {
    @StateObject private var viewModel = ActivityLogViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        List {
            Section(header: Text("Log Files By Created Date"),
                    footer: Text("Up to seven days worth of logs are saved.")) {
                ForEach(viewModel.logFiles.indices, id: \.self) { index in
                    let logFile = viewModel.logFiles[index]
                    NavigationLink(destination: ActivityLogDetailView(logText: viewModel.getLogText(for: logFile),
                                                                  dateString: viewModel.getFormattedDate(for: logFile))) {
                        Text(index == 0 ? "Current" : viewModel.getFormattedDate(for: logFile))
                    }
                }
            }
            
            Section {
                Button(action: {
                    viewModel.showDeleteConfirmation = true
                }) {
                    Text("Clear Old Activity Logs")
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .navigationTitle("Activity Logs")
        .alert("Delete", isPresented: $viewModel.showDeleteConfirmation) {
            Button("No", role: .cancel) { }
            Button("Yes", role: .destructive) {
                viewModel.deleteOldLogs()
            }
        } message: {
            Text("Clear all old activity logs?")
        }
    }
}

class ActivityLogViewModel: ObservableObject {
    @Published var logFiles: [DDLogFileInfo] = []
    @Published var showDeleteConfirmation = false
    
    private let fileLogger: DDFileLogger
    private let dateFormatter: DateFormatter
    
    init() {
        self.fileLogger = WPLogger.shared.fileLogger
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
        return dateFormatter.string(from: logFile.creationDate)
    }
    
    func getLogText(for logFile: DDLogFileInfo) -> String {
        guard let logData = try? Data(contentsOf: URL(fileURLWithPath: logFile.filePath)),
              let logText = String(data: logData, encoding: .utf8) else {
            return ""
        }
        return logText
    }
    
    func deleteOldLogs() {
        WPLogger.shared.deleteArchivedLogs()
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

#Preview {
    NavigationView {
        ActivityLogView()
    }
} 