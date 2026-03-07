type testFn = unit => unit

@module("node:test") external describe: (string, testFn) => unit = "describe"
@module("node:test") external test: (string, testFn) => unit = "test"

@module("node:assert/strict") external equal: ('a, 'a) => unit = "deepStrictEqual"
@module("node:assert/strict") external ok: bool => unit = "ok"
@module("node:assert/strict") external throws: (unit => 'a) => unit = "throws"
