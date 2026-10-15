///|
fn markdown_sample() -> @minimoon.Val[@minimoon.Node] {
  let (target, update) = @minimoon.create_variable("Tap a link or footnote")
  let emit = update.map(value => _ => value)
  let source =
    #|## Native Markdown
    #|
    #|English 与中文 **strong**、*emphasis*、~~strikethrough~~ and `inline code` flow on the same line.
    #|
    #|Inline image: ![check](/assets/mmui/check-light.svg) with text after the image.
    #|
    #|[Callback link](https://example.com) · [Heading anchor](#native-markdown) · note[^one]
    #|
    #|- [x] Native inline text
    #|  - [ ] Nested task
    #|
    #|| Feature | Result |
    #|| :--- | ---: |
    #|| Wide table | Scroll horizontally |
    #|
    #|```mermaid
    #|graph LR; A-->B
    #|```
    #|
    #|Math source: $a^2+b^2=c^2$.
    #|
    #|<b>Raw HTML remains text</b>
    #|
    #|[^one]: Footnotes use document-local anchors.
  let node = @markdown.markdown(
    source,
    id="foundation-markdown",
    on_link=emit,
    on_anchor=emit,
  )
  target.view(target => {
    @minimoon.div(data_section="Markdown", [
      node,
      @minimoon.div(id="markdown-target", target),
    ])
  })
}
