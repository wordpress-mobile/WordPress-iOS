import Foundation

struct JetpackScanThreatViewModel {
    let iconImage: UIImage?
    let iconImageColor: UIColor
    let title: String
    let description: String?

    // More details
    let detailIconImage: UIImage?
    let detailIconImageColor: UIColor
    let problemTitle: String
    let problemDescription: String
    let fixTitle: String?
    let fixDescription: String?
    let technicalDetailsTitle: String
    let technicalDetailsDescription: String
    let fileName: String?
    let fileContext: JetpackThreatContext?
    let primaryButtonTitle: String
    let secondaryButtonTitle: String

    init(threat: JetpackScanThreat) {
        let status = threat.status

        iconImage = Self.iconImage(for: status)
        iconImageColor = Self.iconColor(for: status)
        title = Self.title(for: threat)
        description = Self.description(for: threat)

        // More details
        detailIconImage = UIImage(named: "jetpack-scan-state-error")
        detailIconImageColor = .error
        problemTitle = Strings.details.titles.problem
        problemDescription = threat.description
        fixTitle = Self.fixTitle(for: threat)
        fixDescription = Self.fixDescription(for: threat)
        technicalDetailsTitle = Strings.details.titles.technicalDetails
        technicalDetailsDescription = Strings.details.descriptions.technicalDetails
        fileName = threat.fileName
        fileContext = threat.context
        primaryButtonTitle = Self.primaryButtonTitle(for: threat)
        secondaryButtonTitle = Strings.details.buttons.current
    }

    private static func fixTitle(for threat: JetpackScanThreat) -> String? {
        guard let status = threat.status else {
            return nil
        }

        let fixable = threat.fixable?.type != nil

        switch (status, fixable) {
        case (.fixed, _):
            return Strings.details.titles.fix.fixed
        case (.current, true):
            return Strings.details.titles.fix.fixable
        case (.current, false):
            return Strings.details.titles.fix.notFixable
        default:
            return Strings.details.titles.fix.unknown
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
                title = String(format: Strings.titles.plugin.multiple, plugin.name, plugin.version)
            } else {
                title = Strings.titles.plugin.singular
            }

        case .theme:
            if let plugin = threat.`extension` {
                title = String(format: Strings.titles.theme.multiple, plugin.name, plugin.version)
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

    private static func primaryButtonTitle(for threat: JetpackScanThreat) -> String {
        guard threat.fixable?.type != nil else {
            return Strings.details.buttons.notFixable
        }

        return Strings.details.buttons.fixable
    }

    private struct Strings {

        struct details {

            struct titles {
                static let problem = NSLocalizedString("What was the problem?", comment: "Title for the problem section in the Threat Details")
                static let technicalDetails = NSLocalizedString("The technical details", comment: "Title for the technical details section in Threat Details")

                struct fix {
                    static let fixed = NSLocalizedString("How did Jetpack fix it?", comment: "Title for the fix section in Threat Details: Threat is fixed")
                    static let fixable = NSLocalizedString("How will we fix it?", comment: "Title for the fix section in Threat Details: Threat is fixable")
                    static let notFixable = NSLocalizedString("Resolving the threat", comment: "Title for the fix section in Threat Details: Threat is not fixable")
                    static let unknown = NSLocalizedString("How will we fix it?", comment: "Title for the fix section in Threat Details: Threat is ignored or unknown")
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

            struct buttons {
                static let current = NSLocalizedString("Ignore threat", comment: "Title for button that will ignore the threat")
                static let fixable = NSLocalizedString("Fix threat", comment: "Title for button that will fix the threat")
                static let notFixable = NSLocalizedString("Get a free estimate", comment: "Title for button that will get a free estimate for the threat")
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
}

private extension String {
    func fileName() -> String {
        return (self as NSString).lastPathComponent
    }
}
