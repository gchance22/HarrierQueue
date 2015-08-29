//
//  HarrierQueue.swift
//  HarrierQueue
//  Version 1.0.0
//  Created by Graham Chance on 8/28/15.
//

import Foundation

// Montagu's Harrier
// "As this bird has a wide distribution, it will take whatever prey is available in the area where it nests [and add them to its task queue]" - Wikipedia
//
public class HarrierQueue: NSObject {
    
    /// Tasks waiting to be added to the activeQueue
    private var queuedTasks: [HarrierTask] = []
    
    /// Tasks currently ready and queued.
    private let activeQueue = NSOperationQueue()
    
    /// Should be the task equivalent of activeQueue.
    private var activeTasks: [HarrierTask] {
        return activeQueue.operations as? [HarrierTask] ?? []
    }
    
    private var paused: Bool = false
    
    private var _maxConcurrentTasks: Int {
        didSet {
            activeQueue.maxConcurrentOperationCount = _maxConcurrentTasks
        }
    }
    
    public var maxConcurrentTasks: Int {
        return _maxConcurrentTasks
    }
    
    public var running: Bool {
        return !paused
    }
    
    public var tasks: [HarrierTask] {
        var tasks = queuedTasks
        for task in activeTasks {
            tasks.append(task)
        }
        return tasks
    }
    
    public var runningTasks: [HarrierTask] {
        return activeTasks
    }
    
    public var taskCount: Int {
        return queuedTasks.count + activeTasks.count
    }
    
    public override init() {
        self._maxConcurrentTasks = 3
        super.init()
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
            dequeueTask(queuedTasks.removeLast())
        }
    }
    
    private func dequeueTask(task: HarrierTask) {
        activeQueue.addOperation(task)
    }
    
    private func sortQueue() {
        // remember the array is ordered low priority first
        queuedTasks.sort { !$0.isHigherPriority(thanTask: $1) }
    }
    
    public override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
        if let queue = object as? NSOperationQueue {
            if keyPath == "operationCount" {
                if activeTasks.count < maxConcurrentTasks && running {
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
    public func restart() {
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
        for operation in activeQueue.operations {
            if let operation = operation as? NSOperation {
                operation.cancel()
            }
        }
    }
    
    /**
    Queues up the task. Note: To prevent queueing duplicates, use enqueueTask()
    
    :param: task Task to queued.
    */
    public func enqueueTask(task: HarrierTask) {
        queuedTasks.append(task)
        sortQueue()
        if activeTasks.count < maxConcurrentTasks && running {
            dequeueNextTask()
        }
    }

    /**
    Enqueues a task if a task with the same uniqueIdentifier does not already exist in the queue.
    
    :param: task Task to enqueue.
    */
    public func enqueueUniqueTask(task: HarrierTask) {
        if !contains(tasks, task) {
            enqueueTask(task)
        } else {
            println("Not enqueuing task because it is already in the queue. Task ID: \(task.uniqueIdentifier)")
        }
    }
    
    
}



