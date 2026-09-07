///|
/// RUI multi-thumb normalization adapted for native touch input (MIT).
pub struct SliderSpec {
  min : Int
  max : Int
  step : Int
  min_steps_between : Int
} derive(Eq, Debug)

///|
pub fn slider_spec(
  min? : Int = 0,
  max? : Int = 100,
  step? : Int = 1,
  min_steps_between? : Int = 0,
) -> SliderSpec {
  guard min >= -100000000 &&
    max <= 100000000 &&
    max > min &&
    step > 0 &&
    step <= max - min &&
    min_steps_between >= 0 &&
    min_steps_between <= (max - min) / step else {
    abort("invalid slider range, step or separation")
  }
  { min, max, step, min_steps_between, }
}

///|
pub fn SliderSpec::snap(self : SliderSpec, value : Double) -> Int {
  let value = if value != value {
    self.min.to_double()
  } else {
    value.clamp(min=self.min.to_double(), max=self.max.to_double())
  }
  let steps = ((value - self.min.to_double()) / self.step.to_double() + 0.5).to_int()
  (self.min + steps * self.step).clamp(
    min=self.min,
    max=self.min + (self.max - self.min) / self.step * self.step,
  )
}

///|
pub fn SliderSpec::normalize(
  self : SliderSpec,
  values : Array[Int],
) -> Array[Int] {
  let values = if values.is_empty() {
    [self.min]
  } else {
    values.map(value => self.snap(value.to_double()))
  }
  let gap = self.min_steps_between * self.step
  guard gap == 0 || values.length() - 1 <= (self.max - self.min) / gap else {
    abort("slider has too many thumbs for its minimum separation")
  }
  values.sort()
  for i = 1; i < values.length(); i = i + 1 {
    values[i] = values[i].max(values[i - 1] + gap)
  }
  let last = values.length() - 1
  values[last] = values[last].min(self.snap(self.max.to_double()))
  for i = last - 1; i >= 0; i = i - 1 {
    values[i] = values[i].min(values[i + 1] - gap)
  }
  values
}

///|
pub fn SliderSpec::update(
  self : SliderSpec,
  values : Array[Int],
  index : Int,
  value : Double,
) -> Array[Int] {
  let result = self.normalize(values)
  guard index >= 0 && index < result.length() else { return result }
  let gap = self.min_steps_between * self.step
  let low = if index == 0 { self.min } else { result[index - 1] + gap }
  let high = if index == result.length() - 1 {
    self.snap(self.max.to_double())
  } else {
    result[index + 1] - gap
  }
  result[index] = self.snap(value).clamp(min=low, max=high)
  result
}

///|
pub fn SliderSpec::fraction(self : SliderSpec, value : Int) -> Double {
  ((value - self.min).to_double() / (self.max - self.min).to_double()).clamp(
    min=0.0,
    max=1.0,
  )
}

///|
pub fn SliderSpec::nearest(
  self : SliderSpec,
  values : Array[Int],
  value : Double,
) -> Int {
  let values = self.normalize(values)
  let mut nearest = 0
  let mut distance = (values[0].to_double() - value).abs()
  for index, current in values {
    let next = (current.to_double() - value).abs()
    if next < distance {
      nearest = index
      distance = next
    }
  }
  nearest
}
