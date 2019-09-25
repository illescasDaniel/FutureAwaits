//
//  File.swift
//  
//
//  Created by Daniel Illescas Romero on 25/09/2019.
//

import enum Swift.Result

public struct Futures {
	public static func wait<T,T2, E,E2>(
		_ futures: (Future<T, E>, Future<T2, E2>)
	) -> Future<(T,T2), Error> {
		return Future<(T,T2), Error>({ completion in
			do { completion(.success((try futures.0.get(), try futures.1.get()))) }
			catch AsyncAwait.Error<E>.error(let e) { completion(.failure(e)) }
			catch AsyncAwait.Error<E2>.error(let e) { completion(.failure(e)) }
			catch { completion(.failure(error)) }
		})
	}
	
	public static func wait<T,T2,T3, E,E2,E3>(
		_ futures: (Future<T, E>, Future<T2, E2>, Future<T3, E3>)
	) -> Future<(T,T2,T3), Error> {
		return Future<(T,T2,T3), Error>({ completion in
			do {
				completion(.success(
					(try futures.0.get(), try futures.1.get(), try futures.2.get())
				))
			}
			catch AsyncAwait.Error<E>.error(let error) { completion(.failure(error)) }
			catch AsyncAwait.Error<E2>.error(let error) { completion(.failure(error)) }
			catch AsyncAwait.Error<E3>.error(let error) { completion(.failure(error)) }
			catch { completion(.failure(error)) }
		})
	}
	
	public static func wait<T,T2,T3,T4, E,E2,E3,E4>(
		_ futures: (Future<T, E>, Future<T2, E2>, Future<T3, E3>, Future<T4, E4>)
	) -> Future<(T,T2,T3,T4), Error> {
		return Future<(T,T2,T3,T4), Error>({ completion in
			do {
				completion(.success(
					(try futures.0.get(), try futures.1.get(), try futures.2.get(), try futures.3.get())
				))
			}
			catch AsyncAwait.Error<E>.error(let error) { completion(.failure(error)) }
			catch AsyncAwait.Error<E2>.error(let error) { completion(.failure(error)) }
			catch AsyncAwait.Error<E3>.error(let error) { completion(.failure(error)) }
			catch AsyncAwait.Error<E4>.error(let error) { completion(.failure(error)) }
			catch { completion(.failure(error)) }
		})
	}
	
	public static func wait<T,T2,T3,T4,T5, E,E2,E3,E4,E5>(
		_ futures: (Future<T, E>, Future<T2, E2>, Future<T3, E3>, Future<T4, E4>, Future<T5, E5>)
	) -> Future<(T,T2,T3,T4,T5), Error> {
		return Future<(T,T2,T3,T4,T5), Error>({ completion in
			do {
				completion(.success(
					(try futures.0.get(), try futures.1.get(), try futures.2.get(),
					 try futures.3.get(), try futures.4.get())
				))
			}
			catch AsyncAwait.Error<E>.error(let error) { completion(.failure(error)) }
			catch AsyncAwait.Error<E2>.error(let error) { completion(.failure(error)) }
			catch AsyncAwait.Error<E3>.error(let error) { completion(.failure(error)) }
			catch AsyncAwait.Error<E4>.error(let error) { completion(.failure(error)) }
			catch AsyncAwait.Error<E5>.error(let error) { completion(.failure(error)) }
			catch { completion(.failure(error)) }
		})
	}
	
	public static func wait<T,T2,T3,T4,T5,T6, E,E2,E3,E4,E5,E6>(
		_ futures: (Future<T, E>, Future<T2, E2>, Future<T3, E3>, Future<T4, E4>, Future<T5, E5>, Future<T6, E6>)
	) -> Future<(T,T2,T3,T4,T5,T6), Error> {
		return Future<(T,T2,T3,T4,T5,T6), Error>({ completion in
			do {
				completion(.success(
					(try futures.0.get(), try futures.1.get(), try futures.2.get(),
					 try futures.3.get(), try futures.4.get(), try futures.5.get())
				))
			}
			catch AsyncAwait.Error<E>.error(let error) { completion(.failure(error)) }
			catch AsyncAwait.Error<E2>.error(let error) { completion(.failure(error)) }
			catch AsyncAwait.Error<E3>.error(let error) { completion(.failure(error)) }
			catch AsyncAwait.Error<E4>.error(let error) { completion(.failure(error)) }
			catch AsyncAwait.Error<E5>.error(let error) { completion(.failure(error)) }
			catch AsyncAwait.Error<E6>.error(let error) { completion(.failure(error)) }
			catch { completion(.failure(error)) }
		})
	}
}
