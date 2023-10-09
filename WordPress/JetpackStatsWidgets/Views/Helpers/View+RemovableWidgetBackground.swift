import SwiftUI

extension View {
    func removableWidgetBackground(_ backgroundView: some View = EmptyView()) -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            return containerBackground(for: .widget) {
                backgroundView
            }
        } else {
            return background(backgroundView)
        }
    }
}
