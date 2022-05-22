//
//  Document.swift
//  Palette Viewer
//
//  Created by Darren Ford on 19/5/2022.
//

import Cocoa
import ASEPalette
import UniformTypeIdentifiers

class Document: NSDocument {

	var currentPalette: ASE.Palette?

	override init() {
	    super.init()
		// Add your subclass-specific initialization here.
	}

	override class var autosavesInPlace: Bool {
		return true
	}

	override func makeWindowControllers() {
		// Returns the Storyboard that contains your Document window.
		let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
		let windowController = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("Document Window Controller")) as! NSWindowController
		self.addWindowController(windowController)

		let vc = windowController.contentViewController as! ViewController
		vc.representedObject = self
		vc.currentPalette.palette = currentPalette
	}

//	override func data(ofType typeName: String) throws -> Data {
//		// Insert code here to write your document to data of the specified type, throwing an error in case of failure.
//		// Alternatively, you could remove this method and override fileWrapper(ofType:), write(to:ofType:), or write(to:ofType:for:originalContentsURL:) instead.
//		throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
//	}

	override func read(from url: URL, ofType typeName: String) throws {
		if typeName == UTType.clr.identifier {
			if let colorList = NSColorList(name: NSColorList.Name("Global colors"), fromFile: url.path) {
				self.currentPalette = try ASE.Palette(colorList)
			}
		}
		if typeName == UTType.aco.identifier {
			let palette = try ASE.ACOColorSwatch(fileURL: url)
			self.currentPalette = ASE.Palette()
			self.currentPalette!.colors = palette.colors
		}
		else if typeName == UTType.ase.identifier {
			self.currentPalette = try ASE.Palette(fileURL: url)
		}
		else {
			throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
		}
	}
}
