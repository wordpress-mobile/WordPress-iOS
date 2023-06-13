import Foundation

extension SiteVisibility {
    static func eligiblePickerValues(for blog: Blog) -> [SettingsPickerValue<SiteVisibility>] {
        eligibleValues(for: blog).map {
            SettingsPickerValue(
                title: BlogSiteVisibilityHelper.title(for: $0),
                id: $0,
                hint: BlogSiteVisibilityHelper.hintText(for: $0)
            )
        }
    }

    static func eligibleValues(for blog: Blog) -> [SiteVisibility] {
        var values: [SiteVisibility] = [.public, .hidden]
        if blog.supports(.private) {
            values.append(.private)
        }
        return values
    }
}
