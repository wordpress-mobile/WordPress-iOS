import Foundation
import WordPressUI

class ExperimentalFeaturesDataProvider: ExperimentalFeaturesViewModel.DataProvider {

    let flags: [OverridableFlag] = [
        FeatureFlag.authenticateUsingApplicationPassword,
//        FeatureFlag.newGutenberg,
    ]

    private let flagStore = FeatureFlagOverrideStore()

    func loadItems() throws -> [WordPressUI.Feature] {
        flags.map { flag in
            WordPressUI.Feature(name: flag.description, key: flag.key)
        }
    }

    func value(for feature: WordPressUI.Feature) -> Bool {
        let flag = flag(for: feature)
        return flagStore.overriddenValue(for: flag) ?? flag.originalValue
    }

    func didChangeValue(for feature: WordPressUI.Feature, to newValue: Bool) {
        flagStore.override(flag(for: feature), withValue: newValue)
    }

    private func flag(for feature: WordPressUI.Feature) -> OverridableFlag {
        guard let flag = flags.first(where: { $0.key == feature.key }) else {
            preconditionFailure("Invalid Feature Flag")
        }

        return flag
    }
}
