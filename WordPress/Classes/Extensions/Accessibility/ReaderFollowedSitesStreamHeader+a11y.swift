extension ReaderFollowedSitesStreamHeader: Accessible {
    func configureAccessibility() {
        isAccessibilityElement = true
        accessibilityLabel = NSLocalizedString("Manage", comment: "Button title. Tapping lets the user manage the sites they follow.")
        accessibilityHint = NSLocalizedString("Tapping lets you manage the sites you follow.", comment: "Accessibility hint")
        accessibilityTraits = UIAccessibilityTraitButton
    }
}
