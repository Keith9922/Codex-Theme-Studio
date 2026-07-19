import XCTest
@testable import CodexDreamSkin

final class ModelTests: XCTestCase {
  func testActiveStatusRequiresSessionAndInjector() {
    var status = EngineStatus.off
    status.session = "active"
    XCTAssertFalse(status.isActive)
    status.injectorAlive = true
    XCTAssertTrue(status.isActive)
  }

  func testThemeIDValidationRejectsTraversalAndControlCharacters() {
    XCTAssertTrue(EngineClient.isSafeThemeID("preset-asuka-eva02"))
    XCTAssertFalse(EngineClient.isSafeThemeID("../escape"))
    XCTAssertFalse(EngineClient.isSafeThemeID("bad\nid"))
    XCTAssertFalse(EngineClient.isSafeThemeID(""))
  }

  func testAssetNameValidationRejectsPaths() {
    XCTAssertTrue(EngineClient.isSafeAssetName("background.jpg"))
    XCTAssertFalse(EngineClient.isSafeAssetName("../background.jpg"))
    XCTAssertFalse(EngineClient.isSafeAssetName("folder/background.jpg"))
  }
}
