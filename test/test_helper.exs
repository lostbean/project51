# Start the application so Ecto repos and other OTP apps are running
Mix.Task.run("app.start", [])

Application.ensure_all_started(:mimic)
Mimic.copy(Instructor)
Mimic.copy(OpenTelemetry.Tracer)
Mimic.copy(OpenTelemetry.Ctx)

ExUnit.start()

# Configure Ecto Sandbox for tests that require the database
# This was present in area51_data and area51_web test_helper.exs files.
# The module Area51.Data.Repo should be correct after our renames.
Ecto.Adapters.SQL.Sandbox.mode(Area51.Data.Repo, :manual)

# If other applications had specific setup in their test_helper.exs,
# those lines would be merged here. In this case, core, gleam, and llm
# only had ExUnit.start().

# Support files like DataCase, ConnCase, ChannelCase are typically
# imported via `use` in the individual test files or their specific
# case templates (e.g. test/area51/data/support/data_case.ex)
# and don't need explicit loading here unless they were set up that way.
