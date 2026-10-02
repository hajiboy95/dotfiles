// Prints the next timed event starting within N minutes (default 30)
// as "<minutes until start>|<title>", or nothing. Asks for calendar
// access the first time (granted to sketchybar, which runs it).
import EventKit
import Foundation

let window = Double(CommandLine.arguments.dropFirst().first ?? "30") ?? 30
let store = EKEventStore()
let done = DispatchSemaphore(value: 0)
var granted = false
store.requestFullAccessToEvents { ok, _ in
    granted = ok
    done.signal()
}
done.wait()
guard granted else { exit(0) }

let now = Date()
let predicate = store.predicateForEvents(
    withStart: now,
    end: now.addingTimeInterval(window * 60),
    calendars: nil
)
let next = store.events(matching: predicate)
    .filter { !$0.isAllDay && $0.startDate >= now }
    .min { $0.startDate < $1.startDate }
if let next {
    let minutes = Int((next.startDate.timeIntervalSince(now) / 60).rounded(.up))
    print("\(minutes)|\(next.title ?? "Event")")
}
