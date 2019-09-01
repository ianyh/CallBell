//
//  AppDelegate.swift
//  CallBell
//
//  Created by Ian Ynda-Hummel on 9/1/19.
//  Copyright © 2019 Ian Ynda-Hummel. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    @IBOutlet var statusMenu: NSMenu?
    @IBOutlet var versionMenuItem: NSMenuItem?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let statusItemImage = NSImage(named: "status")
        statusItemImage?.isTemplate = true

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem?.button?.image = statusItemImage
        statusItem?.menu = statusMenu
        
        let version = Bundle.main.infoDictionary?["CFBundleVersion"] as! String
        let shortVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String
        versionMenuItem?.title = "Version \(shortVersion) (\(version))"
    }
    
    @IBAction func openReviewRequests(sender: Any) {
        NSWorkspace.shared.open(URL(string: "https://github.com/pulls/review-requested")!)
    }
}
