import Foundation

extension GutenbergViewController {

    enum Localization {
        static let fileName = "InfoPlist"
    }

    func parseGutenbergTranslations(forLanguage language: String?,
                                    in bundle: Bundle = Bundle.main) -> [String: String]? {
        guard let fileURL = bundle.url(
            forResource: Localization.fileName,
            withExtension: "strings",
            subdirectory: nil,
            localization: language
            ) else {
                return nil
        }
        if let dictionary = NSDictionary(contentsOf: fileURL) as? [String: String] {
            return dictionary
        }
        return nil
    }
}
