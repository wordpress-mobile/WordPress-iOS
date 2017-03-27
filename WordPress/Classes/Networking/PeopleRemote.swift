import Foundation

/// Encapsulates all of the People Management WordPress.com Methods
///
class PeopleRemote: ServiceRemoteWordPressComREST {

    /// Defines the PeopleRemote possible errors.
    ///
    enum ResponseError: Error {
        case decodingFailure
        case invalidInputError
        case userAlreadyHasRoleError
        case unknownError
    }


    /// Retrieves the collection of users associated to a given Site.
    ///
    /// - Parameters:
    ///     - siteID: The target site's ID.
    ///     - offset: The first N users to be skipped in the returned array.
    ///     - count: Number of objects to retrieve.
    ///     - success: Closure to be executed on success.
    ///     - failure: Closure to be executed on error.
    ///
    /// - Returns: An array of Users.
    ///
    func getUsers(_ siteID: Int,
                  offset: Int = 0,
                  count: Int,
                  success: @escaping ((_ users: [User], _ hasMore: Bool) -> Void),
                  failure: @escaping ((Error) -> Void)) {
        let endpoint = "sites/\(siteID)/users"
        let path = self.path(forEndpoint: endpoint, with: .version_1_1)
        let parameters: [String: AnyObject] = [
            "number": count as AnyObject,
            "offset": offset as AnyObject,
            "order_by": "display_name" as AnyObject,
            "order": "ASC" as AnyObject,
            "fields": "ID, nice_name, first_name, last_name, name, avatar_URL, roles, is_super_admin, linked_user_ID" as AnyObject,
        ]

        wordPressComRestApi.GET(path!, parameters: parameters, success: { (responseObject, httpResponse) in
            guard let response = responseObject as? [String: AnyObject],
                let users = response["users"] as? [[String: AnyObject]],
                let people = try? self.peopleFromResponse(users, siteID: siteID, type: User.self) else {
                failure(ResponseError.decodingFailure)
                return
            }

            let hasMore = self.peopleFoundFromResponse(response) > (offset + people.count)
            success(people, hasMore)

        }, failure: { (error, httpResponse) in
            failure(error)
        })
    }

    /// Retrieves the collection of Followers associated to a site.
    ///
    /// - Parameters:
    ///     - siteID: The target site's ID.
    ///     - count: The first N followers to be skipped in the returned array.
    ///     - size: Number of objects to retrieve.
    ///     - success: Closure to be executed on success
    ///     - failure: Closure to be executed on error.
    ///
    /// - Returns: An array of Followers.
    ///
    func getFollowers(_ siteID: Int,
                      offset: Int = 0,
                      count: Int,
                      success: @escaping ((_ followers: [Follower], _ hasMore: Bool) -> Void),
                      failure: @escaping (Error) -> ()) {
        let endpoint = "sites/\(siteID)/follows"
        let path = self.path(forEndpoint: endpoint, with: .version_1_1)
        let pageNumber = (offset / count + 1)
        let parameters: [String: AnyObject] = [
            "number": count as AnyObject,
            "page": pageNumber as AnyObject,
            "fields": "ID, nice_name, first_name, last_name, name, avatar_URL" as AnyObject
        ]

        wordPressComRestApi.GET(path!, parameters: parameters, success: { (responseObject, httpResponse) in
            guard let response = responseObject as? [String: AnyObject],
                let followers = response["users"] as? [[String: AnyObject]],
                let people = try? self.peopleFromResponse(followers, siteID: siteID, type: Follower.self) else {
                failure(ResponseError.decodingFailure)
                return
            }

            let hasMore = self.peopleFoundFromResponse(response) > (offset + people.count)
            success(people, hasMore)

        }, failure: { (error, httpResponse) in
            failure(error)
        })
    }

    /// Retrieves the collection of Viewers associated to a site.
    ///
    /// - Parameters:
    ///     - siteID: The target site's ID.
    ///     - count: The first N followers to be skipped in the returned array.
    ///     - size: Number of objects to retrieve.
    ///     - success: Closure to be executed on success
    ///     - failure: Closure to be executed on error.
    ///
    /// - Returns: An array of Followers.
    ///
    func getViewers(_ siteID: Int,
                    offset: Int = 0,
                    count: Int,
                    success: @escaping ((_ followers: [Viewer], _ hasMore: Bool) -> Void),
                    failure: @escaping (Error) -> ()) {
        let endpoint = "sites/\(siteID)/viewers"
        let path = self.path(forEndpoint: endpoint, with: .version_1_1)
        let pageNumber = (offset / count + 1)
        let parameters: [String: AnyObject] = [
            "number": count as AnyObject,
            "page": pageNumber as AnyObject
        ]

        wordPressComRestApi.GET(path!, parameters: parameters, success: { responseObject, httpResponse in
            guard let response = responseObject as? [String: AnyObject],
                let viewers = response["viewers"] as? [[String: AnyObject]],
                let people = try? self.peopleFromResponse(viewers, siteID: siteID, type: Viewer.self) else {
                failure(ResponseError.decodingFailure)
                return
            }

            let hasMore = self.peopleFoundFromResponse(response) > (offset + people.count)
            success(people, hasMore)

        }, failure: { (error, httpResponse) in
            failure(error)
        })
    }

    /// Updates a specified User's Role
    ///
    /// - Parameters:
    ///     - siteID: The ID of the site associated
    ///     - personID: The ID of the person to be updated
    ///     - newRole: The new Role that should be assigned to the user.
    ///     - success: Optional closure to be executed on success
    ///     - failure: Optional closure to be executed on error.
    ///
    /// - Returns: A single User instance.
    ///
    func updateUserRole(_ siteID: Int,
                        userID: Int,
                        newRole: Role,
                        success: ((Person) -> ())? = nil,
                        failure: ((Error) -> ())? = nil) {
        let endpoint = "sites/\(siteID)/users/\(userID)"
        let path = self.path(forEndpoint: endpoint, with: .version_1_1)
        let parameters = ["roles": [newRole.description]]

        wordPressComRestApi.POST(path!,
                parameters: parameters as [String : AnyObject]?,
                success: { (responseObject, httpResponse) in
                    guard let response = responseObject as? [String: AnyObject],
                                let person = try? self.personFromResponse(response, siteID: siteID, type: User.self) else {
                        failure?(ResponseError.decodingFailure)
                        return
                    }

                    success?(person)
                },
                failure: { (error, httpResponse) in
                    failure?(error)
                })
    }


    /// Deletes or removes a User from a site.
    ///
    /// - Parameters:
    ///     - siteID: The ID of the site associated.
    ///     - userID: The ID of the user to be deleted.
    ///     - reassignID: When present, all of the posts and pages that belong to `userID` will be reassigned
    ///       to another person, with the specified ID.
    ///     - success: Optional closure to be executed on success
    ///     - failure: Optional closure to be executed on error.
    ///
    func deleteUser(_ siteID: Int,
                    userID: Int,
                    reassignID: Int? = nil,
                    success: ((Void) -> Void)? = nil,
                    failure: ((Error) -> Void)? = nil) {
        let endpoint = "sites/\(siteID)/users/\(userID)/delete"
        let path = self.path(forEndpoint: endpoint, with: .version_1_1)
        var parameters = [String: AnyObject]()

        if let reassignID = reassignID {
            parameters["reassign"] = reassignID as AnyObject?
        }

        wordPressComRestApi.POST(path!, parameters: nil, success: { (responseObject, httpResponse) in
            success?()
        }, failure: { (error, httpResponse) in
            failure?(error)
        })
    }


    /// Deletes or removes a Follower from a site.
    ///
    /// - Parameters:
    ///     - siteID: The ID of the site associated.
    ///     - userID: The ID of the follower to be deleted.
    ///     - success: Optional closure to be executed on success
    ///     - failure: Optional closure to be executed on error.
    ///
    func deleteFollower(_ siteID: Int,
                        userID: Int,
                        success: ((Void) -> Void)? = nil,
                        failure: ((Error) -> Void)? = nil) {
        let endpoint = "sites/\(siteID)/followers/\(userID)/delete"
        let path = self.path(forEndpoint: endpoint, with: .version_1_1)

        wordPressComRestApi.POST(path!, parameters: nil, success: { (responseObject, httpResponse) in
            success?()
        }, failure: { (error, httpResponse) in
            failure?(error)
        })
    }


    /// Deletes or removes a User from a site.
    ///
    /// - Parameters:
    ///     - siteID: The ID of the site associated.
    ///     - userID: The ID of the viewer to be deleted.
    ///     - success: Optional closure to be executed on success
    ///     - failure: Optional closure to be executed on error.
    ///
    func deleteViewer(_ siteID: Int,
                      userID: Int,
                      success: ((Void) -> Void)? = nil,
                      failure: ((Error) -> Void)? = nil) {
        let endpoint = "sites/\(siteID)/viewers/\(userID)/delete"
        let path = self.path(forEndpoint: endpoint, with: .version_1_1)

        wordPressComRestApi.POST(path!, parameters: nil, success: { (responseObject, httpResponse) in
            success?()
        }, failure: { (error, httpResponse) in
            failure?(error)
        })
    }


    /// Retrieves all of the Available Roles, for a given SiteID.
    ///
    /// - Parameters:
    ///     - siteID: The ID of the site associated.
    ///     - success: Optional closure to be executed on success.
    ///     - failure: Optional closure to be executed on error.
    ///
    /// - Returns: An array of Person.Role entities.
    ///
    func getUserRoles(_ siteID: Int,
                      success: @escaping (([Role]) -> Void),
                      failure: ((Error) -> ())? = nil) {
        let endpoint = "sites/\(siteID)/roles"
        let path = self.path(forEndpoint: endpoint, with: .version_1_1)

        wordPressComRestApi.GET(path!, parameters: nil, success: { (responseObject, httpResponse) in
            guard let response = responseObject as? [String: AnyObject],
                    let roles = try? self.rolesFromResponse(response) else {
                failure?(ResponseError.decodingFailure)
                return
            }

            success(roles)
        }, failure: { (error, httpResponse) in
            failure?(error)
        })
    }


    /// Validates Invitation Recipients.
    ///
    /// - Parameters:
    ///     - siteID: The ID of the site associated.
    ///     - usernameOrEmail: Recipient that should be validated.
    ///     - role: Role that would be granted to the recipient.
    ///     - success: Closure to be executed on success.
    ///     - failure: Closure to be executed on failure. The remote error will be passed on.
    ///
    func validateInvitation(_ siteID: Int,
                            usernameOrEmail: String,
                            role: Role,
                            success: @escaping ((Void) -> Void),
                            failure: @escaping ((Error) -> Void)) {
        let endpoint = "sites/\(siteID)/invites/validate"
        let path = self.path(forEndpoint: endpoint, with: .version_1_1)

        let parameters = [
            "invitees": usernameOrEmail,
            "role": role.remoteValue
        ]

        wordPressComRestApi.POST(path!, parameters: parameters as [String : AnyObject]?, success: { (responseObject, httpResponse) in
            guard let responseDict = responseObject as? [String: AnyObject] else {
                failure(ResponseError.decodingFailure)
                return
            }

            if let error = self.errorFromInviteResponse(responseDict, usernameOrEmail: usernameOrEmail) {
                failure(error)
                return
            }

            success()

        }, failure: { (error, httpResponse) in
            failure(error)
        })
    }


    /// Sends an Invitation to the specified recipient.
    ///
    /// - Parameters:
    ///     - siteID: The ID of the associated site.
    ///     - usernameOrEmail: Recipient that should receive the invite.
    ///     - role: Role that would be granted to the recipient.
    ///     - message: String that should be sent to the recipient.
    ///     - success: Closure to be executed on success.
    ///     - failure: Closure to be executed on failure. The remote error will be passed on.
    ///
    func sendInvitation(_ siteID: Int,
                        usernameOrEmail: String,
                        role: Role,
                        message: String,
                        success: @escaping ((Void) -> Void),
                        failure: @escaping ((Error) -> Void)) {
        let endpoint = "sites/\(siteID)/invites/new"
        let path = self.path(forEndpoint: endpoint, with: .version_1_1)

        let parameters = [
            "invitees": usernameOrEmail,
            "role": role.remoteValue,
            "message": message
        ]

        wordPressComRestApi.POST(path!, parameters: parameters as [String : AnyObject]?, success: { (responseObject, httpResponse) in
            guard let responseDict = responseObject as? [String: AnyObject] else {
                failure(ResponseError.decodingFailure)
                return
            }

            if let error = self.errorFromInviteResponse(responseDict, usernameOrEmail: usernameOrEmail) {
                failure(error)
                return
            }

            success()

        }, failure: { (error, httpResponse) in
            failure(error)
        })
    }
}


/// Encapsulates PeopleRemote Private Methods
///
private extension PeopleRemote {
    /// Parses a dictionary containing an array of Persons, and returns an array of Person instances.
    ///
    /// - Parameters:
    ///     - response: Raw array of entity dictionaries
    ///     - siteID: the ID of the site associated
    ///     - type: The kind of Person we should parse.
    ///
    /// - Returns: An array of *Person* instances.
    ///
    func peopleFromResponse<T: Person>(_ rawPeople: [[String: AnyObject]],
                                        siteID: Int,
                                        type: T.Type) throws -> [T] {
        let people = try rawPeople.flatMap { (user) -> T? in
            return try personFromResponse(user, siteID: siteID, type: type)
        }

        return people
    }

    /// Parses a dictionary representing a Person, and returns an instance.
    ///
    /// - Parameters:
    ///     - response: Raw backend dictionary
    ///     - siteID: the ID of the site associated
    ///     - type: The kind of Person we should parse.
    ///
    /// - Returns: A single *Person* instance.
    ///
    func personFromResponse<T: Person>(_ user: [String: AnyObject],
                                        siteID: Int,
                                        type: T.Type) throws -> T {
        guard let ID = user["ID"] as? Int else {
            throw ResponseError.decodingFailure
        }

        guard let username = user["nice_name"] as? String else {
            throw ResponseError.decodingFailure
        }

        guard let displayName = user["name"] as? String else {
            throw ResponseError.decodingFailure
        }

        let firstName = user["first_name"] as? String
        let lastName = user["last_name"] as? String
        let avatarURL = (user["avatar_URL"] as? NSString)
            .flatMap { URL(string: $0.byUrlEncoding())}
            .flatMap { Gravatar($0)?.canonicalURL }

        let linkedUserID = user["linked_user_ID"] as? Int ?? ID
        let isSuperAdmin = user["is_super_admin"] as? Bool ?? false
        let roles = user["roles"] as? [String]

        let role: Role

        role = roles?.map({ role -> Role in
            return Role(string: role)
        }).sorted().first ?? Role.Unsupported

        return T(ID            : ID,
                 username      : username,
                 firstName     : firstName,
                 lastName      : lastName,
                 displayName   : displayName,
                 role          : role,
                 siteID        : siteID,
                 linkedUserID  : linkedUserID,
                 avatarURL     : avatarURL,
                 isSuperAdmin  : isSuperAdmin)
    }

    /// Returns the count of persons that can be retrieved from the backend.
    ///
    /// - Parameters response: Raw backend dictionary
    ///
    func peopleFoundFromResponse(_ response: [String: AnyObject]) -> Int {
        return response["found"] as? Int ?? 0
    }


    /// Parses a collection of Roles, and returns instances of the Person.Role Enum.
    ///
    /// - Parameter roles: Raw backend dictionary
    ///
    /// - Returns: Collection of the remote roles.
    ///
    func rolesFromResponse(_ roles: [String: AnyObject]) throws -> [Role] {
        guard let rawRoles = roles["roles"] as? [[String: AnyObject]] else {
            throw ResponseError.decodingFailure
        }

        let parsed = try rawRoles.map { (rawRole) -> Role in
            guard let name = rawRole["name"] as? String else {
                throw ResponseError.decodingFailure
            }

            return Role(string: name)
        }

        let filtered = parsed.filter { $0 != .Unsupported }
        return filtered.sorted()
    }

    /// Parses a remote Invitation Error into a PeopleRemote.Error.
    ///
    /// - Parameters:
    ///     - response: Raw backend dictionary
    ///     - usernameOrEmail: Recipient that was used to either validate, or effectively send an invite.
    ///
    /// - Returns: The remote error, if any.
    ///
    func errorFromInviteResponse(_ response: [String: AnyObject], usernameOrEmail: String) -> Error? {
        guard let errors = response["errors"] as? [String: AnyObject],
            let theError = errors[usernameOrEmail] as? [String: String],
            let code = theError["code"] else {
            return nil
        }

        switch code {
        case "invalid_input":
            return ResponseError.invalidInputError
        case "invalid_input_has_role":
            return ResponseError.userAlreadyHasRoleError
        case "invalid_input_following":
            return ResponseError.userAlreadyHasRoleError
        default:
            return ResponseError.unknownError
        }
    }
}
