protocol WizardDelegate {
    /// Before
    ///
    /// - Parameters:
    ///   - origin: The step triggering the navigation
    ///   - destination: the Identifier of the destination step
    func wizard(_ origin: WizardStep, willNavigateTo destination: Identifier)

    /// After
    ///
    /// - Parameters:
    ///   - origin: The step triggering the navigation
    ///   - destination: the Identifier of the destination step
    func wizard(_ origin: WizardStep, didNavigateTo destination: Identifier)
}
