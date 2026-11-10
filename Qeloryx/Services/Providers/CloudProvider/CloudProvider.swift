import Foundation

public protocol CloudProviderProtocol: Provider {
    func fetchTracks() async throws -> [AstryxTrack]
}

public final class MockCloudProvider: CloudProviderProtocol {
    public let id = "com.qeloryx.provider.cloud.mock"
    public let name = "Mock Cloud"
    public init() {}
    public func fetchTracks() async throws -> [AstryxTrack] { [] }
}
