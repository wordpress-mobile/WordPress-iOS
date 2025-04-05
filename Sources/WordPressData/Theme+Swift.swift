extension Theme {

    public func customizeUrl() -> String {
        let path = "customize.php?theme=\(themePathForCustomization)&hide_close=true"

        return blog.adminUrl(withPath: path)
    }

    private var themePathForCustomization: String {
        guard blog.supports(.customThemes) else {
            return stylesheet
        }

        if custom {
            return themeId
        } else {
            return ThemeIdHelper.themeIdWithWPComSuffix(themeId)
        }
    }
}
