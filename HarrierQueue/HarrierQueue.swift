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
public class HarrierQueue: NSObject, HarrierTaskDelegate {
    
    /// Tasks waiting to be added to the activeQueue
    private var queuedTasks: [HarrierTask] = []
    
    /// Tasks currently running.
    private var _activeTasks: [HarrierTask] = []
    
    /// Tasks currently running.
    private var activeTasks: [HarrierTask] {
        return _activeTasks
    }
    
    /// Whether the queue is paused. When pasued, the queue will not execute any tasks.
    private var paused: Bool = false
    
    /// The max number of tasks that can be executed at once.
    private var _maxConcurrentTasks: Int
    
    /// The max number of tasks that can be executed at once.
    public var maxConcurrentTasks: Int {
        return _maxConcurrentTasks
    }
    
    /// Whether the queue is running. When not running, the queue will not execute any tasks.
    public var running: Bool {
        return !paused
    }
    
    // All tasks, running and queued.
    public var tasks: [HarrierTask] {
        return queuedTasks + activeTasks
    }
    
    /// All tasks currently running.
    public var runningTasks: [HarrierTask] {
        return activeTasks
    }
    
    public var taskCount: Int {
        return queuedTasks.count + activeTasks.count
    }
    
    public override init() {
        self._maxConcurrentTasks = 3
        super.init()
    }
    
    private func dequeueNextTask() {
        if queuedTasks.count > 0 {
            dequeueTask(queuedTasks.removeLast())
        }
    }
    
    private func dequeueTask(task: HarrierTask) {
        _activeTasks.append(task)
    }
    
    private func sortQueue() {
        // remember the array is ordered low priority first
        queuedTasks.sort { !$0.isHigherPriority(thanTask: $1) }
    }
    
    private func addTaskToDatabase(task: HarrierTask) {
        //TODO: implement
    }
    
    private func incrementTaskFailCount(task: HarrierTask) {
        task.failCount++
        //TODO: update database
    }
    
    private func removeTaskFromDatabase(task: HarrierTask) {
        
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
        _activeTasks = []
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
    
    public func removeTask(taskToRemove: HarrierTask) -> HarrierTask? {
        for index in 0...queuedTasks.count {
            if taskToRemove == queuedTasks[index] {
                queuedTasks.removeAtIndex(index)
                return taskToRemove
            }
        }
        if contains(_activeTasks, taskToRemove) {
            println("Task is already running. It cannot be removed.")
        } else {
            println("Task to remove is not in the queue.")
        }
        return nil
    }
    
    public func taskDidCompleteWithStatus(task: HarrierTask, status: HarrierTaskCompletionStatus) {
        // Remove the task from the active queue.
        for index in 0..._activeTasks.count {
            if task == _activeTasks[index] {
                _activeTasks.removeAtIndex(index)
            }
        }
        
        // Deal with the task depending on the status.
        if status == .Abandon || status == .Success {
            removeTaskFromDatabase(task)
        } else if status == .Failed {
            if task.failCount <= task.retryLimit {
                incrementTaskFailCount(task)
                //TODO: set new availabilityDate
                
                // Requeue task.
                enqueueTask(task)
            } else {
                removeTaskFromDatabase(task)
            }
        }
        
    }
}



