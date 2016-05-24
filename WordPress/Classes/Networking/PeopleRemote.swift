import Foundation

/// Encapsulates all of the People Management WordPress.com Methods
///
class PeopleRemote: ServiceRemoteWordPressComREST {

    /// Defines the PeopleRemote possible errors.
    ///
    enum Error: ErrorType {
        case DecodeError
    }

    /// Retrieves the collection of users associated to a given Site.
    ///
    /// - Parameters:
    ///     - siteID: The target site's ID.
    ///     - success: Closure to be executed on success
    ///     - failure: Closure to be executed on error.
    ///
    /// - Returns: An array of Users.
    ///
    func getUsers(siteID: Int, success: ([User] -> Void), failure: (ErrorType -> Void)) {
        let endpoint = "sites/\(siteID)/users"
        let path = pathForEndpoint(endpoint, withVersion: .Version_1_1)
        let parameters = [
            "number": 50,
            "fields": "ID, nice_name, first_name, last_name, name, avatar_URL, roles, is_super_admin, linked_user_ID",
        ]

        wordPressComRestApi.GET(path, parameters: parameters, success: { (responseObject, httpResponse) in
            guard let response = responseObject as? [String: AnyObject],
                      people = try? self.peopleFromResponse(response, siteID: siteID, type: User.self) else
            {
                failure(Error.DecodeError)
                return
            }
            success(people)

        }, failure: { (error, httpResponse) in
            failure(error)
        })
    }

    /// Retrieves the collection of Followers associated to a site.
    ///
    /// - Parameters:
    ///     - siteID: The target site's ID.
    ///     - success: Closure to be executed on success
    ///     - failure: Closure to be executed on error.
    ///
    /// - Returns: An array of Followers.
    ///
    func getFollowers(siteID: Int, success: [Follower] -> (), failure: ErrorType -> ()) {
        let endpoint = "sites/\(siteID)/follows"
        let path = pathForEndpoint(endpoint, withVersion: .Version_1_1)
        let parameters = [
            "number": 50,
            "fields": "ID, nice_name, first_name, last_name, name, avatar_URL"
        ]

        wordPressComRestApi.GET(path, parameters: parameters, success: { (responseObject, httpResponse) in
            guard let response = responseObject as? [String: AnyObject],
                      people = try? self.peopleFromResponse(response, siteID: siteID, type: Follower.self) else
            {
                failure(Error.DecodeError)
                return
            }
            success(people)

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
    func updateUserRole(siteID: Int,
                        userID: Int,
                        newRole: Role,
                        success: (Person -> ())? = nil,
                        failure: (ErrorType -> ())? = nil)
    {
        let endpoint = "sites/\(siteID)/users/\(userID)"
        let path = pathForEndpoint(endpoint, withVersion: .Version_1_1)
        let parameters = ["roles" : [newRole.description]]

        wordPressComRestApi.POST(path,
                parameters: parameters,
                success: { (responseObject, httpResponse) in
                    guard let response = responseObject as? [String: AnyObject],
                                person = try? self.personFromResponse(response, siteID: siteID, type: User.self) else
                    {
                        failure?(Error.DecodeError)
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
    func deleteUser(siteID: Int,
                    userID: Int,
                    reassignID: Int? = nil,
                    success: (Void -> Void)? = nil,
                    failure: (ErrorType -> Void)? = nil)
    {
        let endpoint = "sites/\(siteID)/users/\(userID)/delete"
        let path = pathForEndpoint(endpoint, withVersion: .Version_1_1)
        var parameters = [String: AnyObject]()

        if let reassignID = reassignID {
            parameters["reassign"] = reassignID
        }

        wordPressComRestApi.POST(path, parameters: nil, success: { (responseObject, httpResponse) in
            success?()
        }, failure: { (error, httpResponse) in
            failure?(error)
        })
    }


    /// Retrieves all of the Available Roles, for a given SiteID.
    ///
    /// - Parameters:
    ///     - siteID: The ID of the site associated
    ///     - success: Optional closure to be executed on success
    ///     - failure: Optional closure to be executed on error.
    ///
    /// - Returns: An array of Person.Role entities.
    ///
    func getUserRoles(siteID: Int,
                      success: ([Role] -> Void),
                      failure: (ErrorType -> ())? = nil)
    {
        let endpoint = "sites/\(siteID)/roles"
        let path = pathForEndpoint(endpoint, withVersion: .Version_1_1)

        wordPressComRestApi.GET(path, parameters: nil, success: { (responseObject, httpResponse) in
            guard let response = responseObject as? [String: AnyObject],
                    roles = try? self.rolesFromResponse(response) else
            {
                failure?(Error.DecodeError)
                return
            }

            success(roles)
        }, failure: { (error, httpResponse) in
            failure?(error)
        })
    }
}


/// Encapsulates PeopleRemote Private Methods
///
private extension PeopleRemote {
    /// Parses a dictionary containing an array of Persons, and returns an array of Person instances.
    ///
    /// - Parameters:
    ///     - response: Raw backend dictionary
    ///     - siteID: the ID of the site associated
    ///     - type: The kind of Person we should parse.
    ///
    /// - Returns: An array of *Person* instances.
    ///
    func peopleFromResponse<T : Person>(response: [String: AnyObject],
                                        siteID: Int,
                                        type: T.Type) throws -> [T]
    {
        guard let users = response["users"] as? [[String: AnyObject]] else {
            throw Error.DecodeError
        }

        let people = try users.flatMap { (user) -> T? in
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
    func personFromResponse<T : Person>(user: [String: AnyObject],
                                        siteID: Int,
                                        type: T.Type) throws -> T
    {
        guard let ID = user["ID"] as? Int else {
            throw Error.DecodeError
        }

        guard let username = user["nice_name"] as? String else {
            throw Error.DecodeError
        }

        guard let displayName = user["name"] as? String else {
            throw Error.DecodeError
        }

        let firstName = user["first_name"] as? String
        let lastName = user["last_name"] as? String
        let avatarURL = (user["avatar_URL"] as? NSString)
            .flatMap { NSURL(string: $0.stringByUrlEncoding())}
            .flatMap { Gravatar($0)?.canonicalURL }

        let linkedUserID = user["linked_user_ID"] as? Int ?? ID
        let isSuperAdmin = user["is_super_admin"] as? Bool ?? false
        let roles = user["roles"] as? [String]

        let role : Role

        role = roles?.map({ role -> Role in
            return Role(string: role)
        }).sort().first ?? Role.Unsupported

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

    /// Parses a collection of Roles, and returns instances of the Person.Role Enum.
    ///
    func rolesFromResponse(roles: [String: AnyObject]) throws -> [Role] {
        guard let rawRoles = roles["roles"] as? [[String: AnyObject]] else {
            throw Error.DecodeError
        }

        let parsed = try rawRoles.map { (rawRole) -> Role in
            guard let name = rawRole["name"] as? String else {
                throw Error.DecodeError
            }

            return Role(string: name)
        }

        let filtered = parsed.filter { $0 != .Unsupported }
        return filtered.sort()
    }
}
