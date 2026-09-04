///|
test "toggle card state transition uses current props" {
  let current = initial_model()
  let input = props(
    id="test-card",
    title="Test",
    pulse_step=2,
    tone="bg-sky-50",
  )
  let enabled = update_model(current, input, EnabledChanged(true))
  inspect(enabled.enabled, content="true")
  let pulsed = update_model(enabled, input, Pulse)
  inspect(pulsed.pulses, content="2")
}
