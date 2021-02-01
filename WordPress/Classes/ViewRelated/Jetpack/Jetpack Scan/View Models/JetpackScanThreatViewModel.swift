import Foundation

struct JetpackScanThreatViewModel {
    let iconImage: UIImage?
    let iconImageColor: UIColor
    let title: String
    let description: String?
    let isFixing: Bool

    // More details
    let problemDescription: String
    let fixDescription: String?
    let fileContext: JetpackThreatContext?

    init(threat: JetpackScanThreat) {
        let status = threat.status

        iconImage = Self.iconImage(for: status)
        iconImageColor = Self.iconColor(for: status)
        title = Self.title(for: threat)
        description = Self.description(for: threat)
        isFixing = status == .fixing

        // More details
        problemDescription = threat.description
        fixDescription = Self.fixDescription(for: threat)
        fileContext = threat.context
    }

    private static func fixDescription(for threat: JetpackScanThreat) -> String? {
        guard let fixType = threat.fixable?.type else {
            return Strings.fixDescription.notFixable
        }

        let description: String

        switch fixType {
            case .replace:
                description = Strings.fixDescription.replace
            case .delete:
                description = Strings.fixDescription.delete
            case .update:
                description = Strings.fixDescription.update
            case .edit:
                description = Strings.fixDescription.edit
            default:
                description = Strings.fixDescription.unknown
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

    private struct Strings {
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

        struct fixDescription {
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
}

private extension String {
    func fileName() -> String {
        return (self as NSString).lastPathComponent
    }
}
