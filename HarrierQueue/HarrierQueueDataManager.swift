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
    let dateCreated: Expression<NSDate>
    let retryLimit: Expression<Int64>
    let availabilityDate: Expression<NSDate>
    let data: Expression<String>

    internal init?(filepath: String) {
        do {
            db = try Connection(filepath)
            tasks = Table("tasks")
            uid = Expression<String>("id")
            name = Expression<String?>("name")
            failCount = Expression<Int64>("failCount")
            priorityLevel = Expression<Int64>("priorityLevel")
            dateCreated = Expression<NSDate>("dateCreated")
            retryLimit = Expression<Int64>("retryLimit")
            availabilityDate = Expression<NSDate>("availabilityDate")
            data = Expression<String>("data")
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
                t.column(data)
                })
        } catch  {
            // assume for now that it failed because the table already exists
        }
    }
    
    
    internal func addNewTask(task: HarrierTask) throws {
        var dataAsString = ""
        do {
            if let s = String.init(data: try NSJSONSerialization.dataWithJSONObject(task.data, options: NSJSONWritingOptions.init(rawValue: 0)), encoding: NSUTF8StringEncoding) {
                dataAsString = s
            }
        } catch {
            print("Failed to serialize data for task \"\(task.name)\". This info won't be saved.")
            print(error)
        }
        let insert = tasks.insert(uid <- task.uniqueIdentifier, name <- task.name, failCount <- task.failCount, priorityLevel <- task.priorityLevel, dateCreated <- task.dateCreated, retryLimit <- task.retryLimit, availabilityDate <- task.availabilityDate, data <- dataAsString)
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
    
    internal func fetchTasksFromDB()->[HarrierTask] {
        var savedTasks = [HarrierTask]()
        do {
            for dbtask in try db.prepare(tasks) {
                var taskData = [String: String]()
                if let encodedData = dbtask[data].dataUsingEncoding(NSUTF8StringEncoding) {
                    if let decodedData = try NSJSONSerialization.JSONObjectWithData(encodedData, options: NSJSONReadingOptions.init(rawValue: 0)) as? [String: String] {
                        taskData = decodedData
                    }
                }
                let task = HarrierTask(name: dbtask[name], priority: dbtask[priorityLevel], taskAttributes: taskData, retryLimit: dbtask[retryLimit], availabilityDate: dbtask[availabilityDate],dateCreated: dbtask[dateCreated])
                task.failCount = dbtask[failCount]
               // task.userInfo = [NSJSONSerialization JSONObjectWithData:[resultDictionary[@"userInfo"] dataUsingEncoding:NSUTF8StringEncoding] options:0 error:NULL] ?: @{};
                
                
                savedTasks.append(task)
            }
        } catch {
            print("Could not load tasks.")
        }
        return savedTasks
    }
    
}