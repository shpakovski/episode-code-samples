/*:
 # A Tale of Two Flat-Maps, Exercises

 1. Define `filtered` as a function from `[A?]` to `[A]`.
 */

func filtered<A>(_ xs: [A?]) -> [A] {
  var result: [A] = .init()
  for x in xs {
    switch x {
    case .some(let a):
      result.append(a)
    case .none:
      continue
    }
  }
  return result
}

filtered([1, 2, 3, nil]) // [1, 2, 3]

/*:
 2. Define `partitioned` as a function from `[Either<A, B>]` to `(left: [A], right: [B])`. What does this function have in common with `filtered`?
 */

enum Either<A, B> {
  case left(A)
  case right(B)
}

func partitioned<A, B>(_ xs: [Either<A, B>]) -> (left: [A], right: [B]) {
  var lefts: [A] = .init()
  var rights: [B] = .init()
  for x in xs {
    switch x {
    case let .left(a):
      lefts.append(a)
    case let .right(b):
      rights.append(b)
    }
  }
  return (lefts, rights)
}

partitioned([.left(1), .left(2), .right(true)]) // ([1, 2], [true])

/*:
 3. Define `partitionMap` on `Optional`.
 */

extension Array {
  func partitionMap<A, B>(_ transform: (Element) -> Either<A, B>) -> (lefts: [A], rights: [B]) {
    var result = (lefts: [A](), rights: [B]())
    for x in self {
      switch transform(x) {
      case let .left(a):
        result.lefts.append(a)
      case let .right(b):
        result.rights.append(b)
      }
    }
    return result
  }
}

extension Optional {

  func partitionMap<A>(_ transform: (Wrapped) -> A?) -> A? {
    switch self {
    case .some(let wrapped):
      return transform(wrapped)
    case .none:
      return nil
    }
  }
}

/*:
 4. Dictionary has `mapValues`, which takes a transform function from `(Value) -> B` to produce a new dictionary of type `[Key: B]`. Define `filterMapValues` on `Dictionary`.
 */

extension Array {
  func filterMap<B>(_ transform: (Element) -> B?) -> [B] {
    var result = [B]()
    for x in self {
      switch transform(x) {
      case let .some(x):
        result.append(x)
      case .none:
        continue
      }
    }
    return result
  }
}

extension Dictionary {

  func filterMapValues<B>(_ transform: (Value) -> B?) -> [Key: B] {
    reduce(into: .init()) { result, pair in
      result[pair.key] = transform(pair.value)
    }
  }
}

[1: "2", 2: "String"]
  .filterMapValues(Int.init)

/*:
 5. Define `partitionMapValues` on `Dictionary`.
 */

extension Dictionary {

  func partitionMapValues<A, B>(_ transform: (Value) -> Either<A, B>) -> (left: [Key: A], right: [Key: B]) {
    var left: [Key: A] = .init()
    var right: [Key: B] = .init()
    for (key, value) in self {
      switch transform(value) {
      case .left(let a):
        left[key] = a
      case .right(let b):
        right[key] = b
      }
    }
    return (left, right)
  }
}

[1: 2, 2: 3, 3: 4]
  .partitionMapValues { $0 % 2 == 0 ? .left($0) : .right($0) }

/*:
 6. Rewrite `filterMap` and `filter` in terms of `partitionMap`.
 */

extension Array {

  func filterMap2<B>(_ transform: (Element) -> B?) -> [B] {
    partitionMap { (element) -> Either<B, Void> in
      switch transform(element) {
      case .some(let l):
        return .left(l)
      case .none:
        return .right(())
      }
    }.lefts
  }

  func filter2(_ p: (Element) -> Bool) -> [Element] {
    partitionMap { p($0) ? .left($0) : .right($0) }.lefts
  }
}

[1, 2, 3, 4]
  .filter2 { $0 % 2 == 0 }

/*:
 7. Is it possible to define `partitionMap` on `Either`?
 */

extension Either {

  func partitionMap<C, D>(_ transform: (Either<A, B>) -> Either<C, D>) -> (lefts: [C], rights: [D]) {
    var lefts: [C] = .init()
    var rights: [D] = .init()
    switch transform(self) {
    case .left(let c):
      lefts.append(c)
    case .right(let d):
      rights.append(d)
    }
    return (lefts, rights)
  }
}

[Either.left(1), .right("x"), .left(2), .right("y")]
  .partitionMap { (e: Either<Int, String>) -> Either<Int, String> in
    switch e {
    case .left(let l):
      return .left(l + l)
    case .right(let r):
      return .right(r + r)
    }
  }
