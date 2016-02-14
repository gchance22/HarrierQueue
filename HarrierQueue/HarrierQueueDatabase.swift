//
//  HarrierQueueDatabase.swift
//  Pods
//
//  Created by Graham Chance on 8/30/15.
//
//

import Foundation
import SQLite

internal struct HarrierQueueDatabase {
    
    let db: Connection
    let tasks: Table
    let uid: Expression<String>
    let name: Expression<String?>
    let failCount: Expression<Int64>
    let priorityLevel: Expression<Int64>
    let dateCreated: Expression<NSTimeInterval>
    let retryLimit: Expression<Int64>
    let availabilityDate: Expression<NSDate>
    
    internal init?(filepath: String) {
        do {
            db = try Connection(filepath)
            tasks = Table("tasks")
            uid = Expression<String>("id")
            name = Expression<String?>("name")
            failCount = Expression<Int64>("failCount")
            priorityLevel = Expression<Int64>("priorityLevel")
            dateCreated = Expression<NSTimeInterval>("priorityLevel")
            retryLimit = Expression<Int64>("retryLimit")
            availabilityDate = Expression<NSDate>("availabilityDate")

            try db.run(tasks.create { t in
                t.column(uid, primaryKey: true)
                t.column(name)
                t.column(failCount)
                t.column(priorityLevel)
                t.column(dateCreated)
                t.column(retryLimit)
                t.column(availabilityDate)
                })
            
        } catch {
            return nil
        }
    }
    
    
    internal func addNewTask(task: HarrierTask) throws {
        let insert = tasks.insert(name <- task.name, failCount <- task.failCount, priorityLevel <- task.priorityLevel, dateCreated <- task.dateCreated, retryLimit <- task.retryLimit, availabilityDate <- task.availabilityDate)
        try db.run(insert)
    }
    
    internal func updateTaskFailCount(task: HarrierTask) throws {
        let dbtask = tasks.filter(uid == task.uniqueIdentifier)
        try db.run(dbtask.update(failCount <- task.failCount))

    }
    
}