//
//  PaintNETPaletteCoder.swift
//
//  Copyright © 2024 Darren Ford. All rights reserved.
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

/*
 ; paint.net Palette File
 ; Lines that start with a semicolon are comments
 ; Colors are written as 8-digit hexadecimal numbers: aarrggbb
 ; For example, this would specify green: FF00FF00
 ; The alpha ('aa') value specifies how transparent a color is. FF is fully opaque, 00 is fully transparent.
 ; A palette usually consists of ninety six (96) colors. If there are less than this, the remaining color
 ; slots will be set to white (FFFFFFFF). If there are more, then the remaining colors will be ignored.
 FF000000
 FF404040
 FFFF0000
 FFFF6A00
 FF23FFBD
 */

public extension PAL.Coder {
	/// A coder that handle delimited RGBA strings
	struct PaintNET: PAL_PaletteCoder {
		public let name = "Paint.NET Palette"
		public let fileExtension = ["txt"]
		public init() {}
		static let validHexChars = "0123456789abcdefABCDEF"
	}
}

public extension PAL.Coder.PaintNET {
	func decode(from inputStream: InputStream) throws -> PAL.Palette {
		var allData = inputStream.readAllData()

		guard allData.count > 3 else {
			throw PAL.CommonError.invalidFormat
		}

		let utf8BOM = Data([0xEF,0xBB,0xBF])

		if allData[0 ... 2] == utf8BOM {
			allData = allData.dropFirst(3)
		}

		guard let content = String(data: allData, encoding: allData.stringEncoding ?? .utf8) else {
			throw PAL.CommonError.invalidFormat
		}

		var palette = PAL.Palette()

		// Split into newlines
		let lines = content.split(whereSeparator: \.isNewline)

		for line in lines {
			let line = line.trimmingCharacters(in: .whitespaces)
			if line[line.startIndex] == ";" {
				// Assume a comment. Skip the line
				continue
			}

			if line.count != 8 {
				// Each color line should exist of exactly 8 characters
				throw PAL.CommonError.invalidFormat
			}

			// Line should consist solely of AARRGGBB
			var index = line.startIndex
			let ah = line[index ... line.index(index, offsetBy: 1)]
			index = line.index(index, offsetBy: 2)
			let rh = line[index ... line.index(index, offsetBy: 1)]
			index = line.index(index, offsetBy: 2)
			let gh = line[index ... line.index(index, offsetBy: 1)]
			index = line.index(index, offsetBy: 2)
			let bh = line[index ... line.index(index, offsetBy: 1)]

			guard let aa = Double("0x" + ah).flatMap( { UInt32(exactly: $0) } ) else { continue }
			guard let ra = Double("0x" + rh).flatMap( { UInt32(exactly: $0) } ) else { continue }
			guard let ga = Double("0x" + gh).flatMap( { UInt32(exactly: $0) } ) else { continue }
			guard let ba = Double("0x" + bh).flatMap( { UInt32(exactly: $0) } ) else { continue }

			let color = try PAL.Color(r: UInt8(ra), g: UInt8(ga), b: UInt8(ba), a: UInt8(aa))
			palette.colors.append(color)
		}
		return palette
	}
}

public extension PAL.Coder.PaintNET {
	/// Write out the colors in the palette
	/// 1. One color per line, encoded as a HEX value
	/// 2. Hex encoded
	func encode(_ palette: PAL.Palette) throws -> Data {
		let rgbColors = try palette.allColors()
			.compactMap { try $0.converted(to: .RGB) }

		var content = """
; paint.net Palette File
; Lines that start with a semicolon are comments
; Colors are written as 8-digit hexadecimal numbers: aarrggbb

"""
		try rgbColors.forEach { color in
			let a = UInt8(color.alpha * 255).clamped(to: 0 ... 255)
			guard let rgbs = color.rawHexRGB else {
				throw PAL.CommonError.cannotConvertColorSpace
			}
			content += String(format: "%02x", a) + rgbs + "\n"
		}

		guard let data = content.data(using: .utf8) else {
			throw PAL.CommonError.invalidString
		}
		return data
	}
}
