//
//  HarrierTask.swift
//  HarrierQueue
//
//  Created by Graham Chance on 8/29/15.
//
//

import Foundation

public enum HarrierTaskCompletionStatus: String {
    case Incomplete = "Incomplete",
    Success = "Success",
    Failure = "Failure",
    Abandon = "Abandon",
    Canceled = "Canceled"
}



public class HarrierTask: NSOperation {
    
    
    /// The priority measurement that ranks above all others. 0 (low priority) - infinity (high priority)
    public let basePriority: Int
    
    public let dateCreated: NSTimeInterval
    
    public var retryCount: Int
    
    public let taskAttributes: [String: String]
    
    private var _finished = false
    private var _executing = false
    private var _completionStatus: HarrierTaskCompletionStatus?
    
    public var completionStatus: HarrierTaskCompletionStatus? {
        return _completionStatus
    }
    
    override public var executing: Bool {
        get { return _executing }
        set {
            willChangeValueForKey("isExecuting")
            _executing = newValue
            didChangeValueForKey("isExecuting")
        }
    }
    
    override public var finished:Bool {
        get { return _finished }
        set {
            willChangeValueForKey("isFinished")
            _finished = newValue
            didChangeValueForKey("isFinished")
        }
    }
    
    public var uniqueIdentifier: String {
        var identifier = "HarrierTask"
        for (key, value) in taskAttributes {
            identifier = identifier + "-\(key):\(value)"
        }
        return identifier
    }
    
    public init(basePriority: Int, taskAttributes: [String: String]) {
        self.basePriority = basePriority
        self.dateCreated = NSDate().timeIntervalSince1970
        self.retryCount = 0
        self.taskAttributes = taskAttributes
        super.init()
    }
    
    public func isHigherPriority(thanTask other: HarrierTask) -> Bool {
        return basePriority > other.basePriority || (basePriority == other.basePriority && retryCount < other.retryCount && dateCreated < other.dateCreated)
    }
    
    public override func cancel() {
        super.cancel()
        _completionStatus = .Canceled
        finished = true
    }
    
    public func completeWithStatus(status: HarrierTaskCompletionStatus) {
        _completionStatus = status
        finished = true
    }
    
}

public func ==(lhs: HarrierTask, rhs: HarrierTask) -> Bool {
    return lhs.uniqueIdentifier == rhs.uniqueIdentifier
}
