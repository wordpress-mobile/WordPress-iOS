import Foundation
import WordPressUI
import UIKit
import SwiftUI

class ExperimentalFeaturesDataProvider: ExperimentalFeaturesViewModel.DataProvider {

    let flags: [OverridableFlag] = [
        FeatureFlag.intelligence,
        RemoteFeatureFlag.newStats,
        RemoteFeatureFlag.newGutenberg,
        FeatureFlag.newSupport,
    ]

    private let flagStore = FeatureFlagOverrideStore()

    var notes: [String] {
        [Strings.editorNote]
    }

    func loadItems() throws -> [WordPressUI.Feature] {
        flags.map { flag in
            WordPressUI.Feature(
                name: flag.description,
                key: flag.key
            )
        }
    }

    func value(for feature: WordPressUI.Feature) -> Bool {
        let flag = flag(for: feature)
        return flagStore.overriddenValue(for: flag) ?? flag.originalValue
    }

    func didChangeValue(for feature: WordPressUI.Feature, to newValue: Bool) {
        flagStore.override(flag(for: feature), withValue: newValue)

        WPAnalytics.track(.experimentalFeatureToggled, properties: [
            "feature": feature.name,
            "enabled": newValue
        ])
    }

    private func flag(for feature: WordPressUI.Feature) -> OverridableFlag {
        guard let flag = flags.first(where: { $0.key == feature.key }) else {
            preconditionFailure("Invalid Feature Flag")
        }

        return flag
    }

    enum Strings {
        static let editorNote = NSLocalizedString("experimentalFeatures.editorNote", value: "Experimental Block Editor will become the default in a future release and the ability to disable it will be removed.", comment: "Communicates the future removal of the option to disable the experimental editor, displayed beneath the experimental features list")
    }
}
