//
//  MPackerXApp.swift
//  MPackerX
//
//  Created by Macc on 18/12/28.
//  Copyright © 2018. Macc. All rights reserved.
//

import Cocoa

class mpackSettings {
    var BW:Int = 16
    var H:Int = 0
    var USELOOKUP:Bool = false
    var NEGCHECK:Bool = false
    var DIR:Bool = false
    var MAXD:Int = 0
    var MAXC:Int = 0
    var BMODE:Bool = false
	
	var autoUpdate:Bool = true

    func setDefaults() {
        //BW = 16
        H = 0
        USELOOKUP = true
        NEGCHECK = true
        DIR = true
        MAXD = 32767
        MAXC = 32767
        BMODE = false
    }
    
}

class MPackerXApp {
    
    let mpackerx = MPackerX()
    let msettings = mpackSettings()
    
    var odata:[UInt8] = []  // original data (loaded, loaded->unpacked, imported) = []
    var pdata:[UInt8] = []
    var odatatype:Int = 0   // 0: loaded, unpacked, imported
    var haveodata:Bool = false
    var havepdata:Bool = false
	
	let defaultLoadedInfo = "Open a file to work with\nor just sit there doing nothing..."
	var loadedInfo:String = ""
	var unpackedInfo:String = ""
	var importedInfo:String = ""
	var packedInfo:String = ""
	
	var lastFileName:String = ""
    
    //var odataisunpacked:Bool = false   // ha mar tudjuk, hogy nem lehet kitomoriteni... akkor true
    var odataisnotpacked:Bool = false
    
    // enum
    let LOADEDDATA:Int = 0
    let UNPACKEDDATA:Int = 1
    let IMPORTEDDATA:Int = 2
    
    
    func initApp() {
        print( "MPackerX init \(odata.count)")
        //msettings.setDefaults()
		resetApp()
    }
	func resetApp() {
		loadedInfo = defaultLoadedInfo
		haveodata = false
		havepdata = false
		odatatype = LOADEDDATA
		odataisnotpacked = false
		msettings.setDefaults()
		
		lastFileName = ""
	}
	func setH() {
		msettings.H = haveodata ? Int(ceil(Double(odata.count)/Double(msettings.BW))) : 0
	}
    
    func loadFile( file:String )->Int {
        // load binary to odata
        print( "load \( file )" )
 
        var buf:[UInt8] = [UInt8](repeating: 0, count: 65536)           // temporary buffer to load data to
        
        if let stream:InputStream = InputStream(fileAtPath: file) {
            stream.open()
            let len = stream.read(&buf, maxLength: buf.count)           // load data from file
            stream.close()
            if len <= 0 {
                print("0 byte long file")
                return -2
            }
            odata = [UInt8](buf[..<len])                                // assign loaded data to our odata array
            haveodata = true
            odataisnotpacked = false    // nem tudjuk meg....
            odatatype = LOADEDDATA
			setH()
			let filename = (file as NSString).lastPathComponent
			loadedInfo = "Loaded \( odata.count ) bytes binary file\n\( filename )"
			
			lastFileName = file 	// store filename for later use
            print("odata \( odata.count )")
            
        } else {
            print( "file not found: \( file )" )
            return -1
        }

        
        
        return 0
    }
    func saveOdata( file:String )->Int {
        return saveData( file: file, data: odata )
    }
    func savePdata( file:String )->Int {
        return saveData( file: file, data: pdata )
    }
	func saveData( file:String, data:[UInt8] )->Int {
		print("file size: \( data.count )")
		if let stream:OutputStream = OutputStream(toFileAtPath: file, append: false) {
			stream.open()
			stream.write(data, maxLength: data.count)
			stream.close()
			return 0
		}
		return -1
	}

	func saveExport( file:String, text:String )->Int {
		if let stream:OutputStream = OutputStream(toFileAtPath: file, append: false) {
			stream.open()
			let data:[UInt8] = [UInt8](text.utf8)
			stream.write(data, maxLength: data.count)
			stream.close()
			return 0
		}
		return -1
	}
	
	
	func importFile( text:String )->Int {
        // import data to odata
		var words = text.split(separators: ",! \n\t\r" )
		print( words.count )
		//print( words )
		
		let max = 65536
		var idata:[UInt8] = [UInt8](repeating: 0, count: max)
		var length:Int = 0
		var lastGoodLength:Int

		var error:Bool = false

		var index:Int
		var byte:Int
		
		for word in words {
			
			// check if it starts with $ or 0x
			var tdata:[UInt8] = [UInt8](word.utf8)
			if tdata.count==0 { continue }
			
			if tdata[0]==0x24 {	// $
				tdata = [UInt8](tdata[1...])
			} else if tdata.count>2 && tdata[0]==0x30 && ( tdata[1]==0x58 || tdata[1]==0x78 ) {	//0x, 0X
				tdata = [UInt8](tdata[2...])
			}
			
			// ami maradt az csak hex szam lehet, tehat, ha olyan karakter talalunk ami nem hex, akkor hiba
			print( tdata )
			let remains = tdata.count
			
			lastGoodLength = length
			index = 0
			while index<remains {
				
				if remains>=2 {
					byte = getHexValue(chr: tdata[index])*16+getHexValue(chr: tdata[index+1])
					index += 2
				} else {
					byte = getHexValue(chr: tdata[index])
					index += 1
				}
				if byte<0 {
					length = lastGoodLength
					break
				}		// volt egy rossz szamjegy!
				
				idata[length] = UInt8( byte )
				length += 1
				
				if length==max { break }
				
			}
			
			if length==max { break }
		}
		
		if length==0 { return -1 }
		
		odata = [UInt8](idata[..<length])
		setH()
		print("imported \( odata.count) bytes")
		
		haveodata = true
		odataisnotpacked = false    // nem tudjuk meg....
		odatatype = IMPORTEDDATA
		importedInfo = "Imported data\n\( odata.count ) bytes binary data"
		
		lastFileName = "import" 	// store filename for later use
		return 0
    }
	func getHexValue( chr:UInt8 )->Int {
		switch(chr) {
		case 0x30 ... 0x39: return Int(chr)-0x30
		case 0x41 ... 0x46: return Int(chr)-0x41+10
		case 0x61 ... 0x66: return Int(chr)-0x61+10
		default:            return -255
		}
	}
	
	func setData( data:[UInt8], bw:Int ) {
		odata = data
		msettings.BW = bw
		setH()
		odatatype = LOADEDDATA
		let filename = (lastFileName as NSString).lastPathComponent
		loadedInfo = "Reordered \( odata.count ) bytes binary file\n\( filename )"
	}
	
    func packData() {
        // pack odata -> result in pdata
		let start = DispatchTime.now()

		pdata = mpackerx.mpack(src: odata, settings: msettings)
		havepdata = true
		
		let end = DispatchTime.now()
		let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds
		let timeInterval = Double(nanoTime) / 1000000

		let P = Double( pdata.count )
		let O = Double( odata.count )
		let PC = 100*P/O

		packedInfo = "Packed to \( pdata.count ) bytes in \( String(format:"%.3f", timeInterval ) ) ms\nfrom \( odata.count) bytes original (\( String(format:"%.2f", PC ) )%)"
		
	}
    func unpackData()->Int {
        // unpack odata -> result in odata
		let start = DispatchTime.now()
		let origlen = odata.count
		
        odata = mpackerx.munpack(pdata: odata, settings: msettings)
 
		let end = DispatchTime.now()
		let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds
		let timeInterval = Double(nanoTime) / 1000000
		

		//print("unpacked: \( odata.count )")
        if mpackerx.lastCommandSuccess {
            odataisnotpacked = true
            odatatype = UNPACKEDDATA
			
			if msettings.autoUpdate {
				msettings.BW = mpackerx.lastSettings.BW
				msettings.H = mpackerx.lastSettings.H
				msettings.USELOOKUP = mpackerx.lastSettings.USELOOKUP
				msettings.NEGCHECK = mpackerx.lastSettings.NEGCHECK
				msettings.DIR = mpackerx.lastSettings.DIR
				msettings.MAXD = mpackerx.lastSettings.MAXD
				msettings.MAXC = mpackerx.lastSettings.MAXC
			}

			let P = Double( origlen )
			let O = Double( odata.count )
			let PC = 100*P/O
			
			unpackedInfo = "Unpacked to \( odata.count ) bytes in \( String(format:"%.3f", timeInterval ) ) ms\nfrom \( origlen ) bytes packed original (\( String(format:"%.2f", PC ) )%)"


			return 0
		} else {
			odataisnotpacked = true
		}
		
		return -1
    }
    
    func invertData() {
        // invert odata
        if odata.count==0 { return }
        for i:Int in 0..<odata.count {
            odata[i] ^= 0xFF
        }
    }
    
    
}
