import Foundation
import WordPressUI
import WordPressShared

/// Manages data for our package dependencies
///
actor AcknowledgementsService: AcknowledgementsListViewModel.DataProvider {
    enum Errors: LocalizedError {
        case packageManifestNotFound

        var errorDescription: String? {
            return switch self {
            case .packageManifestNotFound: NSLocalizedString( "acknowledgements.manifest_not_found",
                                                              value: "Unable to load acknowledgements",
                                                              comment: "The file with the acknowledgements is missing")
            }
        }
    }

    struct Package: Codable {
        let identity: String
        let license: String
        let name: String
        let repositoryURL: String
        let revision: String
        let version: String?

        var formattedLicense: String {
            return self.license
                .replacingMatches(of: "(?<=.)\n", with: " ")      // Remove newlines within paragraphs
                .replacingMatches(of: "(?<=\n)[ \t]*", with: "")  // Remove leading whitespace in each line
                .replacingMatches(of: "^[ \t]*(?=\\S)", with: "") // Remove leading whitespace in the document
                .replacingOccurrences(of: "\n", with: "\n\n")     // Add some more spacing between paragraphs
        }

        var firstLineOfLicense: String? {
            // Zendesk doesn't use a named license or a good format, so we'll special-case their stuff
            guard name.range(of: "zendesk", options: .caseInsensitive) == nil else {
                return "Zendesk SDK License" // Doesn't need to be translated because all languages are English
            }

            return license
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .components(separatedBy: .newlines).first
        }
    }

    fileprivate var items: [AcknowledgementItem] = []

    func loadItems() throws -> [WordPressUI.AcknowledgementItem] {
        if items.isEmpty {
            items = try loadPackages().map { package in
                AcknowledgementItem(
                    id: package.identity,
                    title: package.name,
                    description: package.firstLineOfLicense ?? package.version ?? package.revision,
                    license: package.formattedLicense
                )
            }.sorted()
        }

        return items
    }

    fileprivate func loadPackages() throws -> [Package] {
        guard let url = Bundle.main.url(forResource: "package-list", withExtension: "json") else {
            throw Errors.packageManifestNotFound
        }

        guard FileManager.default.fileExists(at: url) else {
            throw Errors.packageManifestNotFound
        }

        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([Package].self, from: data)
    }
}
