//
//  Harrier.swift
//  Harrier
//  Version 1.0.0
//  Created by Graham Chance on 8/28/15.
//  Copyright (c) 2015 DoubleBlue. All rights reserved.
//

import Foundation
import Reachability

// Montagu's Harrier
// "As this bird has a wide distribution, it will take whatever prey is available in the area where it nests [and add them to its task queue]" - Wikipedia
//
public class Harrier {
    
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
        self.maxConcurrentTasks = maxConcurrentTasks
        activeQueue.maxConcurrentTasks = maxConcurrentTasks
    }
 
    /**
    Stop adding tasks to the activeQueue.
    */
    func pause() {
        paused = true
    }
    
    /**
    Start adding tasks to the activeQueue again.
    */
    func restart() {
        paused = false
    }
    
    /**
    Cancel all tasks in activeQueue and empty queuedTasks.
    */
    func cancelAll() {
        queuedTasks = []
        activeTasks = []
        for operation in activeQueue.operations {
            if let operation = operation as? NSOperation {
                operation.cancel()
            }
        }
    }
    
    
    func enqueueTask(task: HarrierTask) {
        queuedTasks.append(task)
    }

    func dequeueNextTask() {
        
    }
    
    func dequeueTask(task: HarrierTask) {
        activeTasks.append(task)
        activeQueue.addOperation(task.operation)
    }
    
    
    
}


public class HarrierTask {

    let usesNetwork: Bool
    
    /// The priority measurement that ranks above all others. 0 (low priority) - infinity (high priority)
    let basePriortity: Int
    
    let operation = NSOperation()
    
    let dateCreated: NSTimeInterval!
    
    public init(basePriority: Int, usesNetwork: Bool = true) {
        self.basePriortity = basePriority
        self.usesNetwork = usesNetwork
        //self.dateCreated = NSTimeInterval
    }
    
}