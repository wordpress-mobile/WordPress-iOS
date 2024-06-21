@testable import WordPressAuthenticator

extension JSONWebToken {

    // Created with https://jwt.io/ with input:
    //
    // header: {
    //   "alg": "HS256",
    //   "typ": "JWT"
    // }
    // payload: {
    //   "key": "value",
    //   "other_key": "other_value"
    // }
    private(set) static var validJWTString = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJrZXkiOiJ2YWx1ZSIsIm90aGVyX2tleSI6Im90aGVyX3ZhbHVlIn0.Koc07zTGuATtQK7EvfAuwgZ-Nsr6P6J3HV4h3QLlXpM"

    // Created with https://jwt.io/ with input:
    //
    // header: {
    //   "alg": "HS256",
    //   "typ": "JWT"
    // }
    // payload: {
    //   "key": "value",
    //   "email": "test@email.com"
    // }
    private(set) static var validJWTStringWithEmailOnly = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJrZXkiOiJ2YWx1ZSIsImVtYWlsIjoidGVzdEBlbWFpbC5jb20ifQ.b-2oTvjpc_qHM5dU6akk_ESe3eWUZwL21pvTsCmW2gE"

    // Created with https://jwt.io/ with input:
    //
    // header: {
    //   "alg": "HS256",
    //   "typ": "JWT"
    // }
    // payload: {
    //   "name": "John Doe",
    //   "key": "value"
    // }
    private(set) static var validJWTStringWithNameOnly = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UiLCJrZXkiOiJ2YWx1ZSJ9.P7Se5_EMlFBg5q8PV4C2IQ1YojTTSgitCBX7FgmXZzs"

    // Created with https://jwt.io/ with input:
    //
    // header: {
    //   "alg": "HS256",
    //   "typ": "JWT"
    // }
    // payload: {
    //   "name": "John Doe",
    //   "key": "value",
    //   "email": "test@email.com"
    // }
    private(set) static var validJWTStringWithNameAndEmail = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UiLCJrZXkiOiJ2YWx1ZSIsImVtYWlsIjoidGVzdEBlbWFpbC5jb20ifQ.-xzg0r5mMnSZ8hE3hk7S93iCZHhOez1QFYdheSmDlx4"

    // For convenience, this exposes the email and name value used in the fixtures.
    // This allows us to use raw strings in tests, rather than having to implement encoding the JWT from an arbitrary string.
    private(set) static var emailFromValidJWTStringWithEmail = "test@email.com"
    private(set) static var nameFromValidJWTStringWithEmail = "John Doe"
}
