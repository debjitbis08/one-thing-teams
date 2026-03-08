module Promise = RescriptCore.Promise

type t<'a, 'e> = Promise.t<result<'a, 'e>>

let ok = (value): t<'a, 'e> => Promise.resolve(Ok(value))

let error = (e): t<'a, 'e> => Promise.resolve(Error(e))

let fromResult = (result: result<'a, 'e>): t<'a, 'e> => Promise.resolve(result)

let flatMap = (promise: t<'a, 'e>, fn: 'a => t<'b, 'e>): t<'b, 'e> =>
  promise->Promise.then(result =>
    switch result {
    | Error(e) => Promise.resolve(Error(e))
    | Ok(value) => fn(value)
    }
  )

let map = (promise: t<'a, 'e>, fn: 'a => 'b): t<'b, 'e> =>
  promise->Promise.thenResolve(result =>
    switch result {
    | Error(e) => Error(e)
    | Ok(value) => Ok(fn(value))
    }
  )
