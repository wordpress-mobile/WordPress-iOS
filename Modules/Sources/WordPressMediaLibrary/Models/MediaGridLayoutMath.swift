import Foundation
import SwiftUI

/// Pure layout math for the Media Library grid. Mirrors V1's
/// `SiteMediaCollectionViewController.updateFlowLayoutItemSize` at lines
/// 148-158: 4 cells per row below 500pt width, 5 otherwise; spacing 2 in
/// default mode, 8 in aspect-ratio mode; cell size rounded down to avoid
/// fractional pixels.
struct MediaGridLayoutMath {
    let availableWidth: CGFloat
    let isAspectRatioMode: Bool

    var spacing: CGFloat { isAspectRatioMode ? 8 : 2 }

    var itemsPerRow: Int { availableWidth < 500 ? 4 : 5 }

    var cellSize: CGFloat {
        let raw = (availableWidth - spacing * CGFloat(itemsPerRow - 1)) / CGFloat(itemsPerRow)
        return raw.rounded(.down)
    }

    var columns: [GridItem] {
        Array(
            repeating: GridItem(.fixed(cellSize), spacing: spacing),
            count: itemsPerRow
        )
    }
}
