//
//  PSPPaletteCoder.swift
//
//  Copyright © 2023 Darren Ford. All rights reserved.
//
//  MIT License
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import DSFRegex
import Foundation

public extension PAL.Coder {
	/// A coder/decoder for JASC PaintShopPro palettes
	struct PaintShopPro: PAL_PaletteCoder {
		public let fileExtension = ["psppalette", "pal"]
		public init() {}
	}
}

public extension PAL.Coder.PaintShopPro {
	func decode(from inputStream: InputStream) throws -> PAL.Palette {
		let allData = inputStream.readAllData()
		guard let content = String(data: allData, encoding: allData.stringEncoding ?? .utf8) else {
			throw PAL.CommonError.invalidFormat
		}

		let lines = content.split(whereSeparator: \.isNewline)
		guard lines.count > 2 else {
			throw PAL.CommonError.invalidFormat
		}

		// BOM
		guard lines[0].contains("JASC-PAL") else {
			throw PAL.CommonError.invalidFormat
		}

		// A version number of some sort?
		guard lines[1] == "0100" else {
			throw PAL.CommonError.invalidFormat
		}

		// The number of colors
		guard let colorCount = Int(lines[2]) else {
			throw PAL.CommonError.invalidFormat
		}

		if colorCount != lines.count - 3 {
			// Just a warning I suppose?
			Swift.print("JASC palette coder - invalid color count?")
		}

		var palette = PAL.Palette()

		let regex = try DSFRegex(#"^\s*(\d+)\s+(\d+)\s+(\d+)\s*$"#)

		for line in lines[3...] {
			let ln = String(line)
			let searchResult = regex.matches(for: ln)
			for match in searchResult {
				let rs = ln[match.captures[0]]
				let gs = ln[match.captures[1]]
				let bs = ln[match.captures[2]]
				guard
					let rv = Int(rs),
					let gv = Int(gs),
					let bv = Int(bs)
				else {
					continue
				}

				let re = max(0, min(1, Float32(rv) / 255.0))
				let ge = max(0, min(1, Float32(gv) / 255.0))
				let be = max(0, min(1, Float32(bv) / 255.0))

				let c = try PAL.Color(name: "", colorSpace: .RGB, colorComponents: [re, ge, be])
				palette.colors.append(c)
			}
		}
		return palette
	}
}

public extension PAL.Coder.PaintShopPro {
	func encode(_ palette: PAL.Palette) throws -> Data {
		var result = "JASC-PAL\n0100\n\(palette.colors.count)"
		for color in palette.colors {
			result += "\n"
			// Colors are RGB
			let rgb = try color.converted(to: .RGB)

			let rv = Int(min(255, max(0, rgb.colorComponents[0] * 255)).rounded(.towardZero))
			let gv = Int(min(255, max(0, rgb.colorComponents[1] * 255)).rounded(.towardZero))
			let bv = Int(min(255, max(0, rgb.colorComponents[2] * 255)).rounded(.towardZero))

			result += "\(rv) \(gv) \(bv)"
		}
		guard let data = result.data(using: .utf8) else {
			throw PAL.CommonError.unsupportedColorSpace
		}

		return data
	}
}
