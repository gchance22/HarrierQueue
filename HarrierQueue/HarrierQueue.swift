//
//  HarrierQueue.swift
//  HarrierQueue
//  Version 0.0.2
//  Created by Graham Chance on 8/28/15.
//

import Foundation

// Montagu's Harrier
// "As this bird has a wide distribution, it will take whatever prey is available in the area where it nests [and add them to its task queue]" - Wikipedia
//

/**
*  The delegate in charge of performing the necessary actions for given tasks.
*/
public protocol HarrierQueueDelegate {
    func executeTask(task: HarrierTask)
}

/// A queue for HarrierTasks.
public class HarrierQueue: HarrierTaskDelegate {
    
    // The dataManager is in charge of fetching saved tasks and updating the database
    private let dataManager: HarrierQueueDataManager?
    
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
    
    private var pollingTimer: NSTimer?
    
    // Whether the next highest priority task is ready to run
    private var validNextTask: Bool {
        if queuedTasks.count > 0 {
            if queuedTasks.last!.availabilityDate.timeIntervalSinceNow <= 0 {
                return true
            }
        }
        return false
    }
    
    // The delegate of the queue in charge of executing tasks
    public var delegate: HarrierQueueDelegate
    
    public var pollingTime: Double = 3.0
    
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
    
    /// Number of tasks queued and active.
    public var taskCount: Int {
        return queuedTasks.count + activeTasks.count
    }
    
    /**
     Non-Persistent Queue Initializer.
     
     - returns: A new non-persistent HarrierQueue with maxConcurrentTasks of 3.
     */
    public init(delegate: HarrierQueueDelegate) {
        self.delegate = delegate
        self._maxConcurrentTasks = 3
        dataManager = nil
    }
    
    /**
     Persistent Queue Initializer.
     
     - parameter filepath: Filepath of SQL database.
     
     - returns: A new Persistent HarrierQueue with maxConcurrentTasks of 3.
     */
    public init(delegate: HarrierQueueDelegate, filepath: String) {
        self.delegate = delegate
        self._maxConcurrentTasks = 3
        self.dataManager = HarrierQueueDataManager(filepath: filepath)
        if self.dataManager == nil {
            print("Failed to initialize database. The HarrierQueue will not be persistent.")
        } else {
            if let tasks = self.dataManager?.fetchTasksFromDB() {
                for task in tasks {
                    self.enqueueTask(task,persist: false)
                }
            }
        }
    }
    
    
    private func dequeueNextTask(){
        if validNextTask {
            dequeueTask(queuedTasks.removeLast())
        } else if queuedTasks.count > 0 {
            pollingTimer = NSTimer.scheduledTimerWithTimeInterval(pollingTime, target: self, selector: Selector("pollingTimerFired"), userInfo: nil, repeats: true)
        }
    }
    
    
    @objc private func pollingTimerFired() {
        if validNextTask {
            pollingTimer?.invalidate()
            dequeueTask(queuedTasks.removeLast())
        }
    }
    
    private func dequeueTask(task: HarrierTask) {
        _activeTasks.append(task)
        delegate.executeTask(task)
    }
    
    private func sortQueue() {
        // remember the array is ordered low priority first
        queuedTasks.sortInPlace { !$0.isHigherPriority(thanTask: $1) }
    }
    
    private func addTaskToDatabase(task: HarrierTask) {
        do {
            try dataManager?.addNewTask(task)
        } catch {
            print("Failed to add task with name \"\(task.name)\" to the queue.")
        }
    }
    
    private func incrementTaskFailCount(task: HarrierTask) {
        task.failCount++
        do {
            try dataManager?.updateTaskFailCount(task)
        } catch {
            print("Failed to increment task fail count for task \"\(task.name)\". This could affect how the queue treats this task!")
        }
    }
    
    private func removeTaskFromDatabase(task: HarrierTask) {
        do {
            try dataManager?.removeTask(task)
        } catch {
            print("Failed to remove task \"\(task.name)\". This could cause it to be run again!")
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
        _activeTasks = []
    }
    
    /**
    Queues up the task. Note: To prevent queueing duplicates, use enqueueTask()
    
    - parameter  task Task to queued.
    - parameter  persist Whether the task should be saved to the database.
    */
    public func enqueueTask(task: HarrierTask, persist: Bool = true) {
        if persist {
            do {
                try dataManager?.addNewTask(task)
            } catch {
                print("Failed to add task \"\(task.name)\" to database. It won't persist.")
                print(error)
            }
        }
        queuedTasks.append(task)
        sortQueue()
        if activeTasks.count < maxConcurrentTasks && running {
            dequeueNextTask()
        }
    }

    /**
    Enqueues a task if a task with the same uniqueIdentifier does not already exist in the queue.
    
     - parameter  task Task to enqueue.
     - parameter  persist Whether the task should be saved to the database.
    */
    public func enqueueUniqueTask(task: HarrierTask, persist: Bool = true) {
        if persist {
            do {
                try dataManager?.addNewTask(task)
            } catch {
                print("Failed to add task \"\(task.name)\" to database. It won't persist.")
                print(error)
            }
        }
        if !tasks.contains(task) {
            enqueueTask(task)
        } else {
            print("Not enqueuing task because it is already in the queue. Task ID: \(task.uniqueIdentifier)")
        }
    }
    
    /**
     Removes the given task from the queue.
     
     - parameter taskToRemove: The task to be removed.
     
     - returns: The task removed is successful, otherwise nil.
     */
    public func removeTask(taskToRemove: HarrierTask) -> HarrierTask? {
        for index in 0...queuedTasks.count {
            if taskToRemove == queuedTasks[index] {
                queuedTasks.removeAtIndex(index)
                return taskToRemove
            }
        }
        if activeTasks.contains(taskToRemove) {
            print("Task is already running. It cannot be removed.")
        } else {
            print("Task to remove is not in the queue.")
        }
        return nil
    }
    

    
    /**
     HarrierTaskDelegate Method.
     
     - parameter task:   The task that has completed.
     - parameter status: The completion status of the task.
     */
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
                task.availabilityDate = NSDate()
                // Requeue task.
                enqueueTask(task)
            } else {
                removeTaskFromDatabase(task)
            }
        }
        
    }
}



