//
//  HarrierQueueDataManager.swift
//  Pods
//
//  Created by Graham Chance on 8/30/15.
//
//

import Foundation
import SQLite

internal struct HarrierQueueDataManager {
    
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
            dateCreated = Expression<NSTimeInterval>("dateCreated")
            retryLimit = Expression<Int64>("retryLimit")
            availabilityDate = Expression<NSDate>("availabilityDate")
        } catch {
            print("\n\n")
            print(error)
            return nil
        }
        
        do {
            try db.run(tasks.create { t in
                t.column(uid, primaryKey: true)
                t.column(name)
                t.column(failCount)
                t.column(priorityLevel)
                t.column(dateCreated)
                t.column(retryLimit)
                t.column(availabilityDate)
                })
        } catch  {
            // assume for now that it failed because the table already exists
        }
    }
    
    
    internal func addNewTask(task: HarrierTask) throws {
        let insert = tasks.insert(uid <- task.uniqueIdentifier, name <- task.name, failCount <- task.failCount, priorityLevel <- task.priorityLevel, dateCreated <- task.dateCreated, retryLimit <- task.retryLimit, availabilityDate <- task.availabilityDate)
        try db.run(insert)
    }
    
    internal func updateTaskFailCount(task: HarrierTask) throws {
        let dbtask = tasks.filter(uid == task.uniqueIdentifier)
        try db.run(dbtask.update(failCount <- task.failCount))

    }
    
    internal func removeTask(task: HarrierTask) throws {
        let dbtask = tasks.filter(uid == task.uniqueIdentifier)
        try db.run(dbtask.delete())
    }
    
    internal func fetchTasksFromDB(complete:[HarrierTask]->()) {
        // TODO: Run on background thread
        var savedTasks = [HarrierTask]()
        do {
            for dbtask in try db.prepare(tasks) {
                let task = HarrierTask(name: dbtask[name], priority: dbtask[priorityLevel], taskAttributes: [:], retryLimit: dbtask[retryLimit], availabilityDate: dbtask[availabilityDate])
                task.dateCreated = dbtask[dateCreated]
                task.failCount = dbtask[failCount]
                savedTasks.append(task)
            }
        } catch {
            print("Could not load tasks.")
        }
        complete(savedTasks)
    }
    
}