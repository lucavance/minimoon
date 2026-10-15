///|
fn document(source : String) -> @minimoon.Page {
  @minimoon.page(
    id="markdown",
    route=@minimoon.route("pages/markdown/index"),
    title="Markdown",
    build=_ => {
      @minimoon.Val::constant(@markdown.markdown(source, id="document"))
    },
  )
}

///|
test "CommonMark and extensions render native text images tables and tasks" {
  let source =
    #|# Hello
    #|
    #|plain **strong** *emphasis* ~~gone~~ `code` ![logo](/logo.svg)
    #|
    #|> quote
    #|
    #|- [x] parent
    #|  - [ ] child
    #|
    #|3. third
    #|4. fourth
    #|
    #|| left | right |
    #|| :--- | ---: |
    #|| one | two |
    #|
    #|note[^n]
    #|
    #|[^n]: footnote body
    #|
    #|```mermaid
    #|graph LR; A-->B
    #|```
    #|
    #|<script>alert('text only')</script>
    #|
    #|$x+y$
  let runtime = @testing.mount(document(source))
  defer {
    let _ = runtime.dispose()
  }
  let text = runtime.tree().text_content()
  for
    expected in [
      "Hello", "strong", "emphasis", "gone", "code", "quote", "parent", "child",
      "☑", "☐", "3.", "4.", "one", "two", "footnote body", "graph LR; A-->B",
      "<script>", "$x+y$",
    ] {
    assert_true(text.contains(expected), msg=expected)
  }
  assert_true(runtime.query(@testing.by_kind("inline")) is Some(_))
  assert_eq(
    runtime.get(@testing.by_kind("image")).prop("src"),
    Some(Json::string("/logo.svg")),
  )
  assert_eq(runtime.query_all(@testing.by_kind("scroll-view")).length(), 2)
}

///|
test "link callbacks sanitize rewritten destinations and namespace anchor targets" {
  let page = @minimoon.page(
    id="links",
    route=@minimoon.route("pages/links/index"),
    title="Links",
    build=_ => {
      let (target, update) = @minimoon.create_variable("")
      let emit = update.map(value => _ => value)
      let markdown = @markdown.markdown(
        "# Hello\n\n[site](https://example.com) [anchor](#hello) [bad](javascript:alert) [rewrite](https://rewrite.test) ![badimage](data:image/svg+xml,bad)",
        id="first",
        on_link=emit,
        on_anchor=emit,
        transform_link=value => {
          if value == "https://rewrite.test" {
            "javascript:bad"
          } else {
            value
          }
        },
      )
      target.view(target => {
        @minimoon.div([
          markdown,
          @minimoon.div(id="target", target),
          @markdown.markdown("# Hello", id="second"),
        ])
      })
    },
  )
  let runtime = @testing.mount(page)
  defer {
    let _ = runtime.dispose()
  }
  assert_eq(runtime.query_all(@testing.by_kind("image")).length(), 0)
  for bad in ["bad", "rewrite"] {
    assert_eq(runtime.get(@testing.by_text(bad)).event("tap"), None)
  }
  let _ = runtime.tap(@testing.by_text("site"))
  assert_eq(
    runtime.get(@testing.by_id("target")).text_content(),
    "https://example.com",
  )
  let headings = runtime.query_all(@testing.by_role("heading"))
  assert_eq(headings.length(), 2)
  assert_true(headings[0].prop("id") != headings[1].prop("id"))
  let _ = runtime.tap(@testing.by_text("anchor"))
  assert_eq(
    Some(Json::string(runtime.get(@testing.by_id("target")).text_content())),
    headings[0].prop("id"),
  )
}

///|
test "CommonMark soft hard breaks and zero based ordered lists retain their meaning" {
  let runtime = @testing.mount(
    document("soft\nnext\n\nhard  \nline\n\n0. zero\n1. one"),
  )
  defer {
    let _ = runtime.dispose()
  }
  let content = runtime.tree().text_content()
  assert_true(content.contains("soft next"))
  assert_true(content.contains("hard\nline"))
  assert_true(content.contains("0."))
  assert_true(content.contains("1."))
  assert_false(content.contains("•"))
}

///|
test "repeated headings get distinct anchors within a document" {
  let runtime = @testing.mount(document("# Hello\n\n# Hello\n\n## Hello"))
  defer {
    let _ = runtime.dispose()
  }
  let headings = runtime.query_all(@testing.by_role("heading"))
  assert_eq(headings.length(), 3)
  let ids = headings.map(heading => heading.prop("id"))
  assert_true(ids[0] != ids[1])
  assert_true(ids[1] != ids[2])
  assert_true(ids[0] != ids[2])
}

///|
test "code and heading callbacks receive public values without parser types" {
  let page = @minimoon.page(
    id="custom",
    route=@minimoon.route("pages/custom/index"),
    title="Custom",
    build=_ => {
      @minimoon.Val::constant(
        @markdown.markdown(
          "## Custom\n\n```moonbit\nlet x = 1\n```",
          id="custom",
          render_heading=(heading, content) => {
            @minimoon.div([
              @minimoon.text(heading.level.to_string() + ":" + heading.text),
              content,
            ])
          },
          render_codeblock=(code, info) => @minimoon.text(info + ":" + code),
        ),
      )
    },
  )
  let runtime = @testing.mount(page)
  defer {
    let _ = runtime.dispose()
  }
  assert_true(runtime.tree().text_content().contains("2:Custom"))
  assert_true(runtime.tree().text_content().contains("moonbit:let x = 1"))
}
