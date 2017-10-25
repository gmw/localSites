//
//  LocalSites.swift
//  LocalSites
//
//  Created by Magnus Wissler on 2017-10-24.
//  Copyright © 2017 plan44.ch. All rights reserved.
//

import Foundation

protocol LocalSitesDelegate {
    func foundServices(_ services: [NetService])
}

extension NetService {
    func getHttpURL() -> URL? {
        if hostName != nil, let txtData = txtRecordData(), port != -1 {
            var urlString: String
            
            if port != 80 {
                urlString = "http://\(hostName!):\(port)"
            } else {
                urlString = "http://\(hostName!)"
            }
            
            let dict = NetService.dictionary(fromTXTRecord: txtData)
            if let pathData = dict["path"],
                let path = String(data:pathData, encoding:.utf8) {
                if !path.starts(with: "/") {
                    urlString += "/" + path
                } else {
                    urlString += path
                }
            }
            return URL(string: urlString)

        }
        return nil
    }
}
class LocalSites: NSObject {
    var domainsToBrowse: [String] = []
    var browsers = [String:NetServiceBrowser]()
    var services = [NetService]()
    var delegate: LocalSitesDelegate?
    
    func startBrowsing() {
        let browser = NetServiceBrowser()
        browser.searchForBrowsableDomains()
    }
    
    func stopBrowsing() {
        
    }
    
    func addBrowseDomain(_ domain: String) {
        let canonicalDomainName = canonicalize(domain)
        if !domainsToBrowse.contains(canonicalDomainName) {
            let browser = NetServiceBrowser()
            browser.delegate = self
            browser.searchForServices(ofType: "_http._tcp", inDomain: canonicalDomainName)
        }
    }

    func removeBrowseDomain(_ domain: String) {
        let canonicalDomainName = canonicalize(domain)
        
        if let browser = browsers[canonicalDomainName] {
            browser.stop()
            browsers.removeValue(forKey: canonicalDomainName)
        }
    }

    func canonicalize(_ domainName: String) -> String {
        guard !domainName.isEmpty else {
            return "local."
        }
        guard domainName.hasSuffix(".") else {
            return domainName + "."
        }
        return domainName
    }
    
}

// MARK: - NetServiceBrowserDelegate -

extension LocalSites: NetServiceBrowserDelegate {
    func netServiceBrowserWillSearch(_ browser: NetServiceBrowser) {
        
    }
    func netServiceBrowserDidStopSearch(_ browser: NetServiceBrowser) {
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String : NSNumber]) {
        
    }
    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        services.append(service)
        if !moreComing {
            delegate?.foundServices(services)
        }
    }
    
}

// MARK: - NetServiceDelegate -

extension LocalSites: NetServiceDelegate {
    func netServiceDidResolveAddress(_ sender: NetService) {
        
    }
    func netService(_ sender: NetService, didUpdateTXTRecord data: Data) {
        
    }
    func netService(_ sender: NetService, didNotResolve errorDict: [String : NSNumber]) {
        
    }
    
}
