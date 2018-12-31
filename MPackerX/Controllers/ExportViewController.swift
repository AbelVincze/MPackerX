//
//  ExportViewController.swift
//  MPackerX
//
//  Created by Macc on 18/12/29.
//  Copyright © 2018. Macc. All rights reserved.
//

import Cocoa

class ExportViewController: NSViewController {
    
    
    @IBOutlet var importExportTextView: NSTextView!
    
    var selectedDisplayMode = 4 // Hex
    var data = ""
 
    weak var mainViewController:ViewController!
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        print("Export Window Loaded")
        
        
        //importExportTextView.textContainer?.widthTracksTextView = false
        //importExportTextView.textContainer?.
        
        
        // Fixing font/color style reset on empty Textfields...
        let font:NSFont = NSFont.userFixedPitchFont(ofSize: 11)!
        let color:NSColor = NSColor.white
        let attributes = NSDictionary(objects: [font, color], forKeys: ([NSAttributedString.Key.font, NSAttributedString.Key.foregroundColor]) as! [NSCopying])
        importExportTextView.typingAttributes = attributes as! [NSAttributedString.Key : Any]
       
    }
    override func viewWillDisappear() {
        print("Export Window Closed")
        if mainViewController != nil {
            mainViewController.exportWindowOpened = false
            mainViewController.updateUI() //csak ha el el akarnank tuntetni az export menupontot amig van export ablak...
        }
    }
    func hexdump() {
        importExportTextView.string = data
    }
    
    
    @IBAction func importButtonClicked(_ sender: Any) {
        print("import")
        //hexImport()
        mainViewController.importFromText( text: importExportTextView.string )
    }
    @IBAction func saveAsButtonClicked(_ sender: Any) {
        print("save as export")
        mainViewController.saveExportedText()
    }
    @IBAction func modeSelectionClicked(_ sender: NSSegmentedControl) {
        processModeChange( newMode: sender.selectedSegment )
    }
    func processModeChange( newMode:Int ) {
        print("newMode: \( newMode )")
        if selectedDisplayMode != newMode {
            
            selectedDisplayMode = newMode
            mainViewController.refreshExportWindowContent()
            
        }
    }
    
    /*
    
    func hexImport() {
        
        let max = 65536
        var idata:[UInt8] = [UInt8](repeating: 0, count: max)
        var length:Int = 0
        var text:String = theTextView.string
        var tdata:[UInt8] = [UInt8](text.utf8)
        var ch:Int = 0
        var chr:UInt8
        var digit:Int = 0
        var digits:[Int] = [ 0,0 ]
        var nodigit:Bool = false
        var hchr:Int
        
        while ch<tdata.count {
            
            //print( tdata[ch] )
            chr = tdata[ch]
            hchr=getHexValue(chr: chr)
            if hchr<0 {
                nodigit = true
            } else {
                digits[digit] = hchr
                digit += 1
            }
            ch += 1
            if nodigit || digit==2 || ch==tdata.count {
                nodigit = false
                if digit==1 {
                    idata[length] = UInt8( digits[0] )
                    digit = 0
                    length += 1
                }
                if digit==2 {
                    idata[length] = UInt8( digits[0]*16 + digits[1] )
                    digit = 0
                    length += 1
                }
                if length>=max { break }
            }
        }
        
        var fdata:[UInt8] = [UInt8](repeating: 0, count: length)
        for i:Int in 0..<length {
            fdata[i] = idata[i]
            //print( fdata[i] )
        }
        
        mainViewController.importData( idata: fdata )
        //return fdata
    }
    func getHexValue( chr:UInt8 )->Int {
        switch(chr) {
        case 0x30 ... 0x39: return Int(chr)-0x30
        case 0x41 ... 0x46: return Int(chr)-0x41+10
        case 0x61 ... 0x66: return Int(chr)-0x61+10
        default:            return -1
        }
        
        
    }
    */
}

