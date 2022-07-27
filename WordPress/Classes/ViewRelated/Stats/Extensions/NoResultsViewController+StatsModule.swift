import Foundation

// Empty states for Stats

extension NoResultsViewController {

    @objc func configureForStatsModuleDisabled() {
        configure(title: Strings.statsModuleDisabled.title,
                  buttonTitle: Strings.statsModuleDisabled.buttonTitle,
                  subtitle: Strings.statsModuleDisabled.subtitle,
                  image: Constants.statsImageName)
    }

    @objc func configureForActivatingStatsModule() {
        configure(title: Strings.activatingStatsModule.title, accessoryView: NoResultsViewController.loadingAccessoryView())
        view.layoutIfNeeded()
    }

    private enum Constants {
        static let statsImageName = "wp-illustration-stats"
    }

    private enum Strings {

        enum statsModuleDisabled {
            static let title = NSLocalizedString("Looking for stats?", comment: "Title for the error view when the stats module is disabled.")
            static let subtitle = NSLocalizedString("Enable site stats to see detailed information about your traffic, likes, comments, and subscribers.", comment:
                                                      "Error message shown when trying to view Stats and the stats module is disabled.")
            static let buttonTitle = NSLocalizedString("Enable Site Stats", comment: "Title for the button that will enable the site stats module.")

        }

        enum activatingStatsModule {
            static let title = NSLocalizedString("Enabling Site Stats...", comment: "Text displayed while activating the site stats module.")
        }
    }

}
