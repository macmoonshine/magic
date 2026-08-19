import XCTest
import libmagic
import Magic

final class LibMagicTests: XCTestCase {
    func testMagicDatabaseLoads() {
        let cookie = magic_open(0)
        XCTAssertNotNil(cookie)
        defer { magic_close(cookie!) }

        let result = magic_load(cookie, Magic.Definition.builtin.filesystemPath)
        if result != 0 {
            XCTFail("magic_load failed: \(magic_error(cookie) != nil ? String(cString: magic_error(cookie)!) : "unknown")")
        }
    }
}
