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
    @IBOutlet weak var addRemoveControl: NSSegmentedControl!

    var browseDomains = [""]
    var delegate: PrefsWindowDelegate?
    var prefs = Preferences()
    
    override var windowNibName : NSNib.Name! {
        return NSNib.Name(rawValue: "PrefsWindow")
    }

    @IBOutlet weak var fieldEditor: NSTextField!
    
    override func windowDidLoad() {
        super.windowDidLoad()

        self.window?.center()
        self.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        monochromeIconCheckbox.state = prefs.useMonochromeIcon ? NSControl.StateValue.on : NSControl.StateValue.off
        browseDomains = prefs.bonjourDomains

        browseDomainsTable.dataSource = self
        browseDomainsTable.delegate = self
    }

    @IBAction func modifyDomainList(_ sender: NSSegmentedControl) {
        switch sender.selectedSegment {
        case 0: // Add
            browseDomains.append("")
            browseDomainsTable.reloadData()
            browseDomainsTable.editColumn(0, row: browseDomains.endIndex-1, with: nil, select: true)
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

    @IBAction func editCell(_ sender: NSTextField) {
        print("editCell")
        let row = browseDomainsTable.row(for: sender)
        browseDomains[row] = sender.stringValue
    }

    @IBAction func tableAction(_ sender: NSTableView) {
        print("tableAction")
        let selectedRow = sender.selectedRow
        if selectedRow != -1 && selectedRow < browseDomains.count {
            addRemoveControl.setEnabled(true, forSegment: 1)
        } else {
            addRemoveControl.setEnabled(false, forSegment: 1)
        }
    }

    // MARK: - NSWindowDelegate -

    func windowWillClose(_ notification: Notification) {
        prefs.useMonochromeIcon = (monochromeIconCheckbox.state == .on)
        prefs.bonjourDomains = browseDomains
        delegate?.prefsDidUpdate()
    }
}

// MARK: - Domain browsing list management

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

    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        print("shouldSelectRow: \(row)?")
        return true
    }

}
