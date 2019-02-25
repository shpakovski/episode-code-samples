/*:
 # Setters and Key Paths Exercises

 1. In this episode we used `Dictionary`’s subscript key path without explaining it much. For a `key: Key`, one can construct a key path `\.[key]` for setting a value associated with `key`. What is the signature of the setter `prop(\.[key])`? Explain the difference between this setter and the setter `prop(\.[key]) <<< map`, where `map` is the optional map.
 */

func prop<Root, Value>(_ keyPath: WritableKeyPath<Root, Value>) -> (@escaping (Value) -> Value) -> (Root) -> Root {
  return { update in
    { root in
      var copy = root
      copy[keyPath: keyPath] = update(copy[keyPath: keyPath])
      return copy
    }
  }
}

func map<A, B>(_ transform: @escaping (A) -> B) -> (A?) -> B? {
  return { $0.map(transform) }
}

// The second expression would have an effect only if the value for key is already assigned
let prop1 = prop(\[Int: String].[1]) // ((Value?) -> Value?) -> ([Key: Value]) -> [Key: Value]
let prop2 = prop(\[Int: String].[1]) <<< map // ((Value) -> Value) -> ([Key: Value]) -> [Key: Value]

/*:
 2. The `Set<A>` type in Swift does not have any key paths that we can use for adding and removing values. However, that shouldn't stop us from defining a functional setter! Define a function `elem` with signature `(A) -> ((Bool) -> Bool) -> (Set<A>) -> Set<A>`, which is a functional setter that allows one to add and remove a value `a: A` to a set by providing a transformation `(Bool) -> Bool`, where the input determines if the value is already in the set and the output determines if the value should be included.
 */

func elem<A>(_ a: A) -> (@escaping (Bool) -> Bool) -> (Set<A>) -> Set<A> {
  return { add in
    { set in
      let isAdded = set.contains(a)
      let shouldAdd = add(isAdded)
      if shouldAdd && isAdded { return set }
      if !shouldAdd && !isAdded { return set }
      var copy = set
      if shouldAdd {
        copy.insert(a)
      } else {
        copy.remove(a)
      }
      return copy
    }
  }
}

let s: Set<Int> = [1, 2, 3, 4]
dump(s |> (elem(2)) { !$0 } |> (elem(5)) { !$0 })

/*:
 3. Generalizing exercise #1 a bit, it turns out that all subscript methods on a type get a compiler generated key path. Use array’s subscript key path to uppercase the first favorite food for a user. What happens if the user’s favorite food array is empty?
 */

struct Food {
  var name: String
}

struct Location {
  var name: String
}

struct User {
  var favoriteFoods: [Food]
  var location: Location
  var name: String
}

let user = User(
  favoriteFoods: [Food(name: "Tacos"), Food(name: "Nachos")],
  location: Location(name: "Brooklyn"),
  name: "Blob"
)

let firstUppercased = (prop(\User.favoriteFoods[0].name)) { $0.uppercased() }
dump(user |> firstUppercased)

// The following statement would crash
// user |> (prop(\User.favoriteFoods)) { _ in [] } <<< firstUppercased

/*:
 4. Recall from a [previous episode](https://www.pointfree.co/episodes/ep5-higher-order-functions) that the free `filter` function on arrays has the signature `((A) -> Bool) -> ([A]) -> [A]`. That’s kinda setter-like! What does the composed setter `prop(\User.favoriteFoods) <<< filter` represent?
 */

func filter<A>(_ f: @escaping (A) -> Bool) -> ([A]) -> [A] {
  return { array in
    array.filter(f)
  }
}
dump([1, 2, 3] |> filter { $0 % 2 != 0 })

let filteredFoods = prop(\User.favoriteFoods) <<< filter
dump(user |> filteredFoods { $0.name != "Tacos" })

/*:
 5. Define the `Result<Value, Error>` type, and create `value` and `error` setters for safely traversing into those cases.
 */

enum Result<Value, Error> {
  case success(Value)
  case failure(Error)
}

func value<Value, Error>(_ f: @escaping (Value) -> Value) -> (Result<Value, Error>) -> Result<Value, Error> {
  return { result in
    guard case let .success(value) = result else { return result }
    return .success(f(value))
  }
}

func error<Value, Error>(_ f: @escaping (Error) -> Error) -> (Result<Value, Error>) -> Result<Value, Error> {
  return { result in
    guard case let .failure(error) = result else { return result }
    return .failure(f(error))
  }
}

dump(Result<Int, Swift.Error>.success(3) |> value { $0 + $0 })

/*:
 6. Is it possible to make key path setters work with `enum`s?
 */

// Currently no, because their behavior on cases without associated values would be undefined.
// However, the compiler could potentially build something like KeyPath<Root, Never> for such.

/*:
 7. Redefine some of our setters in terms of `inout`. How does the type signature and composition change?
 */

func inoutProp<Root, Value>(_ keyPath: WritableKeyPath<Root, Value>) -> (@escaping (inout Value) -> Void) -> (Root) -> Root {
  return { update in
    { root in
      var copy = root
      var value = copy[keyPath: keyPath]
      update(&value)
      copy[keyPath: keyPath] = value
      return copy
    }
  }
}

func inoutValue<Value, Error>(_ f: @escaping (inout Value) -> Void) -> (Result<Value, Error>) -> Result<Value, Error> {
  return { result in
    guard case var .success(value) = result else { return result }
    f(&value)
    return .success(value)
  }
}

let iop = inoutProp(\User.favoriteFoods[0].name) // ((String) -> Void) -> (User) -> User
dump(user |> iop { $0 += $0 })
dump(Result<Int, Swift.Error>.success(2) |> inoutValue { $0 += $0 })
