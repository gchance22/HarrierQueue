//
//  Harrier.swift
//  Harrier
//  Version 1.0.0
//  Created by Graham Chance on 8/28/15.
//  Copyright (c) 2015 DoubleBlue. All rights reserved.
//

import Foundation

// Montagu's Harrier
// "As this bird has a wide distribution, it will take whatever prey is available in the area where it nests [and add them to its task queue]" - Wikipedia
//
public class Harrier: NSObject {
    
    /// Tasks waiting to be added to the activeQueue
    private var queuedTasks: [HarrierTask] = []
    
    /// Tasks currently ready and queued.
    private let activeQueue = NSOperationQueue()
    
    /// Should be the task equivalent of activeQueue.
    private var activeTasks: [HarrierTask] = []
    
    private var paused: Bool = false
    
    public var suspended: Bool {
        return !paused
    }
    
    public var maxConcurrentTasks: Int = 3
    
    init(maxConcurrentTasks: Int) {
        super.init()
        self.maxConcurrentTasks = maxConcurrentTasks
        activeQueue.maxConcurrentOperationCount = maxConcurrentTasks
        setUpKVO()
    }
    
    private func setUpKVO() {
        activeQueue.addObserver(self, forKeyPath: "operationCount", options: NSKeyValueObservingOptions.New  | NSKeyValueObservingOptions.Old, context: nil)
    }
    
    deinit {
        activeQueue.removeObserver(self, forKeyPath: "operationCount")
    }
    
    private func dequeueNextTask() {
        if queuedTasks.count > 0 {
            queuedTasks.removeLast()
        }
    }
    
    private func dequeueTask(task: HarrierTask) {
        activeTasks.append(task)
        activeQueue.addOperation(task.operation)
    }
    
    private func sortQueue() {
        // remember the array is ordered low priority first
        queuedTasks.sort { !$0.isHigherPriority(thanTask: $1) }
    }
    
    public override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
        if let queue = object as? NSOperationQueue {
            if keyPath == "operationCount" {
                if activeTasks.count < maxConcurrentTasks && suspended {
                    dequeueNextTask()
                }
            }
        }
    }

    
    // MARK: Public API
 
    /**
    Stop adding tasks to the activeQueue.
    */
    public func pause() {
        paused = true
    }
    
    /**
    Start adding tasks to the activeQueue again.
    */
    public func start() {
        paused = false
        if activeTasks.count < maxConcurrentTasks {
            dequeueNextTask()
        }
    }
    
    /**
    Cancel all tasks in activeQueue and empty queuedTasks.
    */
    public func cancelAll() {
        queuedTasks = []
        activeTasks = []
        for operation in activeQueue.operations {
            if let operation = operation as? NSOperation {
                operation.cancel()
            }
        }
    }
    
    /**
    Queues up the task.
    
    :param: task Task to be queued.
    */
    public func enqueueTask(task: HarrierTask) {
        queuedTasks.append(task)
        sortQueue()
        if activeTasks.count < maxConcurrentTasks && suspended {
            dequeueNextTask()
        }
    }

    
    
}


public class HarrierTask {

    let usesNetwork: Bool
    
    /// The priority measurement that ranks above all others. 0 (low priority) - infinity (high priority)
    public let basePriority: Int
    
    let operation: NSOperation
    
    let dateCreated: NSTimeInterval
    
    var retryCount: Int
    
    public init(operation: NSOperation, basePriority: Int, usesNetwork: Bool = true) {
        self.basePriority = basePriority
        self.usesNetwork = usesNetwork
        self.dateCreated = NSDate().timeIntervalSince1970
        self.operation = operation
        self.retryCount = 0
    }
    
    public func isHigherPriority(thanTask other: HarrierTask) -> Bool {
        return basePriority > other.basePriority || (basePriority == other.basePriority && retryCount < other.retryCount && dateCreated < other.dateCreated)
    }
}
