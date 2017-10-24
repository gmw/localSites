//
//  Preferences.swift
//  LocalSites
//
//  Created by Magnus Wissler on 2017-10-23.
//  Copyright © 2017 plan44.ch. All rights reserved.
//

import Foundation

struct Preferences {
    
    var useMonochromeIcon: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "monochromeIcon")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "monochromeIcon")
        }
    }
    
    var bonjourDomains: [String] {
        get {
            if let domains = UserDefaults.standard.array(forKey: "bonjourDomains") as? [String] {
               return domains
            } else {
                return ["dns-sd.org."]
            }
            
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "bonjourDomains")
        }
    }
}
