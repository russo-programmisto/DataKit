//
//  InMemoryTable.swift
//  DataKit
//
//  Created by Igor Matyushkin on 02.07.16.
//  Copyright © 2016 Igor Matyushkin. All rights reserved.
//

import UIKit

public class InMemoryTable<ObjectClass where ObjectClass: Object>: NSObject {
    
    // MARK: Class variables & properties
    
    
    // MARK: Public class methods
    
    
    // MARK: Private class methods
    
    
    // MARK: Initializers
    
    public override init() {
        super.init()
        
        
        // Initialize objects collection
        
        _objects = [ObjectClass]()
        
        
        // Initialize operation queue
        
        let nameForOperationQueue = String(format: "Operation queue for %@ table", NSStringFromClass(ObjectClass))
        _operationQueue = dispatch_queue_create(nameForOperationQueue, DISPATCH_QUEUE_SERIAL)
        
        
        // Initialize response queue
        
        _responseQueue = dispatch_get_main_queue()
    }
    
    
    // MARK: Deinitializer
    
    deinit {
    }
    
    
    // MARK: Object variables & properties
    
    private var _objects: [ObjectClass]!
    
    private var objects: [ObjectClass] {
        get {
            return _objects
        }
    }
    
    private var _operationQueue: dispatch_queue_t!
    
    private var operationQueue: dispatch_queue_t {
        get {
            return _operationQueue
        }
    }
    
    private var _responseQueue: dispatch_queue_t!
    
    private var responseQueue: dispatch_queue_t {
        get {
            return _responseQueue
        }
    }
    
    
    // MARK: Public object methods
    
    public func numberOfAllObjectsWithCompletion(completion: (numberOfObjects: Int) -> Void) {
        runOnOperationQueue { 
            let numberOfObjects = self.objects.count
            
            self.runOnResponseQueue({ 
                completion(numberOfObjects: numberOfObjects)
            })
        }
    }
    
    public func numberOfObjectsWithPredicate(predicate: SelectionPredicate<ObjectClass>, andCompletion completion: (numberOfObjects: Int) -> Void) {
        runOnOperationQueue {
            var numberOfObjectsSatisfyingPredicate = 0
            let numberOfAllObjects = self.objects.count
            
            for i in 0..<numberOfAllObjects {
                let object = self.objects[i]
                
                if predicate.evaluateObject(object) {
                    numberOfObjectsSatisfyingPredicate += 1
                }
            }
            
            self.runOnResponseQueue({
                completion(numberOfObjects: numberOfObjectsSatisfyingPredicate)
            })
        }
    }
    
    public func findAllObjectsWithCompletion(completion: (objects: [ObjectClass]) -> Void) {
        runOnOperationQueue { 
            var allObjects = [ObjectClass]()
            allObjects.appendContentsOf(self.objects)
            
            self.runOnResponseQueue({ 
                completion(objects: allObjects)
            })
        }
    }
    
    public func findAllObjectsWithPredicate(predicate: SelectionPredicate<ObjectClass>, andCompletion completion: (objects: [ObjectClass]) -> Void) {
        runOnOperationQueue {
            var resultObjects = [ObjectClass]()
            let numberOfObjects = self.objects.count
            
            for i in 0..<numberOfObjects {
                let object = self.objects[i]
                
                if predicate.evaluateObject(object) {
                    resultObjects.append(object)
                }
            }
            
            self.runOnResponseQueue({ 
                completion(objects: resultObjects)
            })
        }
    }
    
    public func findFirstObjectWithPredicate(predicate: SelectionPredicate<ObjectClass>, andCompletion completion: (object: ObjectClass?) -> Void) {
        runOnOperationQueue {
            let numberOfObjects = self.objects.count
            
            for i in 0..<numberOfObjects {
                let object = self.objects[i]
                
                if predicate.evaluateObject(object) {
                    self.runOnResponseQueue({
                        completion(object: object)
                    })
                    
                    return
                }
            }
            
            self.runOnResponseQueue({
                completion(object: nil)
            })
        }
    }
    
    public func insertObject(object: ObjectClass, withCompletion completion: (() -> Void)?) {
        runOnOperationQueue { 
            self._objects.append(object)
            
            self.runOnResponseQueue({ 
                completion?()
            })
        }
    }
    
    public func deleteAllObjectWithCompletion(completion: ((numberOfDeletedObjects: Int) -> Void)?) {
        runOnOperationQueue {
            let numberOfObjectsToDelete = self.objects.count
            self._objects.removeAll(keepCapacity: false)
            
            self.runOnResponseQueue({
                completion?(numberOfDeletedObjects: numberOfObjectsToDelete)
            })
        }
    }
    
    public func deleteAllObjectsWithPredicate(predicate: SelectionPredicate<ObjectClass>, andCompletion completion: ((numberOfDeletedObjects: Int) -> Void)?) {
        runOnOperationQueue { 
            let indexesOfObjectsToDelete = self.indexesOfAllObjectsSatisfyingPredicate(predicate)
            let numberOfObjectsToDelete = indexesOfObjectsToDelete.count
            
            for i in 0..<numberOfObjectsToDelete {
                let indexOfCurrentObjectToDelete = indexesOfObjectsToDelete[i] - i
                self._objects.removeAtIndex(indexOfCurrentObjectToDelete)
            }
            
            self.runOnResponseQueue({ 
                completion?(numberOfDeletedObjects: numberOfObjectsToDelete)
            })
        }
    }
    
    public func deleteFirstObjectWithPredicate(predicate: SelectionPredicate<ObjectClass>, andCompletion completion: ((deleted: Bool) -> Void)?) {
        runOnOperationQueue {
            let indexOfObjectToDelete = self.indexOfFirstObjectSatisfyingPredicate(predicate)
            
            var deleted = false
            
            if indexOfObjectToDelete != nil {
                self._objects.removeAtIndex(indexOfObjectToDelete!)
                deleted = true
            }
            
            self.runOnResponseQueue({
                completion?(deleted: deleted)
            })
        }
    }
    
    
    // MARK: Private object methods
    
    private func indexesOfAllObjectsSatisfyingPredicate(predicate: SelectionPredicate<ObjectClass>) -> [Int] {
        var resultIndexes = [Int]()
        let numberOfObjects = self.objects.count
        
        for i in 0..<numberOfObjects {
            let object = self.objects[i]
            
            if predicate.evaluateObject(object) {
                resultIndexes.append(i)
            }
        }
        
        return resultIndexes
    }
    
    private func indexOfFirstObjectSatisfyingPredicate(predicate: SelectionPredicate<ObjectClass>) -> Int? {
        let numberOfObjects = self.objects.count
        
        for i in 0..<numberOfObjects {
            let object = self.objects[i]
            
            if predicate.evaluateObject(object) {
                return i
            }
        }
        
        return nil
    }
    
    private func runOnOperationQueue(block: () -> Void) {
        dispatch_async(operationQueue) { 
            block()
        }
    }
    
    private func runOnResponseQueue(block: () -> Void) {
        dispatch_async(responseQueue) {
            block()
        }
    }
    
    
    // MARK: Protocol methods
    
}