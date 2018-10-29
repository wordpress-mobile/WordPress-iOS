protocol WizardDelegate {
    // Before
    func wizard(_ wizard: Wizard, willNavigateToDestinationWith identifier: Identifier)

    // After
    func wizard(_ wizard: Wizard, didNavigateToDestinationWith identifier: Identifier)
}
