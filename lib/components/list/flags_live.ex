defmodule Bonfire.UI.Moderation.FlagsLive do
  use Bonfire.UI.Common.Web, :stateful_component

  declare_extension("UI for moderation",
    icon: "bxs:flag-alt",
    emoji: "🚩",
    description:
      l("User interfaces for flagging content or users, and reviewing and acting on them.")
  )

  #
  prop feed_count, :string, default: ""

  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(feed_id: :flags)}
  end

  # def handle_params(%{"tab" => tab} = _params, _url, socket) do
  #   {:noreply,
  #    assign(socket,
  #      selected_tab: tab
  #    )}
  # end

  # def handle_params(%{} = _params, _url, socket) do
  #   {:noreply,
  #    assign(socket,
  #      current_user: Fake.user_live()
  #    )}
  # end
end
