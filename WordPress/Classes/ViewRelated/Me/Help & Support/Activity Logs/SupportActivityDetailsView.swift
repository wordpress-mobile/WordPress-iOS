import SwiftUI

struct SupportActivityDetailsView: View {
    @StateObject private var viewModel: SupportActivityDetailsViewModel
    @Environment(\.dismiss) private var dismiss

    init(logText: String, logDate: String) {
        _viewModel = StateObject(wrappedValue: SupportActivityDetailsViewModel(logText: logText, logDate: logDate))
    }

    var body: some View {
        ScrollView {
            Text(viewModel.logText)
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
        .navigationTitle(viewModel.logDate)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    viewModel.shareLog()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
    }
}

private final class SupportActivityDetailsViewModel: ObservableObject {
    let logText: String
    let logDate: String

    init(logText: String, logDate: String) {
        self.logText = logText
        self.logDate = logDate
    }

    func shareLog() {
        let activityVC = UIActivityViewController(
            activityItems: [logText],
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
            .markupAsPDF
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
