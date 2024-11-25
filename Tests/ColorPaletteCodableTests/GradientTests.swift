@testable import ColorPaletteCodable
import XCTest

import Foundation

class GradientTests: XCTestCase {
	func testBasic() throws {
		let gradient = PAL.Gradient(
			name: "first",
			colors: [
				try PAL.Color(rgbaHexString: "#FFFFFFFF"),
				try PAL.Color(rgbaHexString: "#444444FF"),
				try PAL.Color(rgbaHexString: "#000000FF")
			]
		)

		XCTAssertEqual("first", gradient.name)
		XCTAssertEqual(3, gradient.stops.count)
		XCTAssertEqual(0, gradient.stops[0].position)
		XCTAssertEqual("#ffffffff", try gradient.stops[0].color.hexRGBA(hashmark: true))
		XCTAssertEqual(0.5, gradient.stops[1].position)
		XCTAssertEqual("#444444ff", try gradient.stops[1].color.hexRGBA(hashmark: true))
		XCTAssertEqual(1.0, gradient.stops[2].position)
		XCTAssertEqual("#000000ff", try gradient.stops[2].color.hexRGBA(hashmark: true))

		let gradients = PAL.Gradients(gradients: [gradient])

		let coder = PAL.Gradients.Coder.JSON()
		let g1 = try coder.encode(gradients)
		let gradients2 = try PAL.Gradients.Decode(from: g1, fileExtension: coder.fileExtension)
		XCTAssertEqual(1, gradients2.count)
		let gradient2 = gradients.gradients[0]

		XCTAssertEqual("first", gradient2.name)
		XCTAssertEqual(3, gradient2.stops.count)
		XCTAssertEqual(0, gradient2.stops[0].position)
		XCTAssertEqual("#ffffffff", try gradient2.stops[0].color.hexRGBA(hashmark: true))
		XCTAssertEqual(0.5, gradient2.stops[1].position)
		XCTAssertEqual("#444444ff", try gradient2.stops[1].color.hexRGBA(hashmark: true))
		XCTAssertEqual(1.0, gradient2.stops[2].position)
		XCTAssertEqual("#000000ff", try gradient2.stops[2].color.hexRGBA(hashmark: true))
	}


	func testBasicWithNoName() throws {
		let gradient = PAL.Gradient(
			colors: [
				try PAL.Color(rgbaHexString: "#FFFFFFFF"),
				try PAL.Color(rgbaHexString: "#444444FF"),
				try PAL.Color(rgbaHexString: "#000000FF")
			]
		)

		XCTAssertEqual(3, gradient.stops.count)
		XCTAssertEqual(0, gradient.stops[0].position)
		XCTAssertEqual("#ffffffff", try gradient.stops[0].color.hexRGBA(hashmark: true))
		XCTAssertEqual(0.5, gradient.stops[1].position)
		XCTAssertEqual("#444444ff", try gradient.stops[1].color.hexRGBA(hashmark: true))
		XCTAssertEqual(1.0, gradient.stops[2].position)
		XCTAssertEqual("#000000ff", try gradient.stops[2].color.hexRGBA(hashmark: true))

		let gradients = PAL.Gradients(gradients: [gradient])

		// Encode
		let format = PAL.Gradients.Coder.JSON.fileExtension
		let coder = try XCTUnwrap(PAL.Gradients.coder(for: format))
		let g1 = try coder.encode(gradients)

		// Decode
		let gradients2 = try PAL.Gradients.Decode(from: g1, fileExtension: format)
		XCTAssertEqual(1, gradients2.count)
		let gradient2 = gradients.gradients[0]

		XCTAssertNil(gradient2.name)
		XCTAssertEqual(3, gradient2.stops.count)
		XCTAssertEqual(0, gradient2.stops[0].position)
		XCTAssertEqual("#ffffffff", try gradient2.stops[0].color.hexRGBA(hashmark: true))
		XCTAssertEqual(0.5, gradient2.stops[1].position)
		XCTAssertEqual("#444444ff", try gradient2.stops[1].color.hexRGBA(hashmark: true))
		XCTAssertEqual(1.0, gradient2.stops[2].position)
		XCTAssertEqual("#000000ff", try gradient2.stops[2].color.hexRGBA(hashmark: true))
	}

	func testUnordered() throws {
		let gradient = PAL.Gradient(
			colors: [
				try PAL.Color(rgbaHexString: "#FFFFFF"),
				try PAL.Color(rgbaHexString: "#444444"),
				try PAL.Color(rgbaHexString: "#000000")
			],
			positions: [0.2, 1, 0]
		).sorted

		// Positions should be ordered once the gradient is created

		XCTAssertEqual(3, gradient.stops.count)
		XCTAssertEqual(0, gradient.stops[0].position)
		XCTAssertEqual("#000000", try gradient.stops[0].color.hexRGB(hashmark: true))
		XCTAssertEqual(0.2, gradient.stops[1].position)
		XCTAssertEqual("#ffffff", try gradient.stops[1].color.hexRGB(hashmark: true))
		XCTAssertEqual(1.0, gradient.stops[2].position)
		XCTAssertEqual("#444444", try gradient.stops[2].color.hexRGB(hashmark: true))
	}

	func testUnnormalized() throws {
		let gradient = PAL.Gradient(
			colors: [
				try PAL.Color(rgbaHexString: "#FFFFFF"),
				try PAL.Color(rgbaHexString: "#121212"),
				try PAL.Color(rgbaHexString: "#444444"),
				try PAL.Color(rgbaHexString: "#000000")
			],
			positions: [100, 0, 5, 85]
		)

		let normalized = try gradient.normalized()

		// Positions should be ordered once the gradient is created, and the
		// positions should be normalized between 0 -> 1

		XCTAssertEqual(4, normalized.stops.count)

		XCTAssertEqual(0, normalized.stops[0].position)
		XCTAssertEqual("#121212", try normalized.stops[0].color.hexRGB(hashmark: true))
		XCTAssertEqual(0.05, normalized.stops[1].position)
		XCTAssertEqual("#444444", try normalized.stops[1].color.hexRGB(hashmark: true))
		XCTAssertEqual(0.85, normalized.stops[2].position)
		XCTAssertEqual("#000000", try normalized.stops[2].color.hexRGB(hashmark: true))
		XCTAssertEqual(1.0, normalized.stops[3].position)
		XCTAssertEqual("#ffffff", try normalized.stops[3].color.hexRGB(hashmark: true))
	}

	func testUnnormalizedNonZeroed() throws {
		let gradient = PAL.Gradient(
			colors: [
				try PAL.Color(rgbaHexString: "#FFFFFF"),
				try PAL.Color(rgbaHexString: "#121212"),
				try PAL.Color(rgbaHexString: "#444444")
			],
			positions: [60, 45, 30]
		)

		let normalized = try gradient.normalized()

		// Positions should be ordered once the gradient is created, and the
		// positions should be normalized between 0 -> 1

		XCTAssertNil(gradient.name)

		XCTAssertEqual(3, gradient.stops.count)

		XCTAssertEqual(0, normalized.stops[0].position)
		XCTAssertEqual("#444444", try normalized.stops[0].color.hexRGB(hashmark: true))
		XCTAssertEqual(0.5, normalized.stops[1].position, accuracy: 4)
		XCTAssertEqual("#121212", try normalized.stops[1].color.hexRGB(hashmark: true))
		XCTAssertEqual(1.0, normalized.stops[2].position)
		XCTAssertEqual("#ffffff", try normalized.stops[2].color.hexRGB(hashmark: true))
	}

	func testDumbAssertion() throws {
		let gradient = PAL.Gradient(colorPositions: [
			(20, try PAL.Color(rgbaHexString: "#FFFFFF")),
			(20, try PAL.Color(rgbaHexString: "#000000")),
		])

		XCTAssertThrowsError(try gradient.normalized())
	}

	func testGradientFromPalette() throws {
		let paletteData = """
			GIMP Palette
			Name: mona
			#Description:
			#Colors: 6
			91	64	78	5b404e
			119	90	95	775a5f
			142	116	112	8e7470
			172	155	144	ac9b90
			210	204	184	d2ccb8
			238	238	225	eeeee1
			"""
		let data = paletteData.data(using: .utf8)!
		let palette = try PAL.Coder.GIMP().decode(from: data)

		let gradient = PAL.Gradient(palette: palette)

		XCTAssertEqual("mona", gradient.name)
		XCTAssertEqual(6, gradient.stops.count)

		XCTAssertEqual("#5b404e", try gradient.stops[0].color.hexRGB(hashmark: true))
		XCTAssertEqual(0, gradient.stops[0].position, accuracy: 0.01)
		XCTAssertEqual("#775a5f", try gradient.stops[1].color.hexRGB(hashmark: true))
		XCTAssertEqual(0.2, gradient.stops[1].position, accuracy: 0.01)
		XCTAssertEqual("#8e7470", try gradient.stops[2].color.hexRGB(hashmark: true))
		XCTAssertEqual(0.4, gradient.stops[2].position, accuracy: 0.01)
		XCTAssertEqual("#ac9b90", try gradient.stops[3].color.hexRGB(hashmark: true))
		XCTAssertEqual(0.6, gradient.stops[3].position, accuracy: 0.01)
		XCTAssertEqual("#d2ccb8", try gradient.stops[4].color.hexRGB(hashmark: true))
		XCTAssertEqual(0.8, gradient.stops[4].position, accuracy: 0.01)
		XCTAssertEqual("#eeeee1", try gradient.stops[5].color.hexRGB(hashmark: true))
		XCTAssertEqual(1, gradient.stops[5].position, accuracy: 0.01)
	}

	func testFlattenTransparencyStops() throws {
		let outputFolder = try! testResultsContainer.subfolder(with: "TransparencyStopFlattening")
		do {
			let gradient = PAL.Gradient(
				stops: [
					PAL.Gradient.Stop(position: 0, color: PAL.Color.blue),
					PAL.Gradient.Stop(position: 1, color: PAL.Color.yellow),
				],
				transparencyStops: [
					PAL.Gradient.TransparencyStop(position: 0, value: 1),
					PAL.Gradient.TransparencyStop(position: 0.2, value: 0.25),
					PAL.Gradient.TransparencyStop(position: 1.0, value: 1),
				]
			)

			#if !os(Linux) && !os(Windows)
			let imOrig = try XCTUnwrap(gradient.image(size: CGSize(width: 400, height: 200)))
			let d1 = try imOrig.representation.png()
			try outputFolder.write(d1, to: "textGradient1_original.png")
			#endif

			let flattened = try gradient.mergeTransparencyStops()
			XCTAssertNil(flattened.transparencyStops)

			#if !os(Linux) && !os(Windows)
			let imFlattened = try XCTUnwrap(flattened.image(size: CGSize(width: 400, height: 200)))
			let d2 = try imFlattened.representation.png()
			try outputFolder.write(d2, to: "textGradient1_flattened.png")
			#endif
		}

		do {
			let gradients = try loadResourceGradient(named: "35.grd")
			XCTAssertEqual(10, gradients.count)

			let first = gradients.gradients[0]
			XCTAssertNotNil(first.transparencyStops)

			#if !os(Linux) && !os(Windows)
			let imOrig = try XCTUnwrap(first.image(size: CGSize(width: 400, height: 200)))
			let d1 = try imOrig.representation.png()
			try outputFolder.write(d1, to: "35_1_orig.png")
			#endif

			let flattened = try first.mergeTransparencyStops()
			XCTAssertNil(flattened.transparencyStops)
			XCTAssertEqual(8, flattened.stops.count)

			#if !os(Linux) && !os(Windows)
			let imFlattened = try XCTUnwrap(flattened.image(size: CGSize(width: 400, height: 200)))
			let d2 = try imFlattened.representation.png()
			try outputFolder.write(d2, to: "35_1_flattened.png")
			#endif
		}

		do {
			let gradients = try loadResourceGradient(named: "30.grd")
			XCTAssertEqual(10, gradients.count)

			let first = gradients.gradients[1]
			XCTAssertEqual(3, first.stops.count)
			XCTAssertNotNil(first.transparencyStops)
			XCTAssertEqual(9, first.transparencyStops?.count)

			#if !os(Linux) && !os(Windows)
			let imOrig = try XCTUnwrap(first.image(size: CGSize(width: 400, height: 200)))
			let d1 = try imOrig.representation.png()
			try outputFolder.write(d1, to: "30_1_orig.png")
			#endif

			let flattened = try first.mergeTransparencyStops()
			XCTAssertNil(flattened.transparencyStops)
			XCTAssertEqual(10, flattened.stops.count)

			#if !os(Linux) && !os(Windows)
			let imFlattened = try XCTUnwrap(flattened.image(size: CGSize(width: 400, height: 200)))
			let d2 = try imFlattened.representation.png()
			try outputFolder.write(d2, to: "30_1_flattened.png")
			#endif
		}
	}

	func testGradientCreationFromArray() throws {
		let colors: [PAL.Color] = [
			try PAL.Color(name: "r", r255: 255, g255: 0, b255: 0),
			try PAL.Color(name: "g", r255: 0, g255: 255, b255: 0),
			try PAL.Color(name: "b", r255: 0, g255: 0, b255: 255),
		]
		let g = colors.gradient()
		XCTAssertNil(g.name)
		XCTAssertEqual([0, 0.5, 1], g.stops.map { $0.position })
		XCTAssertEqual(colors, g.stops.map { $0.color })

		let g1 = colors.gradient(named: "g")
		XCTAssertEqual("g", g1.name)
	}
}
