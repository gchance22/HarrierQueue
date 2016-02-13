import UIKit
import XCTest
import HarrierQueue

class Tests: XCTestCase {
    
    var harrier: HarrierQueue!
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        harrier = HarrierQueue()
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
    
    func testQueuingProcess() {
        let task = HarrierTask(name:"", priority: 0, taskAttributes: [:], retryLimit: 0, availabilityDate: NSDate())
        harrier.enqueueTask(task)
        XCTAssert(harrier.taskCount > 0, "Task was not queued properly")
    }
    
    
    func testPausingAndRestarting() {
        let task = HarrierTask(name:"", priority: 0, taskAttributes: [:], retryLimit: 0, availabilityDate: NSDate())
        harrier.pause()
        harrier.enqueueTask(task)
        XCTAssert(!harrier.running && harrier.runningTasks.count == 0, "Harrier did not pause")
        harrier.restart()
        XCTAssert(harrier.running && harrier.runningTasks.count > 0, "Harrier did not restart")

    }

}
