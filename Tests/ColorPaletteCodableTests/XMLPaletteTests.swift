@testable import ColorPaletteCodable
import XCTest

import Foundation

class XMLPaletteTests: XCTestCase {

	let files = [
		"db32-cmyk",
		"db32-rgb",
		"Signature",
		"ThermoFlex Plus",		// colorspaces
		"Satins Cap Colors"		// CMYK colors
	]

	func testAllRoundTrip() throws {
		try files.forEach { item in
			Swift.print("> Roundtripping: \(item)")
			let paletteURL = try XCTUnwrap(Bundle.module.url(forResource: item, withExtension: "xml"))
			let palette = try PAL.Palette.Decode(from: paletteURL)

			let coder = PAL.Coder.XMLPalette()
			let data = try coder.encode(palette)

			let rebuilt = try coder.decode(from: data)

			XCTAssertEqual(rebuilt.name, palette.name)
			XCTAssertEqual(rebuilt.allColors().count, palette.allColors().count)
		}
	}

	func testXMLWithCustomColorspace() throws {
		let paletteURL = try XCTUnwrap(Bundle.module.url(forResource: "ThermoFlex Plus", withExtension: "xml"))
		let palette = try PAL.Palette.Decode(from: paletteURL)
		XCTAssertEqual(palette.colors.count, 0)
		XCTAssertEqual(palette.groups.count, 1)
		XCTAssertEqual(palette.groups[0].colors.count, 101)
	}

	func testBasicXML1() throws {
		let paletteURL = try XCTUnwrap(Bundle.module.url(forResource: "basic-xml-1", withExtension: "xml"))
		let data = try Data(contentsOf: paletteURL)
		let c = PAL.Coder.BasicXML()

		let palette: PAL.Palette = try {
			try usingStreamData(data) { s in
				return try c.decode(from: s)
			}
		}()
		XCTAssertEqual(palette.colors.count, 5)
		XCTAssertEqual(palette.name, "basicxml")

		let ep = try c.encode(palette)
		let dec = try c.decode(from: ep)
		XCTAssertEqual(dec.colors.count, 5)
		XCTAssertEqual(dec.name, "basicxml")
	}
}
