//
//  HarrierQueueDatabase.swift
//  Pods
//
//  Created by Graham Chance on 8/30/15.
//
//

import Foundation
import FMDB

internal class HarrierQueueDatabase {
    
    let databaseQueue: FMDatabaseQueue
    
    public init(filepath: String) {
        
        databaseQueue = FMDatabaseQueue
    }
}