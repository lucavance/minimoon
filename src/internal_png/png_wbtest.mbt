///|
fn png_test_u32(value : UInt) -> Bytes {
  Bytes::from_array([
    (value >> 24).to_byte(),
    (value >> 16).to_byte(),
    (value >> 8).to_byte(),
    value.to_byte(),
  ])
}

///|
fn png_test_chunk(kind : Bytes, payload : Bytes) -> Bytes {
  let body = kind + payload
  png_test_u32(payload.length().reinterpret_as_uint()) +
  body +
  png_test_u32(chunk_crc(body, 0, body.length()))
}

///|
fn png_test_header(
  width? : UInt = 1,
  height? : UInt = 1,
  depth? : Byte = 8,
  color? : Byte = 6,
  compression? : Byte = 0,
  filter? : Byte = 0,
  interlace? : Byte = 0,
) -> Bytes {
  png_test_chunk(
    b"IHDR",
    png_test_u32(width) +
    png_test_u32(height) +
    Bytes::from_array([depth, color, compression, filter, interlace]),
  )
}

///|
test "PNG container validates headers, dimensions and every chunk CRC without decoding pixels" {
  let header = png_test_header()
  let data = png_test_chunk(b"IDAT", b"compressed fixture")
  let end = png_test_chunk(b"IEND", b"")
  let signature = b"\x89PNG\r\n\x1a\n"
  let good = signature + header + data + end
  assert_eq(dimensions(good), Some((1, 1)))
  assert_eq(
    dimensions(signature + png_test_header(width=256, height=256) + data + end),
    Some((256, 256)),
  )
  assert_eq(
    dimensions(signature + png_test_header(width=257) + data + end),
    Some((257, 1)),
  )
  for
    invalid in [
      b"",
      good[0:33].to_owned(),
      good + b"trailing",
      signature + header + end,
      signature + header + png_test_chunk(b"IDAT", b"") + end,
      signature + header + data,
      signature + header + header + data + end,
      signature + header + png_test_chunk(b"ABCD", b"") + data + end,
      signature + header + png_test_chunk(b"texT", b"") + data + end,
      signature + header + data + png_test_chunk(b"tEXt", b"note") + data + end,
      signature + header + png_test_u32(0xffffffffU) + b"IDAT" + end,
      signature + header + data + png_test_chunk(b"IEND", b"not empty"),
    ] {
    assert_eq(dimensions(invalid), None)
  }
  for
    bad_header in [
      png_test_header(width=0),
      png_test_header(height=0),
      png_test_header(width=0x80000000U),
      png_test_header(depth=4),
      png_test_header(color=1),
      png_test_header(compression=1),
      png_test_header(filter=1),
      png_test_header(interlace=2),
    ] {
    assert_eq(dimensions(signature + bad_header + data + end), None)
  }
  let corrupt = good.to_array()
  corrupt[40] = corrupt[40] ^ 1
  assert_eq(dimensions(Bytes::from_array(corrupt)), None)
}

///|
test "PNG indexed palettes precede contiguous IDAT and must match color depth" {
  let signature = b"\x89PNG\r\n\x1a\n"
  let header = png_test_header(color=3, depth=1)
  let palette = png_test_chunk(b"PLTE", b"rgbRGB")
  let data = png_test_chunk(b"IDAT", b"pixels")
  let end = png_test_chunk(b"IEND", b"")
  assert_eq(dimensions(signature + header + palette + data + end), Some((1, 1)))
  assert_eq(
    dimensions(signature + header + palette + data + data + end),
    Some((1, 1)),
  )
  for
    invalid in [
      signature + header + data + end,
      signature + header + palette + palette + data + end,
      signature + header + png_test_chunk(b"PLTE", b"rgbRGBrgb") + data + end,
      signature + png_test_header(color=0) + palette + data + end,
      signature + png_test_header() + data + palette + end,
    ] {
    assert_eq(dimensions(invalid), None)
  }
}
