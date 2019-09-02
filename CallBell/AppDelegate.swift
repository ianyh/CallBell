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
    
    @IBOutlet var usernameField: NSTextField?
    @IBOutlet var tokenField: NSSecureTextField?
    
    @IBOutlet var mainMenu: NSMenu?
    
    private var monitor: ReviewRequestsMonitor?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem?.menu = statusMenu
        
        let version = Bundle.main.infoDictionary?["CFBundleVersion"] as! String
        let shortVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String
        versionMenuItem?.title = "Version \(shortVersion) (\(version))"
        
        DispatchQueue.main.async {
            self.resetMonitoring()
        }
    }
    
    @IBAction func openReviewRequests(sender: Any) {
        NSWorkspace.shared.open(URL(string: "https://github.com/pulls/review-requested")!)
    }
    
    @IBAction func saveToken(sender: Any) {
        guard let username = usernameField?.stringValue, !username.isEmpty else {
            return presentError()
        }
        
        guard let token = tokenField?.stringValue.data(using: .utf8), !token.isEmpty else {
            return presentError()
        }
        
        let userData = UserData(username: username, token: token)
        
        do {
            try userData.save()
        } catch {
            presentError(error)
        }
        
        resetMonitoring()
    }
    
    private func presentError(_ error: Error? = nil) {
        let alert = NSAlert()
        alert.messageText = error.flatMap { $0.localizedDescription } ?? "Unknown Error"
        alert.runModal()
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
    
    private func resetMonitoring() {
        do {
            let userData = try UserData.existingUserData()
            
            monitor = ReviewRequestsMonitor(userData: userData) { [weak self] result in
                do {
                    let hasReviewRequests = try result.get()
                    self?.updateStatusImage(isEnabled: hasReviewRequests)
                } catch {
                    self?.presentError(error)
                }
            }
            monitor?.start()
        } catch {
            monitor = nil
            
            if let userDataError = error as? UserDataError, case .noStoredData = userDataError {
                updateStatusImage(isEnabled: false)
            } else {
                presentError(error)
            }
            
            return
        }
    }
}
