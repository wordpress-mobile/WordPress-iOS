import Foundation

final class AppIconListViewModel: AppIconListViewModelType {

    // MARK: - Data

    private(set) var icons: [AppIconListSection] = []

    // MARK: - Init

    init() {
        self.load()
    }

    private func load() {
        let allIcons = AppIcon.allIcons

        // Produces a closure which sorts alphabetically, giving priority to items
        // beginning with the specified prefix.
        func sortWithPriority(toItemsWithPrefix prefix: String) -> ((AppIcon, AppIcon) -> Bool) {
            return { (first, second) in
                let firstIsDefault = first.name.hasPrefix(prefix)
                let secondIsDefault = second.name.hasPrefix(prefix)

                if firstIsDefault && !secondIsDefault {
                    return true
                } else if !firstIsDefault && secondIsDefault {
                    return false
                }

                return first.name < second.name
            }
        }

        // Filter out the current and legacy icon groups, with the Blue icons sorted to the top.
        let currentColorfulIcons = allIcons.filter({ $0.isLegacy == false && $0.isBordered == false })
            .sorted(by: sortWithPriority(toItemsWithPrefix: AppIcon.defaultIconName))
        let currentLightIcons = allIcons.filter({ $0.isLegacy == false && $0.isBordered == true })
            .sorted(by: sortWithPriority(toItemsWithPrefix: AppIcon.defaultIconName))
        let legacyIcons = {
            let icons = allIcons.filter({ $0.isLegacy == true })

            guard let legacyIconName = AppIcon.defaultLegacyIconName else {
                return icons
            }

            return icons.sorted(by: sortWithPriority(toItemsWithPrefix: legacyIconName))
        }()

        // Set icons
        let colorfulIconsTitle = NSLocalizedString("Colorful backgrounds", comment: "Title displayed for selection of custom app icons that have colorful backgrounds.")
        let lightIconsTitle = NSLocalizedString("Light backgrounds", comment: "Title displayed for selection of custom app icons that have white backgrounds.")
        let legacyIconsTitle = NSLocalizedString("Legacy Icons", comment: "Title displayed for selection of custom app icons that may be removed in a future release of the app.")
        self.icons = [
            .init(title: colorfulIconsTitle, items: currentColorfulIcons),
            .init(title: lightIconsTitle, items: currentLightIcons),
            .init(title: legacyIconsTitle, items: legacyIcons)
        ].filter { !$0.items.isEmpty }
    }

}
