//
//  ACOColorSwatch+ReadWrite.swift
//
//  Created by Darren Ford on 22/5/2022.
//  Copyright © 2022 Darren Ford. All rights reserved.
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

import Foundation

internal extension ASE.ACOColorSwatch {

	// https://www.adobe.com/devnet-apps/photoshop/fileformatashtml/#50577411_pgfId-1070626

	enum Colorspace: UInt16 {
		case RGB = 0
		case HSB = 1       // Lightness is a 16-bit value from 0...10000. Chrominance components are each 16-bit values from -12800...12700. Gray values are represented by chrominance components of 0. Pure white = 10000,0,0.
		case CMYK = 2      // 0 = 100% ink. For example, pure cyan = 0,65535,65535,65535.
		case LAB = 7       // Lightness is a 16-bit value from 0...10000. Chrominance components are each 16-bit values from -12800...12700. Gray values are represented by chrominance components of 0. Pure white = 10000,0,0.
		case Grayscale = 8 // The first value in the color data is the gray value, from 0...10000.
	}


	/// Load a palette from a .ase palette file
	///
	/// Implementation based on the breakdown from [here](http://www.selapa.net/swatches/colors/fileformats.php#adobe_ase)
	mutating func _load(fileURL: URL) throws {
		guard let inputStream = InputStream(fileAtPath: fileURL.path) else {
			ase_log.log(.error, "Unable to load .ase file")
			throw ASE.CommonError.unableToLoadFile
		}
		inputStream.open()
		try self._load(inputStream: inputStream)
	}

	/// Load from data
	///
	/// Implementation based on the breakdown from [here](http://www.selapa.net/swatches/colors/fileformats.php#adobe_ase)
	mutating func _load(data: Data) throws {
		let inputStream = InputStream(data: data)
		inputStream.open()
		try self._load(inputStream: inputStream)
	}

	/// Load from an InputStream
	///
	/// Implementation based on the breakdown from [here](http://www.selapa.net/swatches/colors/fileformats.php#adobe_ase)
	mutating func _load(inputStream: InputStream) throws {
		// NOTE: Assumption here is that `inputStream` is already open
		// If the input stream isn't open, the reading will hang.

		var v1Colors = [ASE.Color]()
		var v2Colors = [ASE.Color]()

		try (1 ... 2).forEach { type in
			do {
				let version: UInt16 = try readIntegerBigEndian(inputStream)
				if version != type {
					throw ASE.CommonError.invalidVersion
				}
			}
			catch {
				// Version 1 file only (no data after v1 section)
				self.colors = v1Colors
				return
			}

			let numberOfColors: UInt16 = try readIntegerBigEndian(inputStream)

			try (0 ..< numberOfColors).forEach { index in

				let colorSpace: UInt16 = try readIntegerBigEndian(inputStream)
				guard let cs = Colorspace(rawValue: colorSpace) else {
					throw ASE.CommonError.unsupportedColorSpace
				}

				let c0: UInt16 = try readIntegerBigEndian(inputStream)
				let c1: UInt16 = try readIntegerBigEndian(inputStream)
				let c2: UInt16 = try readIntegerBigEndian(inputStream)
				let c3: UInt16 = try readIntegerBigEndian(inputStream)

				let name: String = try {
					if type == 2 {
						return try readPascalStyleUnicodeString(inputStream)
					}
					return ""
				}()

				var color: ASE.Color

				switch cs {
				case .RGB:
					color = try ASE.Color(name: name, model: .RGB, colorComponents: [Float32(c0) / 65535.0, Float32(c1) / 65535.0, Float32(c2) / 65535.0])
				case .CMYK:
					color = try ASE.Color(
						name: name,
						model: .CMYK,
						colorComponents: [
							Float32(65535 - c0) / 65535.0,
							Float32(65535 - c1) / 65535.0,
							Float32(65535 - c2) / 65535.0,
							Float32(65535 - c3) / 65535.0
						])
				case .Grayscale:
					assert(c0 <= 10000)
					color = try ASE.Color(name: name, model: .Gray, colorComponents: [Float32(c0) / 10000])

				case .LAB:
					throw ASE.CommonError.unsupportedColorSpace
				case .HSB:
					throw ASE.CommonError.unsupportedColorSpace
				}

				if type == 1 {
					v1Colors.append(color)
				}
				else if type == 2 {
					v2Colors.append(color)
				}
				else {
					throw ASE.CommonError.invalidVersion
				}
			}
		}

		// If we got here, then we have a v2 file
		self.colors = v2Colors
	}
}

extension ASE.ACOColorSwatch {
	func _data() throws -> Data {
		var outputData = Data(capacity: 1024)

		// Write out both v1 and v2 colors
		try (1 ... 2).forEach { type in
			outputData.append(try writeUInt16BigEndian(UInt16(type)))

			outputData.append(try writeUInt16BigEndian(UInt16(self.colors.count)))

			for color in self.colors {
				var c0: UInt16 = 0
				var c1: UInt16 = 0
				var c2: UInt16 = 0
				var c3: UInt16 = 0

				let acoModel: Colorspace
				switch color.model {
				case .RGB:
					acoModel = .RGB
					c0 = UInt16(65535 * color.colorComponents[0])
					c1 = UInt16(65535 * color.colorComponents[1])
					c2 = UInt16(65535 * color.colorComponents[2])
				case .CMYK:
					acoModel = .CMYK
					c0 = UInt16(65535 - UInt16(65535 * color.colorComponents[0]))
					c1 = UInt16(65535 - UInt16(65535 * color.colorComponents[1]))
					c2 = UInt16(65535 - UInt16(65535 * color.colorComponents[2]))
					c3 = UInt16(65535 - UInt16(65535 * color.colorComponents[3]))
				case .Gray:
					acoModel = .CMYK
					c0 = UInt16(10000 * color.colorComponents[0])

				case .LAB:
					throw ASE.CommonError.unsupportedColorSpace
				}

				outputData.append(try writeUInt16BigEndian(UInt16(acoModel.rawValue)))

				outputData.append(try writeUInt16BigEndian(c0))
				outputData.append(try writeUInt16BigEndian(c1))
				outputData.append(try writeUInt16BigEndian(c2))
				outputData.append(try writeUInt16BigEndian(c3))

				if type == 2 {
					outputData.append(try writePascalStyleUnicodeString(color.name))
				}
			}
		}
		return outputData
	}
}
