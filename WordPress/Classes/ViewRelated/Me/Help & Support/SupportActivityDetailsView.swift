import SwiftUI
import ShareExtensionCore
import CocoaLumberjack

struct SupportActivityDetailsView: View {
    @StateObject private var viewModel: SupportActivityDetailsViewModel
    @Environment(\.dismiss) private var dismiss

    init(logFile: DDLogFileInfo) {
        _viewModel = StateObject(wrappedValue: SupportActivityDetailsViewModel(logFile: logFile))
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                logLinesContent
            }
            .font(.subheadline)
            .padding()
        }
        .navigationTitle(viewModel.logDate)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    viewModel.buttonShareTapped()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
    }

    @ViewBuilder
    private var logLinesContent: some View {
        ForEach(Array(viewModel.logLines.enumerated()), id: \.offset) { _, line in
            Text(line)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private final class SupportActivityDetailsViewModel: ObservableObject {
    let logLines: [String]
    let logDate: String

    init(logFile: DDLogFileInfo) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.doesRelativeDateFormatting = true
        dateFormatter.timeStyle = .short

        self.logDate = logFile.creationDate.map(dateFormatter.string) ?? ""

        guard let logData = try? Data(contentsOf: URL(fileURLWithPath: logFile.filePath)),
              let logText = String(data: logData, encoding: .utf8) else {
            self.logLines = []
            return
        }
        self.logLines = logText
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map(String.init)
    }

    func buttonShareTapped() {
        let activityVC = UIActivityViewController(
            activityItems: [logLines.joined(separator: "\n")],
            applicationActivities: nil
        )

        // Exclude all activity types except copy and mail
        let excludedTypes: [UIActivity.ActivityType] = [
            .postToFacebook,
            .postToTwitter,
            .postToWeibo,
            .message,
            .print,
            .assignToContact,
            .saveToCameraRoll,
            .addToReadingList,
            .postToFlickr,
            .postToVimeo,
            .postToTencentWeibo,
            .airDrop,
            .openInIBooks,
            .markupAsPDF,
            SharePost.activityType
        ]

        activityVC.excludedActivityTypes = excludedTypes

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            activityVC.popoverPresentationController?.sourceView = rootVC.view
            rootVC.present(activityVC, animated: true)
        }
    }
}
