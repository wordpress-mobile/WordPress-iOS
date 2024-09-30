import Foundation
import UIKit

// MARK: - GhostOptions: Content Options.
//
public struct GhostOptions {

    /// GhostCell(s) Reuse Identifier.
    ///
    let reuseIdentifier: String

    /// Indicates how many Sections / Rows per Section should be rendered.
    ///
    let rowsPerSection: [Int]

    /// Indicates if an Emtpy SectionHeader should be rendered (for placeholder purposes).
    ///
    let displaysSectionHeader: Bool

    /// Designated Initializer
    ///
    public init(displaysSectionHeader: Bool = true, reuseIdentifier: String, rowsPerSection: [Int]) {
        self.displaysSectionHeader = displaysSectionHeader
        self.reuseIdentifier = reuseIdentifier
        self.rowsPerSection = rowsPerSection
    }
}
