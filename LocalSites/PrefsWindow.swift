//
//  PrefsWindow.swift
//  LocalSites
//
//  Created by Lukas Zeller on 13.10.17.
//  Copyright © 2017 plan44.ch. All rights reserved.
//

import Cocoa

protocol PrefsWindowDelegate {
  func prefsDidUpdate()
}

class PrefsWindow: NSWindowController, NSWindowDelegate {

  @IBOutlet weak var monochromeIconCheckbox: NSButton!
  @IBOutlet weak var browseDomainsTable: NSTableView!
    
  var browseDomains = ["dns-sd.org."] // Default additional domain if nothing else specified (first run only!)
  var delegate: PrefsWindowDelegate?

  override var windowNibName : NSNib.Name! {
    return NSNib.Name(rawValue: "PrefsWindow")
  }

  override func windowDidLoad() {
    super.windowDidLoad()

    self.window?.center()
    self.window?.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)

    
    let defaults = UserDefaults.standard
    let monochrome = defaults.bool(forKey: "monochromeIcon")
    monochromeIconCheckbox.state = monochrome ? NSControl.StateValue.on : NSControl.StateValue.off
    
    if let domainList = defaults.array(forKey: "browseDomains") as? [String] {
        browseDomains = domainList
    }
    browseDomainsTable.dataSource = self
    browseDomainsTable.delegate = self
  }

    @IBOutlet weak var addRemoveControl: NSSegmentedControl!
    @IBAction func modifyDomainList(_ sender: NSSegmentedControl) {
        switch sender.selectedSegment {
        case 0: // Add
            browseDomains.insert("", at: 0)
            browseDomainsTable.insertRows(at: IndexSet(integer: 0), withAnimation:[.slideDown])
            
        case 1: // Remove
            let row = browseDomainsTable.selectedRow
            if row != -1 {
                browseDomains.remove(at: row)
                browseDomainsTable.removeRows(at: IndexSet(integer:row), withAnimation: [.slideUp])
            }
        default:
            break
        }
    }

    // MARK: - Table Actions
    
    @IBAction func tableAction(_ sender: NSTableView) {
        let selectedRow = sender.selectedRow
        if selectedRow != -1 && selectedRow < browseDomains.count {
            addRemoveControl.setEnabled(true, forSegment: 1)
        }
    }

    // MARK: - NSWindowDelegate
  func windowWillClose(_ notification: Notification) {
    let defaults = UserDefaults.standard
    defaults.setValue(monochromeIconCheckbox.state==NSControl.StateValue.on, forKey: "monochromeIcon")
    defaults.setValue(browseDomains, forKey: "browseDomains")

    delegate?.prefsDidUpdate()
  }

}

extension PrefsWindow: NSTableViewDataSource, NSTableViewDelegate {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return browseDomains.count
    }
    
    static let identifier = NSUserInterfaceItemIdentifier(rawValue: "domainListCell")
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let view = tableView.makeView(withIdentifier: PrefsWindow.identifier , owner: self) as! NSTableCellView
        
        view.textField?.stringValue  = browseDomains[row]
        return view
    }

    func tableView(_ tableView: NSTableView, shouldEdit tableColumn: NSTableColumn?, row: Int) -> Bool {
        return true
    }
    
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        return true
    }

    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        return browseDomains[row]
    }
    func tableView(_ tableView: NSTableView, setObjectValue object: Any?, for tableColumn: NSTableColumn?, row: Int) {
        browseDomains[row] = object as! String
    }
}
