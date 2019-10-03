# FutureAwaits

Lightweight library for async-await programming with `Future`s or `Await` written in Swift.

Follow the **upcoming updates [here](https://trello.com/b/uVivmHBM)**:

**Features:**
- Always returns a result with either a value or a managed error.
- Possibility of running multiple functions concurrently.
- Lower level API with `Await` that returns synchrounous `Result` code.
- Upper level API with `Future`, whose API is similar to `Result`.

## Examples

- **Index**:
	- Using `Future`.
	- Using `Result` and `Await`.

### Future

Future is a class that manages a `Result` built with `Await` / `MultiAwait`.
You can safely pass futures around and only get the result value when you want.

Here are a few usages:

- Creating a `Future`:
```swift
func somethingFuture() -> Future<Int, Test> {
    return Future({ completion in
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
            let retrievedValue = 23
            if Bool.random() {
                completion(.failure(Test.test))
            } else {
                completion(.success(retrievedValue))
            }
        }
    })
}
```

- Creating a `Future` from `Await` or any `Result`:
```swift
func somethingFuture5() -> Future<[Int], Test> {
    return Future(Await.default.run(
        { self.somethingAsync() },
        { self.somethingAsync() }
    ))
}
```

- Getting the value of a `Future` asynchronously:
```swift
somethingFuture().then { result in
    print(result)
}
```

- Getting a value or an error:
```swift
self.somethingFuture().onSuccess { value in
    print(value)
}.onFailure { error in
    print(error)
}
```

- Getting the values of some `Future`'s:
(This waits one by one all the futures, for a more optimized version see `Futures.combine` below)
```swift
Futures.wait(
    self.somethingFuture(), self.somethingFuture2(), self.somethingFuture3()
).onSuccess { (value1, value2, value3) in
    print(value1, value2, value3)
}.onFailure { error in
    print(error.localizedDescription)
}
```

- Mapping a value:
```swift
// map
self.somethingFuture()
    .map { $0 * 2}
    .then { result in
        print(result)
    }
// map + flatMap     
self.somethingFuture()
	.flatMap { self.somethingFuture10(value: $0) }
	.map { $0 * Double(i) }
	.flatMap { self.somethingFuture10(value: Int($0)) }
	.then { result in
		print(result)
	}
```

- Combine multiple future values:
(Concurrently runs all the futures and waits to get all the values)
```swift
Futures.combine(
    self.somethingFuture(), self.somethingFuture2()
).onSuccess { results in
    print(results)
}.onFailure { error in
    print(error)
}
```
**Note:** you can either use `combine` or `combineOmittingErrors` (the later doesn't stop on an error, and it returns a dictionary with the results)

---

### (Lower level) `Result` and `Await`

- Creating a synchrounous `Result` with the `await` function (which is a helper function for the `Await` struct):
```swift
func somethingAsync() -> Result<Int, Test> {
    return await { completion in
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
            let retrievedValue = 23
            if Bool.random() {
                completion(.failure(Test.test))
            } else {
                completion(.success(retrievedValue))
            }
        }
    }
}
```

- Getting the value of a function that uses `Await` with the `async` function:
```swift
async {
    let result = somethingAsync()
    // ... map the value, get the value or error, use it in other operation, etc
}
```

- Running multiple async functions concurrently using the same `Result` type.
```swift
async {
    Await.default.run(
        { self.somethingAsync() },
        { self.somethingAsync() }
    ).onSuccess { results in // results is an array of values
        print(results)
    }.onFailure { error in
        print(error)
    }
}
```
**Note:** you can either use `run` or `runOmittingErrors` (the later doesn't stop on an error, and it returns a dictionary with the results)

- Running multiple async functions concurrently using a different `Result` type.
```swift
async {
    MultiAwait.default.run(
        somethingAsync(),
        somethingAsync()
    ).onSuccess { results in // results is a TUPLE of values
        print(results)
    }.onFailure { error in
        print(error)
    }
}
```
**Note:** you can either use `run` or `runOmittingErrors` (the later doesn't stop on an error, and it returns a tuple with optional values)

**Pro tip**: use `Never` as the error type if the function never returns an error
