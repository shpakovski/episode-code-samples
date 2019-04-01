/*:
 # Algebraic Data Types: Exponents, Exercises

 1. Explore the equivalence of `1^a = a`.
 */

// 1^a = a
// 1 <- a = a
// a -> 1 = a
// (A) -> Void = A

protocol Initable {
  init() // It’s like Void i.e. 1^1 = 1
}

func to<A: Initable>(_ f: (A) -> Void) -> A {
  return A()
}

func from<A: Initable>(_ a: A) -> (A) -> Void {
  return { _ in }
}

/*:
 2. Explore the properties of `0^a`. Consider the cases where `a = 0` and `a != 0` separately.
 */

// 0^0 = 0
// 0 <- 0 = 0
// 0 -> 0 = 0
// (Never) -> Never = Never

func to(_ f: (Never) -> Never) -> Never {
  fatalError()
}

func from(_ n: Never) -> (Never) -> Never {
  return { never in
    switch never {
      //
    }
  }
}

// 0^a = 0
// 0 <- a = 0
// a -> 0 = 0
// (A) -> Never = Never

func to<A>(_ f: (A) -> Never) -> Never {
  fatalError()
}

func from<A>(_ n: Never) -> (A) -> Never {
  return { _ in
    switch n {
      //
    }
  }
}

/*:
 3. How do you think generics fit into algebraic data types? We've seen a bit of this with thinking of `Optional<A>` as `A + 1 = A + Void`.
 */

// Optional<A> = Either<A, Void> = A + Void
// Result<Value, Error> = Either<Value, Error> = Value + Error
// Either<A, Either<B, C>> = A + (B + C) = A + B + C
// Range<A> = A * A = (A, A)
// Array<A> = A * A * A * A * … = (A, A, A, A, …)

/*:
 4. Show that the set type over a type `A` can be represented as `2^A`. What does union and intersection look like in this formulation?
 */

// Set<A> = (A) -> Bool = A -> 2 = 2 <- A = 2^A

func union<A>(_ f: ((A) -> Bool, (A) -> Bool)) -> (A) -> Bool {
  return { a in f.0(a) || f.1(a) }
}

func intersection<A>(_ f: ((A) -> Bool, (A) -> Bool)) -> (A) -> Bool {
  return { a in f.0(a) && f.1(a) }
}

// ((A) -> Bool, (A) -> Bool) = (A) -> Bool
// (A -> 2) * (A -> 2) = A -> 2
// 2^a * 2^a = 2^a — valid only when a = 0, i.e. Never :)
// However: ((A) -> Bool, (A) -> Bool) = ((A) -> Bool, (A) -> Bool)

func unionPlusIntersection<A>(_ f: ((A) -> Bool, (A) -> Bool)) -> ((A) -> Bool, (A) -> Bool) {
  return ({ a in f.0(a) || f.1(a) }, { a in f.0(a) && f.1(a) })
}

/*:
 5. Show that the dictionary type with keys in `K`  and values in `V` can be represented by `V^K`. What does union of dictionaries look like in this formulation?
 */

func get<K, V>(_ k: K) -> V? {
  fatalError()
}

// (K) -> (V + Void) = (V + 1) <- K = (V + 1)^K

func union<K, V>(_ f: ((K) -> V?, (K) -> V?)) -> (K) -> V? {
  return { k in f.0(k) ?? f.1(k) }
}

// ((K) -> (V + Void), (K) -> (V + Void)) = (K) -> (V + Void)
// (K -> (V + 1)) * (K -> (V + 1)) = (K) -> (V + 1)
// (V + 1)^K * (V + 1)^K = (V + 1) <- K
// (V + 1)^(K + K) = (V + 1)^K

/*:
 6. Implement the following equivalence:
 */

func to<A, B, C>(_ f: @escaping (Either<B, C>) -> A) -> ((B) -> A, (C) -> A) {
  return ({ b in f(.left(b)) }, { c in f(.right(c))} )
}

func from<A, B, C>(_ f: ((B) -> A, (C) -> A)) -> (Either<B, C>) -> A {
  return { bc in
    switch bc {
    case let .left(b): return f.0(b)
    case let .right(c): return f.1(c)
    }
  }
}

/*:
 7. Implement the following equivalence:
 */

func to<A, B, C>(_ f: @escaping (C) -> (A, B)) -> ((C) -> A, (C) -> B) {
  return ({ c in f(c).0 }, { c in f(c).1 })
}

func from<A, B, C>(_ f: ((C) -> A, (C) -> B)) -> (C) -> (A, B) {
  return { c in (f.0(c), f.1(c)) }
}
