import Foundation

// Block Operation

class BlockOperationTest {
    private let operationQueue = OperationQueue()
    
    func test() {
        let blockOperation = BlockOperation {
            print("Test BlockOperation")
        }
        operationQueue.addOperation(blockOperation)
    }
}

BlockOperationTest().test()

// Operation Structure

class OperationStructure {
    private let operationQueue = OperationQueue()
    
    func test() {
        let operation = BlockOperation {
            print("Test launched")
        }
        print(operation.isReady)
        print(operation.isCancelled)
        print(operation.isFinished)
        print(operation.isExecuting)
        print(operation.isAsynchronous)
        
        operationQueue.addOperation(operation)
        
        operation.main()
        operation.start()
    }
}

//OperationStructure().test()

// Operation KVO

class OperationKVOTest: NSObject {
    func test() {
        let operation = Operation()
        operation.addObserver(self, forKeyPath: "isCancelled", options: .new, context: nil)
//        operation.cancel()
    }
    
    override class func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "isCancelled" {
            print("Operation is cancelled")
        }
    }
}

OperationKVOTest().test()

// Operation Lifecycle

/**
 ~ isReady
 ~ isExecuting
 ~ isFinished
 ~ isCancelled
 */

// Operation & Operation Queue

class OperationTest2 {
    private let operationQueue = OperationQueue()
    
    func test() {
        operationQueue.addOperation {
            print("test2")
        }
    }
}

OperationTest2().test()

class OperationTest3 {
    class OperationA: Operation {
        override func main() {
            print("test operationA")
        }
    }
    
    private let operationQueue = OperationQueue()
    
    func test() {
        let testOperation = OperationA()
        operationQueue.addOperation(testOperation)
    }
}

OperationTest3().test()

// Exercise 1

class Exercise1 {
    private let operationQueue1 = OperationQueue()
    private let operationQueue2 = OperationQueue()
    
    func test() {
        var int = 1
        let operation = BlockOperation {
            print(int)
            int += 1
        }
        
        operationQueue1.addOperation(operation)
        sleep(1)
        operationQueue2.addOperation(operation)
    }
}

//Exercise1().test()

// Async operation

class AsyncOperation: Operation { // works synchronously
    private var finish = false
    private var execute = false
    private let queue = DispatchQueue(label: "zxh.main.asyncoperation")
    
    override var isAsynchronous: Bool { return true }
    override var isFinished: Bool { finish }
    override var isExecuting: Bool { execute }
    
    override func start() {
        queue.async {
            self.main()
        }
        execute = true
    }
    
    override func main() {
        print("AsyncOperation: test")
        finish = true
        execute = false
    }
}

AsyncOperation().start()

// KVO + Async operation

class AsyncOperation2: Operation {
    private var finish = false
    private var execute = false
    private let queue = DispatchQueue(label: "AsyncOperation")
    
    override var isAsynchronous: Bool { return true }
    override var isFinished: Bool { finish }
    override var isExecuting: Bool { execute }
    
    override func start() {
        willChangeValue(forKey: "isExecuting")
        
        queue.async {
            self.main()
        }
        
        execute = true
        didChangeValue(forKey: "isExecuting")
    }
    
    override func main() {
        print("test main AsyncOperation2")
        willChangeValue(forKey: "isFinished")
        willChangeValue(forKey: "isExecuting")
        
        finish = true
        execute = false
        
        didChangeValue(forKey: "isFinished")
        didChangeValue(forKey: "isExecuting")
    }
}

AsyncOperation2().start()

// maxConcurrentOperationCount

class OperationCountTest {
    private let operationQueue = OperationQueue()
    
    func test() {
        operationQueue.maxConcurrentOperationCount = 1
        operationQueue.addOperation {
            print("wait 1 second")
            sleep(1)
            print("OperationCountTest.test1")
        }
        operationQueue.addOperation {
            print("wait 1 second")
            sleep(1)
            print("OperationCountTest.test2")
        }
        operationQueue.addOperation {
            print("wait 1 second")
            sleep(1)
            print("OperationCountTest.test3")
        }
    }
}

OperationCountTest().test()

// Cancel

class CancelTest {
    private let operationQueue = OperationQueue()
    
    class OperationCancelTest: Operation {
        override func main() {
            if isCancelled {
                return
            }
            
            sleep(1)
            
            if isCancelled { // should check isCancelled
                return
            }
            
            print("OperationCancelTest.test")
        }
    }
    
    
    func test() {
        let cancelOperation = OperationCancelTest()
        operationQueue.addOperation(cancelOperation)
        cancelOperation.cancel()
    }
}

CancelTest().test()

// Exercise 2

class Exercise2 {
    class TestOperation: Operation {
        override func main() {
            sleep(2)
            print("TestOperation.test")
        }
    }
    
    func test() {
        let operationQueue = OperationQueue()
        let testOperation = TestOperation()
        operationQueue.addOperation(testOperation)
        sleep(1)
        testOperation.cancel()
    }
}

Exercise2().test()

class Exercise3 {
    func test() {
        var operationQueue1: OperationQueue? = OperationQueue()
        let operationQueue2 = OperationQueue()
        
        var int = 1
        let operation = BlockOperation {
            print(int)
            int += 1
            sleep(1)
        }
        
        operationQueue1?.addOperation(operation)
        operation.cancel()
        operationQueue1 = nil
        operationQueue2.addOperation(operation)
    }
}

//Exercise3().test()

class Exercise4 {
    func test() {
        let operationQueue = OperationQueue()
        let operation = BlockOperation {
            print("start")
            sleep(2)
            print("end")
        }
        operationQueue.addOperation(operation)
        sleep(1)
        operation.cancel()
    }
}

Exercise4().test()

// Dependencies

// when one operation depends on the execution of the other. It will be executed only after the first one isFinished

class Exercise5 {
    func test() {
        let operationQueue = OperationQueue()
        let operation1 = BlockOperation { print("test1") }
        let operation2 = BlockOperation { print("test2") }
        let operation3 = BlockOperation { print("test3") }
        
        operation3.addDependency(operation2)
        
        operationQueue.addOperations([operation1, operation2, operation3], waitUntilFinished: false)
    }
}

Exercise5().test()

// Serialized operation queue does not offer quite the same behavior as a serial dispatch queue in GCD does;

// waitUntil

class WaitOperationsTest1 {
    private let operationQueue = OperationQueue()
    
    func test() {
        operationQueue.addOperation {
            sleep(1)
            print("test1")
        }
        
        operationQueue.addOperation {
            sleep(2)
            print("test2")
        }
        operationQueue.waitUntilAllOperationsAreFinished()
        print("wait")
    }
}

WaitOperationsTest1().test()

class WaitOperationsTest2 {
    private let operationQueue = OperationQueue()
    
    func test() {
        let operation1 = BlockOperation {
            sleep(1)
            print("test1")
        }
        
        let operation2 = BlockOperation  {
            sleep(2)
            print("test2")
        }
        operationQueue.addOperations([operation1, operation2], waitUntilFinished: true)
        print("wait")
    }
}

WaitOperationsTest2().test()

// Exercise 6

class Exercise6 {
    func test() {
        let operationQueue = OperationQueue()
        operationQueue.addOperation {
            print("Exercise6.test1")
        }
        
        operationQueue.addOperation {
            print("Exercise6.test2")
        }
        
        operationQueue.waitUntilAllOperationsAreFinished()
        
        operationQueue.addOperation {
            print("Exercise6.test3")
        }
    }
}

Exercise6().test()

// Completion Block

class CompletionBlockTest {
    private let operationQueue = OperationQueue()
    
    func test() {
        let operation = BlockOperation {
            print("test")
        }
        operation.completionBlock = {
            print("finish")
        }
        operationQueue.addOperation(operation)
    }
}

CompletionBlockTest().test()

class Exercise7 {
    func test() {
        let operationQueue = OperationQueue()
        
        let operation = BlockOperation {
            print("test")
            sleep(2)
        }
        
        operation.completionBlock = {
            print("finish")
        }
        
        operationQueue.addOperation(operation)
        sleep(1)
        operation.cancel()
    }
}

Exercise7().test()

// Suspend

class OperationSuspendTest {
    private let operationQueue = OperationQueue()
    
    func test() {
        let operation1 = BlockOperation {
            sleep(1)
            print("test1")
        }
        
        let operation2 = BlockOperation {
            sleep(1)
            print("test2")
        }
        
        operationQueue.maxConcurrentOperationCount = 1
        operationQueue.addOperation(operation1)
        operationQueue.addOperation(operation2)
        
        operationQueue.isSuspended = true
    }
}

OperationSuspendTest().test()

class Exercise8 {
    func test() {
        let operationQueue = OperationQueue()
        
        let operation1 = BlockOperation { print("Exercise8.test1") }
        let operation2 = BlockOperation { print("Exercise8.test2") }
        
        operationQueue.addOperations([operation1, operation2], waitUntilFinished: true)
        operationQueue.isSuspended = true
    }
}

Exercise8().test()

class Exercise9 {
    func test() {
        var operationQueue1: OperationQueue? = OperationQueue()
        let operationQueue2 = OperationQueue()
        
        var int = 1
        let operation = BlockOperation { print(int); int += 1; sleep(1) }
        
        operationQueue1?.addOperation(operation)
        operationQueue1?.isSuspended = true
        operationQueue1 = nil
        operationQueue2.addOperation(operation)
    }
}

//Exercise9().test()

class Exercise10 {
    func test() {
        let operationQueue = OperationQueue()
        let operation = BlockOperation {
            print("start")
            sleep(2)
            print("end")
        }
        
        operationQueue.addOperation(operation)
        sleep(1)
        operationQueue.isSuspended = true
    }
}

Exercise10().test()

// GCD vs. Operation

/**
 Operation:
 - Cancelation
 - Observable
 - Dependencies
 
 GCD:
 - Simplicity
 - Low-level
 */

