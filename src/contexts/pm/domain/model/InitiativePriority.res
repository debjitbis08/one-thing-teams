open FibonacciScale

@genType
 type t = {
  userValue: FibonacciScale.t,
  timeCriticality: FibonacciScale.t,
  riskReductionOrOpportunityEnablement: FibonacciScale.t,
  effort: FibonacciScale.t,
  isCore: bool,
}

@genType
let make = (
  ~userValue,
  ~timeCriticality,
  ~riskReductionOrOpportunityEnablement,
  ~effort,
  ~isCore,
  (),
) => {
  userValue,
  timeCriticality,
  riskReductionOrOpportunityEnablement,
  effort,
  isCore,
}

let wsjfNumerator = priority =>
  FibonacciScale.value(priority.userValue)
  + FibonacciScale.value(priority.timeCriticality)
  + FibonacciScale.value(priority.riskReductionOrOpportunityEnablement)

let effortValue = priority => {
  let value = FibonacciScale.value(priority.effort)
  if value == 0 {
    1
  } else {
    value
  }
}

@genType
let calculateWSJF = priority => {
  let numerator = float_of_int(wsjfNumerator(priority))
  let denominator = float_of_int(effortValue(priority))
  numerator /. denominator
}

@genType
let compare = (a, b) => {
  if a.isCore && !b.isCore {
    -1
  } else if !a.isCore && b.isCore {
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
