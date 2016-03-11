# Harrier Queue
Harrier Queue is a persistent task queue written in Swift.
##### "As this bird has a wide distribution, it will take whatever prey is available in the area where it nests [and add them to its task queue]" - Wikipedia

## Usage
```swift
let queue = HarrierQueue(delegate: delegate, filepath: "path/to/save/db.sqlite")
let task = HarrierTask(name:"A task", priority: 0, taskAttributes: ["key1": "value", "key2": "value"], retryLimit: 3, availabilityDate: NSDate())
queue.enqueueTask(task)
```

## Requirements

## Installation

Harrier is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "HarrierQueue"
```

## Author

Graham Chance

## License

Harrier is available under the MIT license. See the LICENSE file for more info.
