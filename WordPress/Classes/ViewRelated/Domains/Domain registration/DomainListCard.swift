import SwiftUI

struct DomainListCard: View {
    struct Info {
        let domainName: String
        let domainHeadline: String
        let state: State
    }

    enum State {
        case completeSetup
        case Failed
        case Error
        case inProgress
        case actionRequired
        case expired
        case expiringSoon
        case renew
        case verifyEmail
        case active
    }

    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }

//    private var domainText: some View {
//
//    }
}

struct DomainListCard_Previews: PreviewProvider {
    static var previews: some View {
        DomainListCard()
    }
}
