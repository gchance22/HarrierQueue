//
//  HarrierTask.swift
//  HarrierQueue
//
//  Created by Graham Chance on 8/29/15.
//
//

import Foundation

/// No retry constant.
public let kNoRetryLimit = -1

/**
 Task status.
 
 - Waiting: Queued, but not running.
 - Running: Currently running.
 - Done:    Done running.
 */
public enum HarrierTaskStatus: String {
    case Waiting
    case Running
    case Done
}

/**
 Completion status of a task.
 
 - Success: Completed entirely with no issues.
 - Failed:  Failed to complete.
 - Abandon: Task has been abandoned, i.e. not completed, but will not be attempted again.
 */
public enum HarrierTaskCompletionStatus: String {
    case Success
    case Failed
    case Abandon
}


/**
 *  The delegate for HarrierTasks.
 */
internal protocol HarrierTaskDelegate {
    func taskDidCompleteWithStatus(task: HarrierTask, status: HarrierTaskCompletionStatus)
}


/// A Task to be queued in a HarrierQueue.
public class HarrierTask: Equatable {
    
    private var status: HarrierTaskStatus?
    
    private var delegate: HarrierTaskDelegate?
    
    /// The number of times the task has failed.
    internal var failCount: Int64

    /// The name of the task. Not required. Note it is used in the uniqueIdentifier.
    public let name: String?
    
    /// The priority measurement that ranks above all others. 0 (low priority) - infinity (high priority)
    public let priorityLevel: Int64
    
    /// The date the task was first initialized.
    public let dateCreated: NSDate
    
    /// The number of times the task can be retried before it is abandoned.
    public let retryLimit: Int64
    
    /// Any data or information that the task holds.
    public let data: NSDictionary
    
    /// The soonest the task can be executed.
    public var availabilityDate: NSDate
    
    /// A combination of task name and data, creating a unique ID.
    public var uniqueIdentifier: String {
        var identifier = ""
        if let taskName = name { identifier += taskName }
        for (key, value) in data {
            identifier += "-\(key):\(value)"
        }
        return identifier
    }
    
    /**
     HarrierTask Initializer.
     
     - parameter name:             Task name.
     - parameter priority:         Priority of task relative to others (0 is lowest priority).
     - parameter taskAttributes:   A dictionary of any data the task contains.
     - parameter retryLimit:       How many times the task should be reattempted if it fails.
     - parameter availabilityDate: Date the task can be first attempted.
     - parameter dateCreated:      Current date by default. Don't change unless you have a good reason.
     
     - returns: Returns a new HarrierTask with the given properties.
     */
    public init(name: String?, priority: Int64, taskAttributes: [String: String], retryLimit: Int64, availabilityDate: NSDate, dateCreated: NSDate = NSDate()) {
        self.name             = name
        self.priorityLevel    = priority
        self.data   = taskAttributes
        self.retryLimit       = retryLimit
        self.availabilityDate = availabilityDate
        self.dateCreated      = dateCreated
        self.failCount        = 0
    }
    
    /**
     Compares the task to another, based on priority in the queue.
     
     - parameter other: The task to compare to.
     
     - returns: Returns whether this task is higher priority to the given task.
     */
    public func isHigherPriority(thanTask other: HarrierTask) -> Bool {
        if self.availabilityDate.timeIntervalSinceNow > 0 { 
            return self.availabilityDate.timeIntervalSinceNow < other.availabilityDate.timeIntervalSinceNow
        } else if other.availabilityDate.timeIntervalSinceNow > 0 {
            return true
        } else {
            return priorityLevel > other.priorityLevel || (priorityLevel == other.priorityLevel && failCount < other.failCount && dateCreated.timeIntervalSince1970 < other.dateCreated.timeIntervalSince1970)
        }
    }
    
    /**
     Completes the task.
     
     - parameter completionStatus: The status of completion, i.e. success, failed, or abandoned.
     */
    internal func completeWithStatus(completionStatus: HarrierTaskCompletionStatus) {
        self.status = .Done
        delegate?.taskDidCompleteWithStatus(self, status: completionStatus)
    }
    
}


public func ==(lhs: HarrierTask, rhs: HarrierTask) -> Bool {
    return lhs.uniqueIdentifier == rhs.uniqueIdentifier
}
