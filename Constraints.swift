//
//  Constraints.swift
//  SnapClient
//
//  Created by Josh Benson on 7/17/20.
//  Copyright © 2020 Kboy. All rights reserved.
//

import Foundation
import Firebase

struct Constants
{
    struct refs
    {
        static let databaseRoot = Database.database().reference()
        static let databaseChats = databaseRoot.child("chats")
    }
}
