import Foundation

/// Responsible for initialization and invocation of WizardSteps
protocol SiteCreationWizardStepInvoker {
    var segmentsStep: WizardStep { get }
    var intentStep: WizardStep { get }
    var nameStep: WizardStep { get }
    var designStep: WizardStep { get }
    var addressStep: WizardStep { get }
    var siteAssemblyStep: WizardStep { get }
}
