// QELORYX — Tests
// CapabilityRegistryTests.swift

import XCTest
@testable import QeloryxCore

final class CapabilityRegistryTests: XCTestCase {
    
    var registry: AstryxCapabilityRegistry!
    
    override func setUp() {
        super.setUp()
        registry = AstryxCapabilityRegistry()
        registry.reset()
    }
    
    func testDefaultCapabilitiesRegistered() {
        let all = registry.allCapabilities()
        XCTAssertFalse(all.isEmpty)
        XCTAssertNotNil(registry.capability(for: CapabilityID.lyrics))
        XCTAssertNotNil(registry.capability(for: CapabilityID.eq))
        XCTAssertNotNil(registry.capability(for: CapabilityID.spaces))
    }
    
    func testIsEnabled() {
        XCTAssertTrue(registry.isEnabled(CapabilityID.lyrics))
        XCTAssertFalse(registry.isEnabled(CapabilityID.cloud)) // Disabled by default
    }
    
    func testRegisterCustomCapability() {
        let custom = BaseCapability(id: "com.test.custom", name: "Custom", description: "Test")
        registry.register(custom)
        
        XCTAssertNotNil(registry.capability(for: "com.test.custom"))
        XCTAssertTrue(registry.isEnabled("com.test.custom"))
    }
    
    func testEnableDisable() async throws {
        let id = CapabilityID.cloud
        XCTAssertFalse(registry.isEnabled(id))
        
        try await registry.enable(id: id)
        XCTAssertTrue(registry.isEnabled(id))
        
        try await registry.disable(id: id)
        XCTAssertFalse(registry.isEnabled(id))
    }
    
    func testEnabledCapabilities() {
        let enabled = registry.enabledCapabilities()
        XCTAssertFalse(enabled.isEmpty)
        XCTAssertTrue(enabled.allSatisfy { $0.isEnabled })
    }
}
