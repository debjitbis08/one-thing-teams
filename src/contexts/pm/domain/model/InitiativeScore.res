open PmDomain

let revenueBucketToFib = bucket =>
  switch bucket {
  | Lt1Pct => 1
  | Pct1to3 => 2
  | Pct3to8 => 3
  | Pct8to20 => 5
  | Gt20 => 8
  }

let wsjfNumerator = (score: initiativeScore) =>
  switch score.cod {
  | DirectRevenue({bucket, note: _}) => 7 * revenueBucketToFib(bucket)
  | Proxy({
      visionAlignment,
      frequency,
      retentionPotential,
      differentiation,
      complexityImpact,
      futureLeverage,
      timeCriticality,
    }) =>
    FibonacciScale.value(visionAlignment.value) +
    FibonacciScale.value(frequency.value) +
    FibonacciScale.value(retentionPotential.value) +
    FibonacciScale.value(differentiation.value) +
    FibonacciScale.value(complexityImpact.value) +
    FibonacciScale.value(futureLeverage.value) +
    FibonacciScale.value(timeCriticality.value)
  }

let effortValue = (score: initiativeScore) => {
  let value = FibonacciScale.value(score.effort.value)
  if value == 0 {
    1
  } else {
    value
  }
}
