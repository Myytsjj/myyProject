///|
test "render html sanitizes unsafe links and escapes media attributes" {
  let md = "[click](javascript:alert(1)) and ![a\" onerror=\"x](pic\" bad)"
  let html = render_html(to_events(Parser::new(md).parse()))
  inspect(
    html,
    content=(
      #|<p>
      #|<a href="#unsafe-url">click</a> and <img src="pic" alt="a&quot; onerror=&quot;x" />
      #|</p>
      #|
    ),
  )
}
