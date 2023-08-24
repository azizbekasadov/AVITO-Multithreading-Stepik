import Darwin
import Foundation
import ObjectiveC
import CoreFoundation

// Unix `pthread`

var thread = pthread_t(bitPattern: 0)
var attr = pthread_attr_t()
pthread_attr_init(&attr)
pthread_create(&thread, &attr, { pointer in
    print("Test")
    return nil
}, nil)

// Objective-C `Threads` (class)

var nsthread = Thread(block: {
    print("Test")
})
nsthread.start()

// Exercise 1

fileprivate class Exercise1 {
    func fire() {
        var thread1 = pthread_t(bitPattern: 0)
        var attr1 = pthread_attr_t()
         
        pthread_attr_init(&attr1)
        pthread_create(&thread1, &attr1, { pointer in
         
           print("test1")
         
           return nil
        }, nil)
         
        var thread2 = pthread_t(bitPattern: 0)
        var attr2 = pthread_attr_t()
         
        pthread_attr_init(&attr2)
        pthread_create(&thread2, &attr2, { pointer in
            print("test2")
            return nil
        }, nil)
    }
}

Exercise1().fire()

fileprivate class Exercise2 {
    func fire() {
        let thread1 = Thread {
            print("test1")
            
            let thread2 = Thread {
                print("test2")
            }
            thread2.start()
        }
        
        thread1.start()
    }
}

Exercise2().fire()

// Quality of Service

@available(iOS 8.0, *)
public enum QualityOfService: NSInteger {
    case userInteractive // fast operations on main, with UI, like animations, or UI refreshing
    case userInitiated // for tasks to get instant prompt
    case utility // for long-time operations
    case background // for more energy-saving long-time operation
    case `default` // between userInitiated and utility
    case unspecified // for old API that does not support QoS
}

// Example

class PThreadQoSTest {
    func fire() {
        var thread = pthread_t(bitPattern: 0)
        var attr = pthread_attr_t()
        pthread_attr_init(&attr)
        pthread_attr_set_qos_class_np(&attr, QOS_CLASS_USER_INITIATED, 0) // to set QoS
        pthread_create(&thread, &attr, { pointer in
            print("Test")
            pthread_set_qos_class_self_np(QOS_CLASS_BACKGROUND, 0) // to change QoS
            
            return nil
        }, nil)
    }
}

PThreadQoSTest().fire()

// Example 2

class QoSThreadTest {
    func fire() {
        let thread = Thread {
            print("Test")
            print(qos_class_self())
        }
        thread.qualityOfService = .userInteractive
        thread.start()
        
        print(qos_class_main())
    }
}

QoSThreadTest().fire()

// Exercise 3

class Exercise3 {
    func fire() {
        let thread1 = Thread {
            print("test1")
        }
        thread1.qualityOfService = .utility
        thread1.start()
         
        let thread2 = Thread {
            print("test2")
        }
        thread2.qualityOfService = .userInitiated
        thread2.start()
    }
}

Exercise3().fire()

// Synchronization

// `pthread_mutex`

class MutexTest {
    private var mutex = pthread_mutex_t()
    
    init() {
        pthread_mutex_init(&mutex, nil)
    }
    
    func fire() {
        pthread_mutex_trylock(&mutex)
        //...
        print("Hello Mutext")
        // ...
        pthread_mutex_unlock(&mutex)
    }
}

MutexTest().fire()

// `NSMutex` from `Foundation`

class MutexNSLockTest {
    private let lock = NSLock()
    
    func fire(i: Int) {
        lock.lock()
        //...
        print("Hello NSLock")
        // ...
        lock.unlock()
    }
}

MutexNSLockTest().fire(i: 0)

// Recursive Mutex

// отличается от обычного тем, что позволяет потоку захватывать множество раз захватывать один и тот же ресурс. Ядро операционной системы сохраняет след захваченного потока. Используется в рекурсивных функциях.

class RecursiveMutex {
    private var mutex = pthread_mutex_t()
    private var attr = pthread_mutexattr_t()
    
    init() {
        pthread_mutexattr_init(&attr)
        pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_RECURSIVE)
        pthread_mutex_init(&mutex, &attr)
    }
    
    func test1() {
        pthread_mutex_lock(&mutex)
        test2()
        pthread_mutex_unlock(&mutex)
    }
    
    func test2() {
        pthread_mutex_lock(&mutex)
        print("test2")
        pthread_mutex_unlock(&mutex)
    }
}

RecursiveMutex().test1()

// NSRecursiveLock from Foundation

class NSRecursiveLockTest {
    private let lock = NSRecursiveLock()
    
    func test1() {
        lock.lock()
        test2()
        lock.unlock()
    }
    
    func test2() {
        lock.lock()
        print("test2")
        lock.unlock()
    }
}

NSRecursiveLockTest().test2()

// Condition

// Unix Condition pthread

class MutexConditionTest {
    private var condition = pthread_cond_t()
    private var mutex = pthread_mutex_t()
    private var check = false
    
    init() {
        pthread_cond_init(&condition, nil)
        pthread_mutex_init(&mutex, nil)
    }
    
    func test1() -> MutexConditionTest {
        pthread_mutex_lock(&mutex)
        while !check {
            pthread_cond_wait(&condition, &mutex)
        }
        pthread_mutex_unlock(&mutex)
        return self
    }
    
    func test2() -> MutexConditionTest {
        pthread_mutex_lock(&mutex)
        check = true
        pthread_cond_signal(&condition)
        pthread_mutex_unlock(&mutex)
        return self
    }
}

MutexConditionTest().test2().test1()

// NSCondition

// Foundation thread condition

class ConditionTest {
    private var condition = NSCondition()
    private var check: Bool = false
    
    func test1() {
        condition.lock()
        while !check {
            condition.wait()
        }
        condition.unlock()
    }
    
    func test2() {
        condition.lock()
        check = true
        condition.signal()
        condition.unlock()
    }
}

class _MutexConditionTest {
    private var condition = pthread_cond_t()
    private var mutex = pthread_mutex_t()
    private var check = false

    init() {
        pthread_cond_init(&condition, nil)
        pthread_mutex_init(&mutex, nil)
    }

    func test_1() {
        print("\(#function) \(self) start")
        pthread_mutex_lock(&mutex)
        while check == false {
            print("\(#function) \(self) while check")
            pthread_cond_wait(&condition, &mutex)
        }
        // do something
        print("\(#function) \(self) get signal")
        pthread_mutex_unlock(&mutex)
        print("\(#function) \(self) end")
    }

    func test_2() {
        print("\(#function) \(self) start")
        pthread_mutex_lock(&mutex)
        check = true
        pthread_cond_signal(&condition)
        print("\(#function) \(self) send signal")
        pthread_mutex_unlock(&mutex)
        print("\(#function) \(self) end")
    }
}

let mutexConditionTest = _MutexConditionTest()

// создаем свою очередь
var queue_1 = DispatchQueue(label: "com.condition.serialQueue_1")

// описываем разные потоки
let threads_1: [Thread] = [
    .init { mutexConditionTest.test_1() },
    .init { mutexConditionTest.test_2() },
]

// выполняем работу из очереди в разных потоках
threads_1.forEach { thread in queue_1.sync { thread.start() } }

// Exercise 4

class Exercise4 {
    private let condition = NSCondition()
    private var check: Bool = false
     
    func test1() {
        condition.lock()
        while(!check) {
            condition.wait()
        }
        print("test")
        condition.unlock()
    }
     
    func test2() {
        condition.lock()
     
        check = true
        condition.unlock()
    }
     
    func fire() {
        let thread1 = Thread {
            self.test1()
        }
        thread1.start()
         
        let thread2 = Thread {
            self.test2()
        }
        thread2.start()
    }
}


Exercise4().fire()

// Read Write Lock

// pthread -> exists only in Unix notation

class ReadWriteLock {
    private var lock = pthread_rwlock_t()
    private var attr = pthread_rwlockattr_t()
    
    private var test: Int = 0
    
    init() {
        pthread_rwlock_init(&lock, &attr)
    }
    
    var testProperty: Int {
        get {
            pthread_rwlock_rdlock(&lock)
            let tmp = test
            pthread_rwlock_unlock(&lock)
            return tmp
        }
        set {
            pthread_rwlock_wrlock(&lock)
            test = newValue
            pthread_rwlock_unlock(&lock)
        }
    }
        
}

print(ReadWriteLock().testProperty)

// Spin Lock

class SpinLock {
    private var lock = OS_SPINLOCK_INIT
    
    func test() {
        OSSpinLockLock(&lock)
        print("Spin lock is on \(#function)")
        OSSpinLockUnlock(&lock)
    }
}

// не является энергоэффективным

// Unfair Lock

@available(iOS 10.0, *)
class UnfairLockTest {
    private var lock = os_unfair_lock_s()
    
    func test() {
        os_unfair_lock_lock(&lock)
        print(type(of: self))
        os_unfair_lock_unlock(&lock)
    }
}

private var lock = os_unfair_lock_s()
 
class Exercise5 {
    func test(i: Int) {
       os_unfair_lock_lock(&lock)
       sleep(1)
       print(i)
       os_unfair_lock_unlock(&lock)
    }
    
    func fire() {
        let thread1 = Thread {
            self.test(i: 1)
        }
        thread1.start()
         
        let thread2 = Thread {
            self.test(i: 2)
        }
        thread2.start()
         
        let thread3 = Thread {
            self.test(i: 3)
        }
        thread3.start()
    }
}

Exercise5().fire()

// Synchronized

// concept from Objective-C

class SynchronizedTest {
    private let lock = NSObject() // mutex
    
    func test() {
        objc_sync_enter(lock)
        print(type(of: self))
        objc_sync_exit(lock)
    }
}

SynchronizedTest().test()

// Multithreading issues / problems

// `DEADLOCK`

class DeadlockTest {
    private let lock1 = NSLock()
    private let lock2 = NSLock()
    
    var resourceA = false
    var resourceB = false
    
    func fire() {
        let thread1 = Thread {
            self.lock1.lock()
            self.resourceA = true
            
            self.lock2.lock()
            self.resourceB = true
            self.lock2.unlock()
            
            self.lock1.unlock()
        }
        
        thread1.start()
        
        let thread2 = Thread {
            self.lock2.lock()
            self.resourceB = true
            
            self.lock1.lock()
            self.resourceA = true
            self.lock1.unlock()
            
            self.lock2.unlock()
        }
        
        thread2.start()
        
        print(resourceA)
        print(resourceB)
    }
}

DeadlockTest().fire()


// Atomic operations

class AtomicOperationsPseudoCodeTest {
    func compareAndSwap(_ old: Int, _ new: Int, value: UnsafeMutablePointer<Int>) -> Bool {
        if value.pointee == old {
            value.pointee = new
            return true
        }
        return false
    }
    
    func atomicAdd(_ amount: Int, value: UnsafeMutablePointer<Int>) -> Int {
        var success = false
        var new: Int = 0
        
        while !success {
            let original = value.pointee
            new = original + amount
            success = compareAndSwap(original, new, value: value)
        }
        
        return new
    }
}

var pValue: Int = 0
AtomicOperationsPseudoCodeTest().atomicAdd(10, value: &pValue)
print(pValue)

class AtomicOperationsTest {
    private var i: Int64 = 0
    
    func test() {
        OSAtomicCompareAndSwap64(i, 10, &i)
        OSAtomicAdd64(20, &i)
        OSAtomicIncrement64Barrier(&i)
    }
}

AtomicOperationsTest().test()

// Memory Barrier

class MemoryBarrierTest {
    class TestClass {
        var t1: Int?
        var t2: Int?
    }
    
    var testClass: TestClass?
    
    func test() {
        let thread1 = Thread {
            let tmp = TestClass()
            tmp.t1 = 100
            tmp.t2 = 500
            OSMemoryBarrier()
            self.testClass = tmp
        }
        thread1.start()
        
        let thread2 = Thread {
            while self.testClass == nil {}
            OSMemoryBarrier()
            print(self.testClass?.t1)
        }
        thread2.start()
    }
}

MemoryBarrierTest().test()

