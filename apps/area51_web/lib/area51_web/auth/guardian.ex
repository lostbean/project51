defmodule Area51Web.Auth.Guardian do
  @moduledoc """
  Used for JWT authentication handling.
  """
  alias Area51Core.User
  alias JokenJwks.DefaultStrategyTemplate.EtsCache
  require OpenTelemetry.Tracer

  # Add this module to the application tree
  defmodule Strategy do
    @moduledoc """
    Module defining the strategy to fecth and cache (using ETS) JWKS to validate JWT
    """
    use JokenJwks.DefaultStrategyTemplate

    def init_opts(opts) do
      module_config = Application.fetch_env!(:area51_web, __MODULE__)

      jwks_url =
        module_config |> Keyword.get(:jwks_url)

      Keyword.merge(opts,
        jwks_url: jwks_url,
        http_adapter: Tesla.Adapter.Hackney,
        first_fetch_sync: true
      )
    end
  end

  def get_signers() do
    EtsCache.get_signers(Strategy)
  end

  def resource_from_claims(%{"sub" => external_id}) do
    {:ok, %User{external_id: external_id, username: "dev"}}
  end

  def resource_from_claims(_claims) do
    {:error, "Invalid claims"}
  end

  def verify_and_get_user_info(token) do
    OpenTelemetry.Tracer.with_span "area51_web.auth.guardian.verify_and_get_user_info" do
      token_config = %{}
      joken_plugins = [{JokenJwks, strategy: Strategy}]

      with {:ok, claims} <-
             Joken.verify_and_validate(token_config, token, nil, nil, joken_plugins),
           {:ok, user} <- resource_from_claims(claims) do
        {:ok, user}
      else
        _ ->
          # In development, allow access without authentication
          if Mix.env() == :dev do
            :logger.warning("DEV MODE: Allowing unauthenticated WebSocket connection")

            dev_user = %User{
              external_id: "only||dev",
              username: "Developer"
            }

            {:ok, dev_user}
          else
            {:error, "Unauthorized access"}
          end
      end
    end
  end
end
