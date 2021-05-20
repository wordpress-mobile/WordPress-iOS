import SwiftUI

struct GroupedViewData {

    let widgetTitle: LocalizedStringKey
    let siteName: String
    let upperLeftTitle: LocalizedStringKey
    let upperLeftValue: Int
    let upperRightTitle: LocalizedStringKey
    let upperRightValue: Int
    let lowerLeftTitle: LocalizedStringKey
    let lowerLeftValue: Int
    let lowerRightTitle: LocalizedStringKey
    let lowerRightValue: Int

    let statsURL: URL?
}
