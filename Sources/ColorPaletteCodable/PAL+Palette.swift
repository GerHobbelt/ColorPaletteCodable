//
//  PAL+Palette.swift
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

import Foundation

public extension PAL {
	/// A color palette
	struct Palette: Equatable, Codable {
		/// The palette name
		public var name: String = ""

		/// Colors that are not assigned to a group ('global' colors)
		public var colors: [Color] = []

		/// Groups of colors
		public var groups = [Group]()

		/// Create an empty palette
		public init() {}

		/// Create a palette
		/// - Parameters:
		///   - name: The palette name
		///   - colors: The global colors
		///   - groups: The palettes groups
		public init(name: String = "", colors: [PAL.Color], groups: [PAL.Group] = []) {
			self.name = name
			self.colors = colors
			self.groups = groups
		}
	}
}

public extension PAL.Palette {
	/// Create a palette by mixing between two colors
	/// - Parameters:
	///   - name: The palette name
	///   - first: The first (starting) color for the palette
	///   - last: The second (ending) color for the palette
	///   - count: Number of colors to generate
	init(named name: String? = nil, firstColor: PAL.Color, lastColor: PAL.Color, count: Int) throws {
		self.init(
			name: name ?? "",
			colors: try PAL.Color.interpolate(firstColor: firstColor, lastColor: lastColor, count: count)
		)
	}
}

// MARK: - Conveniences

public extension PAL.Palette {
	/// Returns all the groups for the palette. Global colors are represented in a group called 'global'
	@inlinable var allGroups: [PAL.Group] {
		return [PAL.Group(name: "global", colors: self.colors)] + self.groups
	}

	/// Returns all the colors in the palette as a flat array of colors (all group information is lost)
	func allColors() -> [PAL.Color] {
		var results: [PAL.Color] = self.colors
		self.groups.forEach { results.append(contentsOf: $0.colors) }
		return results
	}

	/// Returns a copy of this palette with all colors conforming to the specific colorspace
	/// - Parameter colorspace: The colorspace to convert
	/// - Returns: A new palette
	///
	/// Throws an error if any of the palette's colors cannot be converted
	func copy(using colorspace: PAL.ColorSpace) throws -> PAL.Palette {
		let colors = try self.colors.map { try $0.converted(to: colorspace) }
		let groups = try self.groups.map { group in
			let colors = try group.colors.map { try $0.converted(to: colorspace) }
			return PAL.Group(name: group.name, colors: colors)
		}
		return PAL.Palette(name: self.name, colors: colors, groups: groups)
	}
}

// MARK: - Encoding/Decoding

public extension PAL.Palette {
	internal enum CodingKeys: String, CodingKey {
		case name
		case colors
		case groups
	}

	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
		self.colors = try container.decodeIfPresent([PAL.Color].self, forKey: .colors) ?? []
		self.groups = try container.decodeIfPresent([PAL.Group].self, forKey: .groups) ?? []
	}

	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		if !self.name.isEmpty {
			try container.encode(name, forKey: .name)
		}
		if !self.colors.isEmpty {
			try container.encode(colors, forKey: .colors)
		}
		if !self.groups.isEmpty {
			try container.encode(groups, forKey: .groups)
		}
	}
}
