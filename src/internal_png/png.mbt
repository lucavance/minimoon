///|
fn read_u32(bytes : Bytes, offset : Int) -> UInt {
  (bytes[offset].to_uint() << 24) |
  (bytes[offset + 1].to_uint() << 16) |
  (bytes[offset + 2].to_uint() << 8) |
  bytes[offset + 3].to_uint()
}

///|
fn chunk_crc(bytes : Bytes, start : Int, end : Int) -> UInt {
  let mut crc = 0xffffffffU
  for index = start; index < end; index = index + 1 {
    crc = crc ^ bytes[index].to_uint()
    for bit = 0; bit < 8; bit = bit + 1 {
      crc = (crc >> 1) ^ (if (crc & 1) == 1 { 0xedb88320U } else { 0U })
    }
  }
  crc ^ 0xffffffffU
}

///|
/// Validate the PNG container, dimensions and IHDR fields without decompressing
/// image pixels. Every chunk is bounds-checked and CRC-checked. This build-time
/// parser is shared by generation and artifact verification.
pub fn dimensions(bytes : Bytes) -> (Int, Int)? {
  guard bytes.length() >= 57 &&
    bytes[0:8] == b"\x89PNG\r\n\x1a\n" &&
    bytes[8:16] == b"\x00\x00\x00\x0dIHDR" else {
    return None
  }
  let width = read_u32(bytes, 16)
  let height = read_u32(bytes, 20)
  guard width > 0 && width <= 0x7fffffffU && height > 0 && height <= 0x7fffffffU else {
    return None
  }
  let depth = bytes[24].to_int()
  let color = bytes[25].to_int()
  let valid_depth = match color {
    0 => [1, 2, 4, 8, 16].contains(depth)
    2 | 4 | 6 => depth == 8 || depth == 16
    3 => [1, 2, 4, 8].contains(depth)
    _ => false
  }
  guard valid_depth && bytes[26] == 0 && bytes[27] == 0 && bytes[28] <= 1 else {
    return None
  }
  let mut offset = 8
  let mut palette = false
  let mut data = false
  let mut data_ended = false
  let mut payload = false
  while offset < bytes.length() {
    guard bytes.length() - offset >= 12 else { return None }
    let length = read_u32(bytes, offset)
    guard length <= (bytes.length() - offset - 12).reinterpret_as_uint() else {
      return None
    }
    let size = length.reinterpret_as_int()
    let end = offset + size + 12
    let kind = bytes[offset + 4:offset + 8]
    for index = offset + 4; index < offset + 8; index = index + 1 {
      let char = bytes[index].to_int()
      guard (char >= 65 && char <= 90) || (char >= 97 && char <= 122) else {
        return None
      }
    }
    guard bytes[offset + 6].to_int() <= 90 &&
      chunk_crc(bytes, offset + 4, end - 4) == read_u32(bytes, end - 4) else {
      return None
    }
    if kind == b"IHDR" {
      guard offset == 8 && size == 13 else { return None }
    } else if kind == b"PLTE" {
      guard !palette &&
        !data &&
        color != 0 &&
        color != 4 &&
        size > 0 &&
        size % 3 == 0 &&
        size <= 768 &&
        (color != 3 || size / 3 <= 1 << depth) else {
        return None
      }
      palette = true
    } else if kind == b"IDAT" {
      guard !data_ended && (color != 3 || palette) else { return None }
      data = true
      payload = payload || size > 0
    } else if kind == b"IEND" {
      guard size == 0 && data && payload && end == bytes.length() else {
        return None
      }
      return Some((width.reinterpret_as_int(), height.reinterpret_as_int()))
    } else {
      // Unknown critical chunks cannot be interpreted safely.
      guard bytes[offset + 4].to_int() >= 97 else { return None }
    }
    if data && kind != b"IDAT" {
      data_ended = true
    }
    offset = end
  }
  None
}
