defmodule Area51.Web.SessionListChannelTest do
  # Changed to async: false to avoid mocking conflicts
  use Area51.Web.LiveStateChannelCase, async: false

  alias Area51.Web.Auth.Guardian
  alias Area51.Web.SessionListChannel

  @endpoint Area51.Web.Endpoint
  @channel_name "session_list"

  # Mock user for testing
  @user %{id: 1, username: "test_user"}
  @valid_token "valid_test_token"

  # Mock function for auth to avoid actual JWT verification
  defp mock_guardian_verify(_token) do
    {:ok, @user}
  end

  setup do
    # Make sure Guardian module exists before attempting to mock it
    # This prevents the "not_mocked" error
    Code.ensure_loaded(Guardian)

    # Mock the Guardian.verify_and_get_user_info function
    :meck.new(Guardian, [:passthrough])

    :meck.expect(Guardian, :verify_and_get_user_info, fn token ->
      mock_guardian_verify(token)
    end)

    # Make sure GameSession module exists before attempting to mock it
    Code.ensure_loaded(Area51.Data.GameSession)

    # Mock Area51.Data.GameSession.list_sessions_for_ui
    :meck.new(Area51.Data.GameSession, [:passthrough])

    :meck.expect(Area51.Data.GameSession, :list_sessions_for_ui, fn ->
      [
        %{id: 1, title: "Mystery at the Mansion", created_at: "2025-05-01T12:00:00Z"},
        %{id: 2, title: "The Alien Conspiracy", created_at: "2025-05-02T14:30:00Z"}
      ]
    end)

    # Create test socket
    socket = Phoenix.ChannelTest.socket(Area51.Web.LiveStateSocket, %{}, %{})

    # Ensure mocks are unloaded even if the test fails
    on_exit(fn ->
      :meck.unload()
    end)

    {:ok, socket: socket}
  end

  describe "joining the channel" do
    test "authenticates and sets initial state", %{socket: socket} do
      expected_initial_state = %{
        username: @user.username,
        sessions: [
          %{id: 1, title: "Mystery at the Mansion", created_at: "2025-05-01T12:00:00Z"},
          %{id: 2, title: "The Alien Conspiracy", created_at: "2025-05-02T14:30:00Z"}
        ],
        error: nil
      }

      {_socket, _state} =
        join_and_assert_initial_state(
          socket,
          SessionListChannel,
          @channel_name,
          expected_initial_state,
          # Pass token in join params
          %{"token" => @valid_token}
        )
    end
  end

  describe "handling events" do
    setup %{socket: socket} do
      expected_initial_state = %{
        username: @user.username,
        sessions: [
          %{id: 1, title: "Mystery at the Mansion", created_at: "2025-05-01T12:00:00Z"},
          %{id: 2, title: "The Alien Conspiracy", created_at: "2025-05-02T14:30:00Z"}
        ],
        error: nil
      }

      {joined_socket, _state} =
        join_and_assert_initial_state(
          socket,
          SessionListChannel,
          @channel_name,
          expected_initial_state,
          # Pass token in join params
          %{"token" => @valid_token}
        )

      {:ok, joined_socket: joined_socket}
    end

    test "refresh_sessions updates the sessions list", %{joined_socket: socket} do
      # Mock a different return value for list_sessions_for_ui on second call
      :meck.expect(Area51.Data.GameSession, :list_sessions_for_ui, fn ->
        [
          %{id: 1, title: "Mystery at the Mansion", created_at: "2025-05-01T12:00:00Z"},
          %{id: 2, title: "The Alien Conspiracy", created_at: "2025-05-02T14:30:00Z"},
          %{id: 3, title: "New Mystery", created_at: "2025-05-03T09:15:00Z"}
        ]
      end)

      # The expected patch should be an addition of a new session
      expected_patch = [
        %{
          "op" => "add",
          "path" => "/sessions/2",
          "value" => %{id: 3, title: "New Mystery", created_at: "2025-05-03T09:15:00Z"}
        }
      ]

      push_event_and_assert_patch(
        socket,
        "refresh_sessions",
        %{},
        expected_patch,
        1
      )
    end

    test "create_session handles success case", %{joined_socket: socket} do
      # Make sure Agent module exists before attempting to mock it
      Code.ensure_loaded(Area51.LLM.Agent)

      # Mock the generate_mystery_with_topic and create_game_session functions
      :meck.new(Area51.LLM.Agent, [:passthrough])

      :meck.expect(Area51.LLM.Agent, :generate_mystery_with_topic, fn _topic ->
        {:ok, %{title: "Space Station Mystery", narrative: "Initial narrative..."}}
      end)

      :meck.expect(Area51.Data.GameSession, :create_game_session, fn _mystery_data ->
        :ok
      end)

      # Update the mock for list_sessions_for_ui to include the new session
      :meck.expect(Area51.Data.GameSession, :list_sessions_for_ui, fn ->
        [
          %{id: 1, title: "Mystery at the Mansion", created_at: "2025-05-01T12:00:00Z"},
          %{id: 2, title: "The Alien Conspiracy", created_at: "2025-05-02T14:30:00Z"},
          %{id: 3, title: "Space Station Mystery", created_at: "2025-05-03T10:00:00Z"}
        ]
      end)

      # The expected patch should be an addition of a new session
      expected_patch = [
        %{
          "op" => "add",
          "path" => "/sessions/2",
          "value" => %{id: 3, title: "Space Station Mystery", created_at: "2025-05-03T10:00:00Z"}
        }
      ]

      push_event_and_assert_patch(
        socket,
        "create_session",
        %{"topic" => "Space station mystery"},
        expected_patch,
        1
      )

      # Only unload if it was successfully loaded
      if :meck.validate(Area51.LLM.Agent) do
        :meck.unload(Area51.LLM.Agent)
      end
    end

    test "create_session handles error case", %{joined_socket: socket} do
      # Make sure Agent module exists before attempting to mock it
      Code.ensure_loaded(Area51.LLM.Agent)

      # Mock the generate_mystery_with_topic to return an error
      :meck.new(Area51.LLM.Agent, [:passthrough])

      :meck.expect(Area51.LLM.Agent, :generate_mystery_with_topic, fn _topic ->
        {:error, "LLM service unavailable"}
      end)

      # The expected patch should set the error field
      expected_patch = [
        %{
          "op" => "replace",
          "path" => "/error",
          "value" => "Failed to create new session"
        }
      ]

      push_event_and_assert_patch(
        socket,
        "create_session",
        %{"topic" => "Bad mystery topic"},
        expected_patch,
        1
      )

      # Only unload if it was successfully loaded
      if :meck.validate(Area51.LLM.Agent) do
        :meck.unload(Area51.LLM.Agent)
      end
    end
  end
end
