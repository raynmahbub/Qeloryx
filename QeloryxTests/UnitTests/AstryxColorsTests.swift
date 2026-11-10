// QELORYX — Tests
// AstryxColorsTests.swift

import XCTest
#if canImport(QeloryxDesignSystem)
@testable import QeloryxDesignSystem
#else
@testable import Qeloryx
#endif
import SwiftUI

final class AstryxColorsTests: XCTestCase {
    
    func testColorTokensExist() {
        // Just ensure colors can be instantiated without crashing
        _ = AstryxColors.auroraBlue
        _ = AstryxColors.midnight
        _ = AstryxColors.emerald
        _ = AstryxColors.sunset
        _ = AstryxColors.iceWhite
        
        _ = AstryxColors.Midnight.tone900
        _ = AstryxColors.Midnight.tone800
        _ = AstryxColors.Aurora.tone500
        _ = AstryxColors.Semantic.background
        _ = AstryxColors.Semantic.foreground
    }
    
    func testHexInitialization() {
        let color = Color(hex: "#3B82F6")
        XCTAssertNotNil(color)
        
        let color2 = Color(hex: "#050816")
        XCTAssertNotNil(color2)
    }
}
