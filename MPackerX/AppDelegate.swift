//
//  AppDelegate.swift
//  MPackerX
//
//  Created by Macc on 18/12/27.
//  Copyright © 2018. Macc. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var viewcontroller:ViewController? = nil
    
    @IBOutlet weak var newMenuItem: NSMenuItem!
    @IBOutlet weak var openMenuItem: NSMenuItem!
    @IBOutlet weak var clearRecentMenuItem: NSMenuItem!
    @IBOutlet weak var saveAsMenuItem: NSMenuItem!
    @IBOutlet weak var importExportMenuItem: NSMenuItem!
    @IBOutlet weak var pageSetupMenuItem: NSMenuItem!
    @IBOutlet weak var printMenuItem: NSMenuItem!
    @IBOutlet weak var cutMenuItem: NSMenuItem!
    @IBOutlet weak var copyMenuItem: NSMenuItem!
    @IBOutlet weak var pasteMenuItem: NSMenuItem!
    @IBOutlet weak var selectAllMenuItem: NSMenuItem!
    @IBOutlet weak var findMenuItem: NSMenuItem!
    @IBOutlet weak var findAndReplaceMenuItem: NSMenuItem!
    @IBOutlet weak var findNextMenuItem: NSMenuItem!
    @IBOutlet weak var findPreviousMenuItem: NSMenuItem!
    @IBOutlet weak var useSelectionForFindMenuItem: NSMenuItem!
    @IBOutlet weak var jumpToSelectionMenuItem: NSMenuItem!
    @IBOutlet weak var invertMenuItem: NSMenuItem!
    @IBOutlet weak var reorderMenuItem: NSMenuItem!
    @IBOutlet weak var cropMenuItem: NSMenuItem!
    @IBOutlet weak var packMenuItem: NSMenuItem!
    @IBOutlet weak var unpackMenuItem: NSMenuItem!
    @IBOutlet weak var mpacker9bMenuItem: NSMenuItem!
    @IBOutlet weak var autoRepackMenuItem: NSMenuItem!
    @IBOutlet weak var autoUnpackMenuItem: NSMenuItem!
    @IBOutlet weak var autoUpdateSettingsMenuItem: NSMenuItem!
    @IBOutlet weak var defaultSettingsMenuItem: NSMenuItem!
    @IBOutlet weak var mpackerxHelpMenuItem: NSMenuItem!
    
    //var mvc:ViewController? = nil

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    // Quit Application on main window close
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        NSApplication.shared.terminate(self)
        return true
    }
 
    func setViewController( vc:ViewController ) {
        // this func is called from the ViewController, now appdelegate have access to it!
        viewcontroller = vc
    }
    // Function needed to open files from the finder
    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        viewcontroller?.openFileFromFinder( file: filename )
        return true
    }

}

