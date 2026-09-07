///|
pub(all) struct Bounds {
  left : Double
  top : Double
  width : Double
  height : Double
} derive(Eq, Debug)

///|
pub(all) enum Placement {
  BottomStart
  BottomCenter
  BottomEnd
  TopStart
  TopCenter
  TopEnd
  LeftStart
  LeftCenter
  LeftEnd
  RightStart
  RightCenter
  RightEnd
} derive(Eq, Debug)

///|
/// Flip on the main axis, then shift inside the measured viewport.
pub fn place(
  anchor : Bounds,
  surface : Bounds,
  viewport : Bounds,
  placement : Placement,
  gap? : Double = 8.0,
  align_offset? : Double = 0.0,
) -> Bounds {
  let horizontal = placement is LeftStart ||
    placement is LeftCenter ||
    placement is LeftEnd ||
    placement is RightStart ||
    placement is RightCenter ||
    placement is RightEnd
  let end = placement is BottomEnd ||
    placement is TopEnd ||
    placement is LeftEnd ||
    placement is RightEnd
  let center = placement is BottomCenter ||
    placement is TopCenter ||
    placement is LeftCenter ||
    placement is RightCenter
  let above = placement is TopStart ||
    placement is TopCenter ||
    placement is TopEnd
  let left = placement is LeftStart ||
    placement is LeftCenter ||
    placement is LeftEnd
  let below_y = anchor.top + anchor.height + gap
  let above_y = anchor.top - surface.height - gap
  let right_x = anchor.left + anchor.width + gap
  let left_x = anchor.left - surface.width - gap
  let mut y = if horizontal {
    anchor.top +
    (if end {
      anchor.height - surface.height
    } else if center {
      (anchor.height - surface.height) / 2.0
    } else {
      0.0
    }) +
    align_offset
  } else if above {
    above_y
  } else {
    below_y
  }
  let mut x = if horizontal {
    if left {
      left_x
    } else {
      right_x
    }
  } else if end {
    anchor.left + anchor.width - surface.width
  } else if center {
    anchor.left + (anchor.width - surface.width) / 2.0
  } else {
    anchor.left
  }
  if horizontal {
    if left && left_x < viewport.left {
      x = right_x
    }
    if !left && right_x + surface.width > viewport.left + viewport.width {
      x = left_x
    }
  } else {
    x = x + align_offset
    if above && above_y < viewport.top {
      y = below_y
    }
    if !above && below_y + surface.height > viewport.top + viewport.height {
      y = above_y
    }
  }
  {
    left: x
    .max(viewport.left)
    .min((viewport.left + viewport.width - surface.width).max(viewport.left)),
    top: y
    .max(viewport.top)
    .min((viewport.top + viewport.height - surface.height).max(viewport.top)),
    width: surface.width.min(viewport.width),
    height: surface.height.min(viewport.height),
  }
}

///|
/// Resize one adjacent pair without changing total size or unrelated panes.
pub fn resize_pair(
  sizes : Array[Double],
  index : Int,
  delta : Double,
  minimums : Array[Double],
  maximums : Array[Double],
) -> Array[Double] {
  guard index >= 0 && index + 1 < sizes.length() else { return sizes.copy() }
  let total = sizes[index] + sizes[index + 1]
  let low = minimums
    .get(index)
    .unwrap_or(0.0)
    .max(total - maximums.get(index + 1).unwrap_or(100.0))
  let high = maximums
    .get(index)
    .unwrap_or(100.0)
    .min(total - minimums.get(index + 1).unwrap_or(0.0))
  guard low <= high else { return sizes.copy() }
  let next = sizes.copy()
  next[index] = (sizes[index] + delta).clamp(min=low, max=high)
  next[index + 1] = total - next[index]
  next
}

///|
pub fn page_count(total : Int, page_size : Int) -> Int {
  if total <= 0 {
    1
  } else {
    (total + page_size.max(1) - 1) / page_size.max(1)
  }
}
