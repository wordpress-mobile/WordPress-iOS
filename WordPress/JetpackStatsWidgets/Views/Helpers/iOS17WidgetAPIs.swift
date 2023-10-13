import SwiftUI
import WidgetKit

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

/// Silence warnings on Xcode 14
extension WidgetConfiguration {
    func iOS17ContentMarginsDisabled() -> some WidgetConfiguration {
        if #available(iOSApplicationExtension 17.0, *) {
            return contentMarginsDisabled()
        } else {
            return self
        }
    }

    func iOS17ContainerBackgroundRemovable(_ isRemovable: Bool = true) -> some WidgetConfiguration {
        if #available(iOSApplicationExtension 17.0, *) {
            return containerBackgroundRemovable(isRemovable)
        } else {
            return self
        }
    }
}
