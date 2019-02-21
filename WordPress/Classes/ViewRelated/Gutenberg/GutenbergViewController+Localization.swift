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
            localization: currentLProjFolderName()
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

    private func currentLProjFolderName() -> String? {
        var lProjFolderName = Locale.current.identifier
        if let identifierWithoutRegion = Locale.current.identifier.split(separator: "_").first {
            lProjFolderName = String(identifierWithoutRegion)
        }
        return lProjFolderName
    }
}
