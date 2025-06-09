defmodule Area51.Web.LiveStateSocket do
  use Phoenix.Socket

  require OpenTelemetry.Tracer
  alias OpenTelemetry.Tracer
  alias Area51.Web.InvestigationChannel
  alias Area51.Web.JobManagementChannel
  alias Area51.Web.SessionListChannel

  channel(InvestigationChannel.channel_name(), InvestigationChannel)
  channel(SessionListChannel.channel_name(), SessionListChannel)
  channel(JobManagementChannel.channel_name(), JobManagementChannel)

  @impl true
  def connect(_params, socket, _connect_info) do
    Tracer.with_span "livestate.connection" do
      span_ctx = Tracer.current_span_ctx()
      trace_id = OpenTelemetry.Span.trace_id(span_ctx)

      socket =
        socket
        |> assign(:otel_span_ctx, span_ctx)
        |> assign(:trace_id, trace_id)

      {:ok, socket}
    end
  end

  @impl true
  def id(_socket), do: "area51"
end
