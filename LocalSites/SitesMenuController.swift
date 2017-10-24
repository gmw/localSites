//
//  SitesMenuController.swift
//  LocalSites
//
//  Created by Lukas Zeller on 24.09.17.
//  Copyright © 2017 plan44.ch. All rights reserved.
//

import Cocoa
import Foundation
import os

class SitesMenuController: NSObject, NetServiceBrowserDelegate, NetServiceDelegate, NSMenuDelegate, PrefsWindowDelegate {

    @IBOutlet weak var statusMenu: NSMenu!
    @IBOutlet weak var operationModeItem: NSMenuItem!
    
    let debugOutput = true
    
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength);
    
    var aboutWindow: AboutWindow!
    var prefsWindow: PrefsWindow!
    var prefs = Preferences()
    var netServiceBrowsers = [NetServiceBrowser]();
    var services: Set<NetService> = Set();
    
    var numStaticMenuItems = 0;
    let headerMenuItems = 1;
    var menuIsOpen = false;
    
    var pendingResolves = 0;
    
    enum Browsers {
        case system
        case firefox
        case chrome
        case safari
        case opera
        case icab
    }
    
    var browser = Browsers.system;
    
    let browserTexts = [
        Browsers.system : "default browser",
        Browsers.firefox : "Firefox",
        Browsers.chrome : "Chrome",
        Browsers.safari : "Safari",
        Browsers.opera : "Opera",
        Browsers.icab : "iCab"
    ]
    
    let browserBundleIds = [
        Browsers.firefox : "org.mozilla.firefox",
        Browsers.chrome : "com.google.Chrome",
        Browsers.safari : "com.apple.Safari",
        Browsers.opera : "com.operasoftware.Opera",
        Browsers.icab : "de.icab.iCab"
    ]

    override func awakeFromNib() {
        updateIcon()
        statusItem.menu = statusMenu
        numStaticMenuItems = statusMenu.items.count
        refreshMenu() // make sure we display the "no bonjour found" item until bonjour finds something for the first time
        aboutWindow = AboutWindow()
        prefsWindow = PrefsWindow()
        prefsWindow.delegate = self
        
        startServiceBrowsers()
    }

    func startServiceBrowsers() {
        // - start network service search for default domain
        
        let nsb = NetServiceBrowser()
        nsb.delegate = self
        nsb.searchForServices(ofType: "_http._tcp", inDomain: "")
        
        netServiceBrowsers.append(nsb)
        
        let browseDomains = prefs.bonjourDomains
        
        // Search additional domains
        for domainName in browseDomains {
            let nsb = NetServiceBrowser()
            nsb.delegate = self
            nsb.searchForServices(ofType: "_http._tcp", inDomain: domainName)
            print("Starting search in domain \(domainName)")
            netServiceBrowsers.append(nsb)
        }
    }

    func stopServiceBrowsers() {
        for sb in netServiceBrowsers {
            sb.stop()
        }
        netServiceBrowsers.removeAll()
    }
    
    func updateOpStatus() {
        if let om = operationModeItem {
            om.title = "Open in \(browserTexts[browser] ?? "unknown"):"
        }
    }


  // MARK: - NSMenuDelegate -

    func menuWillOpen(_ menu: NSMenu) {
        if let currentFlags = NSApp.currentEvent?.modifierFlags {
            // - modifier watch
            switch currentFlags.intersection(.deviceIndependentFlagsMask) {
            case [.option] :
                self.browser = Browsers.firefox
            case [.option, .shift] :
                self.browser = Browsers.icab
            case [.control]:
                self.browser = Browsers.chrome
            case [.control, .shift]:
                self.browser = Browsers.opera
            case [.control, .option]:
                self.browser = Browsers.safari
            default:
                self.browser = Browsers.system
            }
        }
        updateOpStatus();
        menuIsOpen = true;
    }

    func menuDidClose(_ menu: NSMenu) {
        menuIsOpen = false;
    }

    // MARK: - NetServiceBrowserDelegate -
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didFindDomain domainString: String, moreComing: Bool) {
        print("Found domain \(domainString) with \(browser.debugDescription)")
    }
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didRemoveDomain domainString: String, moreComing: Bool) {
        print("Removed domain \(domainString)")
    }
    
    func netServiceBrowser(_: NetServiceBrowser , didFind service: NetService, moreComing: Bool) {
        if debugOutput { print("didFind '\(service.name)', domain:\(service.domain), hostname:\(service.hostName ?? "<none>") - \(moreComing ? "more coming" : "all done")") }
        services.insert(service)
        service.delegate = self
        service.resolve(withTimeout:5)
        pendingResolves += 1
        if !moreComing {
            refreshMenu()
        }
    }

    func netServiceBrowser(_:NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
        if debugOutput { print("didRemove '\(service.name)' domain:\(service.domain), hostname:\(service.hostName ?? "<none>") - \(moreComing ? "more coming" : "all done")") }
        services.remove(service)
        if !moreComing {
            refreshMenu()
        }
    }
    
    func netServiceBrowserWillSearch(_:NetServiceBrowser) {
        if debugOutput { print("netServiceBrowserWillSearch") }
    }

    func netServiceBrowser(_:NetServiceBrowser, didNotSearch errorDict: [String : NSNumber]) {
        print("netServiceBrowser didNotSearch:\(errorDict)")
    }

    func netServiceBrowserDidStopSearch(_:NetServiceBrowser) {
        if debugOutput { print("netServiceBrowserDidStopSearch") }
    }

    // MARK: - NetServiceDelegate -
    
    func netServiceDidResolveAddress(_ service: NetService) {
        if debugOutput { print("netService '\(service.name)' didResolveAddress hostname:\(service.hostName ?? "<none>")") }
        pendingResolves -= 1
        if pendingResolves < 1 {
            refreshMenu()
            pendingResolves = 0
        }
    }

    func netService(_ service: NetService, didNotResolve errorDict: [String : NSNumber])
    {
        if debugOutput { print("netService '\(service.name)' didNotResolve error:\(errorDict)") }
        services.remove(service)
        if pendingResolves < 1{
            refreshMenu()
            pendingResolves = 0
        }
    }
    
    func netServiceDidStop(_ sender: NetService) {
        services.remove(sender)
    }

    // MARK: - Menu management
    
    func refreshMenu() {
        if debugOutput {
            for service in services {
                print("- '\(service.name)'    -    '\(service.hostName ?? "<none>")'")
            }
        }
        
        // remove the previous menu items
        for _ in 0..<statusMenu.items.count-numStaticMenuItems {
            statusMenu.removeItem(at: headerMenuItems)
        }
        // show new services
        if (services.count>0) {
            // sort the services
            let sortedServices : [NetService] = services.sorted(by: { $0.name.caseInsensitiveCompare($1.name) == .orderedDescending });
            for service in sortedServices {
                let item = NSMenuItem();
                item.title = service.name;
                item.representedObject = service;
                item.target = self
                item.action = #selector(localSiteMenuItemSelected)
                item.isEnabled = service.hostName != nil
                statusMenu.insertItem(item, at: headerMenuItems)
            }
        }
        else {
            // no bonjour items
            let item = NSMenuItem();
            item.title = "No Bonjour websites found";
            item.isEnabled = false
            statusMenu.insertItem(item, at: headerMenuItems)
        }
    }

    // MARK: - Actions
    
    @objc func localSiteMenuItemSelected(_ sender:Any) {
        if let item = sender as? NSMenuItem, let service = item.representedObject as? NetService {
            if debugOutput { print("- '\(service.name)'    -    '\(service.hostName ?? "<none>")'") }
            if let hoststring = service.hostName {
                // check for path
                var path = ""
                if let txtData = service.txtRecordData() {
                    let txtRecords = NetService.dictionary(fromTXTRecord: txtData)
                    if let pathData = txtRecords["path"],
                        let pathStr = String(data:pathData, encoding: .utf8) {
                        path = pathStr
                        if !path.starts(with: "/") {
                            path.insert("/", at: path.startIndex)
                        }
                    }
                }
                // check for dot at end of hostName
                var hostname = hoststring
                if (hostname.last ?? "_") == "." {
                    hostname.remove(at: hostname.index(before: hostname.endIndex))
                }
                if let url = URL(string: "http://" + hostname + ":" + String(service.port) + path) {
                    if let browserBundleId = browserBundleIds[browser] {
                        if debugOutput { print("have browser '\(browserBundleId)' open '\(url)'") }
                        NSWorkspace.shared.open([url], withAppBundleIdentifier: browserBundleId, options: NSWorkspace.LaunchOptions.default, additionalEventParamDescriptor: nil, launchIdentifiers: nil);
                    }
                    else {
                        // use system default browser
                        if debugOutput { print("have default browser open '\(url)'") }
                        NSWorkspace.shared.open(url)
                    }
                }
            }
        }
    }
    
    func prefsDidUpdate() {
        updateIcon()
        stopServiceBrowsers()
        startServiceBrowsers()
    }
    
    func updateIcon() {
        let defaults = UserDefaults.standard
        let monochrome = defaults.bool(forKey: "monochromeIcon")
        let icon = NSImage(named: NSImage.Name(rawValue: "statusIcon"))
        icon?.isTemplate = monochrome
        statusItem.image = icon
    }
    
    // MARK: - Actions -
    
    @IBAction func quitChosen(_ sender: NSMenuItem) {
        NSApplication.shared.terminate(self)
    }
    
    @IBAction func aboutChosen(_ sender: NSMenuItem) {
        aboutWindow.showWindow(nil)
    }
    
    @IBAction func prefsChosen(_ sender: NSMenuItem) {
        prefsWindow.showWindow(nil)
    }
}
