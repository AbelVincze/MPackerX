//
//  CropViewController.swift
//  MPackerX
//
//  Created by Macc on 18/12/29.
//  Copyright © 2018. Macc. All rights reserved.
//

import Cocoa

class CropViewController: NSViewController {

	weak var mainViewController:ViewController!

	var targetBW:Int	= 0
	var targetH:Int		= 0
	var targetLen:Int	= 0
	var tdata:[UInt8]	= [UInt8]()		// temp data (result)
	var sourceLen:Int	= 0
	var sdata:[UInt8]	= [UInt8]()		// source data to work with

	var preview:Bool	= true

	var offset:Int		= 0
	var length:Int		= 0
	var RB:Int			= 0
	var H:Int			= 0
	var T:Int			= 0
	var L:Int			= 0
	var R:Int			= 0
	var B:Int			= 0

	var NRB:Int			= 0
	
	override public func viewDidLoad() {
		super.viewDidLoad()
		print("Crop Window Loaded")
		
	}
	override func viewWillDisappear() {
		print("Crop Window Closed")
		if mainViewController != nil {
			mainViewController.cropWindowOpened = false
			mainViewController.updateBitmapDisplay()
			mainViewController.updateUI()
			
		}
	}

	@IBOutlet weak var offsetTextField: NSTextField!
	@IBOutlet weak var offsetStepper: NSStepper!
	@IBOutlet weak var lengthTextField: NSTextField!
	@IBOutlet weak var lengthStepper: NSStepper!
	@IBOutlet weak var RBTextField: NSTextField!
	@IBOutlet weak var RBStepper: NSStepper!
    @IBOutlet weak var HTextField: NSTextField!
    @IBOutlet weak var TTextField: NSTextField!
	@IBOutlet weak var TStepper: NSStepper!
	@IBOutlet weak var LTextField: NSTextField!
	@IBOutlet weak var LStepper: NSStepper!
	@IBOutlet weak var RTextField: NSTextField!
	@IBOutlet weak var RStepper: NSStepper!
	@IBOutlet weak var BTextField: NSTextField!
	@IBOutlet weak var BStepper: NSStepper!
	
	@IBOutlet weak var previewCheckbox: NSButton!
	@IBOutlet weak var cancelButton: NSButton!
	@IBOutlet weak var applyButton: NSButton!

	@IBAction func offsetEntered(_ sender: Any) {
		setOffset( value: offsetTextField.integerValue )
		setH(); setT( value: T );  setL( value: L )
		updateUI()
		updatePreview()
	}
	@IBAction func offsetStepperClicked(_ sender: Any) {
		setOffset( value: offsetStepper.integerValue )
		setH(); setT( value: T );  setL( value: L )
		updateUI()
		updatePreview()
	}
	@IBAction func lengthEntered(_ sender: Any) {
		setLength( value: lengthTextField.integerValue )
		setH(); setT( value: T );  setL( value: L )
		updateUI()
		updatePreview()
	}
	@IBAction func lengthStepperClicked(_ sender: Any) {
		setLength( value: lengthStepper.integerValue )
		setH(); setT( value: T );  setL( value: L )
		updateUI()
		updatePreview()
	}
	@IBAction func RBEntered(_ sender: Any) {
		setRB( value: RBTextField.integerValue )
		updateUI()
		updatePreview()
	}
	@IBAction func RBStepperClicked(_ sender: Any) {
		setRB( value: RBStepper.integerValue )
		updateUI()
		updatePreview()
	}
	@IBAction func TEntered(_ sender: Any) {
		setT( value: TTextField.integerValue )
		updateUI()
		updatePreview()
	}
	@IBAction func TStepperClicked(_ sender: Any) {
		setT( value: TStepper.integerValue )
		updateUI()
		updatePreview()
	}
	@IBAction func LEntered(_ sender: Any) {
		setL( value: LTextField.integerValue )
		updateUI()
		updatePreview()
	}
	@IBAction func LStepperClicked(_ sender: Any) {
		setL( value: LStepper.integerValue )
		updateUI()
		updatePreview()
	}
	@IBAction func REntered(_ sender: Any) {
		setR( value: RTextField.integerValue )
		updateUI()
		updatePreview()
	}
	@IBAction func RStepperClicked(_ sender: Any) {
		setR( value: RStepper.integerValue )
		updateUI()
		updatePreview()
	}
	@IBAction func BEntered(_ sender: Any) {
		setB( value: BTextField.integerValue )
		updateUI()
		updatePreview()
	}
	@IBAction func BStepperClicked(_ sender: Any) {
		setB( value: BStepper.integerValue )
		updateUI()
		updatePreview()
	}
	
	@IBAction func previewCheckboxClicked(_ sender: Any) {
		preview = previewCheckbox.integerValue==1
		print("preview \( preview )")
		if preview { updatePreview() }
		else { mainViewController.updateBitmapDisplay() }	// restore original
	}
	@IBAction func cancelClicked(_ sender: Any) {
		self.view.window?.windowController?.close()
	}
	@IBAction func applyClicked(_ sender: Any) {
		crop()
		mainViewController.applyEditedData( data: tdata, bw: NRB )
		self.view.window?.windowController?.close()
	}

	
	func initCrop( data:[UInt8], bw:Int, h:Int, len:Int ) {
		print("initCrop")
		
		sourceLen	= len
		sdata		= data
		
		setOffset(value: 0)
		setLength(value: len)
		setRB( value: bw )
		//setH()
		print("RB: \(RB), H: \(H)")
		/*setT(value: 0)
		setL(value: 0)
		setR(value: 0)
		setB(value: 0)*/

		updateUI()
	}


	func setOffset( value:Int ) {
		var t = value
		if t>sourceLen-1 { t = sourceLen-1 }
		if t<0 { t = 0 }
		offset = t
		offsetStepper.integerValue = t
		let max = sourceLen-t
		if length>max { setLength( value: max) }
	}
	func setLength( value:Int ) {
		var t = value
		if t>sourceLen { t = sourceLen }
		if t<1 { t = 1 }
		length = t
		lengthStepper.integerValue = t
		let max = sourceLen-t
		if offset>max { setOffset( value: max) }
	}
	func setRB( value:Int ) {
		var t = value
		if t>1024 { t = 1024 }
		if t<1 { t = 1 }
		RB = t
		RBStepper.integerValue = t
		setH()
		setT( value: T)
		setL( value: L)
	}
	func setH() {
		H = Int( ceil( Double(length)/Double(RB) ) )
	}

	func setT( value:Int ) {
		var t = value
		if t>H-1 { t = H-1 }
		if t<0 { t = 0 }
		T = t
		let max = H-T-1
		if B>max { setB( value: max) }
		
		TStepper.integerValue = t
	}
	func setL( value:Int ) {
		var t = value
		if t>RB-1 { t = RB-1 }
		if t<0 { t = 0 }
		L = t
		let max = RB-L-1
		if R>max { setR( value: max) }

		LStepper.integerValue = t
	}
	func setR( value:Int ) {
		var t = value
		if t>RB-1 { t = RB-1 }
		if t<0 { t = 0 }
		R = t
		let max = RB-R-1
		if L>max { setL( value: max) }
		RStepper.integerValue = t
	}
	func setB( value:Int ) {
		var t = value
		if t>H-1 { t = H-1 }
		if t<0 { t = 0 }
		B = t
		let max = H-B-1
		if T>max { setT( value: max) }
		BStepper.integerValue = t
	}

	func updateUI() {
		
		offsetTextField.stringValue = String( offset )
		lengthTextField.stringValue = String( length )
		RBTextField.stringValue = String( RB )
		HTextField.stringValue = String( H )+(length%RB>0 ? "!" : "" )
		TTextField.stringValue = String( T )
		LTextField.stringValue = String( L )
		RTextField.stringValue = String( R )
		BTextField.stringValue = String( B )
	}
	func updatePreview() {
		if preview {
			crop()
			mainViewController.previewBitmapDisplay( data: tdata, bw: NRB )
		}
	}


	func crop() {
		
		var sI = offset + (T*RB) + L
		NRB = RB - L - R
		
		let maxLine = H - T - B
		
		var maxLen = NRB*maxLine
		if maxLen>length { maxLen = length }
		
		tdata = [UInt8](repeating: 0, count: maxLen )
		var tI = 0
		
		for _:Int in 0..<maxLine {
			
			for i:Int in 0..<NRB {
				
				if tI+i<maxLen && sI+i<sourceLen {
					tdata[tI+i] = sdata[sI+i]
				}
				
			}

			tI += NRB
			sI += RB
			
		}
		
	}
}

