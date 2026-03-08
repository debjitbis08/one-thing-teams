open PmDomain

let proxyNumerator = (~userValue, ~timeCriticality, ~riskReduction) =>
  FibonacciScale.value(userValue.value) +
  FibonacciScale.value(timeCriticality.value) +
  FibonacciScale.value(riskReduction.value)

let effortValue = (effort: score) => {
  let value = FibonacciScale.value(effort.value)
  if value == 0 {
    1
  } else {
    value
  }
}

let calculateWSJF = (score: initiativeScore) =>
  switch score {
  | Proxy({userValue, timeCriticality, riskReduction, effort}) =>
    float_of_int(proxyNumerator(~userValue, ~timeCriticality, ~riskReduction)) /.
    float_of_int(effortValue(effort))
  | BreakEven({contributionCount, effort}) =>
    contributionCount /. float_of_int(effortValue(effort))
  }

let isCore = (score: initiativeScore) =>
  switch score {
  | Proxy({isCore}) => isCore
  | BreakEven({isCore}) => isCore
  }

let compare = (a: initiativeScore, b: initiativeScore) => {
  let coreA = isCore(a)
  let coreB = isCore(b)
  if coreA && !coreB {
    -1
  } else if !coreA && coreB {
    1
  } else {
    let wsjfA = calculateWSJF(a)
    let wsjfB = calculateWSJF(b)
    if wsjfA == wsjfB {
      0
    } else if wsjfA > wsjfB {
      -1
    } else {
      1
    }
  }
}
