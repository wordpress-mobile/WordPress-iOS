import Foundation

public enum Strings {
    public enum Errors {
        public static let network = NSLocalizedString(
            "jetpackSocial.error.network",
            value: "Network error. Please check your connection and try again.",
            comment: "Error shown when a social sharing network call fails."
        )

        public static let notAuthenticated = NSLocalizedString(
            "jetpackSocial.error.notAuthenticated",
            value: "You need to sign in again to manage social accounts.",
            comment: "Error shown when the WP.com auth token is missing or invalid."
        )

        public static let connectionNotFoundFormat = NSLocalizedString(
            "jetpackSocial.error.connectionNotFound",
            value: "Connection %1$@ was not found.",
            comment: "Error when a publicize connection ID can't be found. %1$@ is the connection ID."
        )

        public static let keyringNotFoundFormat = NSLocalizedString(
            "jetpackSocial.error.keyringNotFound",
            value: "Keyring connection %1$@ was not found.",
            comment: "Error when a keyring token ID can't be found. %1$@ is the token ID."
        )

        public static let noKeyringForServiceFormat = NSLocalizedString(
            "jetpackSocial.error.noKeyringForService",
            value: "No connected accounts for %1$@.",
            comment:
                "Error when the WP.com account has no authorized keyring for a given service. %1$@ is the service label (e.g. 'Mastodon')."
        )

        public static let noPagesForFacebook = NSLocalizedString(
            "jetpackSocial.error.noPagesForFacebook",
            value:
                "The Facebook connection cannot find any Pages. Publicize cannot connect to Facebook Profiles, only published Pages.",
            comment:
                "Error shown after Facebook OAuth when the user's account doesn't manage any Facebook Pages, since Publicize only targets Pages."
        )

        public static let learnMore = NSLocalizedString(
            "jetpackSocial.error.learnMore",
            value: "Learn more",
            comment: "Link label that opens documentation explaining how to resolve a social sharing error."
        )

        public static let decoding = NSLocalizedString(
            "jetpackSocial.error.decoding",
            value: "Received an unexpected response from the server.",
            comment: "Error shown when decoding a social sharing response fails."
        )

        public static let unknown = NSLocalizedString(
            "jetpackSocial.error.unknown",
            value: "Something went wrong. Please try again.",
            comment: "Generic fallback error for social sharing."
        )
    }

    public enum ManageConnections {
        public static let navigationTitle = NSLocalizedString(
            "jetpackSocial.manageConnections.title",
            value: "Social",
            comment: "Title of the Social Sharing settings screen."
        )

        public static let connectedHeader = NSLocalizedString(
            "jetpackSocial.manageConnections.connectedHeader",
            value: "Connected Accounts",
            comment: "Section header listing currently connected social accounts."
        )

        public static let footer = NSLocalizedString(
            "jetpackSocial.manageConnections.footer",
            value: "Connect your favorite social media services to automatically share new posts with friends.",
            comment: "Footer caption under the list of services in the Connect Account picker modal."
        )

        public static let sharedBadge = NSLocalizedString(
            "jetpackSocial.manageConnections.sharedBadge",
            value: "Shared",
            comment: "Badge shown on connections that are shared with other site users."
        )

        public static let brokenStatus = NSLocalizedString(
            "jetpackSocial.manageConnections.brokenStatus",
            value: "Needs attention",
            comment: "Status text for a broken / invalid / refresh-failed connection."
        )

        public static let deleteButton = NSLocalizedString(
            "jetpackSocial.manageConnections.delete",
            value: "Disconnect",
            comment: "Button that removes a social sharing connection."
        )

        public static let deleteConfirmTitleFormat = NSLocalizedString(
            "jetpackSocial.manageConnections.deleteConfirmTitle",
            value: "Are you sure you want to disconnect %1$@?",
            comment: "Confirmation alert title. %1$@ is the connected account's display name."
        )

        public static let connectNewAccount = NSLocalizedString(
            "jetpackSocial.manageConnections.connectNewAccount",
            value: "Connect a New Account",
            comment: "Button on the Social screen that opens the add-connection modal."
        )

        public static let connectedFooter = NSLocalizedString(
            "jetpackSocial.manageConnections.connectedFooter",
            value:
                "Connect your social media accounts and send a post's featured image and content to the selected channels when the post is published.",
            comment: "Footer caption under the Connected Accounts section on the Social screen."
        )

        public static let cancelButton = NSLocalizedString(
            "jetpackSocial.manageConnections.cancel",
            value: "Cancel",
            comment: "Cancel button in the disconnect confirmation alert."
        )

        public static let yesButton = NSLocalizedString(
            "jetpackSocial.manageConnections.yes",
            value: "Yes",
            comment: "Confirm button in the disconnect confirmation alert."
        )

        public static let retry = NSLocalizedString(
            "jetpackSocial.manageConnections.retry",
            value: "Retry",
            comment: "Button to retry a failed load."
        )

        public static let deleteFailedTitle = NSLocalizedString(
            "jetpackSocial.manageConnections.deleteFailedTitle",
            value: "Couldn't Disconnect",
            comment: "Title of the alert shown when disconnecting a social connection fails."
        )

        public static let deleteFailedDismiss = NSLocalizedString(
            "jetpackSocial.manageConnections.deleteFailedDismiss",
            value: "OK",
            comment: "Dismiss button in the disconnect failure alert."
        )
    }

    public enum AccountConfirmation {
        public static let title = NSLocalizedString(
            "jetpackSocial.accountConfirmation.title",
            value: "Connection confirmation",
            comment: "Navigation title of the account confirmation screen shown after OAuth."
        )

        public static let description = NSLocalizedString(
            "jetpackSocial.accountConfirmation.description",
            value:
                "You're connecting this account. New posts will automatically be shared to it. You can change this when writing a post.",
            comment: "Explanation text shown at the top of the account confirmation screen."
        )

        public static let allConnectedDescription = NSLocalizedString(
            "jetpackSocial.accountConfirmation.allConnectedDescription",
            value:
                "You're all set. Every available account is already connected to this site, and your new posts will be shared automatically. You can change this when writing a post.",
            comment:
                "Message shown at the top of the account confirmation screen when every available account is already connected to the site."
        )

        public static let done = NSLocalizedString(
            "jetpackSocial.accountConfirmation.done",
            value: "Done",
            comment:
                "Button that dismisses the account confirmation screen when every account is already connected and there is nothing to confirm."
        )

        public static let markAsSharedLabel = NSLocalizedString(
            "jetpackSocial.accountConfirmation.markAsSharedLabel",
            value: "Mark the connection as shared",
            comment: "Toggle label controlling whether the new connection is shared with other site users."
        )

        public static let markAsSharedFooter = NSLocalizedString(
            "jetpackSocial.accountConfirmation.markAsSharedFooter",
            value:
                "If enabled, the connection will be available to all administrators, editors, and authors. You can change this later.",
            comment: "Footer caption below the 'Mark the connection as shared' toggle."
        )

        public static let confirm = NSLocalizedString(
            "jetpackSocial.accountConfirmation.confirm",
            value: "Confirm",
            comment: "Nav-bar button that finalizes the social connection after choosing an account."
        )

        public static let connectedSectionTitle = NSLocalizedString(
            "jetpackSocial.accountConfirmation.connectedSection",
            value: "Connected",
            comment: "Section header listing accounts already connected to this site."
        )

        public static let loadingMessage = NSLocalizedString(
            "jetpackSocial.accountConfirmation.loading",
            value: "Loading accounts…",
            comment: "Loading caption while fetching accounts for the confirmation screen."
        )

        public static let retry = NSLocalizedString(
            "jetpackSocial.accountConfirmation.retry",
            value: "Retry",
            comment: "Button to retry a failed account fetch."
        )
    }

    public enum ServiceDetail {
        public static let connectedNoticeFormat = NSLocalizedString(
            "jetpackSocial.serviceDetail.connectedNotice",
            value: "%1$@ connected",
            comment: "Notice shown after a social connection is successfully created. %1$@ is the service label."
        )

        public static let failureAlertTitle = NSLocalizedString(
            "jetpackSocial.serviceDetail.failureTitle",
            value: "Connection Failed",
            comment: "Title of the alert shown when adding a social connection fails."
        )

        public static let failureAlertRetry = NSLocalizedString(
            "jetpackSocial.serviceDetail.failureRetry",
            value: "Retry",
            comment: "Retry button in the add-connection failure alert."
        )

        public static let failureAlertCancel = NSLocalizedString(
            "jetpackSocial.serviceDetail.failureCancel",
            value: "Cancel",
            comment: "Cancel button in the add-connection failure alert."
        )
    }

    public enum ConnectionDetail {
        public static let settingsHeader = NSLocalizedString(
            "jetpackSocial.connectionDetail.settingsHeader",
            value: "Settings",
            comment: "Section header on the connection detail screen."
        )

        public static let availableToAllUsers = NSLocalizedString(
            "jetpackSocial.connectionDetail.availableToAllUsers",
            value: "Available to all users",
            comment: "Toggle label controlling whether a connection is shared with all site users."
        )

        public static let availableToAllUsersFooter = NSLocalizedString(
            "jetpackSocial.connectionDetail.availableToAllUsersFooter",
            value: "Allow this connection to be used by all admins and users of your site.",
            comment: "Footer caption below the 'Available to all users' toggle."
        )

        public static let updateFailedTitle = NSLocalizedString(
            "jetpackSocial.connectionDetail.updateFailedTitle",
            value: "Couldn't Update Connection",
            comment: "Title of the alert shown when updating a social connection setting fails."
        )

        public static let updateFailedDismiss = NSLocalizedString(
            "jetpackSocial.connectionDetail.updateFailedDismiss",
            value: "OK",
            comment: "Dismiss button in the social connection update failure alert."
        )
    }

    public enum OAuthWebView {
        public static let connectTitleFormat = NSLocalizedString(
            "jetpackSocial.oauthWebView.connectTitle",
            value: "Connect to %1$@",
            comment: "Navigation bar title of the OAuth webview. %1$@ is the service label (e.g. 'Mastodon')."
        )
    }

    public enum ServicePicker {
        public static let navigationTitle = NSLocalizedString(
            "jetpackSocial.servicePicker.title",
            value: "Connect Account",
            comment: "Navigation bar title of the service picker modal shown when adding a new social connection."
        )
    }
}
