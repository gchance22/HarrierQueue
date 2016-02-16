import UIKit
import XCTest
import HarrierQueue

class Tests: XCTestCase {
    
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
    
    func testExample() {
        // This is an example of a functional test case.
        XCTAssert(true, "Pass")
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock() {
            // Put the code you want to measure the time of here.
        }
    }
    
    func testDBFileCreation() {
        let _ = HarrierQueue(filepath: dbPath.absoluteString)
        XCTAssert(NSFileManager.defaultManager().fileExistsAtPath(dbPath.path!), "No DB file was created")
    }
    
    func testQueuingProcess() {
        let harrier = HarrierQueue()
        let task = HarrierTask(name:"", priority: 0, taskAttributes: [:], retryLimit: 0, availabilityDate: NSDate())
        harrier.enqueueTask(task)
        XCTAssert(harrier.taskCount > 0, "Task was not queued properly")
    }
    
    
    func testPausingAndRestarting() {
        let harrier = HarrierQueue()
        let task = HarrierTask(name:"", priority: 0, taskAttributes: [:], retryLimit: 0, availabilityDate: NSDate())
        harrier.pause()
        harrier.enqueueTask(task)
        XCTAssert(!harrier.running, "Harrier did not pause")
        XCTAssert(harrier.runningTasks.count == 0, "Harrier did not actually pause")
        harrier.restart()
        XCTAssert(harrier.running && harrier.runningTasks.count > 0, "Harrier did not restart")
    }
    
    func testPersistence() {
        let harrier = HarrierQueue(filepath: dbPath.absoluteString)
        harrier.pause()
        let availDate = NSDate()
        let testDic = ["key":"value", "key2": "value2"]
        let task = HarrierTask(name:"", priority: 0, taskAttributes: testDic, retryLimit: 0, availabilityDate: availDate)
        harrier.enqueueTask(task)
        let harrier2 = HarrierQueue(filepath: dbPath.absoluteString)
        XCTAssert(harrier2.taskCount == 1, "Harrier did not persist")
        if let recoveredTask = harrier2.tasks.first {
            XCTAssert(testDic == recoveredTask.data, "Harrier did not persist")
        }

    }

}
