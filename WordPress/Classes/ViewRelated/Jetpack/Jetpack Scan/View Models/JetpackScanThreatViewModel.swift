import Foundation

struct JetpackScanThreatViewModel {

    private let threat: JetpackScanThreat

    let iconImage: UIImage?
    let iconImageColor: UIColor
    let title: String
    let description: String?
    let isFixing: Bool
    private let hasValidCredentials: Bool?

    // Threat Details
    let detailIconImage: UIImage?
    let detailIconImageColor: UIColor
    let problemTitle: String
    let problemDescription: String
    let fixTitle: String?
    let fixDescription: String?
    let technicalDetailsTitle: String
    let technicalDetailsDescription: String
    let fileName: String?
    let fileNameBackgroundColor: UIColor
    let fileNameColor: UIColor
    let fileNameFont: UIFont

    // Threat Detail Action
    let fixActionTitle: String?
    let fixActionEnabled: Bool
    let ignoreActionTitle: String?
    let ignoreActionMessage: String
    let warningActionTitle: HighlightedText?

    // Threat Detail Success
    let fixSuccessTitle: String
    let ignoreSuccessTitle: String

    // Threat Detail Error
    let fixErrorTitle: String
    let ignoreErrorTitle: String

    // Attributed string
    lazy var attributedFileContext: NSAttributedString? = {
        let contextConfig = JetpackThreatContext.JetpackThreatContextRendererConfig(
            numberAttributes: [
                NSAttributedString.Key.font: Constants.monospacedFont,
                NSAttributedString.Key.foregroundColor: Constants.colors.normal.numberText,
                NSAttributedString.Key.backgroundColor: Constants.colors.normal.numberBackground
            ],
            highlightedNumberAttributes: [
                NSAttributedString.Key.font: Constants.monospacedFont,
                NSAttributedString.Key.foregroundColor: Constants.colors.normal.numberText,
                NSAttributedString.Key.backgroundColor: Constants.colors.highlighted.numberBackground
            ],
            contentsAttributes: [
                NSAttributedString.Key.font: Constants.monospacedFont,
                NSAttributedString.Key.foregroundColor: Constants.colors.normal.text,
                NSAttributedString.Key.backgroundColor: Constants.colors.normal.background
            ],
            highlightedContentsAttributes: [
                NSAttributedString.Key.font: Constants.monospacedFont,
                NSAttributedString.Key.foregroundColor: Constants.colors.normal.text,
                NSAttributedString.Key.backgroundColor: Constants.colors.highlighted.numberBackground
            ],
            highlightedSectionAttributes: [
                NSAttributedString.Key.font: Constants.monospacedFont,
                NSAttributedString.Key.foregroundColor: Constants.colors.highlighted.text,
                NSAttributedString.Key.backgroundColor: Constants.colors.highlighted.background
            ]
        )

        return threat.context?.attributedString(with: contextConfig)
    }()

    init(threat: JetpackScanThreat, hasValidCredentials: Bool? = nil) {
        self.threat = threat
        self.hasValidCredentials = hasValidCredentials

        let status = threat.status

        iconImage = Self.iconImage(for: status)
        iconImageColor = Self.iconColor(for: status)
        title = Self.title(for: threat)
        description = Self.description(for: threat)
        isFixing = status == .fixing

        // Threat Details
        detailIconImage = UIImage(named: "jetpack-scan-state-error")
        detailIconImageColor = .error
        problemTitle = Strings.details.titles.problem
        problemDescription = threat.description
        fixTitle = Self.fixTitle(for: threat)
        fixDescription = Self.fixDescription(for: threat)
        technicalDetailsTitle = Strings.details.titles.technicalDetails
        technicalDetailsDescription = Strings.details.descriptions.technicalDetails
        fileName = threat.fileName
        fileNameBackgroundColor = Constants.colors.normal.background
        fileNameFont = Constants.monospacedFont
        fileNameColor = Constants.colors.normal.text

        // Threat Details Action
        fixActionTitle = Self.fixActionTitle(for: threat)
        fixActionEnabled = hasValidCredentials ?? false
        ignoreActionTitle = Self.ignoreActionTitle(for: threat)
        ignoreActionMessage = Strings.details.actions.messages.ignore
        warningActionTitle = Self.warningActionTitle(for: threat, hasValidCredentials: hasValidCredentials)

        // Threat Detail Success
        fixSuccessTitle = Strings.details.success.fix
        ignoreSuccessTitle = Strings.details.success.ignore

        // Threat Details Error
        fixErrorTitle = Strings.details.error.fix
        ignoreErrorTitle = Strings.details.error.ignore
    }

    private static func fixTitle(for threat: JetpackScanThreat) -> String? {
        guard let status = threat.status else {
            return nil
        }

        let fixable = threat.fixable?.type != nil

        switch (status, fixable) {
        case (.fixed, _):
            return Strings.details.titles.fix.fixed
        case (.current, false):
            return Strings.details.titles.fix.notFixable
        default:
            return Strings.details.titles.fix.default
        }
    }

    private static func fixDescription(for threat: JetpackScanThreat) -> String? {
        guard let fixType = threat.fixable?.type else {
            return Strings.details.descriptions.fix.notFixable
        }

        let description: String

        switch fixType {
            case .replace:
                description = Strings.details.descriptions.fix.replace
            case .delete:
                description = Strings.details.descriptions.fix.delete
            case .update:
                description = Strings.details.descriptions.fix.update
            case .edit:
                description = Strings.details.descriptions.fix.edit
            case .rollback:
                if let target = threat.fixable?.target {
                    description = String(format: Strings.details.descriptions.fix.rollback.withTarget, target)
                } else {
                    description = Strings.details.descriptions.fix.rollback.withoutTarget
                }
            default:
                description = Strings.details.descriptions.fix.unknown
        }
        return description
    }

    private static func description(for threat: JetpackScanThreat) -> String? {
        guard threat.status != .fixing else {
            return Self.fixDescription(for: threat)
        }

        let type = threat.type
        let description: String?

        switch type {
        case .core:
            description = Strings.description.core
        case .file:
            let signature = threat.signature
            description = String(format: Strings.description.file, signature)
        case .plugin:
            description = Strings.description.plugin
        case .theme:
            description = Strings.description.theme
        case .database:
            description = Strings.description.database
        default:
            description = Strings.description.unknown
        }

        return description
    }

    private static func title(for threat: JetpackScanThreat) -> String {
        let type = threat.type
        let title: String

        switch type {
        case .core:
            if let fileName = threat.fileName?.fileName() {
                title = String(format: Strings.titles.core.multiple, fileName)
            } else {
                title = Strings.titles.core.singular
            }

        case .file:
            if let fileName = threat.fileName?.fileName() {
                title = String(format: Strings.titles.file.multiple, fileName)
            } else {
                title = Strings.titles.file.singular
            }

        case .plugin:
            if let plugin = threat.`extension` {
                title = String(format: Strings.titles.plugin.multiple, plugin.slug, plugin.version)
            } else {
                title = Strings.titles.plugin.singular
            }

        case .theme:
            if let plugin = threat.`extension` {
                title = String(format: Strings.titles.theme.multiple, plugin.slug, plugin.version)
            } else {
                title = Strings.titles.theme.singular
            }

        case .database:
            if let rowCount = threat.rows?.count, rowCount > 0 {
                title = String(format: Strings.titles.database.multiple, "\(rowCount)")
            } else {
                title = Strings.titles.database.singular
            }

        default:
            title = Strings.titles.unknown
        }

        return title
    }

    private static func iconColor(for status: JetpackScanThreat.ThreatStatus?) -> UIColor {
        switch status {
        case .current:
            return .error
        case .fixed:
            return .success
        default:
            return .neutral(.shade20)
        }
    }

    private static func iconImage(for status: JetpackScanThreat.ThreatStatus?) -> UIImage? {
        var image: UIImage = .gridicon(.notice)

        if status == .fixed {
            if let icon = UIImage(named: "jetpack-scan-threat-fixed") {
                image = icon
            }
        }

        return image.imageWithTintColor(.white)
    }

    private static func fixActionTitle(for threat: JetpackScanThreat) -> String? {
        guard
            threat.fixable?.type != nil,
            threat.status != .fixed && threat.status != .ignored
        else {
            return nil
        }

        return Strings.details.actions.titles.fixable
    }

    private static func ignoreActionTitle(for threat: JetpackScanThreat) -> String? {
        guard threat.status != .fixed && threat.status != .ignored else {
            return nil
        }

        return Strings.details.actions.titles.ignore
    }

    private static func warningActionTitle(for threat: JetpackScanThreat, hasValidCredentials: Bool?) -> HighlightedText? {
        guard fixActionTitle(for: threat) != nil,
              let hasValidCredentials = hasValidCredentials,
              !hasValidCredentials else {
            return nil
        }

        let warningString = String(format: Strings.details.actions.titles.enterServerCredentialsFormat,
                                   Strings.details.actions.titles.enterServerCredentialsSubstring)

        let warningActionTitle = HighlightedText(substring: Strings.details.actions.titles.enterServerCredentialsSubstring,
                                                 string: warningString)

        return warningActionTitle
    }

    private struct Strings {

        struct details {

            struct titles {
                static let problem = NSLocalizedString("What was the problem?", comment: "Title for the problem section in the Threat Details")
                static let technicalDetails = NSLocalizedString("The technical details", comment: "Title for the technical details section in Threat Details")

                struct fix {
                    static let `default` = NSLocalizedString("How will we fix it?", comment: "Title for the fix section in Threat Details")
                    static let fixed = NSLocalizedString("How did Jetpack fix it?", comment: "Title for the fix section in Threat Details: Threat is fixed")
                    static let notFixable = NSLocalizedString("Resolving the threat", comment: "Title for the fix section in Threat Details: Threat is not fixable")
                }
            }

            struct descriptions {
                static let technicalDetails = NSLocalizedString("Threat found in file:", comment: "Description for threat file")

                struct fix {
                    static let replace = NSLocalizedString("Jetpack Scan will replace the affected file or directory.", comment: "Description that explains how we will fix the threat")
                    static let delete = NSLocalizedString("Jetpack Scan will delete the affected file or directory.", comment: "Description that explains how we will fix the threat")
                    static let update = NSLocalizedString("Jetpack Scan will update to a newer version.", comment: "Description that explains how we will fix the threat")
                    static let edit = NSLocalizedString("Jetpack Scan will edit the affected file or directory.", comment: "Description that explains how we will fix the threat")
                    struct rollback {
                        static let withTarget = NSLocalizedString("Jetpack Scan will rollback the affected file to the version from %1$@.", comment: "Description that explains how we will fix the threat")
                        static let withoutTarget = NSLocalizedString("Jetpack Scan will rollback the affected file to an older (clean) version.", comment: "Description that explains how we will fix the threat")
                    }

                    static let unknown = NSLocalizedString("Jetpack Scan will resolve the threat.", comment: "Description that explains how we will fix the threat")

                    static let notFixable = NSLocalizedString("Jetpack Scan cannot automatically fix this threat. We suggest that you resolve the threat manually: ensure that WordPress, your theme, and all of your plugins are up to date, and remove the offending code, theme, or plugin from your site.", comment: "Description that explains that we are unable to auto fix the threat")
                }
            }

            struct actions {

                struct titles {
                    static let ignore = NSLocalizedString("Ignore threat", comment: "Title for button that will ignore the threat")
                    static let fixable = NSLocalizedString("Fix threat", comment: "Title for button that will fix the threat")
                    static let enterServerCredentialsSubstring = NSLocalizedString("Enter your server credentials", comment: "Error message displayed when site credentials aren't configured.")
                    static let enterServerCredentialsFormat = NSLocalizedString("%1$@ to fix this threat.", comment: "Title for button when a site is missing server credentials. %1$@ is a placeholder for the string 'Enter your server credentials'.")
                }

                struct messages {
                    static let ignore = NSLocalizedString("You shouldn’t ignore a security issue unless you are absolutely sure it’s harmless. If you choose to ignore this threat, it will remain on your site \"%1$@\".", comment: "Message displayed in ignore threat alert. %1$@ is a placeholder for the blog name.")
                }
            }

            struct success {
                static let fix = NSLocalizedString("The threat was successfully fixed.", comment: "Message displayed when a threat is fixed successfully.")
                static let ignore = NSLocalizedString("Threat ignored.", comment: "Message displayed when a threat is ignored successfully.")
            }

            struct error {
                static let fix = NSLocalizedString("Error fixing threat. Please contact our support.", comment: "Error displayed when fixing a threat fails.")
                static let ignore = NSLocalizedString("Error ignoring threat. Please contact our support.", comment: "Error displayed when ignoring a threat fails.")
            }
        }


        struct titles {
            struct core {
                static let singular = NSLocalizedString("Infected core file", comment: "Title for a threat")
                static let multiple = NSLocalizedString("Infected core file: %1$@", comment: "Title for a threat that includes the file name of the file")
            }

            struct file {
                static let singular = NSLocalizedString("A file contains a malicious code pattern", comment: "Title for a threat")
                static let multiple = NSLocalizedString("The file %1$@ contains a malicious code pattern", comment: "Title for a threat that includes the file name of the file")
            }

            struct plugin {
                static let singular = NSLocalizedString("Vulnerable Plugin", comment: "Title for a threat")
                static let multiple = NSLocalizedString("Vulnerable Plugin: %1$@ (version %2$@)", comment: "Title for a threat that includes the file name of the plugin and the affected version")
            }

            struct theme {
                static let singular = NSLocalizedString("Vulnerable Theme", comment: "Title for a threat")
                static let multiple = NSLocalizedString("Vulnerable Theme %1$@ (version %2$@)", comment: "Title for a threat that includes the file name of the theme and the affected version")
            }

            struct database {
                static let singular = NSLocalizedString("Database threat", comment: "Title for a threat")
                static let multiple = NSLocalizedString("Database %1$d threats", comment: "Title for a threat that includes the number of database rows affected")
            }

            static let unknown = NSLocalizedString("Threat Found", comment: "Title for a threat")
        }

        struct description {
            static let core = NSLocalizedString("Vulnerability found in WordPress", comment: "Summary description for a threat")
            static let file = NSLocalizedString("Threat found %1$@", comment: "Summary description for a threat that includes the threat signature")
            static let plugin = NSLocalizedString("Vulnerability found in plugin", comment: "Summary description for a threat")
            static let theme = NSLocalizedString("Vulnerability found in theme", comment: "Summary description for a threat")
            static let database: String? = nil
            static let unknown = NSLocalizedString("Miscellaneous vulnerability", comment: "Summary description for a threat")
        }
    }

    private struct Constants {
        static let monospacedFont = WPStyleGuide.monospacedSystemFontForTextStyle(.footnote)

        struct colors {
            struct normal {
                static let text = UIColor.muriel(color: .gray, .shade100)
                static let background = UIColor.muriel(color: .gray, .shade5)
                static let numberText = UIColor.muriel(color: .gray, .shade100)
                static let numberBackground = UIColor.muriel(color: .gray, .shade20)
            }

            struct highlighted {
                static let text = UIColor.white
                static let background = UIColor.muriel(color: .error, .shade50)
                static let numberBackground = UIColor.muriel(color: .error, .shade5)
            }
        }
    }
}

private extension JetpackThreatContext {

    struct JetpackThreatContextRendererConfig {
        let numberAttributes: [NSAttributedString.Key: Any]
        let highlightedNumberAttributes: [NSAttributedString.Key: Any]
        let contentsAttributes: [NSAttributedString.Key: Any]
        let highlightedContentsAttributes: [NSAttributedString.Key: Any]
        let highlightedSectionAttributes: [NSAttributedString.Key: Any]
    }

    func attributedString(with config: JetpackThreatContextRendererConfig) -> NSAttributedString? {

        guard let longestLine = lines.sorted(by: { $0.contents.count > $1.contents.count }).first else {
            return nil
        }

        // Calculates the "longest" number string length
        // This will be used to pad the number column to make sure it's all the same size regardless of
        // the line number length
        //
        // i.e. Last line number is 1000, which is 4 chars
        // When processing line 50 we'll append 2 spaces to the end so it ends up being equal to 4

        let lastNumberLength = String(lines.last?.lineNumber ?? 0).count

        let longestLineLength = longestLine.contents.count

        let attrString = NSMutableAttributedString()

        for line in lines {

            // Number attributed string

            var numberStr = String(line.lineNumber)
            let numberPadding = String().padding(toLength: lastNumberLength - numberStr.count,
                                                 withPad: Constants.noBreakSpace, startingAt: 0)
            numberStr = numberPadding + numberStr
            let numberAttr = NSMutableAttributedString(string: numberStr)

            // Contents attributed string

            let contents = line.contents
            let contentsPadding = String().padding(toLength: longestLineLength - contents.count,
                                                   withPad: Constants.noBreakSpace, startingAt: 0)

            let contentsStr = String(format: Constants.contentsStrFormat, Constants.columnSpacer + contents + contentsPadding)
            let contentsAttr = NSMutableAttributedString(string: contentsStr)

            // Highlight logic

            if let highlights = line.highlights {

                numberAttr.setAttributes(config.highlightedNumberAttributes,
                                         range: NSRange(location: 0, length: numberStr.count))

                contentsAttr.addAttributes(config.highlightedContentsAttributes,
                                           range: NSRange(location: 0, length: contentsStr.count))

                for highlight in highlights {
                    let location = highlight.location
                    let length = highlight.length + Constants.columnSpacer.count
                    let range = NSRange(location: location, length: length)

                    contentsAttr.addAttributes(config.highlightedSectionAttributes, range: range)
                }

            } else {
                numberAttr.setAttributes(config.numberAttributes,
                                         range: NSRange(location: 0, length: numberStr.count))

                contentsAttr.setAttributes(config.contentsAttributes,
                                           range: NSRange(location: 0, length: contentsStr.count))
            }

            attrString.append(numberAttr)
            attrString.append(contentsAttr)
        }

        return attrString
    }

    private struct Constants {
        static let contentsStrFormat = "%@\n"
        static let noBreakSpace = "\u{00a0}"
        static let columnSpacer = " "
    }
}

private extension String {
    func fileName() -> String {
        return (self as NSString).lastPathComponent
    }
}


private extension WPStyleGuide {
    static func monospacedSystemFontForTextStyle(_ style: UIFont.TextStyle,
                                          fontWeight weight: UIFont.Weight = .regular) -> UIFont {
        guard let fontDescriptor = WPStyleGuide.fontForTextStyle(style, fontWeight: weight).fontDescriptor.withDesign(.monospaced) else {
            return UIFont.monospacedSystemFont(ofSize: 13, weight: weight)
        }

        return UIFontMetrics.default.scaledFont(for: UIFont(descriptor: fontDescriptor, size: 0.0))
    }
}
