import Foundation

// MARK: - BlogFeature

/// Defines whether the _blog_ supports a given feature.
///
/// - warning: These flags are app-agnostic. If the app needs to determine
/// whether to show a feature, it should implement additional logic on top.
@objc public enum BlogFeature: UInt {
    case removable
    case visibility
    case wpComRESTAPI
    case oAuth2Login
    case reblog
    case commentLikes
    case stats
    case activity
    case mentions
    case xposts
    case pushNotifications
    case themeBrowsing
    case customThemes
    case premiumThemes
    case menus
    case `private`
    case sharing
    case people
    case siteManagement
    case plans
    case pluginManagement
    case jetpackImageSettings
    case jetpackSettings
    case domains
    case noncePreviews
    case mediaMetadataEditing
    case mediaAltEditing
    case mediaDeletion
    case stockPhotos
    case homepageSettings
    case contactInfo
    case blockEditorSettings
    case layoutGrid
    case tiledGallery
    case videoPress
    case videoPressV5
    case facebookEmbed
    case instagramEmbed
    case loomEmbed
    case smartframeEmbed
    case fileDownloadsStats
    case blaze
    case pages
    case siteMonitoring
    case publicize
    case shareButtons
}

extension Blog {

    @objc public func supports(_ feature: BlogFeature) -> Bool {
        switch feature {
        case .removable:
            return !isDefaultAccount
        case .visibility:
            return isDefaultAccount
        case .wpComRESTAPI, .commentLikes, .stockPhotos:
            return supportsRestAPI
        case .oAuth2Login:
            return isHostedAtWPcom
        case .reblog, .plans:
            return isHostedAtWPcom && isAdmin
        case .stats:
            return supportsRestAPI && isViewingStatsAllowed
        case .activity:
            return supportsRestAPI && isAdmin
        case .mentions, .xposts:
            return isAccessibleThroughWPCom()
        case .pushNotifications:
            return isDefaultAccount
        case .themeBrowsing, .menus, .homepageSettings:
            return supportsRestAPI && isAdmin
        case .customThemes:
            return supportsRestAPI && isAdmin && !isHostedAtWPcom
        case .premiumThemes:
            return supports(.customThemes) && (planID?.intValue == Self.jetpackProfessionalYearlyPlanId || planID?.intValue == Self.jetpackProfessionalMonthlyPlanId)
        case .private:
            return isHostedAtWPcom
        case .sharing:
            return supports(.publicize) || supports(.shareButtons)
        case .people:
            return supportsRestAPI && isUserCapableOf(.ListUsers)
        case .siteManagement:
            return isHostedAtWPcom && isAdmin
        case .pluginManagement:
            return supportsPluginManagement
        case .jetpackImageSettings:
            return hasRequiredJetpackVersion("5.6")
        case .jetpackSettings:
            return supportsRestAPI && !isHostedAtWPcom && isAdmin
        case .domains:
            return (isHostedAtWPcom || isAtomic) && isAdmin && !isWPForTeams
        case .noncePreviews:
            return supportsRestAPI && !isHostedAtWPcom
        case .mediaMetadataEditing, .mediaDeletion:
            return isAdmin
        case .mediaAltEditing:
            // alt is not supported via XML-RPC API
            // https://core.trac.wordpress.org/ticket/58582
            // https://github.com/wordpress-mobile/WordPress-Android/issues/18514#issuecomment-1589752274
            return supportsRestAPI || supportsCoreRestApi
        case .contactInfo:
            return hasRequiredJetpackVersion("8.5") || isHostedAtWPcom
        case .blockEditorSettings:
            return hasRequiredWordPressVersion("5.8")
        case .layoutGrid:
            return isHostedAtWPcom || isAtomic
        case .tiledGallery, .videoPress, .fileDownloadsStats:
            return isHostedAtWPcom
        case .videoPressV5:
            return isHostedAtWPcom || isAtomic || hasRequiredJetpackVersion("8.5")
        case .facebookEmbed, .instagramEmbed, .loomEmbed:
            return hasRequiredJetpackVersion("9.0") || isHostedAtWPcom
        case .smartframeEmbed:
            return hasRequiredJetpackVersion("10.2") || isHostedAtWPcom
        case .blaze:
            return canBlaze
        case .pages:
            return isAdmin || isUserCapableOf(.EditPages)
        case .siteMonitoring:
            return isAdmin && isAtomic
        case .publicize:
            return supportsPublicize
        case .shareButtons:
            return supportsShareButtons
        }
    }

    @objc public var isStatsActive: Bool {
        isJetpackModuleActive("stats") || isHostedAtWPcom
    }

    @objc public func hasRequiredWordPressVersion(_ requiredVersion: String) -> Bool {
        version.compare(requiredVersion, options: .numeric) != .orderedAscending
    }
}

// MARK: - Private

private extension Blog {

    static let jetpackProfessionalYearlyPlanId = 2004
    static let jetpackProfessionalMonthlyPlanId = 2001

    /// Whether the blog has a WP.com account (can use the REST API).
    var supportsRestAPI: Bool {
        account != nil
    }

    var isDefaultAccount: Bool {
        account?.isDefaultWordPressComAccount ?? false
    }

    var supportsPublicize: Bool {
        guard supportsRestAPI, isPublishingPostsAllowed() else {
            return false
        }
        if isHostedAtWPcom {
            return !getOptionBoolean(name: "publicize_permanently_disabled")
        } else {
            return isJetpackModuleActive("publicize")
        }
    }

    var supportsShareButtons: Bool {
        guard isAdmin, supportsRestAPI else {
            return false
        }
        if isHostedAtWPcom {
            return true
        } else {
            return isJetpackModuleActive("sharedaddy")
        }
    }

    var supportsPluginManagement: Bool {
        guard isAdmin else { return false }

        if hasRequiredJetpackVersion("5.6") {
            return true
        }
        if isHostedAtWPcom && hasBusinessPlan && siteVisibility != .private {
            return true
        }
        if account == nil && !isHostedAtWPcom && selfHostedSiteRestApi != nil
            && hasRequiredWordPressVersion("5.5") {
            return true
        }
        return false
    }

    func isJetpackModuleActive(_ moduleName: String) -> Bool {
        guard let activeModules = getOptionValue("active_modules") as? [String] else {
            return false
        }
        return activeModules.contains(moduleName)
    }

    func hasRequiredJetpackVersion(_ requiredVersion: String) -> Bool {
        guard supportsRestAPI, !isHostedAtWPcom,
              let version = jetpack?.version else {
            return false
        }
        return version.compare(requiredVersion, options: .numeric) != .orderedAscending
    }
}
