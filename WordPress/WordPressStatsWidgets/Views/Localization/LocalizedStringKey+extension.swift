import SwiftUI

extension LocalizedStringKey {
    static let defaultBundle = Bundle(for: StatsWidgetsService.self)

    /// LocalizedStringKey is used as a wrapper of NSLocalizedString, in order to use synthetic keys and assign a default value
    /// in case of missing localization. This will need to be updated (if and) as soon as LocalizedStringKey supports default values
    init(_ key: String, defaultValue: String, comment: String) {
        self.init(NSLocalizedString(key, tableName: nil, bundle: Self.defaultBundle, value: defaultValue, comment: comment))
    }
}
