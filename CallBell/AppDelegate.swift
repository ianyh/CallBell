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
    
    private lazy var monitor: ReviewRequestsMonitor = {
        return ReviewRequestsMonitor(username: "ianyh", token: "<>") { hasReviewRequests in
            self.updateStatusImage(isEnabled: hasReviewRequests)
        }
    }()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem?.menu = statusMenu
        
        let version = Bundle.main.infoDictionary?["CFBundleVersion"] as! String
        let shortVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String
        versionMenuItem?.title = "Version \(shortVersion) (\(version))"
        
        DispatchQueue.main.async {
            self.monitor.start()
        }
    }
    
    private func updateStatusImage(isEnabled: Bool) {
        let statusItemImage: NSImage?

        if isEnabled {
            statusItemImage = NSImage(named: "status")
        } else {
            statusItemImage = NSImage(named: "status-disabled")
        }
        
        statusItemImage?.isTemplate = true

        statusItem?.button?.image = statusItemImage
    }
    
    @IBAction func openReviewRequests(sender: Any) {
        NSWorkspace.shared.open(URL(string: "https://github.com/pulls/review-requested")!)
    }
}