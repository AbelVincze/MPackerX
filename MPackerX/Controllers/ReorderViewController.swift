//
//  ReorderViewController.swift
//  MPackerX
//
//  Created by Macc on 18/12/29.
//  Copyright © 2018. Macc. All rights reserved.
//

import Cocoa

class ReorderViewController: NSViewController {

	weak var mainViewController:ViewController!
	
	let HORIZONTAL	= 0
	let VERTICAL	= 0
	
	var sourceBW	= 0
	var sourceH		= 0
	var sourceLen	= 0
	var sdata:[UInt8]	= [UInt8]()
	
	var BBW:Int		= 0
	var BH:Int		= 0
	var SA:Int		= 0
	
	var HT:Int		= 0
	var VT:Int		= 0
	var TA:Int		= 0
	
	var targetBW:Int	= 0
	var targetH:Int		= 0
	var targetLen:Int	= 0
	var tdata:[UInt8]	= [UInt8]()
	
	var preview:Bool	= true
	
	
	
	@IBOutlet weak var BBWTextField: NSTextField!
	@IBOutlet weak var BBWStepper: NSStepper!
	@IBOutlet weak var BHTextField: NSTextField!
	@IBOutlet weak var BHStepper: NSStepper!
	@IBOutlet weak var SASegments: NSSegmentedControl!
	
	@IBOutlet weak var HTTextField: NSTextField!
	@IBOutlet weak var HTStepper: NSStepper!
	@IBOutlet weak var VTTextField: NSTextField!
	@IBOutlet weak var VTStepper: NSStepper!
	@IBOutlet weak var TASegments: NSSegmentedControl!
	
	
	
	@IBAction func BBWEntered(_ sender: Any) {
		setBBW( value: BBWTextField.integerValue )
		updatePreview()
	}
	@IBAction func BBWStepperClicked(_ sender: Any) {
		setBBW( value: BBWStepper.integerValue )
		updateUI()
		updatePreview()
	}
	@IBAction func BHEntered(_ sender: Any) {
		setBH( value: BHTextField.integerValue )
		updatePreview()
	}
	@IBAction func BHStepperClicked(_ sender: Any) {
		setBH( value: BHStepper.integerValue )
		updateUI()
		updatePreview()
	}
	@IBAction func SASegmentClicked(_ sender: NSSegmentedControl) {
		setSA( value: sender.selectedSegment )
		updatePreview()
	}
	
	@IBAction func HTEntered(_ sender: Any) {
		setHT( value: HTTextField.integerValue )
		updatePreview()
	}
	@IBAction func HTStepperClicked(_ sender: Any) {
		setHT( value: HTStepper.integerValue )
		updateUI()
		updatePreview()
	}
	@IBAction func VTEntered(_ sender: Any) {
		setVT( value: VTTextField.integerValue )
		updatePreview()
	}
	@IBAction func VTStepperCLicked(_ sender: Any) {
		setVT( value: VTStepper.integerValue )
		updateUI()
		updatePreview()
	}
	@IBAction func TASegmentsClicked(_ sender: NSSegmentedControl) {
		setTA( value: sender.selectedSegment )
		updatePreview()
	}

	
	
	@IBOutlet weak var reorderPreviewCheckbox: NSButton!
	@IBAction func reorderPreviewClicked(_ sender: Any) {
		preview = reorderPreviewCheckbox.integerValue==1
		print("preview \( preview )")
		if preview { updatePreview() }
		else { mainViewController.updateBitmapDisplay() }	// restore original
	}
	@IBAction func cancelButtonClicked(_ sender: Any) {
		
		self.view.window?.windowController?.close()
	}
	@IBAction func applyButtonClicked(_ sender: Any) {
		reorder()
		mainViewController.applyEditedData( data: tdata, bw: HT*BBW )
		self.view.window?.windowController?.close()
	}
	
	
	
	override public func viewDidLoad() {
		super.viewDidLoad()
		print("Reorder Window Loaded")
		
	}
	override func viewWillDisappear() {
		print("Reorder Window Closed")
		if mainViewController != nil {
			mainViewController.reorderWindowOpened = false
			mainViewController.updateBitmapDisplay()
			mainViewController.updateUI()
			
		}
	}
	
	
	
	func initReorder( data:[UInt8], bw:Int, h:Int, len:Int ) {
		print("initReorder")

		sourceBW	= bw
		sourceH		= h
		sourceLen	= len
		sdata		= data
		
		setBBW( value: bw )
		setBH( value: 1 )
		setSA( value: HORIZONTAL )
		
		setHT( value: 1 )
		setVT( value: h )
		setTA( value: HORIZONTAL )
		
		updateUI()
	}
	
	func setBBW( value:Int ) {
		BBW = value
		if BBW<1 { BBW = 1 }
		if BBW>1024 { BBW = 1024 }
		BBWStepper.integerValue = BBW
	}
	func setBH( value:Int ) {
		BH = value
		if BH<1 { BH = 1 }
		if BH>8192 { BH = 8192 }
		BHStepper.integerValue = BH
	}
	func setSA( value:Int ) {
		SA = value==0 ? 0 : 1
		SASegments.selectedSegment = SA
	}
	func setHT( value:Int ) {
		HT = value
		if HT<1 { HT = 1 }
		if HT>1024 { HT = 1024 }
		HTStepper.integerValue = HT
	}
	func setVT( value:Int ) {
		VT = value
		if VT<1 { VT = 1 }
		if VT>8192 { VT = 8192 }
		VTStepper.integerValue = VT
	}
	func setTA( value:Int ) {
		TA = value==0 ? 0 : 1
		TASegments.selectedSegment = TA
	}

	func updateUI() {
		
		BBWTextField.stringValue = String( BBW )
		BHTextField.stringValue = String( BH )
		HTTextField.stringValue = String( HT )
		VTTextField.stringValue = String( VT )
		
/*	let HORIZONTAL	= 0
let VERTICAL	= 0

var sourceBW	= 0
var sourceH		= 0
var sourceLen	= 0
var sdata:[UInt8]	= [UInt8]()

var BBW:Int		= 0
var BH:Int		= 0
var SA:Int		= 0

var HT:Int		= 0
var VT:Int		= 0
var TA:Int		= 0

var targetBW:Int	= 0
var targetH:Int		= 0
var targetLen:Int	= 0

var tdata:[UInt8]	= [UInt8]()

*/
	
		
		
	}
	
	func updatePreview() {
		if preview {
			reorder()
			mainViewController.previewBitmapDisplay( data: tdata, bw: HT*BBW )
		}
	}
	
	func reorder() {
	
		
		var sX:Int = 0
		var sY:Int = 0
		var tX:Int = 0
		var tY:Int = 0
		
		let maxsX:Int = sourceBW
		let maxsY:Int = sourceH
		
		
		// most hogy tudjuk mekkora tetuletrol olvasunk, es mekkora helyre irunk, deritsuk ki osszesen hany tile-unk lesz
		
		let crop:Bool = true	// ez azt jelenti, hogy a nem egesz tile-ok torlodnek
		let PAD:UInt8 = 0x00	// ha false, akkor meg paddingot kap
		
		let maxsHT:Int = crop ? Int(floor(Double(maxsX)/Double(BBW))) :
								Int(ceil(Double(maxsX)/Double(BBW)))			// max source horizontal tiles
		let maxsVT:Int = crop ? Int(floor(Double(maxsY)/Double(BH))) :
								Int(ceil(Double(maxsY)/Double(BH)))
		
		let maxTiles:Int = maxsHT*maxsVT
		
		if TA==0 {
			// horizontal target
			if HT>maxTiles {
				setHT( value: maxTiles )
				setVT( value: 1 )
			} else {
				setVT( value: Int(ceil(Double(maxTiles)/Double(HT))) )
			}
			
		} else {
			// vertical arrengement
			if VT>maxTiles {
				setVT( value: maxTiles )
				setHT( value: 1 )
			} else {
				setHT( value: Int(ceil(Double(maxTiles)/Double(VT))) )
			}

		}
		// HT, VT fixed
		
		let maxtX:Int = HT*BBW
		let maxtY:Int = VT*BH

		var sHT:Int = 0
		var sVT:Int = 0
		var tHT:Int = 0
		var tVT:Int = 0
		
		var sI:Int = 0
		var tI:Int = 0
		var B:UInt8 = 0
		
		tdata = [UInt8](repeating: PAD, count: 65536)

		for T:Int in 0..<maxTiles {
			
			
			// transfer a single tile
			sX = sHT*BBW
			sY = sVT*BH
			
			tX = tHT*BBW
			tY = tVT*BH
			
			for y:Int in 0..<BH {
				
				for x:Int in 0..<BBW {
				
					if x+sX>=maxsX || y+sY>=maxsY || x+tX>=maxtX || y+tY>=maxtY { continue }

					sI = sX+x+maxsX*(sY+y)
					tI = tX+x+maxtX*(tY+y)
					
					if tI>=65536 { continue }
					
					B = sI<sourceLen ? sdata[sI] : PAD
					tdata[tI] = B
				}
				
				
			}
			
			if SA==0	{ sHT += 1; if sHT==maxsHT { sHT = 0; sVT += 1 } }
			else		{ sVT += 1; if sVT==maxsVT { sVT = 0; sHT += 1 } }
			if TA==0	{ tHT += 1; if tHT==HT { tHT = 0; tVT += 1 } }
			else 		{ tVT += 1; if tVT==VT { tVT = 0; tHT += 1 } }
		}
		
		tdata = [UInt8](tdata[0..<(maxtX*maxtY)])
		
		
		updateUI()
	}
}

