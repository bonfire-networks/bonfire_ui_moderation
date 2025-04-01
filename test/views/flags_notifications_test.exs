defmodule Bonfire.UI.Moderation.Notifications.Flag.Test do
  use Bonfire.UI.Moderation.ConnCase, async: true

  alias Bonfire.Me.Users
  alias Bonfire.Social.Fake
  alias Bonfire.Social.Flags
  alias Bonfire.Posts

  describe "show" do
    test "flags on a post (which admin has permission to see) in admin's notifications" do
      some_account = fake_account!()
      {:ok, someone} = Users.make_admin(fake_user!(some_account))
      poster = fake_user!()

      # Create a post
      attrs = %{post_content: %{html_body: "epic html post"}}

      assert {:ok, post} =
               Posts.publish(current_user: poster, post_attrs: attrs, boundary: "public")

      # Flag the post
      flagger = fake_user!()
      Flags.flag(flagger, post)

      # Check notifications
      conn(user: someone, account: some_account)
      |> visit("/notifications")
      |> PhoenixTest.open_browser()
      |> assert_has(".bonfire_feed", text: "epic html post")
      |> assert_has(".bonfire_feed", text: flagger.profile.name)
      |> assert_has(".bonfire_feed", text: "flagged")
    end

    # TODO? This is not the current behaviour, flags are not shown in notifications but only in admin panel
    @tag :fixme
    test "flags on a post (which admin does not explicitly have permission to see) in admin's notifications" do
      alice_account = fake_account!()
      {:ok, alice} = Users.make_admin(fake_user!(alice_account))
      bob = fake_user!()

      # Create a post with limited visibility
      attrs = %{post_content: %{html_body: "<p>here is an epic html post</p>"}}

      assert {:ok, post} =
               Posts.publish(current_user: bob, post_attrs: attrs, boundary: "mentions")

      # Flag the post
      flagger = fake_user!()
      Flags.flag(flagger, post)

      # Check notifications
      conn(user: alice, account: alice_account)
      |> visit("/notifications")
      |> assert_has(".bonfire_feed", text: "epic html post")
      |> assert_has(".bonfire_feed", text: flagger.profile.name)
      |> assert_has(".bonfire_feed", text: "flagged")
    end
  end
end
