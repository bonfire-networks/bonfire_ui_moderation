defmodule Bonfire.UI.Moderation.FlagTest do
  use Bonfire.UI.Moderation.ConnCase, async: true

  alias Bonfire.Social.Fake
  alias Bonfire.Posts
  alias Bonfire.Social.Graph.Follows
  alias Bonfire.Me.Accounts
  alias Bonfire.Me.Users
  alias Bonfire.Files.Test
  import Bonfire.Common.Enums
  alias Bonfire.Common.Config

  setup do
    _ = fake_admin!()
    account = fake_account!()
    me = fake_user!(account)
    alice = fake_user!(account)
    bob = fake_user!(account)
    carl = fake_user!(account)

    conn = conn(user: me, account: account)

    {:ok, conn: conn, account: account, me: me, alice: alice, bob: bob, carl: carl}
  end

  test "Flagging a post works", %{conn: conn, me: me, account: account, alice: alice} do
    # Alice creates a post
    Process.put(:feed_live_update_many_preload_mode, :inline)
    content = "here is an epic html post"
    attrs = %{post_content: %{html_body: content}}
    assert {:ok, post} = Posts.publish(current_user: alice, post_attrs: attrs, boundary: "local")

    # Login as me and flag the post
    conn
    |> visit("/feed/local")
    |> click_button("[data-role=open_modal]", "Flag this post")
    |> fill_in("Add a comment for the flag", with: "test")
    |> click_button("button[data-role=submit_flag]", "Flag this post")
    |> assert_has("[role=alert]", text: "flagged!")
  end

  test "If I already flagged an activity, I want to be told rather than be able to attempt flagging twice",
       %{conn: conn, me: me, account: account, alice: alice} do
    Process.put(:feed_live_update_many_preload_mode, :inline)
    # Alice creates a post
    content = "here is an epic html post"
    attrs = %{post_content: %{html_body: content}}
    assert {:ok, post} = Posts.publish(current_user: alice, post_attrs: attrs, boundary: "local")

    # I flag the post
    {:ok, _flag} = Bonfire.Social.Flags.flag(me, post.id)

    # Visit the local feed and check that we can see the post
    conn
    |> visit("/feed/local")
    |> assert_has("article", text: content)
    |> click_button("[data-role=open_modal]", "Flag this post")
    |> assert_has("button", text: "Already flagged")
  end

  test "Flagging a user works", %{conn: conn, me: me, account: account, carl: carl} do
    Process.put(:feed_live_update_many_preload_mode, :inline)
    # Alice creates a post
    content = "here is an epic html post"
    attrs = %{post_content: %{html_body: content}}
    assert {:ok, post} = Posts.publish(current_user: carl, post_attrs: attrs, boundary: "local")

    # Flag the user
    session = conn
    |> visit("/feed/local")
    |> assert_has("article", text: content)
    # |> click_button("[data-role=open_modal]", "Flag this post")
    |> click_button("[data-role=open_modal]", "Flag #{carl.profile.name}")
    |> fill_in("Add a comment for the flag", with: "test")
    # |> click_button("button[data-role=submit_flag]", "Flag this post")
    |> click_button("button[data-role=submit_flag]", "Flag #{carl.profile.name}")
    |> assert_has("[role=alert]", text: "flagged!")

    Process.put(:feed_live_update_many_preload_mode, :async_actions)


      session
      |> visit("/settings/user/flags")
      |> wait_async()
      # |> PhoenixTest.open_browser()
      |> within("#flags_list", fn session ->
        session
        |> assert_has("article", text: carl.profile.name)
        |> refute_has("article", text: content)
      end)
  end

  test "Unflag a post works", %{conn: conn, me: me, account: account, carl: carl} do
    # Alice creates a post
    content = "here is an epic html post"
    attrs = %{post_content: %{html_body: content}}
    assert {:ok, post} = Posts.publish(current_user: carl, post_attrs: attrs, boundary: "local")

    # Flag the post
    {:ok, _flag} = Bonfire.Social.Flags.flag(me, post.id)

    # Unflag the post
    conn
    |> visit("/settings/user/flags")
    |> assert_has("article", text: content)
    |> click_button("[data-role=unflag]", "Unflag")
    |> assert_has("[role=alert]", text: "Unflagged!")
    |> refute_has("article", text: content)
  end

  test "Unflag a user works", %{conn: conn, me: me, account: account, alice: alice} do
    # Flag a user
    {:ok, flag} = Bonfire.Social.Flags.flag(me, alice.id)

    # Check and unflag
    conn
    |> visit("/settings/user/flags")
    |> assert_has("article", text: alice.profile.name)
    |> click_button("button[data-role=unflag]", "Unflag")
    |> assert_has("[role=alert]", text: "Unflagged!")
    |> refute_has("article", text: alice.profile.name)
  end

  # can add once we implement custom roles
  # NOTE: we do have `Bonfire.Boundaries.can?(context, :mediate, :instance)`
  # test "If I have the right instance permission, as a user I want to see and act upon the flags feed in admin settings" do

  # end
end
