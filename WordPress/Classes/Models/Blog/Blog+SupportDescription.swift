import WordPressData

extension Blog {

    /// Formatted information to send to Support when user creates a new ticket.
    var supportDescription: String {
        let blogType = "Type: \(stateDescription)"
        let urlType = wordPressComRestApi != nil ? "REST" : "Self-hosted"
        let urlString = "URL: \(url ?? "'no url!'")"

        let username: String?
        let planDescription: String?
        if account == nil {
            if let jetpackConnectedUsername = jetpack?.connectedUsername {
                username = jetpackConnectedUsername
            } else {
                username = nil
            }
            planDescription = nil
        } else {
            let planIDString: String
            if let planID {
                planIDString = "\(planID)"
            } else {
                planIDString = "'no id'"
            }
            planDescription = "Plan: \(planTitle ?? "'no title'") (\(planIDString))"
            username = nil
        }

        var blogInformation: [String] = []

        // Add information to array in the order we want to display it.
        blogInformation.append(blogType)

        if let username {
            blogInformation.append(username)
        }

        blogInformation.append(urlType)
        blogInformation.append(urlString)

        if let planDescription {
            blogInformation.append(planDescription)
        }

        if let jetpack, jetpack.isInstalled, let version = jetpack.version {
            blogInformation.append("Jetpack-version: \(version)")
        }

        return blogInformation.joined(separator: " ")
    }

    var stateDescription: String {
        guard account == nil else {
            return "wpcom"
        }

        guard let jetpack else {
            return "self_hosted"
        }

        if jetpack.isConnected {
            let apiType = wordPressComRestApi != nil ? "REST" : "XML-RPC"
            return "jetpack_connected - \(apiType)"
        }

        if jetpack.isInstalled {
            return "self-hosted - jetpack_installed"
        }

        return "self_hosted"
    }
}
