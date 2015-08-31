//
//  HarrierDelegate.swift
//  Pods
//
//  Created by Graham Chance on 8/29/15.
//
//

import Foundation

public protocol HarrierQueueDelegate {
    
    func executeTask(task: HarrierTask)
    
}