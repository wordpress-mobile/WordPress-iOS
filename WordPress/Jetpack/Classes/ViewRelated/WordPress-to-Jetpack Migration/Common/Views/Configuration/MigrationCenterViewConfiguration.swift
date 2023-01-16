struct MigrationCenterViewConfiguration {

    let attributedText: NSAttributedString
}

extension MigrationCenterViewConfiguration {

    init(step: MigrationStep) {
        self.attributedText = Appearance.highlightText(Appearance.highlightedText(for: step), inString: Appearance.text(for: step))
    }
}

private extension MigrationCenterViewConfiguration {

    enum Appearance {

        static let notificationsText = NSLocalizedString("migration.notifications.footer",
                                                   value: "When the alert appears tap Allow to continue receiving all your WordPress notifications.",
                                                   comment: "Footer for the migration notifications screen.")
        static let notificationsHighlightedText = NSLocalizedString("migration.notifications.footer.highlighted",
                                                       value: "Allow",
                                                       comment: "Highlighted text in the footer of the migration notifications screen.")

        static let doneText = NSLocalizedString("migration.done.footer",
                                                   value: "Please delete the WordPress app to avoid data conflicts.",
                                                   comment: "Footer for the migration done screen.")
        static let doneHighlightedText = NSLocalizedString("migration.done.footer.highlighted",
                                                       value: "delete the WordPress app",
                                                       comment: "Highlighted text in the footer of the migration done screen.")

        static func text(for step: MigrationStep) -> String {
            switch step {
            case .notifications:
                return notificationsText
            case .done:
                return doneText
            default:
                return ""
            }
        }

        static func highlightedText(for step: MigrationStep) -> String {
            switch step {
            case .notifications:
                return notificationsHighlightedText
            case .done:
                return doneHighlightedText
            default:
                return ""
            }
        }

        static func highlightText(_ subString: String, inString: String) -> NSAttributedString {
            let attributedString = NSMutableAttributedString(string: inString)

            guard let subStringRange = inString.nsRange(of: subString) else {
                return attributedString
            }

            attributedString.addAttributes([.font: WPStyleGuide.fontForTextStyle(.footnote, fontWeight: .bold)],
                                           range: subStringRange)
            return attributedString
        }
    }
}
