//
//  mpackerx.swift
//  Bitmaptool
//
//  Created by Macc on 18/12/14.
//  Copyright © 2018. Macc. All rights reserved.
//

import Cocoa



class MPackerX {
    
    let mmchl:Int = 4
    let maxpatterns:Int = 8
    var bits:[UInt8] = [ 128, 64, 32, 16, 8, 4, 2, 1 ]
    var anbits:[Int] = [ 1, 2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048, 4096, 8192, 16384, 32768 ]

    var compressedLength:Int = 0
    var decompressedLength:Int = -1
    var decompressedBW:Int = 0
    
    var lastCommandSuccess = false
    
    struct repeatdata {
        var L:Int = 0
        var T:Int = 0
        var SRC:Int = 200
        var N:Bool = false
    }
    struct blockdata {
        var ST:Bool = false
        var L:Int = 0
        var T:Int = 0
        var SRC:Int = 200
        var N:Bool = false
    } 
    struct bytecount {
        var B:UInt8 = 0
        var C:Int = 0
    }
    struct testdata {
        var m:Int = 0
        var v:Int = 0
    }

    func mpack( src:[UInt8], settings:mpackSettings )->[UInt8] {
        
        //var USELOOKUP:Bool = LOOKUP
		var maxd:Int = 0	// pozitiv visszajelzes vegett mengezzuk mik voltak a maxok, hogy ahhoz adaptalodjon a beallitas
		var maxc:Int = 0
		
        
        var pdata:[UInt8] = [UInt8](repeating: 0x55, count: 65536)    // packed data
        var data:[UInt8]
        
        let maxrepeats = 8192
        var repeats:[repeatdata] = [repeatdata](repeating: repeatdata(), count: maxrepeats)
        
        
        let filesize:Int = src.count
        var expsize:Int
        //var USELOOKUP:Bool = true
        //var DIR:Bool = true
        //var NEGCHECK:Bool = true
        
        //if b_mode { USELOOKUP = false }
        
        var H:Int = 0
        //var BW:Int = 16
        
        if( H==0 ) { // default setting
            H = Int(ceil(Double(filesize)/Double(settings.BW)))
        }
        expsize = settings.BW*H

        // Copy data with the right order
        data = [UInt8](repeating: 0, count: 65536 )
        if settings.DIR {
            /*  a bitmap grafikak (1 bites) tomoritesenek kulcsa, ez a byte sorrend,
                igy sokkal tobb ismedlodes szurheto ki mint hagyomanyos sorrendben. */
            var c:Int = 0
            for y:Int in 0..<H {
                for x:Int in 0..<settings.BW {
					data[x*H+y] = c<filesize ? src[c] : 0xAA
					
                    c += 1
                }
            }
            
        } else {
            // just copy data to the buffer;
            for i:Int in 0..<65536 {
                if i<src.count { data[i] = src[i] }
                else { data[i] = 0x55 }
            }
        }

        
        // PASS 1 - searching for repeats (one of the key part of the packing) --------------
        
        var bin:Int = 1             // byte in (position)
        var chbin:Int               // check byte in (position)
        var best:repeatdata = repeatdata()        // best is a temp rep struct to store actual better
        var repcount:Int = 0        // how many repeats are stored already;
        var repbytecount:Int = 0    // how many bytes are repeated;
        let maxdatal:Int = settings.MAXC+mmchl
        let maxdist:Int = settings.MAXD
        let l:Int = expsize
        var maxchecklength:Int
        var maxcheckdist:Int
        var chp:Int
        
        print( "find repeats" )
        
        while bin<(l-mmchl) {
            
            maxchecklength = l-bin        // max hosszusag amit ellenorizhetunk
            maxcheckdist = bin            // max tavolsag ameddig nezelodhetunk
            if maxchecklength>maxdatal { maxchecklength=maxdatal }
            if maxcheckdist>maxdist    {  maxcheckdist=maxdist   }
            
            chbin = bin - 1   // Az ellenorzest kozvetlenul az elozo byte-tol nezzuk, hogy a legkozelebbi legyen a legoptimalisabb...
            best.L = 0        // best result
            
            while chbin>=(bin-maxcheckdist) {
                chp = 0       // check position
                
                while( chp<maxchecklength && data[ bin+chp ] == data[ chbin+chp ] ) { chp += 1 }
                if( chp>=mmchl && best.L<chp ) {
                    best.L = chp
                    best.T = bin
                    best.SRC = chbin
                    best.N = false
                } else if( settings.NEGCHECK ) {
                    chp = 0;
                    while( chp<maxchecklength && data[ bin+chp ] == 255-data[ chbin+chp ] ) { chp += 1 }
                    if( chp>=mmchl && best.L<chp ) {
                        best.L = chp
                        best.T = bin
                        best.SRC = chbin
                        best.N = true
                    }
                }
                chbin -= 1
            }
            if best.L>=mmchl {
                if repcount==maxrepeats  {
                    print("too much repeats")
                    return src
                }
                repeats[repcount] = best
                repcount += 1
                repbytecount += best.L
                bin += best.L
            } else {
                bin += 1
            }
            
        }
        
        print( "Repeats found: "+String(repcount) )

        
        // PASS 2 - building Blocks ---------------------------------------------------------
        
        var prevend:Int = 0
        var blkcount:Int = 0
        var T:Int
        
        let maxblocks = repcount*2+1
        var blocks:[blockdata] = [blockdata](repeating: blockdata(), count: maxblocks )

        var r:Int = 0
        while r<repcount {
            T = repeats[r].T
            if prevend<T {
                blocks[blkcount].ST = true
                blocks[blkcount].L = T-prevend
                blocks[blkcount].T = prevend
                blkcount += 1
            }
            blocks[blkcount].ST = false
            blocks[blkcount].L = repeats[r].L
            blocks[blkcount].T = T
            blocks[blkcount].SRC = repeats[r].SRC
            blocks[blkcount].N = repeats[r].N
            blkcount += 1

            prevend = T+repeats[r].L;
			
			if repeats[r].L>maxc { maxc = repeats[r].L }
			var dist = T-repeats[r].SRC
			if dist>maxd { maxd = dist }

            r += 1
        }
        if prevend<l {
            blocks[blkcount].ST = true
            blocks[blkcount].L = l-prevend
            blocks[blkcount].T = prevend
            blkcount += 1
        }
        
        print( "Blocks: "+String(blkcount)+" ("+String(blkcount-repcount)+" streams, "+String(repcount)+" repeats)" )
        
        // PASS 3 - generate lookup table ---------------------------------------------------
        
        
        var bc:[bytecount] = [bytecount](repeating: bytecount(), count: 256 )
        for i:Int in 0..<256 { bc[i] = bytecount(B: UInt8(i), C: 0 ) }

        var lookup:[UInt8] = [UInt8](repeating: 0, count: 256 )
        var rlookup:[UInt8] = [UInt8](repeating: 0, count: 256 )
        var SDATA:[testdata] = [testdata](repeating: testdata(), count: 256)
        var sdatacount:Int = 0
        

        var bitvars:UInt8 = 0
        var len:Int = 0
        var MAX:Int = 0
        var maxsaves:Int = 0
        var maxvs:Int = 0
        var checks:Int = 0
        var maxpatt:[UInt8] = []    //[UInt8](repeating: 0, count: maxpatterns)
        var ubits:[UInt8] = []      //[UInt8](repeating: 0, count: maxpatterns)
        var maxvars:Int = 5
        var LIrefs:Int = 0

        var pattern:[UInt8] = []

        func dotest( SDATA:[testdata], sdatacount:Int, max:Int )->[UInt8] {
            
            //testvars vars = (testvars){ 1, (int)sdatacount, MAX, 0, 0, 0 };
            bitvars = 1
            len = sdatacount
            MAX = max
            maxsaves = 0
            maxvs = 0
            checks = 0
            //LIrefs = 0
            maxpatt = [UInt8](repeating: 0, count: maxpatterns)
            ubits = [UInt8](repeating: 0, count: maxpatterns)
            checkdepth( d: 0, SDATA: SDATA )
            
            //print( String(sdatacount) )//+ " (" + String(LIrefs) + " references)" )
            var i:Int = 0
            var out:String = ""

            while i<maxpatterns {
                if maxpatt[i]==0 { out += " " }
                else { out += String(maxpatt[i]) + " " }
                i += 1
            }
            out += "(" + String(checks) + " checks, "
            out += "saved " + String(maxsaves) + "b, "
            var m = 0
            if MAX==0 { m = len }
            out += String(floor(Double(maxsaves)/Double(8)) - Double(m)) + "B in total)"
            print( out )
            
            //for( int i=0; i<maxpatterns; i++ ) result[i] = vars.maxpatt[i];
            return maxpatt
        }
        func checkdepth( d:Int, SDATA:[testdata] ) {
            
            //print( String(d) + " - " + String(len) ) 
            
            if d>maxvars { return }                          // when we need to stop...
            
            var i:Int = d
            while i<maxpatterns {
                ubits[i] = 0    // reset the sub-bits
                i += 1
            }
            // how many bytes need to be addressed
            var lookuprest:Int
            if MAX>0 {
                lookuprest = MAX
            } else {
                lookuprest = len-1        // fix!!! -1
            }
            i = 0
            while i<d {
                lookuprest -= 1<<ubits[i]
                i += 1
            }
            // how many max bits we need for starting?
            var mbit:Int = 1
            while (1<<mbit)<=lookuprest { mbit += 1 }
            
            // start checking with the largest single variation
            ubits[d] = UInt8(mbit)
            //checkresult result;
            var result = getsaves( SDATA: SDATA )
            //cout << +result.pattern[0] << "\n";
            if result.saved>maxsaves || (result.saved==maxsaves && maxvs>d) {
                maxsaves = result.saved
                maxvs = d
                /*var i:Int = 0
                while i<maxpatterns {
                    if i<=d { maxpatt[i] = result.pattern[i] }
                    else { maxpatt[i] = 0 }
                    i += 1
                }*/
                maxpatt = result.pattern
            }
            checks += 1
            
            mbit -= 1
            if mbit==0 || d==maxvars { return }    //no more check is needed!
            
            i = mbit
            while i>0 {
                ubits[d] = UInt8(i)
                checkdepth( d: d+1, SDATA: SDATA )
                i -= 1
            }
            
            return
        }
        func getsaves( SDATA:[testdata] )->(saved:Int, pattern:[UInt8]) {
            // calculates how many bits/bytes are saved with a pattern configuration
            
            var bit:Int = 0
            var bitp:Int = 0
            var mbit:Int = 0
            var totalbits:Int = 0
            var totalsaved:Int = 0
            var last:Bool = false
            var error:Bool = false
            var pcount:Int = 0
            var val:Int
            var fix:Int = 0
            var tb:Int
            var sm:Int
            
            pattern = [UInt8](repeating: 0, count: maxpatterns)
            
            if MAX>0 {
                tb = 16
                sm = 4
            } else {
                tb = 8
                sm = 3
            }
            
            var i:Int = 0
            while i<len {
                
                if mbit==0 {
                    
                    pattern[pcount] = ubits[bitp]
                    pcount += 1
                    if i>0 && MAX>0 {
                        fix += 1<<ubits[bitp-1]
                    }
                    
                    if bitp==maxpatterns-1 || ubits[bitp+1]==0 {
                        last = true
                    } else {
                        bit += 1
                    }
                    
                    totalbits = bit+Int(ubits[bitp]);
                    if( ubits[bitp]>0 ) {
                        mbit = 1<<ubits[bitp];
                        bitp += 1
                    } else {
                        error = true
                        totalbits = tb
                        if MAX>0 { break }
                        else { mbit = 999999 }
                    }
                }
                if MAX>0 {
                    val = SDATA[i].v
                    if val-fix >= mbit {
                        mbit = 0
                        //i -= 1
                        continue
                    }
                }
                
                totalsaved += SDATA[i].m * (tb-totalbits);
                if MAX==0 { mbit -= 1 }
                
                i += 1
                
            }
            var ts:Int
            if error { ts = 0 }
            else { ts = totalsaved - (bitp-1)*sm }
            return (saved: ts, pattern: pattern )
        }
        
        
        bin = 0                     // reset the data pointer
        var n:UInt8
        if settings.USELOOKUP {
            
            var bl:Int = 0
            while bl<blkcount {
                //print( bin )
                if blocks[bl].ST==true {    // it's a stream, so copy bytes...
                    var i:Int = 0
                    while i<blocks[bl].L {
                        n = data[ bin ]
                        bin += 1
                        bc[Int(n)].C += 1
                        i += 1
                    }
                    LIrefs += blocks[bl].L
                } else {
                    bin += blocks[bl].L
                }
                bl += 1
            }
            //sort(bc, bc+256, bcsorter);        // sort results by descending order
            
            bc.sort { $0.C > $1.C }
            
            var i:Int = 0
            while i<256 {
                //print( bc[i].C )
                if bc[i].C>0 {
                    lookup[ Int(bc[i].B) ] = UInt8(i);
                    rlookup[i] = bc[i].B;
                    SDATA[sdatacount].m = bc[i].C;
                    sdatacount += 1
                }
                i += 1
            }
            
            //cout << "Lookup table entries: " << +sdatacount << "\n";
            //if( v_mode ) cout << "LUT entries:\t" << +sdatacount << "\t(" << LIrefs << " references)\n";
            
        }
        
        // PASS 4 - optimize number representations (LUindex, Lengths, Distances) -----------
        // optimize lookup table linking (how to store index bytes in less bit)

        var LIbitdepths:[UInt8] = []
        if settings.USELOOKUP {
            print( "LUT pattern:" )
            LIbitdepths = dotest( SDATA: SDATA, sdatacount: sdatacount, max: 0 )
        }

        // optimize counter bits and distance bits (how to store index bytes in less bit)
        var cntlist:[Int] = [Int](repeating: 0, count: blkcount)
        var distlist:[Int] = [Int](repeating: 0, count: repcount+1)
        var clcount:Int = 0
        var dlcount:Int = 0
        
        var bl:Int = 0
        while bl<blkcount {
            if blocks[bl].ST == true {    // it's a stream, so copy bytes...
                cntlist[clcount] = blocks[bl].L-1
                clcount += 1
            } else {
                cntlist[clcount] = blocks[bl].L-mmchl
                distlist[dlcount] = blocks[bl].T - blocks[bl].SRC
                clcount += 1
                dlcount += 1
            }
            bl += 1
        }
        cntlist.sort { $0 < $1 }
        distlist.sort { $0 < $1 }
        
        var CNTlist:[testdata] = [testdata](repeating: testdata(), count: blkcount)
        var DISTlist:[testdata] = [testdata](repeating: testdata(), count: repcount+1)
        
        var Clcount:Int = 1
        var Dlcount:Int = 1
        
        CNTlist[0] = testdata(m: 1, v: cntlist[0])
        for i:Int in 1..<clcount {
            if CNTlist[Clcount-1].v == cntlist[i] { CNTlist[Clcount-1].m += 1 }
            else {
                CNTlist[Clcount] = testdata(m: 1, v: cntlist[i] )
                Clcount += 1
            }
        }
        DISTlist[0] = testdata( m: 1, v: dlcount>0 ? distlist[0] :0 )
        if dlcount>0 { for i:Int in 1..<dlcount {
            if DISTlist[Dlcount-1].v == distlist[i] { DISTlist[Dlcount-1].m += 1 }
            else {
                DISTlist[Dlcount] = testdata( m: 1, v: distlist[i] )
                Dlcount += 1
            }
        } }
		
		
		
        
        var CNTbitdepths:[UInt8] = []    // = [UInt8](repeating: 0, count: maxpatterns )
        print( "CNT pattern:" )
        CNTbitdepths = dotest( SDATA: CNTlist, sdatacount: Clcount, max: CNTlist[Clcount-1].v )
        
        var DISTbitdepths:[UInt8] = []   //= [UInt8](repeating: 0, count: maxpatterns )
        print( "DIST pattern:" )
        DISTbitdepths = dotest( SDATA: DISTlist, sdatacount: Dlcount, max: DISTlist[Dlcount-1].v )


		// info to sent to GUI
		//maxd = DISTlist[Dlcount-1].v
		maxc -= mmchl
		print("DIST max = \( maxd )")
		print("CNT max = \( maxc )")
		
        
        // PASS 5 - assemble packed data ----------------------------------------------------

        var bitpos:Int = 0
        var bitbuff:Int = 0
        var bout:Int = 0
        
        func pushbit( sbit:Int ) {
            if bitpos==0 {
                bitbuff = bout
                bout += 1
                pdata[ bitbuff ] = 0xFF
                //print( "NB - "+String(bitbuff) )
            }
            if sbit>0 {
                pdata[ bitbuff ] = pdata[ bitbuff ]|bits[bitpos]
            } else {
                pdata[ bitbuff ] = pdata[ bitbuff ]&(255-bits[bitpos])
            }
            bitpos = (bitpos+1)&0x07;
        }
        func pushnbits( nbit:Int, data:Int ) {
            var ab:Int = nbit-1
            for _ in 0..<nbit {
                pushbit( sbit: data&anbits[ab] )
                ab -= 1
            }
        }
        func pushdatabits( bitdepths:[UInt8], l:Int, v:Int )->Int {        //lookup index
            var vbit:Int = 0
            var actbits:Int = Int(bitdepths[ vbit ])
            var fix:Int = 0
            var comp:Int = 1<<actbits
            for _ in 1..<l {
                if v < comp {
                    pushnbits( nbit: vbit, data: 0 )
                    pushbit( sbit: 1 )
                    pushnbits( nbit: actbits, data: v-fix )
                    return actbits+vbit+1
                }
                vbit += 1
                actbits = Int(bitdepths[ vbit ])
                fix = comp
                comp += 1<<actbits
            }
            
            pushnbits( nbit: vbit, data: 0 );
            pushnbits( nbit: actbits, data: v-fix );
            return actbits+vbit;
            
        }

        bin = 0;
        
        //var isStream:Bool = true
        var next:Bool = false        // next block is repeat

        var tdl:Int = 0
        var tcnt:Int = 0
        //var pdbit:Int = 0        // nit pointer.
        
        var LIbitdepthscount:Int = 0
        var CNTbitdepthscount:Int = 0
        var DISTbitdepthscount:Int = 0
        
        for i:Int in 0..<maxpatterns {
            if settings.USELOOKUP && LIbitdepths[i]>0 { LIbitdepthscount += 1 }
            if CNTbitdepths[i]>0 { CNTbitdepthscount += 1 }
            if DISTbitdepths[i]>0 { DISTbitdepthscount += 1 }
        }
        if LIbitdepthscount==0 { settings.USELOOKUP = false }
        /*cout << "LIbitdepthscount: " << LIbitdepthscount << "\n";
         cout << "CNTbitdepthscount: " << CNTbitdepthscount << "\n";
         cout << "DISTbitdepthscount: " << DISTbitdepthscount << "\n";*/
        
        // Start writing the output:
        // output "header":
        pdata[ bout ] =  UInt8( (H&0xFF00)>>8 )        // Bitmap height (16 bit big endian)
        pdata[ bout+1 ] =  UInt8( H&0xFF )
        pdata[ bout+2 ] =  UInt8( settings.BW )                    // Bitmap bytewidth (width/8)
        bout += 3
        
        /*if( !b_mode ) {
        pushbit( sbit:(USELOOKUP?1:0) );            // Do we use Lookup table?
        pushbit( sbit:(NEGCHECK?1:0) );            // Do we use negative repeats?
        pushbit( sbit:(DIR?1:0) );
        //}*/

        if settings.USELOOKUP { pushbit( sbit:1) } else { pushbit( sbit:0) }
        if settings.NEGCHECK { pushbit( sbit:1) } else { pushbit( sbit:0) }
        if settings.DIR { pushbit( sbit:1) } else { pushbit( sbit:0) }

        // Finally, if we uses LOOKUP table, store the table data.
        if( settings.USELOOKUP ) {
            pdata[ bout ] = UInt8(sdatacount&0xFF)    // store lookup table lenght
            bout += 1
            for i:Int in 0..<sdatacount {
                pdata[ bout ] = rlookup[i];    // store lookup table entries
                bout += 1
            }
            pushnbits( nbit: 3, data: LIbitdepthscount-1 );    // and we store the lookup table bits..
            for i:Int in 0..<LIbitdepthscount { pushnbits( nbit: 3, data: Int( LIbitdepths[i] )-1 ) }
            
        }
        
        pushnbits( nbit: 3, data: CNTbitdepthscount-1 );
        for i:Int in 0..<CNTbitdepthscount { pushnbits( nbit: 4, data: Int( CNTbitdepths[i] )-1 ) }
        pushnbits( nbit: 3, data: DISTbitdepthscount-1 );
        for i:Int in 0..<DISTbitdepthscount { pushnbits( nbit: 4, data: Int( DISTbitdepths[i] )-1 ) }
        
        
        // just packing:
        
        var src:Int
        var dist:Int
        var dl:Int
        
        
        for bl:Int in 0..<blkcount {
            //print( String(bl)+" - "+String(bout)+", ST: "+String(blocks[bl].ST)+", len: "+String(blocks[bl].L)+", T: "+String(blocks[bl].T) )
            if blocks[bl].ST == true {    // it's a stream, so copy bytes...
                tcnt += pushdatabits( bitdepths: CNTbitdepths, l: CNTbitdepthscount, v: blocks[bl].L-1 )
                for _ in 0..<blocks[bl].L {
                    n = UInt8(data[ bin ])
                    bin += 1
                    if settings.USELOOKUP {
                        pushdatabits( bitdepths: LIbitdepths, l: LIbitdepthscount, v: Int( lookup[ Int(n) ] ) )
                    } else {
                        pdata[ bout ] = n
                        bout += 1
                    }
                }
            } else {
                next = (bl+1<blkcount) ? blocks[bl+1].ST: true
                pushbit( sbit: next ? 1:0 )
                
                src = blocks[bl].SRC
                dist = blocks[bl].T - src
                
                dl = pushdatabits( bitdepths: DISTbitdepths, l: DISTbitdepthscount, v: dist )
                pushdatabits( bitdepths: CNTbitdepths, l: CNTbitdepthscount, v: blocks[bl].L-mmchl )
                tdl += dl;
                if settings.NEGCHECK { pushbit( sbit: blocks[bl].N ? 1:0 ) }
                
                bin += blocks[bl].L
            }
            
        }
        
        /*
         console.log("dist bits: "+tdl );
         console.log("CNT bits:  "+tcnt );
         var pdl = Math.ceil( pdbit/8 );            // The length of the pack data
         
         */
        /*
        if( force_hex || (!haveoutfile && !trying) ) hexdump( pdata, bout );    // print result as hexdump
        if( v_mode ) {
            cout << "Packed size:\t" << +bout << "B\t(" << +(bin-bout) << "B less, " << +(((float)bout/bin)*100)<< "% of the original)\n";
        }
        if( haveoutfile && !trying ) {
            // save the packed file.
            ofstream myFile;
            myFile.open(outfile, ofstream::binary);
            if( !myFile.is_open() ) { cout << "Can't write file\n"; return; }
            myFile.write(pdata, bout);
            myFile.close();
            if( v_mode ) cout << "Packed to file:\t" << outfile << "\n";
            
        }
        */
        
        
        
        print( "Compressed length: "+String(bout) )
        compressedLength = bout
		
		if settings.autoUpdate {	// update setting if needed
			settings.MAXC = maxc
			settings.MAXD = maxd
		}
		
        return [UInt8](pdata[..<bout])
    }
 
    var lastSettings:mpackSettings = mpackSettings()
    func munpack( pdata:[UInt8], settings:mpackSettings )->[UInt8] {
        
        //decompressedLength = -1
        lastCommandSuccess = false
        //lastUnpackSettings
		var maxd:Int = 0
		var maxc:Int = 0
		
        
        var filesize = pdata.count
        if filesize < 8 { return pdata }
        
        var expsize:Int = 0
        var bin:Int = 0
        
        var error:Int = 0  // Script is fail proof, but is forced to generate data..
        var warn:Bool = false
        
        
        
        var H:Int = Int(pdata[ bin ])*256;   // 1. byte
        H += Int(pdata[ bin+1 ]);            // 2. byte
        var BW:Int = Int(pdata[ bin+2 ]);    // 3. byte
        
        bin += 3
        
        expsize = BW*H;
        print( "BW: \(BW)\nH:  \(H)\nExpsize: \(expsize)" )
        if expsize==0 { return pdata }
        
        if expsize>0x10000 {
            return pdata
            //error += 1
            //expsize = 0x10000
            // hiba tortent, de korrigalunk...
        }
        
        var data:[UInt8] = [UInt8](repeating: 0x55, count: expsize )
        
        var bitpos:Int = 0
        var bitbuff:Int = 0
        
        func pullbit()->Int {
            if bitpos==0 {
                bitbuff = bin
                bin += 1
            }
			if bitbuff>=pdata.count { error += 1; return 0 }
            let bit:Int = (pdata[ bitbuff ] & bits[bitpos])>0 ? 1:0
            bitpos = (bitpos+1)&0x07
            return bit
        }
        func pullnbits( nbit:Int )->Int {
            var n:Int = 0
            var ab:Int = nbit-1
            for _ in 0..<nbit {
                n += pullbit()*anbits[ab]
                ab -= 1
            }
            return n
        }
        func pulldatabits( bitdepths:[UInt8], l:Int )->Int {
            var b:Int
            var vbit:Int = 0
            var actbits:Int = Int(bitdepths[ vbit ])
            var fix:Int = 0
            
            for _ in 1..<l {
                b = pullbit()
                if b==1 { break }
                
                fix += 1<<actbits
                vbit += 1
                actbits = Int(bitdepths[ vbit ])
            }
            return pullnbits( nbit: actbits )+fix;
        }
        
        let USELOOKUP:Bool = pullbit()==1
        let NEGCHECK:Bool = pullbit()==1
        let DIR:Bool = pullbit()==1
        
        #if DEBUG
            print( "USELOOKUP: \(USELOOKUP)\nNEGCHECK: \(NEGCHECK)\nDIR: \(DIR)" )
        #endif
        
        var ll:Int = 0
        
        var rlookup:[UInt8] = [UInt8](repeating: 0, count: 256)
        var LIbitdepths:[UInt8] = [UInt8](repeating: 0, count: maxpatterns)
        var CNTbitdepths:[UInt8] = [UInt8](repeating: 0, count: maxpatterns)
        var DISTbitdepths:[UInt8] = [UInt8](repeating: 0, count: maxpatterns)
        var LIbitdepthscount:Int = 0
        var CNTbitdepthscount:Int = 0
        var DISTbitdepthscount:Int = 0
        
        if USELOOKUP {
            ll = Int(pdata[ bin ])
            if ll==0 { ll = 256 }
            if bin+ll+4 > filesize { return pdata } // hiba
            print("LUT entries: \(ll)")
            bin += 1
            for i:Int in 0..<ll { rlookup[i] = pdata[ bin+i ] }
            bin += ll
            
            LIbitdepthscount = pullnbits( nbit: 3 )+1;
            for i:Int in 0..<LIbitdepthscount { LIbitdepths[i] = UInt8(pullnbits( nbit: 3 )+1) }
            
            #if DEBUG
                var out:String="LIbitdepths: "
                for i:Int in 0..<LIbitdepthscount { out += "\( LIbitdepths[i] ) " }
                print( out )
            #endif
        }
        
        CNTbitdepthscount = pullnbits( nbit: 3 )+1;
        for i:Int in 0..<CNTbitdepthscount { CNTbitdepths[i] = UInt8(pullnbits( nbit: 4 )+1) }
        DISTbitdepthscount = pullnbits( nbit: 3 )+1;
        for i:Int in 0..<DISTbitdepthscount { DISTbitdepths[i] = UInt8(pullnbits( nbit: 4 )+1) }
 
        #if DEBUG
            var out:String="CNTbitdepths: "
            for i:Int in 0..<CNTbitdepthscount { out += "\( CNTbitdepths[i] ) " }
            out += "\nDISTbitdepths: "
            for i:Int in 0..<DISTbitdepthscount { out += "\( DISTbitdepths[i] ) " }
            print( out )
        #endif

        
        var bout:Int = 0
        var isStream:Bool = true
        var next:Bool = false
        
        var stcnt:Int = 0
        var b:UInt8
        var src:Int
        var L:Int
        var neg:Int
        var dist:Int
        
        
        while bout<expsize && error==0 {
            if isStream {
                stcnt = pulldatabits( bitdepths: CNTbitdepths, l: CNTbitdepthscount );
                for i:Int in 0...stcnt {
                    if USELOOKUP {
                        
                        b = rlookup[ pulldatabits( bitdepths: LIbitdepths, l: LIbitdepthscount )&0xFF ]
                       
                    } else {
                        if bin >= filesize { print("bin too big"); return pdata }
                        b = pdata[ bin ]
                        bin += 1
                    }
                    if bout<expsize {
                        data[ bout ] = b
                        bout += 1
                    }
                }
                isStream = false
            } else {
                isStream = pullbit()>0
                dist = pulldatabits( bitdepths: DISTbitdepths, l: DISTbitdepthscount)
                //cout << hex << +bout << " - RDIST: " << +dist << "\n";
				if dist>maxd { maxd = dist }
				
                src = bout-dist
                L = pulldatabits( bitdepths: CNTbitdepths, l: CNTbitdepthscount )+mmchl
				if L>maxc { maxc = L }
				
                neg = NEGCHECK ? pullbit() : 0
                for i:Int in 0..<L {
                    if bout>=expsize { bout = expsize-1; error += 1 }
                    if src<0 { src = 0; error += 1 }
                    if src>=expsize { src = expsize-1; error += 1 }
                    data[ bout ] = ( neg>0 ? 255-data[ src ]: data[ src ] )
                    bout += 1
                    src += 1
                }
            }
        }

		print("DIST max = \( maxd )")
		print("CNT max = \( maxc )")

		print( "Error: \( error )" )
        if expsize != bout || error>0 { return pdata }
        //decompressedLength = bout
        //decompressedBW = BW
		
        lastCommandSuccess = true
        
        lastSettings.BW = BW
        lastSettings.H = H
        lastSettings.NEGCHECK = NEGCHECK
        lastSettings.DIR = DIR
        lastSettings.USELOOKUP = USELOOKUP
		lastSettings.MAXC = maxc-mmchl
		lastSettings.MAXD = maxd

        /* Do reorder here */
        if DIR {
            var rdata:[UInt8] = [UInt8](repeating: 0, count: data.count )
            for y:Int in 0..<H {
                for x:Int in 0..<BW {
                    rdata[x+y*BW] =  data[x*H+y]
                }
            }
            return [UInt8](rdata[..<Int(H*BW)])
        }
        
        return [UInt8](data[..<bout])
    }
    
    // megoldani a settings adaptalasat az utolso feladathoz (BW, MAXD, MAXC, stb)
    
    
}
