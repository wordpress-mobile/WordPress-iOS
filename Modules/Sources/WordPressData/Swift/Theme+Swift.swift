extension Theme {

    public func customizeUrl() -> String? {
        guard let themePathForCustomization else { return nil }

        let path = "customize.php?theme=\(themePathForCustomization)&hide_close=true"
        return blog?.makeAdminURL(path: path)?.absoluteString
    }

    private var themePathForCustomization: String? {
        guard let blog, blog.supports(.customThemes) else {
            return stylesheet
        }

        if custom {
            return themeId
        } else {
            return themeId.flatMap(ThemeIdHelper.themeIdWithWPComSuffix)
        }
    }
}
