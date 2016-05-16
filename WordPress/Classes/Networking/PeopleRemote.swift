import Foundation

/// Encapsulates all of the People Management WordPress.com Methods
///
class PeopleRemote: ServiceRemoteREST {
    /// Typealiases
    ///
    typealias Role = Person.Role

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
    /// - Returns: An array of *Person* instances (AKA "People).
    ///
    func getUsersFor(siteID: Int, success: People -> (), failure: ErrorType -> ()) {
        let endpoint = "sites/\(siteID)/users"
        let path = pathForEndpoint(endpoint, withVersion: ServiceRemoteRESTApiVersion_1_1)
        let parameters = [
            "number": 50,
            "fields": "ID, nice_name, first_name, last_name, name, avatar_URL, roles, is_super_admin, linked_user_ID",
        ]

        api.GET(path, parameters: parameters, success: { (operation, responseObject) in
            guard let response = responseObject as? [String: AnyObject],
                      people = try? self.peopleFromResponse(response, siteID: siteID) else
            {
                failure(Error.DecodeError)
                return
            }

            success(people)

        }, failure: { (operation, error) in
            failure(error)
        })
    }

    }

    /// Updates a given User, of the specified site, with a new Role.
    ///
    /// - Parameters:
    ///     - siteID: The ID of the site associated
    ///     - personID: The ID of the person to be updated
    ///     - newRole: The new Role that should be assigned to the user.
    ///     - success: Optional closure to be executed on success
    ///     - failure: Optional closure to be executed on error.
    ///
    /// - Returns: A single *Person* instance.
    ///
    func updatePersonFor(siteID     : Int,
                         personID   : Int,
                         newRole    : Role,
                         success    : (Person -> ())? = nil,
                         failure    : (ErrorType -> ())? = nil)
    {
        let endpoint = "sites/\(siteID)/users/\(personID)"
        let path = pathForEndpoint(endpoint, withVersion: ServiceRemoteRESTApiVersion_1_1)
        let parameters = ["roles" : [newRole.description]]

        api.POST(path,
                parameters: parameters,
                success: {
                    (operation, responseObject) in
                    guard let response = responseObject as? [String: AnyObject],
                              person = try? self.personFromResponse(response, siteID: siteID) else
                    {
                        failure?(Error.DecodeError)
                        return
                    }

                    success?(person)
                },
                failure: {
                    (operation, error) in
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
    func getAvailableRolesFor(siteID    : Int,
                              success   : ([Role] -> Void),
                              failure   : (ErrorType -> ())? = nil)
    {
        let endpoint = "sites/\(siteID)/roles"
        let path = pathForEndpoint(endpoint, withVersion: ServiceRemoteRESTApiVersion_1_1)

        api.GET(path, parameters: nil, success: { (operation, responseObject) in
            guard let response = responseObject as? [String: AnyObject],
                    roles = try? self.rolesFromResponse(response) else
            {
                failure?(Error.DecodeError)
                return
            }

            success(roles)
        }, failure: { (operation, error) in
            failure?(error)
        })
    }
}


/// Encapsulates PeopleRemote Private Methods
///
private extension PeopleRemote {
    /// Parses a dictionary containing an array of persons, and returns an array of Person instances.
    ///
    /// - Parameters:
    ///     - response: Raw backend dictionary
    ///     - siteID: the ID of the site associated
    ///
    /// - Returns: An array of *Person* instances.
    ///
    private func peopleFromResponse(response: [String: AnyObject], siteID: Int) throws -> People {
        guard let users = response["users"] as? [[String: AnyObject]] else {
            throw Error.DecodeError
        }

        let people = try users.flatMap { (user) -> Person? in
            return try personFromResponse(user, siteID: siteID)
        }

        return people
    }

    /// Parses a dictionary representing a Person, and returns an instance.
    ///
    /// - Parameters:
    ///     - response: Raw backend dictionary
    ///     - siteID: the ID of the site associated
    ///
    /// - Returns: A single *Person* instance.
    ///
    private func personFromResponse(user: [String: AnyObject], siteID: Int) throws -> Person {
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

        let role = roles?.map({ role -> Role in
            return Role(string: role)
        }).sort().first ?? .Unsupported

        return Person(ID            : ID,
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
    private func rolesFromResponse(roles: [String: AnyObject]) throws -> [Role] {
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
