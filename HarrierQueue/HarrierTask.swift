//
//  HarrierTask.swift
//  HarrierQueue
//
//  Created by Graham Chance on 8/29/15.
//
//

import Foundation


let kNoRetryLimit = -1

public enum HarrierTaskStatus: String {
    case Waiting = "Waiting"
    case Running = "Running"
    case Done    = "Success"
}

public enum HarrierTaskCompletionStatus: String {
    case Success = "Success"
    case Failed = "Failed"
    case Abandon = "Abandon"
}


public protocol HarrierTaskDelegate {
    func taskDidCompleteWithStatus(task: HarrierTask, status: HarrierTaskCompletionStatus)
}


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
    public let dateCreated: NSTimeInterval
    
    /// The number of times the task can be retried before it is abandoned.
    public var retryLimit: Int64
    
    /// Any data or information that the task holds.
    public let data: [String: String]
    
    /// The soonest the task can be executed.
    public var availabilityDate: NSDate
    
    
    public var uniqueIdentifier: String {
        var identifier = ""
        if let taskName = name { identifier += taskName }
        for (key, value) in data {
            identifier += "-\(key):\(value)"
        }
        return identifier
    }
    
    public init(name: String?, priority: Int64, taskAttributes: [String: String], retryLimit: Int64, availabilityDate: NSDate) {
        self.name             = name
        self.priorityLevel    = priority
        self.data   = taskAttributes
        self.retryLimit       = retryLimit
        self.availabilityDate = availabilityDate
        self.dateCreated      = NSDate().timeIntervalSince1970
        self.failCount        = 0
    }
    
    public func isHigherPriority(thanTask other: HarrierTask) -> Bool {
        return priorityLevel > other.priorityLevel || (priorityLevel == other.priorityLevel && failCount < other.failCount && dateCreated < other.dateCreated)
    }
    
    public func completeWithStatus(completionStatus: HarrierTaskCompletionStatus) {
        self.status = .Done
        delegate?.taskDidCompleteWithStatus(self, status: completionStatus)
    }
    
}

public func ==(lhs: HarrierTask, rhs: HarrierTask) -> Bool {
    return lhs.uniqueIdentifier == rhs.uniqueIdentifier
}
