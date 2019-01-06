//
//  ViewController.swift
//  MPackerX
//
//  Created by Macc on 18/12/27.
//  Copyright © 2018. Macc. All rights reserved.
//

/*

    - manage menu visibility
    - manage layout visibility
 
    - manage controls, packer settings
 
 
 
 
*/


import Cocoa

// custom NSView class to fix imageInterpolations
class BitmapImageView: NSImageView {
    override func draw(_ dirtyRect: NSRect ) {
        NSGraphicsContext.current!.imageInterpolation = NSImageInterpolation.none
        super.draw( dirtyRect )
    }
}

// custom NSView class for enable dragging dragging
class DragView:NSView {
    //var filePath: String?

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        if #available(OSX 10.13, *) {
            registerForDraggedTypes([NSPasteboard.PasteboardType.URL, NSPasteboard.PasteboardType.fileURL])
        } else {
            // Fallback on earlier versions
        }
    }
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        //if checkExtension(sender) == true {
        //    self.layer?.backgroundColor = NSColor.blue.cgColor
        // all extensions
        return .copy
        //} else {
        //    return NSDragOperation()
        //}
    }
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        print("perform drag")
        guard let pasteboard = sender.draggingPasteboard.propertyList(forType: NSPasteboard.PasteboardType(rawValue: "NSFilenamesPboardType")) as? NSArray,
            let path = pasteboard[0] as? String
            else { return false }
        
        let vc = self.window?.contentViewController as! ViewController
        vc.openFile( file: path )
        return true
    }

}

class ExportPanel: NSPanel {
}

// creating a new split function for multiple separators...
extension Collection where Element: Equatable {
	func split<S: Sequence>(separators: S)->[SubSequence] where Element == S.Element {
		return split { separators.contains($0) }
	}
}

class ViewController: NSViewController {
    // ------------------------------------------------------------------------------------------------ VARIABLES
    let mpackerxapp = MPackerXApp()
    var appdelegate:AppDelegate? = nil
	
	var exportWindowController:NSWindowController!
	var exportViewController:ExportViewController!
	var reorderWindowController:NSWindowController!
	var reorderViewController:ReorderViewController!
	var cropWindowController:NSWindowController!
	var cropViewController:CropViewController!

    // ------------------------------------------------------------------------------------------------ OVERRIDES
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        // set scroll position to top!
        if let documentView = bitmapScrollView.documentView {
            documentView.scroll(NSPoint(x: 0, y: documentView.bounds.size.height))
        }
        // disable interpolation for our bitmap view to get clear pixel edged!
        //bitmapView.imageScaling = NSImageScaling.scaleNone
        // access our delegate!
        appdelegate = NSApplication.shared.delegate as? AppDelegate
        appdelegate?.setViewController(vc: self)
        
        mpackerxapp.initApp()   // init app
        initBWStepper()
		initMAXDStepper()
		initMAXCStepper()
		
		
		
        
        updateUI()              // init UI
        updateBitmapDisplay()   // Display something


		
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    // ------------------------------------------------------------------------------------------------ @IBOutlets MENU
    //@IBOutlet weak var newMenuItem: NSMenuItem!

    
    // ------------------------------------------------------------------------------------------------ @IBActions MENU

    @IBAction func fileNewMenuItemClicked(_ sender: Any ) {
        resetApp()
    }
	@IBAction func fileOpenMenuItemClicked(_ sender: Any ) {
		openBinary()
	}
	@IBAction func fileAppendMenuItemClicked(_ sender: Any ) {
		appendBinary()
	}
	@IBAction func fileSaveAsMenuItemClicked(_ sender: Any ) {
        saveAs()
    }
    @IBAction func fileImportExportMenuItemClicked(_ sender: Any ) {
        openExportWindow()
		//updateUI()
    }
    // ---------------------------------------------------------------
    @IBAction func editSelectAllMenuItemClicked(_ sender: Any ) {
		if exportWindowOpened {
			exportViewController.importExportTextView.selectAll(self)
		}
    }

    @IBAction func dataInvertMenuItemClicked(_ sender: Any ) {
        mpackerxapp.invertData()
        updateBitmapDisplay()
    }
    @IBAction func dataReorderMenuItemClicked(_ sender: Any ) {
        openReorderWindow()
    }
    @IBAction func dataCropMenuItemClicked(_ sender: Any ) {
        openCropWindow()
    }
    // ---------------------------------------------------------------    
    @IBAction func packMenuItemClicked(_ sender: Any ) {
        packData()
    }
    @IBAction func unpackMenuItemClicked(_ sender: Any ) {
		unpackData()
    }
    @IBAction func bmodeMenuItemClicked(_ sender: Any ) {
        print("bmodeMenuItemClicked")
    }
    @IBAction func autoRepackMenuItemClicked(_ sender: NSMenuItem ) {
        print("autoRepackMenuItemClicked")
        sender.state = sender.state == NSControl.StateValue.on ? NSControl.StateValue.off : NSControl.StateValue.on
        AUTOREPACK = sender.state == NSControl.StateValue.on ? true : false
		if AUTOREPACK { packData() }
    }
    @IBAction func autoUnpackMenuItemClicked(_ sender: NSMenuItem ) {
        print("autoUnpackMenuItemClicked")
        sender.state = sender.state == NSControl.StateValue.on ? NSControl.StateValue.off : NSControl.StateValue.on
        AUTOUNPACK = sender.state == NSControl.StateValue.on ? true : false

    }
	@IBAction func defaultSettingsMenuItemClicked(_ sender: Any ) {
		defaultSettings()
	}
	@IBAction func autoUpdateSettingsMenuItemClicked(_ sender: NSMenuItem ) {
		//autoUpdateSettings()
		sender.state = sender.state == NSControl.StateValue.on ? NSControl.StateValue.off : NSControl.StateValue.on
		mpackerxapp.msettings.autoUpdate = sender.state == NSControl.StateValue.on ? true : false
	}
/*
 @IBAction func autoCompressMenuItemSelected(_ sender: NSMenuItem) {
 print("autoCompress")
 sender.state = sender.state == NSControl.StateValue.on ? NSControl.StateValue.off : NSControl.StateValue.on
 autoCompress = sender.state == NSControl.StateValue.on ? true : false
 if haveCompressedData && autoCompress {
 compressData()
 updateDisplay()
 }
 }

 */
    // ------------------------------------------------------------------------------------------------ @IBOutlets UI

	@IBOutlet weak var infoTextField: NSTextField!
	@IBOutlet weak var markButton: NSButton!
	@IBOutlet weak var markButtonImageCell: NSButtonCell!
	
    @IBOutlet weak var bitmapView: BitmapImageView!
    @IBOutlet weak var bitmapScrollView: NSScrollView!
    @IBOutlet weak var openButton: NSButton!
    @IBOutlet weak var unpackButton: NSButton!
    @IBOutlet weak var packButton: NSButton!
    @IBOutlet weak var LUTCheckbox: NSButton!
    @IBOutlet weak var NEGCheckbox: NSButton!
    @IBOutlet weak var reorderCheckbox: NSButton!
    @IBOutlet weak var BWTextField: NSTextField!
    @IBOutlet weak var BWStepper: NSStepper!
    @IBOutlet weak var heightTextField: NSTextField!
	@IBOutlet weak var MAXDTextField: NSTextField!
	@IBOutlet weak var MAXDStepper: NSStepper!
	@IBOutlet weak var MAXCTextField: NSTextField!
	@IBOutlet weak var MAXCStepper: NSStepper!

    // ------------------------------------------------------------------------------------------------ @IBActions UI

	@IBAction func markButtonClicked(_ sender: Any) {
		print("Mark Button CLicked")
		discardPackedDisplay()
	}
	@IBAction func openButtonClicked(_ sender: Any) {
        openBinary()
    }
    @IBAction func packButtonClicked(_ sender: Any) {
		packData()
    }
    @IBAction func unpackButtonClicked(_ sender: Any) {
		unpackData()
    }
    @IBAction func LUTCheckboxClicked(_ sender: Any) {
        let stat = LUTCheckbox.intValue>0
        mpackerxapp.msettings.USELOOKUP = stat
        packSettingChanged()
    }
    @IBAction func NEGCheckboxClicked(_ sender: Any) {
        let stat = NEGCheckbox.intValue>0
        mpackerxapp.msettings.NEGCHECK = stat
        packSettingChanged()
    }
	@IBAction func reorderCheckboxClicked(_ sender: Any) {
        let stat = reorderCheckbox.intValue>0
        mpackerxapp.msettings.DIR = stat
        packSettingChanged()
    }
	@IBAction func BWEntered(_ sender: Any) {
		let ov = mpackerxapp.msettings.BW
		var nv = BWTextField.integerValue
		if nv>256 { nv=256; BWTextField.integerValue=nv }
		if nv<1  { nv=1;  BWTextField.integerValue=nv }
		//setH()
		BWStepper.integerValue = nv
		mpackerxapp.msettings.BW = nv
		if ov != nv {
			mpackerxapp.setH()
			packSettingChanged()
		}
	}
    @IBAction func BWStepperClicked(_ sender: Any) {
		let nv = BWStepper.integerValue
		if mpackerxapp.msettings.BW != nv {
			mpackerxapp.msettings.BW = nv
        	BWTextField.integerValue = mpackerxapp.msettings.BW
			mpackerxapp.setH()
			packSettingChanged()
		}
    }
	@IBAction func MAXDEntered(_ sender: Any) {
		let ov = mpackerxapp.msettings.MAXD
		var nv = MAXDTextField.integerValue
		if nv>32767 { nv=32767; MAXDTextField.integerValue=nv }
		if nv<1  { nv=1;  MAXDTextField.integerValue=nv }
		//setH()
		MAXDStepper.integerValue = nv
		mpackerxapp.msettings.MAXD = nv
		if ov != nv { packSettingChanged() }
	}
	@IBAction func MAXDStepperClicked(_ sender: Any) {
		let nv = MAXDStepper.integerValue
		if mpackerxapp.msettings.MAXD != nv {
			mpackerxapp.msettings.MAXD = nv
			MAXDTextField.integerValue = mpackerxapp.msettings.MAXD
			//setH()
			packSettingChanged()
		}
	}
    @IBAction func MAXCEntered(_ sender: Any) {
		let ov = mpackerxapp.msettings.MAXC
		var nv = MAXCTextField.integerValue
		if nv>32767 { nv=32767; MAXCTextField.integerValue=nv }
		if nv<1  { nv=1;  MAXCTextField.integerValue=nv }
		//setH()
		MAXCStepper.integerValue = nv
		mpackerxapp.msettings.MAXC = nv
		if ov != nv { packSettingChanged() }
    }
	@IBAction func MAXCStepperClicked(_ sender: Any) {
		let nv = MAXCStepper.integerValue
		if mpackerxapp.msettings.MAXC != nv {
			mpackerxapp.msettings.MAXC = nv
			MAXCTextField.integerValue = mpackerxapp.msettings.MAXC
			//setH()
			packSettingChanged()
		}
	}


	func initBWStepper() {
		BWStepper.minValue = 1
		BWStepper.maxValue = 256
		BWStepper.integerValue = mpackerxapp.msettings.BW
		
	}
	func initMAXDStepper() {
		MAXDStepper.minValue = 1
		MAXDStepper.maxValue = 32767
		MAXDStepper.integerValue = mpackerxapp.msettings.MAXD
		
	}
	func initMAXCStepper() {
		MAXCStepper.minValue = 1
		MAXCStepper.maxValue = 32767
		MAXCStepper.integerValue = mpackerxapp.msettings.MAXC
		
	}

    // ------------------------------------------------------------------------------------------------ FUNCTIONS
	
	let NODISPLAY = 0
    let LOADEDDISPLAY = 1
    let UNPACKEDDISPLAY = 2
    let IMPORTEDDISPLAY = 3
    let PACKEDDISPLAY = 4
    
    var AUTOUNPACK:Bool = true
    var AUTOREPACK:Bool = false

    var workingInBackground:Bool = false
    var displayMode:Int = 0
	
	var exportWindowOpened:Bool = false
	var reorderWindowOpened:Bool = false
	var cropWindowOpened:Bool = false
    //var BW:Int = 16
    
    func updateUI() {
        print("updateUI")
        
        // enable/disable menu items:
        /*
         minden action disabled ha working in background
         
         File New   - csak ha van betoltott/importalt adat (de minek nullazunk?) isNew==false
         File Open  - mindig hasznalhato (kiveve background working)
         File SaveAs - csak akkor, ha van megnyitva valami
         File Print - csak ha van megnyitva valami
 
         Edit SelectAll - csak ha textboxban vagyunk, vagy Editor ablakban
         Data menu  - csak ha van betoltott adat, es opened nezetben vagyunk
         
        */
        let isNew = !mpackerxapp.haveodata
        let packed = displayMode == PACKEDDISPLAY
		let canUnpack = !isNew && !mpackerxapp.odataisnotpacked && !packed
		let mainf = !reorderWindowOpened && !cropWindowOpened
		
        appdelegate?.newMenuItem.isEnabled      = !isNew && mainf
        appdelegate?.openMenuItem.isEnabled     = true && mainf
		appdelegate?.openRecentMenuItem.isEnabled = true && mainf
		appdelegate?.appendMenuItem.isEnabled	= !isNew && mainf
		appdelegate?.saveAsMenuItem.isEnabled   = !isNew && mainf
		appdelegate?.importExportMenuItem.isEnabled   = true	//!exportWindowOpened
		appdelegate?.selectAllMenuItem.isEnabled = exportWindowOpened
		
        appdelegate?.packMenuItem.isEnabled     = !isNew && mainf
        packButton.isEnabled                    = !isNew && mainf
        appdelegate?.unpackMenuItem.isEnabled   = canUnpack && mainf
        unpackButton.isEnabled                  = canUnpack && mainf

        appdelegate?.invertMenuItem.isEnabled   = !isNew && !packed && mainf
        appdelegate?.reorderMenuItem.isEnabled  = !isNew && !packed && mainf
        appdelegate?.cropMenuItem.isEnabled     = !isNew && !packed && mainf
		
		openButton.isEnabled					= mainf
		BWTextField.isEnabled					= mainf
		BWStepper.isEnabled						= mainf
		MAXDTextField.isEnabled					= mainf
		MAXDStepper.isEnabled					= mainf
		MAXCTextField.isEnabled					= mainf
		MAXCStepper.isEnabled					= mainf
		LUTCheckbox.isEnabled					= mainf
		NEGCheckbox.isEnabled					= mainf
		reorderCheckbox.isEnabled				= mainf
        
        // Update visible values with the stored settings
        BWTextField.stringValue					= String( mpackerxapp.msettings.BW )
        BWStepper.integerValue                  = mpackerxapp.msettings.BW
		
		let padding:Int = mpackerxapp.msettings.H * mpackerxapp.msettings.BW - mpackerxapp.odata.count
		heightTextField.stringValue				= String( mpackerxapp.msettings.H ) + ( padding>0 ? "!" : "" )
        
		MAXDTextField.stringValue				= String( mpackerxapp.msettings.MAXD )
		MAXDStepper.integerValue				= mpackerxapp.msettings.MAXD
		MAXCTextField.stringValue				= String( mpackerxapp.msettings.MAXC )
		MAXCStepper.integerValue				= mpackerxapp.msettings.MAXC
		
        appdelegate?.autoUnpackMenuItem.state = AUTOUNPACK ? NSControl.StateValue.on : NSControl.StateValue.off
        appdelegate?.autoRepackMenuItem.state = AUTOREPACK ? NSControl.StateValue.on : NSControl.StateValue.off
        //appdelegate?.autoUnpackMenuItem.isEnabled   = AUTOUNPACK
        //appdelegate?.autoRepackMenuItem.isEnabled   = AUTOREPACK
		LUTCheckbox.intValue                    = mpackerxapp.msettings.USELOOKUP ? 1:0
        NEGCheckbox.intValue                    = mpackerxapp.msettings.NEGCHECK ? 1:0
        reorderCheckbox.intValue                = mpackerxapp.msettings.DIR ? 1:0


		switch displayMode {
		case LOADEDDISPLAY:
			infoTextField.stringValue = mpackerxapp.loadedInfo
			markButtonImageCell.image = NSImage(named: "loadedMark" )
		case IMPORTEDDISPLAY:
			infoTextField.stringValue = mpackerxapp.importedInfo
			markButtonImageCell.image = NSImage(named: "importedMark" )
		case UNPACKEDDISPLAY:
			infoTextField.stringValue = mpackerxapp.unpackedInfo
			markButtonImageCell.image = NSImage(named: "unpackedMark" )
		case PACKEDDISPLAY:
			infoTextField.stringValue = mpackerxapp.packedInfo
			markButtonImageCell.image = NSImage(named: "packedMark" )
		default:
			infoTextField.stringValue = mpackerxapp.defaultLoadedInfo
			markButtonImageCell.image = NSImage(named: "loadedMark" )
		}
		
		
    }
    func updateBitmapDisplay() {
        print("updateBitmapDisplay")
        
        let memory = UnsafeMutablePointer<UInt8>.allocate(capacity: 65536)
        let pixels = UnsafePointer<UInt8>.init( memory )
        
        for i:Int in 0..<65536 { memory[i] = 0x55 }
        
        switch displayMode {
        case LOADEDDISPLAY, UNPACKEDDISPLAY, IMPORTEDDISPLAY:
            let length = mpackerxapp.odata.count
            
            var i:Int = 0
            var bin:Int = 0
			let bw = mpackerxapp.msettings.BW
            while bin<length && i<65536 {
                //memory[i] = UInt8.random(in: 0 ..< 255)
                memory[i] = mpackerxapp.odata[bin]
                i += 1
                bin += 1
                /*if( bin%mpackerxapp.msettings.BW==0 ) {
                    i += (32-mpackerxapp.msettings.BW)
                }*/
				if bw<=32 {
					if bin%bw==0 { i += (32-bw) }
				} else {
					if i%32==0 { bin += (bw-32) }
				}
            }
        case PACKEDDISPLAY:
            for i:Int in 0..<mpackerxapp.pdata.count {
                memory[i] = mpackerxapp.pdata[i]
            }
        default:
            print("nothing to display?")
        }
        

        let size:NSSize = NSSize( width: 256, height: 2048 )
        bitmapView.image = imageFromPixels(size: size, pixels: pixels , width: Int(256), height: Int(2048) )
        
        if exportWindowOpened { refreshExportWindowContent() }
        
    }
	func applyEditedData( data:[UInt8], bw:Int ) {
		mpackerxapp.setData( data: data, bw: bw)
		displayMode = LOADEDDISPLAY
	}
	func previewBitmapDisplay( data:[UInt8], bw:Int ) {
		print("updateBitmapDisplay")
		
		let memory = UnsafeMutablePointer<UInt8>.allocate(capacity: 65536)
		let pixels = UnsafePointer<UInt8>.init( memory )
		
		for i:Int in 0..<65536 { memory[i] = 0x55 }
		
		let length = data.count
		
		var i:Int = 0
		var bin:Int = 0
		while bin<length && i<65536 {
			//memory[i] = UInt8.random(in: 0 ..< 255)
			memory[i] = data[bin]
			i += 1
			bin += 1
			if bw<=32 {
				if bin%bw==0 { i += (32-bw) }
			} else {
				if i%32==0 { bin += (bw-32) }
			}
		}
		
		let size:NSSize = NSSize( width: 256, height: 2048 )
		bitmapView.image = imageFromPixels(size: size, pixels: pixels , width: Int(256), height: Int(2048) )
		
		//if exportWindowOpened { refreshExportWindowContent() }
		
	}
	func discardPackedDisplay() {
		if displayMode != PACKEDDISPLAY { return }
		
		switch mpackerxapp.odatatype {
		case mpackerxapp.LOADEDDATA:
			displayMode = LOADEDDISPLAY
		case mpackerxapp.UNPACKEDDATA:
			displayMode = UNPACKEDDISPLAY
		case mpackerxapp.IMPORTEDDATA:
			displayMode = IMPORTEDDISPLAY
		default:
			displayMode = LOADEDDISPLAY
		}
		mpackerxapp.havepdata = false
		
		updateUI()
		updateBitmapDisplay()
		
	}
	func resetApp() {
		mpackerxapp.resetApp()
		displayMode = NODISPLAY
		updateUI()
		updateBitmapDisplay()
	}
	
    func imageFromPixels(size: NSSize, pixels: UnsafePointer<UInt8>, width: Int, height: Int)-> NSImage { //No need to pass another CGImage
        let rgbColorSpace = CGColorSpaceCreateDeviceGray()
        let bitmapInfo:CGBitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue)
        let bitsPerComponent = 1 //number of bits in UInt8
        let bitsPerPixel = 1 * bitsPerComponent //ARGB uses 4 components
        let bytesPerRow = bitsPerPixel * width / 8 // bitsPerRow / 8 (in some cases, you need some paddings)
        let providerRef = CGDataProvider(
            data: NSData(bytes: pixels, length: height * bytesPerRow) //Do not put `&` as pixels is already an `UnsafePointer`
        )
        
        let cgim = CGImage(
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bitsPerPixel: bitsPerPixel,
            bytesPerRow: bytesPerRow, //->not bits
            space: rgbColorSpace,
            bitmapInfo: bitmapInfo,
            provider: providerRef!,
            decode: nil,
            shouldInterpolate: false,
            intent: CGColorRenderingIntent.defaultIntent
        )
        return NSImage(cgImage: cgim!, size: size)
    }
    func openBinary()->Int {
        
		let file:String = openDialog( title: "Open Binary" )
        return openFile( file: file )
    }
	func openFile( file:String )->Int {
		if file.count>0 {
			if mpackerxapp.loadFile(file: file)==0 {
				print("successfully loaded, try to unpack")
				//if autodecompress -> try to autoDecompress
				displayMode = LOADEDDISPLAY
				
				if AUTOUNPACK {
					if mpackerxapp.unpackData()==0 {
						displayMode = UNPACKEDDISPLAY
					}
				}
				updateBitmapDisplay()
				
				addRecentDoc( file: file )
			}
			updateUI()
			
			return 0
		}
		return -1
	}
	func appendBinary()->Int {
		
		let file:String = openDialog( title: "Append Binary" )
		return appendFile( file: file )
	}
	func appendFile( file:String )->Int {
		if file.count>0 {
			if mpackerxapp.appendFile(file: file) == 0 {
				updateUI()
				updateBitmapDisplay()
				addRecentDoc( file: file )
			}
			return 0
		}
		return -1
	}
	func addRecentDoc( file: String ) {
		// Add successfully opened file to the recent files menu
		NSDocumentController.shared.noteNewRecentDocumentURL(URL(fileURLWithPath: file))
	}
	func openDialog( title:String )->String {
        let dialog = NSOpenPanel()
        
        dialog.title                   = title
        dialog.showsResizeIndicator    = true
        dialog.showsHiddenFiles        = false
        dialog.canChooseDirectories    = false
        dialog.canCreateDirectories    = false
        dialog.allowsMultipleSelection = false
        //dialog.allowedFileTypes        = []
        
        if (dialog.runModal() == NSApplication.ModalResponse.OK) {
            let result = dialog.url // Pathname of the file
            if (result != nil) { return result!.path }
        }
        
        return ""
        
    }
    func openFileFromFinder( file:String ) {
        //print( "open file from finder: \( file )")
        openFile( file: file )
    }

	func saveAs() {
		
		var type:String
		//var ext:String
		var filename:String = (mpackerxapp.lastFileName as NSString).lastPathComponent
		let basefilename = removeExtension(filename: filename)
		
		switch displayMode {
		case LOADEDDISPLAY:
			type = "Original"
		case UNPACKEDDISPLAY:
			type = "Unpacked"
			filename = basefilename
		case IMPORTEDDISPLAY:
			type = "Imported"
		case PACKEDDISPLAY:
			type = "Packed"
			filename = basefilename + ".pkx"
		default:
			print("Nothing to save...")
			return
		}
		
		let title = "Save \(type) File As"
		let nameField = "Save As"
		
		let file = saveAsDialog(title: title, nameField: nameField, filename: filename)
		
		if file == "" {
			print("Save Cancelled")
			return
		}
		
		// And finally we save!
		if displayMode == PACKEDDISPLAY { mpackerxapp.savePdata(file: file) }
		else { mpackerxapp.saveOdata(file: file) }

	}
	func removeExtension( filename:String )->String {
		var basefilenameparts = filename.components(separatedBy: ".")
		if basefilenameparts.count > 1 { // If there is a file extension
			basefilenameparts.removeLast()
			return basefilenameparts.joined(separator: ".")
		} else {
			return filename
		}

	}
	func saveAsDialog( title:String, nameField:String, filename:String )->String {
		let dialog = NSSavePanel()
		
		dialog.title                   = title
		dialog.showsResizeIndicator    = true
		dialog.showsHiddenFiles        = false
		dialog.canCreateDirectories    = false
		dialog.nameFieldLabel          = nameField
		dialog.canCreateDirectories    = true
		dialog.nameFieldStringValue    = filename
		
		if (dialog.runModal() == NSApplication.ModalResponse.OK) {
			let result = dialog.url
			if (result != nil) {
				let path = result!.path
				print("save as "+path)
				return path
			} else {
				print("Something gone wrong with the input")
			}
		} else {
			print("cancel save as")
		}
		return ""
	}

	
	func defaultSettings() {
		mpackerxapp.msettings.setDefaults()
		packSettingChanged()
	}

	func packSettingChanged() {
		updateUI()
		if displayMode == PACKEDDISPLAY && AUTOREPACK {
			packData()
		}
		if displayMode != PACKEDDISPLAY {
			updateBitmapDisplay()
		}
	}
	func packData() {
		if mpackerxapp.haveodata {
			mpackerxapp.packData()
			displayMode = PACKEDDISPLAY
			updateUI()
			updateBitmapDisplay()
		}
	}
	func unpackData() {
		if mpackerxapp.unpackData()==0 {
			displayMode = UNPACKEDDISPLAY
			updateBitmapDisplay()
		}
		updateUI()
	}
	
	func openReorderWindow() {
		if reorderWindowOpened { return }
		
		let storyboard = NSStoryboard(name: "Main", bundle: nil)
		reorderWindowController = storyboard.instantiateController(withIdentifier: "ReorderWindowController") as? NSWindowController
		
		if reorderWindowController!.window != nil {
			
			reorderWindowOpened = true
			
			reorderViewController = reorderWindowController.contentViewController as? ReorderViewController
			reorderWindowController.showWindow(self)
			reorderViewController.mainViewController = self

			
			reorderViewController.initReorder(data: mpackerxapp.odata,
											  bw: mpackerxapp.msettings.BW,
											  h: mpackerxapp.msettings.H,
											  len: mpackerxapp.odata.count)
			
			updateUI()
		}
		
	}
	func openCropWindow() {
		if cropWindowOpened { return }
		
		let storyboard = NSStoryboard(name: "Main", bundle: nil)
		cropWindowController = storyboard.instantiateController(withIdentifier: "CropWindowController") as? NSWindowController
		
		if cropWindowController!.window != nil {
			
			cropWindowOpened = true
			
			cropViewController = cropWindowController.contentViewController as? CropViewController
			cropWindowController.showWindow(self)
			cropViewController.mainViewController = self

			cropViewController.initCrop(data: mpackerxapp.odata,
										bw: mpackerxapp.msettings.BW,
										h: mpackerxapp.msettings.H,
										len: mpackerxapp.odata.count)
			
			updateUI()
		}
		
	}

	func openExportWindow() {
		if exportWindowOpened { return }
		
		let storyboard = NSStoryboard(name: "Main", bundle: nil)
		exportWindowController = storyboard.instantiateController(withIdentifier: "ExportWindowController") as? NSWindowController
		
		if exportWindowController!.window != nil {
			
			exportWindowOpened = true
			
			exportViewController = exportWindowController.contentViewController as? ExportViewController
			exportWindowController.showWindow(self)
			exportViewController.mainViewController = self 
			
			refreshExportWindowContent()
			updateUI()
		}
	}
	func saveExportedText()->Int {
		var filename:String = (mpackerxapp.lastFileName as NSString).lastPathComponent
		let basefilename = removeExtension(filename: filename)

		switch displayMode {
		case LOADEDDISPLAY, IMPORTEDDISPLAY:
			filename = basefilename+"_hexdump"
		case UNPACKEDDISPLAY:
			filename = basefilename+"_unpacked_hexdump"
		case PACKEDDISPLAY:
			filename = basefilename+"_packed_hexdump"
		default:
			filename = basefilename
		}
		
		let file = saveAsDialog(title: "Save Exported Hexdump as Text File", nameField: "Save As", filename: filename+".txt")
		
		if file.count>0 {
			return mpackerxapp.saveExport(file: file, text: exportViewController.data )
		}
		return -1
	}
	func refreshExportWindowContent() {
		exportViewController.data = getHexData( mode: exportViewController.selectedDisplayMode )
		exportViewController.hexdump()
	}
	func getHexData( mode:Int )->String {
		var hex = ""
		//var mode = 0    // 0: plain hex, 1: ASM 68k, (2: ASM 6510, 3: C++, 4: Swift4)
		var src:[UInt8]
		var length:Int
		
		var codeprefix = ""
		var prefix = ""
		var numprefix = ""
		var spacer = " "
		var max = 16
		var codepostfix = ""
		var lastspacer = false
		var havecomment = false
		var commentprefix = ""
		
		switch mode {
		case 0:
			prefix = "\t!byte "
			numprefix = "$"
			spacer = ", "
			havecomment = true
			commentprefix = "  ;"
			//max = 8
			break
		case 1:
			prefix = "\tdc.b "
			numprefix = "$"
			spacer = ", "
			havecomment = true
			commentprefix = "  ;"
			//max = 8
			break
		case 2:
			codeprefix = "unsigned char binarydata[] = {\n"
			prefix = "\t"
			numprefix = "0x"
			spacer = ", "
			lastspacer = true
			codepostfix = "\n};"
			havecomment = true
			commentprefix = "  //"
			//max = 8
			break
		case 3:
			codeprefix = "var binarydata:[UInt8] = [\n"
			prefix = "\t"
			numprefix = "0x"
			spacer = ", "
			lastspacer = true
			codepostfix = "\n]"
			havecomment = true
			commentprefix = "  //"
			//max = 8
			break
		case 4:
			break
		default:
			print("default mode")
		}
		
		switch displayMode {
		case LOADEDDISPLAY, UNPACKEDDISPLAY, IMPORTEDDISPLAY:
			length = mpackerxapp.odata.count
			src = mpackerxapp.odata
		case PACKEDDISPLAY:
			length = mpackerxapp.pdata.count
			src = mpackerxapp.pdata
		default:
			return "Nothing to export..."
		}

		var first:Bool = false
		var last:Bool = false
		var end:Bool = false
		
		hex += codeprefix
		
		for i:Int in 0..<length {
			
			first = (i%max==0)
			last = ((i+1)%max==0)
			end = i==length-1
			
			if first { hex += prefix }
			
			hex += numprefix + String(format:"%02X", src[i])
			
			if last {
				if !end && lastspacer { hex += spacer }
				//if havecomment { hex += commentprefix + numprefix + String(format:"%0X", i-(i%max)) }
				hex += "\n"
			} else if !end {
				hex += spacer
			}
			
		}
		hex += codepostfix
		
		
		return hex
	}
	func importFromText( text:String ) {
		if reorderWindowOpened || cropWindowOpened { return }
		if mpackerxapp.importFile(text: text)==0 {
			displayMode = IMPORTEDDISPLAY
			updateUI()
			updateBitmapDisplay()
			print("Import success")
		}
	}
}

