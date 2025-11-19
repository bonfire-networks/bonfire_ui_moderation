defmodule Bonfire.UI.Moderation.FlagActionLive do
  use Bonfire.UI.Common.Web, :stateless_component
  alias Bonfire.Social.Flags
  alias Bonfire.Common.Settings

  prop object, :any
  prop parent_id, :string, default: nil
  prop permalink, :string, default: nil
  prop label, :string, default: nil
  prop flagged, :any, default: nil
  prop hide_icon, :boolean, default: false
  prop object_type, :string, default: nil
  prop is_remote, :boolean, default: nil
end
