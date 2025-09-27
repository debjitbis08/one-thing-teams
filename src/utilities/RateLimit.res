module StringMap = Belt.MutableMap.String

module TokenBucketRateLimit = {
  type refillingBucket = {
    mutable count: int,
    mutable refilledAtMs: float,
  }

  type t = {
    max: int,
    refillIntervalSeconds: int,
    storage: StringMap.t<refillingBucket>,
  }

  let make = (~max: int, ~refillIntervalSeconds: int): t => {
    if max <= 0 {
      raise(Failure("TokenBucketRateLimit: max must be positive"))
    }
    if refillIntervalSeconds <= 0 {
      raise(Failure("TokenBucketRateLimit: refill interval must be positive"))
    }
    {
      max,
      refillIntervalSeconds,
      storage: StringMap.make(),
    }
  }

  let computeRefill = (bucket: refillingBucket, nowMs: float, refillIntervalMs: float, max: int) => {
    let elapsedMs = nowMs -. bucket.refilledAtMs
    let refillCount =
      if refillIntervalMs <= 0.0 {
        0
      } else {
        int_of_float(elapsedMs /. refillIntervalMs)
      }
    let total = bucket.count + refillCount
    let newCount = if total > max { max } else { total }
    (newCount, nowMs)
  }

  let check = (self: t, key: string, cost: int) => {
    if cost <= 0 {
      true
    } else {
      switch StringMap.get(self.storage, key) {
      | None => true
      | Some(bucket) =>
          let nowMs = RescriptCore.Date.now()
          let refillIntervalMs = float_of_int(self.refillIntervalSeconds * 1000)
          let (newCount, _) = computeRefill(bucket, nowMs, refillIntervalMs, self.max)
          newCount >= cost
      }
    }
  }

  let consume = (self: t, key: string, cost: int) => {
    if cost <= 0 {
      true
    } else {
      let nowMs = RescriptCore.Date.now()
      let refillIntervalMs = float_of_int(self.refillIntervalSeconds * 1000)
      let bucket =
        switch StringMap.get(self.storage, key) {
        | None => {
            count: self.max,
            refilledAtMs: nowMs,
          }
        | Some(existing) => existing
        }

      let (available, updatedRefilledAtMs) = computeRefill(bucket, nowMs, refillIntervalMs, self.max)
      bucket.count = available
      bucket.refilledAtMs = updatedRefilledAtMs

      if bucket.count < cost {
        bucket.count = available
        StringMap.set(self.storage, key, bucket)
        false
      } else {
        bucket.count = bucket.count - cost
        bucket.refilledAtMs = nowMs
        StringMap.set(self.storage, key, bucket)
        true
      }
    }
  }
}

module BasicRateLimit = {
  type record = {
    mutable count: int,
    mutable startsAtMs: float,
  }

  type t = {
    max: int,
    windowSizeInSeconds: int,
    storage: StringMap.t<record>,
  }

  let make = (~max: int, ~windowSizeInSeconds: int): t => {
    if max <= 0 {
      raise(Failure("BasicRateLimit: max must be positive"))
    }
    if windowSizeInSeconds <= 0 {
      raise(Failure("BasicRateLimit: window size must be positive"))
    }
    {
      max,
      windowSizeInSeconds,
      storage: StringMap.make(),
    }
  }

  let windowIntervalMs = self => float_of_int(self.windowSizeInSeconds * 1000)

  let check = (self: t, key: string, cost: int) => {
    if cost <= 0 {
      true
    } else {
      switch StringMap.get(self.storage, key) {
      | None => true
      | Some(record) =>
          let nowMs = RescriptCore.Date.now()
          if nowMs -. record.startsAtMs >= windowIntervalMs(self) {
            true
          } else {
            record.count >= cost
          }
      }
    }
  }

  let consume = (self: t, key: string, cost: int) => {
    if cost <= 0 {
      true
    } else {
      let nowMs = RescriptCore.Date.now()
      let windowMs = windowIntervalMs(self)
      let record =
        switch StringMap.get(self.storage, key) {
        | None => {
            count: self.max,
            startsAtMs: nowMs,
          }
        | Some(existing) =>
            if nowMs -. existing.startsAtMs >= windowMs {
              existing.count = self.max
              existing.startsAtMs = nowMs
              existing
            } else {
              existing
            }
        }

      if record.count < cost {
        StringMap.set(self.storage, key, record)
        false
      } else {
        record.count = record.count - cost
        StringMap.set(self.storage, key, record)
        true
      }
    }
  }

  let reset = (self: t, key: string) => StringMap.remove(self.storage, key)
}

module Counter = {
  type t = {
    max: int,
    storage: StringMap.t<int>,
  }

  let make = (~max: int): t => {
    if max <= 0 {
      raise(Failure("Counter: max must be positive"))
    }
    {
      max,
      storage: StringMap.make(),
    }
  }

  let increment = (self: t, key: string) => {
    let current = StringMap.get(self.storage, key)->Belt.Option.getWithDefault(0)
    let next = current + 1
    if next > self.max {
      StringMap.remove(self.storage, key)
      false
    } else {
      StringMap.set(self.storage, key, next)
      true
    }
  }

  let reset = (self: t, key: string) => StringMap.remove(self.storage, key)
}
