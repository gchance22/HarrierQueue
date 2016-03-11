import UIKit
import XCTest
import HarrierQueue

class Tests: XCTestCase {
    
    class TestQueueDelegate: HarrierQueueDelegate {
        
        var expectation: XCTestExpectation?
        var dateOfExecution: NSDate?
        
        init() { }
        
        init(expectation: XCTestExpectation) {
            self.expectation = expectation
        }

        func executeTask(task: HarrierTask) {
            dateOfExecution = NSDate()
            self.expectation?.fulfill()
        }
        
    }
    
    var dbPath : NSURL = {
        let fm = NSFileManager.defaultManager()
        let url = try! fm.URLForDirectory(NSSearchPathDirectory.CachesDirectory,
            inDomain: NSSearchPathDomainMask.UserDomainMask,
            appropriateForURL: nil, create: true)
        return url.URLByAppendingPathComponent("db.sqlite3")
    }()

    
    override func setUp() {
        super.setUp()
        deleteDBFile()
    }
    
    func deleteDBFile() {
        do {
            if NSFileManager.defaultManager().fileExistsAtPath(dbPath.absoluteString) {
                try NSFileManager.defaultManager().removeItemAtURL(dbPath)
            }
        } catch { }
    }

    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    
    func testDBFileCreation() {
        let _ = HarrierQueue(delegate: TestQueueDelegate(),filepath: dbPath.absoluteString)
        XCTAssert(NSFileManager.defaultManager().fileExistsAtPath(dbPath.path!), "No DB file was created")
    }
    
    func testQueuingProcess() {
        let harrier = HarrierQueue(delegate: TestQueueDelegate())
        let task = HarrierTask(name:"", priority: 0, taskAttributes: [:], retryLimit: 0, availabilityDate: NSDate())
        harrier.enqueueTask(task)
        XCTAssert(harrier.taskCount > 0, "Task was not queued properly")
    }
    
    
    func testPausingAndRestarting() {
        let harrier = HarrierQueue(delegate: TestQueueDelegate())
        let task = HarrierTask(name:"", priority: 0, taskAttributes: [:], retryLimit: 0, availabilityDate: NSDate())
        harrier.pause()
        harrier.enqueueTask(task)
        XCTAssert(!harrier.running, "Harrier did not pause")
        XCTAssert(harrier.runningTasks.count == 0, "Harrier did not actually pause")
        harrier.restart()
        XCTAssert(harrier.running && harrier.runningTasks.count > 0, "Harrier did not restart")
    }
    
    func testPersistence() {
        let harrier = HarrierQueue(delegate: TestQueueDelegate(),filepath: dbPath.absoluteString)
        harrier.pause()
        let availDate = NSDate()
        let testDic = ["key":"value", "key2": "value2"]
        let task = HarrierTask(name:"", priority: 0, taskAttributes: testDic, retryLimit: 0, availabilityDate: availDate)
        harrier.enqueueTask(task)
        let harrier2 = HarrierQueue(delegate: TestQueueDelegate(), filepath: dbPath.absoluteString)
        XCTAssert(harrier2.taskCount == 1, "Harrier did not persist")
        if let recoveredTask = harrier2.tasks.first {
            XCTAssert(testDic == recoveredTask.data, "Harrier did not persist")
        }

    }
    
    
    func testExecution() {
        let delegate = TestQueueDelegate()
        let harrier = HarrierQueue(delegate: delegate)
        let task = HarrierTask(name:"", priority: 0, taskAttributes: [:], retryLimit: 0, availabilityDate: NSDate())
        let expectation = expectationWithDescription("execute task")
        delegate.expectation = expectation
        harrier.enqueueTask(task)
        waitForExpectationsWithTimeout(2.0, handler:nil)

    }
    
    
    func testDelayedAvailabilityDateExecution() {
        let delegate = TestQueueDelegate()
        let harrier = HarrierQueue(delegate: delegate)
        let availabilityDate = NSDate(timeIntervalSinceNow: 2)
        let task = HarrierTask(name:"", priority: 0, taskAttributes: [:], retryLimit: 0, availabilityDate: availabilityDate)
        let expectation = expectationWithDescription("execute task")
        delegate.expectation = expectation
        harrier.enqueueTask(task)
        waitForExpectationsWithTimeout(5.0, handler:nil)
        XCTAssert(delegate.dateOfExecution?.timeIntervalSinceNow >= availabilityDate.timeIntervalSinceNow, "Task fired before its availability date")
    }
    
    
    func testTaskPriorities() {
        let task1 = HarrierTask(name:"", priority: 0, taskAttributes: [:], retryLimit: 0, availabilityDate: NSDate())
        var task2 = HarrierTask(name:"", priority: 1, taskAttributes: [:], retryLimit: 0, availabilityDate: NSDate())
        XCTAssert(task1.isHigherPriority(thanTask: task2) == false, "Priority numbers are not working for tasks")

        task2 = HarrierTask(name:"", priority: 1, taskAttributes: [:], retryLimit: 0, availabilityDate: NSDate().dateByAddingTimeInterval(10))
        XCTAssert(task1.isHigherPriority(thanTask: task2) == true, "A task with a future availability date is being prioritized over a task with a past availability date")

        // doesnt test fail count prioritization
    }

}
