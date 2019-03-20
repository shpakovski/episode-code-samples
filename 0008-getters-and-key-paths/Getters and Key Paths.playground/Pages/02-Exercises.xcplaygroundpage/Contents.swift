import Foundation

/*:
 # Getters and Key Paths Exercises

 1. Find three more standard library APIs that can be used with our `get` and `^` helpers.
 */

func get<Root, Value>(_ keyPath: KeyPath<Root, Value>) -> (Root) -> Value {
  return { $0[keyPath: keyPath] }
}

prefix operator ^
prefix func ^ <Root, Value>(_ keyPath: KeyPath<Root, Value>) -> (Root) -> Value {
  return get(keyPath)
}

func combining<Root, Value>(_ f: @escaping (Root) -> Value, by g: @escaping (Value, Value) -> Value) -> (Value, Root) -> Value {
    return { g($0, f($1)) }
}

func their<Root, Value>(_ f: @escaping (Root) -> Value, _ g: @escaping (Value, Value) -> Bool) -> (Root, Root) -> Bool {
  return { g(f($0), f($1)) }
}

func their<Root, Value: Comparable>(_ f: @escaping (Root) -> Value) -> (Root, Root) -> Bool {
  return their(f, <)
}

struct User {
  let id: Int
  let email: String
}

let users = [
  User(id: 1, email: "blob@pointfree.co"),
  User(id: 2, email: "protocol.me.maybe@appleco.example"),
  User(id: 3, email: "bee@co.domain"),
  User(id: 4, email: "a.morphism@category.theory")
]

extension User {
  var isStaff: Bool {
    return self.email.hasSuffix("@pointfree.co")
  }
}

// map, filter, sorted, max, min, reduce

dump(users.first(where: (!) <<< ^\.isStaff))
dump(users.last(where: (!) <<< ^\.isStaff))
users.contains(where: ^\.isStaff)
users.allSatisfy(^\.isStaff)

// users.prefix(while:)
// users.removeAll(where:)
// etc.

/*:
 2. The one downside to key paths being _only_ compiler generated is that we do not get to create new ones ourselves. We only get the ones the compiler gives us.

    And there are a lot of getters and setters that are not representable by key paths. For example, the “identity” key path `KeyPath<A, A>` that simply returns `self` for the getter and that setting on it leaves it unchanged. Can you think of any other interesting getters/setters that cannot be represented by key paths?
 */

// Swift 5 introduced \User.self as an identity key path
// Sad but enum cases cannot be represented by key paths
// It would be nice to have them for tuples as well!

/*:
 3. In our [Setters and Key Paths](https://www.pointfree.co/episodes/ep7-setters-and-key-paths) episode we showed how `map` could kinda be seen as a “setter” by saying:

    “If you tell me how to transform an `A` into a `B`, I will tell you how to transform an `[A]` into a `[B]`.”

    There is also a way to think of `map` as a “getter” by saying:

    “If you tell me how to get a `B` out of an `A`, I will tell you how to get an `[B]` out of an `[A]`.”

    Try composing `get` with free `map` function to construct getters that go even deeper into a structure.

    You may want to use the data types we defined [last time](https://github.com/pointfreeco/episode-code-samples/blob/1998e897e1535a948324d590f2b53b6240662379/0007-setters-and-key-paths/Setters%20and%20Key%20Paths.playground/Contents.swift#L2-L20).
 */

struct Food {
  var name: String
}

struct Location {
  var name: String
}

struct User2 {
  var favoriteFoods: [Food]
  var location: Location
  var name: String
}

let users2 = [
  User2(
    favoriteFoods: [Food(name: "Tacos"), Food(name: "Nachos")],
    location: Location(name: "Brooklyn"),
    name: "Blob"),
  User2(
    favoriteFoods: [Food(name: "Soup")],
    location: Location(name: "New York"),
    name: "Temp")]

func map<A, B>(_ f: @escaping (A) -> B) -> ([A]) -> [B] {
  return { $0.map(f) }
}

let userLocationNames: ([User2]) -> [String] = ^\User2.location.name |> map
dump(users2 |> userLocationNames)

/*:
 4. Repeat the above exercise by seeing how the free optional `map` can allow you to dive deeper into an optional value to extract out a part.

    Key paths even give first class support for this operation. Do you know what it is?
 */

func map<A, B>(_ f: @escaping (A) -> B) -> (A?) -> B? {
  return { $0.map(f) }
}

let userLocationName: (User2?) -> String? = ^\User2.location.name |> map
dump(users2.first |> userLocationName)

// Q: Key paths even give first class support for this operation. Do you know what it is?
// A: No, please explain 🙏

/*:
 5. Key paths aid us in getter composition for structs, but enums don't have any stored properties. Write a getter function for `Result` that plucks out a value if it exists, such that it can compose with `get`. Use this function with a value in `Result<User, String>` to return the user's name.
 */

enum Result<Value, Error> {
  case success(Value)
  case failure(Error)
}
let result = Result<User2, String>.success(users2[0])
func get<Root, Value, Error>(_ keyPath: KeyPath<Root, Value>) -> (Result<Root, Error>) -> Value {
  return { result in
    guard case let .success(root) = result else { fatalError() }
    return root[keyPath: keyPath]
  }
}
dump(result |> get(\User2.name))

/*:
 6. Key paths work immediately with all fields in a struct, but only work with computed properties on an enum. We saw in [Algebra Data Types](https://www.pointfree.co/episodes/ep4-algebraic-data-types) that structs and enums are really just two sides of a coin: neither one is more important or better than the other.

    What would it look like to define an `EnumKeyPath<Root, Value>` type that encapsulates the idea of “getting” and “setting” cases in an enum?
 */

enum Session {
  enum Account {
    case individual(email: String)
    case enterprise(id: UUID)
  }
  case loggedOut
  case loggedIn(account: Account)
}

// https://gist.github.com/mbrandonw/e6247b84f2a3b83c8fa27d022eed3927
struct EnumKeyPath<Whole, Part> { // A keypath-like structure for enums.
  let get: (Whole) -> Part? // Given an enum, we can try to get the associated value in a case.
  let set: (Part) -> Whole // Given an associated value, we can plug it into the enum.
}

protocol Enum {
  subscript<Part>(keyPath: EnumKeyPath<Self, Part>) -> Part? { get set }
}

extension Enum {
  subscript<Part>(keyPath: EnumKeyPath<Self, Part>) -> Part? {
    get {
      return keyPath.get(self)
    }
    set(newValue) {
      newValue.map { self = keyPath.set($0) }
    }
  }
}

extension Session: Enum {}

enum Session: Enum {
  enum Account {
    case individual(email: String)
    case enterprise(id: UUID)
  }
  case loggedOut
  case loggedIn(account: Account)
}

let loggedOut = EnumKeyPath<Session, Void>(get: {
  guard case .loggedOut = $0 else { return nil }
  return ()
}, set: { _ in .loggedOut })

let loggedIn = EnumKeyPath<Session, Session.Account>(get: {
  guard case let .loggedIn(account) = $0 else { return nil }
  return account
}, set: { .loggedIn(account: $0) })

var session = Session.loggedOut
dump(session[loggedOut])

session[loggedIn] = .individual(email: "hello@world.com")
dump(session)

/*:
 7. Given a value in `EnumKeyPath<A, B>` and `EnumKeyPath<B, C>`, can you construct a value in
 `EnumKeyPath<A, C>`?
 */

let individual = EnumKeyPath<Session.Account, String>(get: {
  guard case let .individual(email) = $0 else { return nil }
  return email
}, set: { .individual(email: $0) })

func + <A, B, C>(lhs: EnumKeyPath<A, B>, rhs: EnumKeyPath<B, C>) -> EnumKeyPath<A, C> {
  return .init(get: { a in
    guard let b = lhs.get(a) else { return nil }
    return rhs.get(b)
  }, set: { c in
    return lhs.set(rhs.set(c))
  })
}

dump(session[loggedIn + individual])

/*:
 8. Given a value in `EnumKeyPath<A, C>` and a value in `EnumKeyPath<B, C>`, can you construct a value in `EnumKeyPath<Either<A, B>, C>`?
 */

enum Either<A, B> {
  case left(A)
  case right(B)
}

func - <A, B, C>(lhs: EnumKeyPath<A, C>, rhs: EnumKeyPath<B, C>) -> EnumKeyPath<Either<A, B>, C> {
  return .init(get: { ab in
    switch ab {
    case let .left(a): return lhs.get(a)
    case let .right(b): return rhs.get(b)
    }
  }, set: { c in
    return .left(lhs.set(c)) // .right(rhs.set(c))
  })
}

// The answer is no, because both left and right values can be constructed in a setter
