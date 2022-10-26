//
//  PreviewViewController.swift
//
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

import Cocoa
import Quartz

import ColorPaletteCodable

class PreviewViewController: NSViewController, QLPreviewingController {
	@IBOutlet var gradientView: GradientDisplayView!

	var gradient: PAL.Gradient?

	override var nibName: NSNib.Name? {
		return NSNib.Name("PreviewViewController")
	}

	override func loadView() {
		super.loadView()
		// Do any additional setup after loading the view.
	}

	/*
	 * Implement this method and set QLSupportsSearchableItems to YES in the Info.plist of the extension if you support CoreSpotlight.
	 *
	 func preparePreviewOfSearchableItem(identifier: String, queryString: String?, completionHandler handler: @escaping (Error?) -> Void) {
	 // Perform any setup necessary in order to prepare the view.

	 // Call the completion handler so Quick Look knows that the preview is fully loaded.
	 // Quick Look will display a loading spinner while the completion handler is not called.
	 handler(nil)
	 }
	 */

	func preparePreviewOfFile(at url: URL, completionHandler handler: @escaping (Error?) -> Void) {
		// Add the supported content types to the QLSupportedContentTypes array in the Info.plist of the extension.

		// Perform any setup necessary in order to prepare the view.

		// Call the completion handler so Quick Look knows that the preview is fully loaded.
		// Quick Look will display a loading spinner while the completion handler is not called.

		do {
			try self.configure(for: url)
			self.gradientView.gradient = self.gradient
			handler(nil)
		}
		catch {
			handler(error)
		}

		handler(nil)
	}

	func configure(for url: URL) throws {
		self.gradient = try PAL.Gradient.Decode(from: url)
	}
}

class GradientDisplayView: NSView {
	override var isOpaque: Bool { false }

	private var _gradient: CGGradient?

	var gradient: PAL.Gradient? {
		didSet {
			self._gradient = gradient?.cgGradient()
		}
	}

	override func draw(_ dirtyRect: NSRect) {
		super.draw(dirtyRect)

		guard
			let g = _gradient,
			let ctx = NSGraphicsContext.current?.cgContext
		else {
			return
		}

		/*
		 ┌────────────────────┐
		 │                    │█
		 │                    │█
		 │                    │█
		 │                    │█
		 │                    │█
		 └────────────────────┘█
		  ██████████████████████
		 */

		// Give a 1px breathing space around the outside of the drawing
		let insetRect = self.bounds.insetBy(dx: 1, dy: 1)

		let dimension = min(insetRect.width / 6, insetRect.height / 6)

		var horizontalRect = insetRect
		do {
			horizontalRect.size.height = dimension

			// The drawing rectangle, WITHOUT the shadow
			let coreRect = CGRect(
				x: horizontalRect.origin.x,
				y: horizontalRect.origin.y + 3,
				width: horizontalRect.width - 3,
				height: horizontalRect.height - 3
			)

			// The path for the gradient content
			let boundsPath = CGPath(roundedRect: coreRect, cornerWidth: 4, cornerHeight: 4, transform: nil)

			// Draw the gradient within the bounds path
			ctx.savingState {
				$0.addPath(boundsPath)
				$0.clip()
				$0.drawLinearGradient(
					g,
					start: .zero,
					end: CGPoint(x: horizontalRect.width, y: 0),
					options: [.drawsAfterEndLocation, .drawsBeforeStartLocation]
				)
			}

			// Draw a border around the gradient path
			ctx.savingState {
				$0.addPath(boundsPath)
				let alpha: Double = NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast ? 1.0 : 0.1
				$0.setStrokeColor(NSColor.textColor.withAlphaComponent(alpha).cgColor)
				$0.setLineWidth(1)
				$0.strokePath()
			}

			// Add a shadow to the gradient path.
			ctx.savingState {
				// Add a path around the bounds
				$0.addPath(CGPath(rect: self.bounds, transform: nil))
				// Add another path around the bounds path
				$0.addPath(boundsPath)
				// Clip the drawing using evenOdd, which means that the clip path is the DIFFERENCE between the two paths
				$0.clip(using: .evenOdd)

				// Now, draw the shadow
				$0.addPath(boundsPath)
				$0.setFillColor(CGColor.white.copy(alpha: 0.3)!)
				$0.setShadow(offset: CGSize(width: 2, height: -2), blur: 3, color: .black)
				$0.fillPath()
			}
		}

		var verticalRect = insetRect
		do {
			verticalRect.origin.x = insetRect.maxX - dimension - 3
			verticalRect.origin.y = dimension + 16
			verticalRect.size.width = dimension
			verticalRect.size.height = insetRect.maxY - dimension - 16

			// The drawing rectangle, WITHOUT the shadow
			let coreRect = CGRect(
				x: verticalRect.origin.x,
				y: verticalRect.origin.y + 3,
				width: verticalRect.width - 3,
				height: verticalRect.height - 3
			)

			// The path for the gradient content
			let boundsPath = CGPath(roundedRect: verticalRect, cornerWidth: 4, cornerHeight: 4, transform: nil)

			// Draw the gradient within the bounds path
			ctx.savingState {
				$0.addPath(boundsPath)
				$0.clip()
				$0.drawLinearGradient(
					g,
					start: CGPoint(x: 0, y: coreRect.minY),
					end: CGPoint(x: 0, y: coreRect.maxY),
					options: [.drawsAfterEndLocation, .drawsBeforeStartLocation]
				)
			}

			// Draw a border around the gradient path
			ctx.savingState {
				$0.addPath(boundsPath)
				let alpha: Double = NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast ? 1.0 : 0.1
				$0.setStrokeColor(NSColor.textColor.withAlphaComponent(alpha).cgColor)
				$0.setLineWidth(1)
				$0.strokePath()
			}

			// Add a shadow to the gradient path.
			ctx.savingState {
				// Add a path around the bounds
				$0.addPath(CGPath(rect: self.bounds, transform: nil))
				// Add another path around the bounds path
				$0.addPath(boundsPath)
				// Clip the drawing using evenOdd, which means that the clip path is the DIFFERENCE between the two paths
				$0.clip(using: .evenOdd)

				// Now, draw the shadow
				$0.addPath(boundsPath)
				$0.setFillColor(CGColor.white.copy(alpha: 0.3)!)
				$0.setShadow(offset: CGSize(width: 2, height: -2), blur: 3, color: .black)
				$0.fillPath()
			}
		}

		do {
			let radialRect = CGRect(
				x: horizontalRect.minX,
				y: dimension + 3,
				width: verticalRect.maxX - dimension - 16,
				height: verticalRect.maxY - dimension - 16)

			let w = min(radialRect.width - 3, radialRect.height - 3)

			let midx = (radialRect.width - w) / 2
			let midy = (radialRect.height - w) / 2

			// The drawing rectangle, WITHOUT the shadow
			let coreRect = CGRect(
				x: radialRect.origin.x + midx,
				y: radialRect.origin.y + 16 + midy,
				width: w,
				height: w
			)

			// The path for the gradient content
			let boundsPath = CGPath(ellipseIn: coreRect, transform: nil)

			// Draw the gradient within the bounds path
			ctx.savingState {
				$0.addPath(boundsPath)
				$0.clip()
				$0.drawRadialGradient(
					g,
					startCenter: CGPoint(x: coreRect.midX, y: coreRect.midY),
					startRadius: 0,
					endCenter: CGPoint(x: coreRect.midX, y: coreRect.midY),
					endRadius: max(coreRect.width, coreRect.height) / 2,
					options: [.drawsAfterEndLocation, .drawsBeforeStartLocation]
				)
			}

			// Add a shadow to the gradient path.
			ctx.savingState {
				// Add a path around the bounds
				$0.addPath(CGPath(rect: self.bounds, transform: nil))
				// Add another path around the bounds path
				$0.addPath(boundsPath)
				// Clip the drawing using evenOdd, which means that the clip path is the DIFFERENCE between the two paths
				$0.clip(using: .evenOdd)

				// Now, draw the shadow
				$0.addPath(boundsPath)
				$0.setFillColor(CGColor.white.copy(alpha: 0.3)!)
				$0.setShadow(offset: CGSize(width: 2, height: -2), blur: 3, color: .black)
				$0.fillPath()
			}

			// Draw a border around the gradient path
			ctx.savingState {
				$0.addPath(boundsPath)
				let alpha: Double = NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast ? 1.0 : 0.1
				$0.setStrokeColor(NSColor.textColor.withAlphaComponent(alpha).cgColor)
				$0.setLineWidth(1)
				$0.strokePath()
			}
		}

	}
}

extension CGContext {
	@inlinable func savingState(_ block: (CGContext) -> Void) {
		self.saveGState()
		defer { self.restoreGState() }
		block(self)
	}
}