//
//  Functions.swift
//  PasscodeLock
//
//  Created by Yanko Dimitrov on 8/28/15.
//  Copyright © 2015 Yanko Dimitrov. All rights reserved.
//

import Foundation

func localizedStringFor(_ key: String, comment: String) -> String {
    
    let name = "PasscodeLock"
    let bundle = bundleForResource(name, ofType: "strings")

    return NSLocalizedString(key, tableName: name, bundle: bundle, comment: comment)
}

func bundleForResource(_ name: String, ofType type: String) -> Bundle {
    
    if(Bundle.main.path(forResource: name, ofType: type) != nil) {
        return Bundle.main
    }
    
    // Modified by X 20171025
//    return Bundle(for: PasscodeLock.self)
    let bundle = Bundle(for: PasscodeLock.self)
    let url = bundle.url(forResource: "PasscodeLock", withExtension: "bundle")!
    return Bundle(url: url)!
    // ~
}
