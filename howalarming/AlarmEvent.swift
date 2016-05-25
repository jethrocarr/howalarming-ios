//
//  AlarmEvent.swift
//  howalarming
//
//  Defines the data objects for alarm events.
//
//  Created by Jethro Carr on 25/05/16.
//  Copyright © 2016 Jethro Carr. All rights reserved.
//

import Foundation


class AlarmEvent: NSObject {
    
    // MARK: Properties
    var type: String
    var code: String
    var message: String
    var raw: String
    
    
    // MARK: Initialization
    init?(type: String, code: String, message: String, raw: String) {
        // Initalize properties
        self.type = type
        self.code = code
        self.message = message
        self.raw = raw

        // TODO: No need for validation currently, they are all expected and all strings.
    }
    
}