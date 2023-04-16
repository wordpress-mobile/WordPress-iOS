import CoreUI

// `MurielColor` depends on `AppStyleGuide` as described in the code below.
//
// That might have been convenient when all the code was in a single app target, but it became a
// problem when the Jetpack app was introduced and `AppStyleGuide` duplicated, and even more as
// we started modularizing the code.
//
// This extension is a compromise to keep the code compiling while we come up with a better design.
extension MurielColor {

    // MARK: - Muriel's semantic colors
    static let accent = AppStyleGuide.accent
    static let brand = AppStyleGuide.brand
    static let divider = AppStyleGuide.divider
    static let error = AppStyleGuide.error
    static let gray = AppStyleGuide.gray
    static let primary = AppStyleGuide.primary
    static let success = AppStyleGuide.success
    static let text = AppStyleGuide.text
    static let textSubtle = AppStyleGuide.textSubtle
    static let warning = AppStyleGuide.warning
    static let jetpackGreen = AppStyleGuide.jetpackGreen
    static let editorPrimary = AppStyleGuide.editorPrimary
}
