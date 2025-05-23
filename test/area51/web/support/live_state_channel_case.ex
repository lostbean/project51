defmodule Area51.Web.LiveStateChannelCase do
  @moduledoc """
  This module defines the test case to be used by
  LiveState channel tests.

  It extends the regular ChannelCase with LiveState-specific
  helpers for more convenient testing of LiveState channels.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # Import the base ChannelCase
      use Area51.Web.ChannelCase

      # Import LiveStateTestUtils
      import Area51.Web.LiveStateTestUtils

      # Alias useful modules for LiveState testing
      alias Phoenix.Socket.Message
    end
  end

  # No setup hook here since it's already provided by ChannelCase
  # When we use Area51.Web.ChannelCase above, it brings in all the setup
end
