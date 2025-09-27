open PmDomain

let revenueBucketToFib = bucket =>
  switch bucket {
  | Lt1Pct => 1.0
  | Pct1to3 => 2.0
  | Pct3to8 => 3.0
  | Pct8to20 => 5.0
  | Gt20 => 8.0
  }

let wsjfNumerator = (score: initiativeScore) =>
  switch score.cod {
  | DirectRevenue({bucket, note: _}) => 7.0 *. revenueBucketToFib(bucket)
  | Proxy({
      visionAlignment,
      frequency,
      retentionPotential,
      differentiation,
      complexityImpact,
      futureLeverage,
      timeCriticality,
    }) =>
    (Belt.Int.toFloat(FibonacciScale.value(visionAlignment.value) +
    FibonacciScale.value(frequency.value) +
    FibonacciScale.value(retentionPotential.value) +
    FibonacciScale.value(differentiation.value)) /. 4.0) +.
    (Belt.Int.toFloat(FibonacciScale.value(complexityImpact.value) +
    FibonacciScale.value(futureLeverage.value)) /. 2.0) +.
    Belt.Int.toFloat(FibonacciScale.value(timeCriticality.value))
  }

let effortValue = (score: initiativeScore) => {
  let value = FibonacciScale.value(score.effort.value)
  if value == 0 {
    1
  } else {
    value
  }
}
