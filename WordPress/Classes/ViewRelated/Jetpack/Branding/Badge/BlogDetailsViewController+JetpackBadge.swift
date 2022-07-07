extension BlogDetailsViewController {

    /// Creates a Jetpack badge row on My Site menu.
    /// - Returns: an instance of the row.
    @objc func jetpackBadgeSectionViewModel() -> BlogDetailsSection {
        let row = BlogDetailsRow()
        row.callback = {}
        let section = BlogDetailsSection(title: nil,
                                         rows: [row],
                                         footerTitle: nil,
                                         category: .jetpackBadge)
        return section
    }
}
