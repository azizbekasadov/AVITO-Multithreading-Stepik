import Foundation

// Serial

let serialQueue = DispatchQueue(label: "hello.serial")

// Concurrent

let concurrentQueue = DispatchQueue(label: "hello.concurrent", attributes: .concurrent)

// Queue Pool

let poolQueue = DispatchQueue.global()

// Main

let mainQueue = DispatchQueue.main

// Methods ~ Async/Sync

let methodsQueue = DispatchQueue.global(qos: .background)

methodsQueue.async {
    print("123")
}

methodsQueue.sync {
    print("321")
}

// Async/Sync after

methodsQueue.asyncAndWait(execute: DispatchWorkItem(block: {
    print("Hello, waiting")
}))

methodsQueue.asyncAfter(deadline: .now() + 1) {
    print("I have been waiting")
}


// Concurrent perform

class ConcurrentPerformTest {
    
    func test() {
        DispatchQueue.concurrentPerform(iterations: 3) { i in
            print(i)
        }
    }
}

ConcurrentPerformTest().test()

// Work Item

class DispatchWorkItemTest1 {
    private let queue = DispatchQueue(label: "DispatchWorkItemTest1", attributes: .concurrent)
    
    func testNotify() {
        let item = DispatchWorkItem {
            print("test")
        }
        
        item.notify(queue: .main, execute: {
            print("finish test")
        })
        
        queue.async(execute: item)
    }
}

DispatchWorkItemTest1().testNotify()

// <= allows cancelling current work item

class DispatchWorkItemTest2 {
    private let queue = DispatchQueue(label: "DispatchWorkItemTest2", attributes: .concurrent)
    
    func testCancel() {
        queue.async {
            sleep(1)
            print("test1")
        }
        
        queue.async {
            sleep(1)
            print("test2")
        }
        
        let item = DispatchWorkItem {
            print("test")
        }
        
        queue.async(execute: item)
        
        item.cancel()
    }
        
}

DispatchWorkItemTest2().testCancel()

// Semaphores

class SemaphoreTest {
    private let semaphore = DispatchSemaphore(value: 0)
    
    func test() {
        DispatchQueue.global().async {
            sleep(3)
            print("1")
            self.semaphore.signal()
        }
        semaphore.wait()
        print("2")
    }
}

SemaphoreTest().test()

class SemaphoreTest2 {
    private let semaphore = DispatchSemaphore(value: 2)
    
    private func doWork() {
        semaphore.wait()
        print("test")
        sleep(3)
        semaphore.signal()
    }
    
    func test() {
        DispatchQueue.global().async {
            self.doWork()
        }
        
        DispatchQueue.global().async {
            self.doWork()
        }
        
        DispatchQueue.global().async {
            self.doWork()
        }
    }
}

SemaphoreTest2().test()

class SemaphoreTest3 {
    private let semaphore = DispatchSemaphore(value: 1)
    
    private func doWork() {
        semaphore.wait()
        print("SemaphoreTest3")
        sleep(2)
        semaphore.signal()
    }
    
    func test() {
        DispatchQueue.global().async {
            self.doWork()
        }
        
        DispatchQueue.global().async {
            self.doWork()
        }
        
        DispatchQueue.global().async {
            self.doWork()
        }
    }
}

SemaphoreTest3().test()

// DispatchGroup

class DispatchGroupTest1 {
    private let group = DispatchGroup()
    private let queue = DispatchQueue(label: "DispatchGroupTest1", attributes: .concurrent)
    
    func testNotify() {
        queue.async(group: group) {
            sleep(1)
            print("1")
        }
        queue.async(group: group) {
            sleep(2)
            print("2")
        }
        group.notify(queue: .main) {
            print("finish all")
        }
    }
}


class DispatchGroupTest2 {
    private let group = DispatchGroup()
    private let queue = DispatchQueue(label: "DispatchGroupTest2", attributes: .concurrent)
    
    func testWait() {
        group.enter()
        queue.async {
            sleep(1)
            print("1")
            self.group.leave()
        }
        group.enter()
        queue.async {
            sleep(2)
            print("2")
            self.group.leave()
        }
        group.wait()
        print("Finish all")
    }
}

DispatchGroupTest2().testWait()

// Dispatch Barrier

class DispatchBarrierTest {
    private let queue = DispatchQueue(label: "DispatchBarrierTest", attributes: .concurrent)
    
    private var internalTest: Int = 0
    
    func setTest(_ test: Int) {
        queue.async(flags: .barrier) {
            self.internalTest = test
        }
    }
    
    func test() -> Int {
        var tmp: Int = 0
        queue.async {
            tmp = self.internalTest
        }
        return tmp
    }
}

// Dispatch Source

// - Timer d.s.

class DispatchSourceTest1 {
    private let source = DispatchSource.makeTimerSource()
    
    func test() {
        source.setEventHandler {
            print("testSource")
        }
        source.schedule(deadline: .now(), repeating: 5)
        source.activate()
    }
}

DispatchSourceTest1().test()

// - Signal d.s.

class DispatchSourceTest2 {
    private let source = DispatchSource.makeUserDataAddSource(queue: .main)
    
    init() {
        source.setEventHandler {
            print(self.source.data)
        }
        source.activate()
    }
    
    func test() {
        DispatchQueue.global().async {
            self.source.add(data: 10)
        }
    }
}

DispatchSourceTest2().test()

// Target queue hierarchy

class TargetQueueHierarchyTest1 {
    private let targetQueue = DispatchQueue(label: "TargetQueue")
    
    func test() { // queues MUST be serial
        let queue1 = DispatchQueue(label: "Queue1", target: targetQueue)
        queue1.async {
            print("Queue1.print")
        }
        let dispatchSource1 = DispatchSource.makeTimerSource(queue: queue1)
        dispatchSource1.setEventHandler {
            print("test1Queue1")
        }
        dispatchSource1.activate()
        
        let queue2 = DispatchQueue(label: "Queue2", target: targetQueue)
        queue2.async {
            print("Queue1.print")
        }
        let dispatchSource2 = DispatchSource.makeTimerSource(queue: queue2)
        dispatchSource2.setEventHandler {
            print("test2Queue2")
        }
        dispatchSource2.activate()
    }
    
}

TargetQueueHierarchyTest1().test()

// Dispatch IO ~ allows to interact with IO and file system

class GCDChannelTest {
    private let queue = DispatchQueue(label: "GCDChannelTest", attributes: .concurrent)
    
    private var channel: DispatchIO? // descriptor
    
    func test() {
        guard let filePath = Bundle.main.path(forResource: "test", ofType: "") else { return }
        
        channel = DispatchIO(type: .stream, path: filePath, oflag: O_RDONLY, mode: 0, queue: .global(), cleanupHandler: { error in
            print(error.description)
        })
        channel?.read(offset: 0, length: Int.max, queue: queue, ioHandler: { done, data, error in
            if error == 0 {
                print(error.description)
                return
            }
            
            print(data)
        })
    }
}

GCDChannelTest().test()
