import Testing
@testable import JetpackSocial

@Suite("ConnectionStatus")
struct ConnectionStatusTests {
    @Test("maps known wire values")
    func mapsKnownValues() {
        #expect(ConnectionStatus(wireString: "ok") == .ok)
        #expect(ConnectionStatus(wireString: "broken") == .broken)
        #expect(ConnectionStatus(wireString: "invalid") == .invalid)
        #expect(ConnectionStatus(wireString: "refresh-failed") == .refreshFailed)
    }

    @Test("unknown strings map to .unknown")
    func mapsUnknownToUnknown() {
        #expect(ConnectionStatus(wireString: "gibberish") == .unknown)
        #expect(ConnectionStatus(wireString: "") == .unknown)
    }

    @Test("nil wire value maps to .unknown")
    func mapsNilToUnknown() {
        #expect(ConnectionStatus(wireString: nil) == .unknown)
    }

    @Test("isBroken is true only for server-confirmed bad states")
    func isBrokenOnlyForBadStates() {
        #expect(!ConnectionStatus.ok.isBroken)
        #expect(!ConnectionStatus.unknown.isBroken)
        #expect(ConnectionStatus.broken.isBroken)
        #expect(ConnectionStatus.invalid.isBroken)
        #expect(ConnectionStatus.refreshFailed.isBroken)
    }
}
