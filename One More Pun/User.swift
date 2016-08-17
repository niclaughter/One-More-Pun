//
//  User.swift
//  One More Pun
//
//  Created by Nicholas Laughter on 8/16/16.
//  Copyright © 2016 Areios. All rights reserved.
//

import Foundation
import Firebase

class User: FirebaseType {
    
    let email: String
    let username: String
    
    private let emailKey = "email"
    private let usernameKey = "username"
    
    var endpoint: String {
        return "users"
    }
    
    var identifier: String?
    
    var dictionaryCopy: [String : AnyObject] {
        return [emailKey: email, usernameKey: username]
    }
    
    init(email: String, username: String, identifier: String) {
        self.email = email
        self.username = username
        self.identifier = identifier
    }
    
    required init?(dictionary: [String : AnyObject], identifier: String) {
        guard let email = dictionary[emailKey] as? String,
            username = dictionary[usernameKey] as? String else { return nil }
        self.email = email
        self.username = username
    }
}