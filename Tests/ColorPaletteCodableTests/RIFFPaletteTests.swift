@testable import ColorPaletteCodable
import XCTest

final class RIFFSwatchesTests: XCTestCase {
	func testBasic() throws {
		let paletteURL = try XCTUnwrap(Bundle.module.url(forResource: "arne-v20-16", withExtension: "pal"))
		let coder = PAL.Coder.RIFF()
		let palette = try coder.decode(from: paletteURL)
		XCTAssertEqual(16, palette.colors.count)
		XCTAssertEqual(palette.colors[0], try PAL.Color(r: 0, g: 0, b: 0))
		XCTAssertEqual(palette.colors[1], try PAL.Color(r: 157, g: 157, b: 157))
		XCTAssertEqual(palette.colors[14], try PAL.Color(r: 49, g: 162, b: 242))
		XCTAssertEqual(palette.colors[15], try PAL.Color(r: 178, g: 220, b: 239))
	}

	func testBasic2() throws {
		let paletteURL = try XCTUnwrap(Bundle.module.url(forResource: "sample", withExtension: "pal"))
		let coder = PAL.Coder.RIFF()
		let palette = try coder.decode(from: paletteURL)
		XCTAssertEqual(256, palette.colors.count)
	}
}
