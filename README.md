# FutureAwaits

Lightweight library for async-await programming written in Swift.

**Features:**
- Always returns a result with either a value or a managed error
- Possibility of running multiple functions concurrently
- Most of the API is based on Swift 5 `Result` type instead of creating an extensive API.
Which means:
    - map method
    - Get value or error
    - Get value or nil using try?

## Examples

### `Result` and `Await`

- Creating a synchrounous `Result` with the `await` function (which is a helper function for the `Await` struct):
```swift
func somethingAsync() -> Result<Int, AsyncAwait.Error<Test>> {
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
    }.onError { error in
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
    }.onError { error in
        print(error)
    }
}
```
**Note:** you can either use run or runOmittingErrors (the later doesn't stop on an error, and it returns a tuple with optional values)

**Pro tip**: use `Never` as the error type if the function never returns an error

---

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
                completion(.failure(Test.test))	 // ??
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

- Getting the synchrounous value of a `Future`:
```swift
async {
    let result1 = somethingFuture().syncResult
    let result2 = somethingFuture2().syncResult
    print(result1, result2)
}
```
