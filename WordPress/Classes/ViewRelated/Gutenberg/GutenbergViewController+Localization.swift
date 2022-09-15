import Foundation

extension GutenbergViewController {

    enum Localization {
        static let fileName = "Localizable"
    }

    func parseGutenbergTranslations(in bundle: Bundle = Bundle.main) -> [String: [String]]? {
        guard let fileURL = bundle.url(
            forResource: Localization.fileName,
            withExtension: "strings",
            subdirectory: nil,
            localization: currentLProjFolderName(in: bundle)
            ) else {
                return nil
        }
        if let dictionary = NSDictionary(contentsOf: fileURL) as? [String: String] {
            var resultDict: [String: [String]] = [:]
            for (key, value) in dictionary {
                resultDict[key] = [value]
            }
            return resultDict
        }
        return nil
    }

    private func currentLProjFolderName(in bundle: Bundle) -> String? {
        /// Localizable.strings file path use dashes for languages and regions (e.g. pt-BR)
        /// We cannot use Locale.current.identifier directly because it uses underscores
        /// Bundle.preferredLocalizations matches what NSLocalizedString uses
        /// and is safer than parsing and converting identifiers ourselves
        return bundle.preferredLocalizations.first
    }
}
