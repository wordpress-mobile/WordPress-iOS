/// A text-type UIActivityItemSource for the share app activity.
///
/// Provides additional subject string so the subject line is filled when sharing the app via mail.
///
final class ShareAppTextActivityItemSource: NSObject {
    private let message: String

    init(message: String) {
        self.message = message
    }
}

// MARK: - UIActivityItemSource

extension ShareAppTextActivityItemSource: UIActivityItemSource {
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        // informs the activity controller that the activity type is text.
        return String()
    }

    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        return message
    }

    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
        return .defaultSubjectText
    }
}

// MARK: - Localized Strings

private extension String {
    static let defaultSubjectText = NSLocalizedString("WordPress Apps - Apps for any screen",
                                                      comment: "Subject line for when sharing the app with others through mail or any other activity types "
                                                        + "that support contains a subject field.")
}
