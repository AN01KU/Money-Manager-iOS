import Testing
@testable import Money_Manager

@MainActor
struct NetworkMonitorProtocolTests {

    @Test("MockNetworkMonitor defaults to connected")
    func defaultsToConnected() {
        let monitor = MockNetworkMonitor()
        #expect(monitor.isConnected == true)
    }

    @Test("MockNetworkMonitor can be initialized offline")
    func canBeInitializedOffline() {
        let monitor = MockNetworkMonitor(isConnected: false)
        #expect(monitor.isConnected == false)
    }

    @Test("MockNetworkMonitor isConnected is mutable")
    func isConnectedIsMutable() {
        let monitor = MockNetworkMonitor(isConnected: false)
        monitor.isConnected = true
        #expect(monitor.isConnected == true)
    }

    @Test("NetworkMonitor conforms to NetworkMonitorProtocol")
    func networkMonitorConformsToProtocol() {
        let monitor: any NetworkMonitorProtocol = NetworkMonitor.shared
        #expect(monitor.isConnected == false || monitor.isConnected == true)
    }
}
