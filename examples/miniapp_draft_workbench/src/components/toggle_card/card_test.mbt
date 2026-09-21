///|
test "toggle card state transition uses current props" {
  let current = @toggle_card.initial_model()
  let input = @toggle_card.props(
    id="test-card",
    title="Test",
    pulse_step=2,
    tone="bg-sky-50",
  )
  let enabled = @toggle_card.update_model(current, input, EnabledChanged(true))
  inspect(enabled.enabled, content="true")
  let pulsed = @toggle_card.update_model(enabled, input, Pulse)
  inspect(pulsed.pulses, content="2")
}
