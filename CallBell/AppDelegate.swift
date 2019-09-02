//
//  AppDelegate.swift
//  CallBell
//
//  Created by Ian Ynda-Hummel on 9/1/19.
//  Copyright © 2019 Ian Ynda-Hummel. All rights reserved.
//

import Cocoa

enum RequestsStatus {
    case someRequests(Int)
    case noRequests
}

enum State {
    case starting
    case enabled(RequestsStatus)
    case disabled
}

extension State {
    func statusItemImage() -> NSImage? {
        let image: NSImage?
        
        switch self {
        case .starting:
            return nil
        case .enabled(.someRequests):
            image = NSImage(named: "status")
        case .enabled(.noRequests), .disabled:
            image = NSImage(named: "status-disabled")
        }
        
        image?.isTemplate = true
        return image
    }
    
    func countMenuItemTitle() -> String {
        switch self {
        case .starting:
            return ""
        case let .enabled(.someRequests(count)):
            return "\(count) requested reviews"
        case .enabled(.noRequests):
            return "No requested reviews"
        case .disabled:
            return "Disabled"
        }
    }
    
    var enabledState: NSControl.StateValue {
        switch self {
        case .starting, .disabled:
            return .off
        case .enabled:
            return .on
        }
    }
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    @IBOutlet var statusMenu: NSMenu?
    @IBOutlet var versionMenuItem: NSMenuItem?
    @IBOutlet var countMenuItem: NSMenuItem?
    @IBOutlet var enabledMenuItem: NSMenuItem?
    
    @IBOutlet var usernameField: NSTextField?
    @IBOutlet var tokenField: NSSecureTextField?
    
    @IBOutlet var mainMenu: NSMenu?
    
    private var monitor: ReviewRequestsMonitor?
    private var state: State = .starting {
        didSet {
            statusItem?.button?.image = state.statusItemImage()
            countMenuItem?.title = state.countMenuItemTitle()
            enabledMenuItem?.state = state.enabledState
        }
    }

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
    
    @IBAction func deleteToken(sender: Any) {
        do {
            let userData = try UserData.existingUserData()
            try userData.delete()
        } catch {
            presentError(error)
        }
        
        resetMonitoring()
    }
    
    @IBAction func toggleEnabled(sender: Any) {
        switch state {
        case .starting:
            return
        case .enabled:
            state = .disabled
        case .disabled:
            state = .starting
        }
        resetMonitoring()
    }
    
    private func presentError(_ error: Error? = nil) {
        let alert = NSAlert()
        alert.messageText = error.flatMap { $0.localizedDescription } ?? "Unknown Error"
        alert.runModal()
    }

    private func resetMonitoring() {
        if case .disabled = state {
            monitor = nil
            return
        }
        
        do {
            let userData = try UserData.existingUserData()
            
            monitor = ReviewRequestsMonitor(userData: userData) { [weak self] result in
                do {
                    let count = try result.get()
                    self?.state = count > 0 ? .enabled(.someRequests(count)) : .enabled(.noRequests)
                } catch {
                    self?.state = .enabled(.noRequests)
                    self?.presentError(error)
                }
            }
            monitor?.start()
        } catch {
            monitor = nil
            state = .enabled(.noRequests)
            
            if let userDataError = error as? UserDataError, case .noStoredData = userDataError {
                return
            }
            
            presentError(error)
        }
    }
}
