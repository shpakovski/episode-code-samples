func first<A, B, C>(_ f: @escaping (A) -> C) -> ((A, B)) -> (C, B) {
  return { pair in
    (f(pair.0), pair.1)
  }
}

func second<A, B, C>(_ f: @escaping (B) -> C) -> ((A, B)) -> (A, C) {
  return { pair in
    (pair.0, f(pair.1))
  }
}

precedencegroup BackwardsComposition {
  associativity: left
}
infix operator <<<: BackwardsComposition
func <<< <A, B, C>(_ f: @escaping (B) -> C, _ g: @escaping (A) -> B) -> (A) -> C {
  return { f(g($0)) }
}

/*:
 # Functional Setters Exercises

 1. As we saw with free `map` on `Array`, define free `map` on `Optional` and use it to compose setters that traverse into an optional field.
 */

public func map<A, B>(_ f: @escaping (A) -> B) -> (A?) -> B? {
  return { a in a.map(f) }
}

var xy: (Int?, Int?) = (nil, 2)
print(xy |> (second <<< map) { $0 * 2 })

/*:
 2. Take the following `User` struct and write a setter for its `name` property. Add another property, and add a setter for it. What are some potential issues with building these setters?
 */

struct User1 {
  let name: String
}

func userName(_ f: @escaping (String) -> String) -> (User1) -> User1 {
  return { .init(name: f($0.name)) }
}
print(User1(name: "X") |> userName { $0 + $0 } )

struct User2 {
  let name: String
  let age: Int
}

func userName2(_ f: @escaping (String) -> String) -> (User2) -> User2 {
  return { .init(name: f($0.name), age: $0.age) }
}
func userAge2(_ f: @escaping (Int) -> Int) -> (User2) -> User2 {
  return { .init(name: $0.name, age: f($0.age)) }
}
print(User2(name: "X", age: 20) |> userName2 { $0 + "!" } <> userAge2 { $0 + 1 } )

// The problem is that in addition to the new setter, we have to modify all existing setters.

/*:
 3. Add a `location` property to `User`, which holds a `Location`, defined below. Write a setter for `userLocationName`. Now write setters for `userLocation` and `locationName`. How do these setters compose?
 */

struct Location {
  let name: String
}
struct User {
  let name: String
  let age: Int
  let location: Location
}
let user = User(name: "X", age: 30, location: Location(name: "Earth"))

func userLocationName(_ f: @escaping (String) -> String) -> (User) -> User {
  return { .init(name: $0.name, age: $0.age, location: .init(name: f($0.location.name))) }
}
print(user |> userLocationName { "Maybe \($0)" })

func userLocation(_ f: @escaping (Location) -> Location) -> (User) -> User {
  return { .init(name: $0.name, age: $0.age, location: f($0.location)) }
}
func locationName(_ f: @escaping (String) -> String) -> (Location) -> Location {
  return { .init(name: f($0.name)) }
}
print(user |> (userLocation <<< locationName) { "Definitely \($0)" })

/*:
 4. Do `first` and `second` work with tuples of three or more values? Can we write `first`, `second`, `third`, and `nth` for tuples of _n_ values?
 */

func first<A, B, C, D>(_ f: @escaping (A) -> D) -> ((A, B, C)) -> (D, B, C) {
  return { (f($0.0), $0.1, $0.2) }
}

func second<A, B, C, D>(_ f: @escaping (B) -> D) -> ((A, B, C)) -> (A, D, C) {
  return { ($0.0, f($0.1), $0.2) }
}

func third<A, B, C, D>(_ f: @escaping (C) -> D) -> ((A, B, C)) -> (A, B, D) {
  return { ($0.0, $0.1, f($0.2)) }
}

// Each nth function for a tuple of m values would require m + 1 generic parameters.

/*:
 5. Write a setter for a dictionary that traverses into a key to set a value.
 */

func setValue<Key, Value>(for key: Key) -> (@escaping (Value?) -> Value) -> ([Key: Value]) -> [Key: Value] {
  return { f in {
    var copy = $0
    copy[key] = f(copy[key])
    return copy
  } }
}

let kv = [1: "A", 2: "B"]
print(kv |> (setValue(for: 3)) { _ in "C" })

/*:
 6. Write a setter for a dictionary that traverses into a key to set a value if and only if that value already exists.
 */

func updateValue<Key, Value>(for key: Key) -> (@escaping (Value) -> Value) -> ([Key: Value]) -> [Key: Value] {
  return { f in {
    var copy = $0
    copy[key] = copy[key].map(f)
    return copy
  } }
}

print(kv |> (updateValue(for: 3)) { _ in "C" })
print(kv |> (updateValue(for: 2)) { _ in "D" })

/*:
 7. What is the difference between a function of the form `((A) -> B) -> (C) -> (D)` and one of the form `(A) -> (B) -> (C) -> D`?
 */

// The first takes a closure as its parameter and returns a closure as result.
// The second takes a value as its parameters and returns a closure which returns a closure as result.
