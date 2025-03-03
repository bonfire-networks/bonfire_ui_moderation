defmodule Bonfire.UI.Moderation.FlagTest do
  use Bonfire.UI.Moderation.ConnCase, async: true

  alias Bonfire.Social.Fake
  alias Bonfire.Posts
  alias Bonfire.Social.Graph.Follows
  alias Bonfire.Me.Accounts
  alias Bonfire.Me.Users
  alias Bonfire.Files.Test
  import Bonfire.Common.Enums

  setup do
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
    content = "here is an epic html post"
    attrs = %{post_content: %{html_body: content}}
    assert {:ok, post} = Posts.publish(current_user: alice, post_attrs: attrs, boundary: "local")

    # Login as me and flag the post
    conn
    |> visit("/feed/local")
    |> click_button("[data-role=open_modal]", "Flag this post")
    |> click_button("button[data-role=submit_flag]", "Flag this post")
    |> assert_has("[role=alert]", text: "flagged!")
  end

  test "If I already flagged an activity, I want to be told rather than be able to attempt flagging twice",
       %{conn: conn, me: me, account: account, alice: alice} do
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
    |> click_button("article li[data-role=flag_object] div[data-role=open_modal]")
    |> assert_has(text: "Already flagged")
  end

  test "Flagging a user works", %{conn: conn, me: me, account: account, alice: alice} do
    # Alice creates a post
    content = "here is an epic html post"
    attrs = %{post_content: %{html_body: content}}
    assert {:ok, post} = Posts.publish(current_user: alice, post_attrs: attrs, boundary: "local")

    # Flag the user
    conn
    |> visit("/feed/local")
    |> assert_has("article", text: content)
    |> click_button("article li[data-role=flag_author] div[data-role=open_modal]")
    |> click_button("button[data-role=submit_flag]")
    |> assert_has("[role=alert]", text: "flagged!")
    |> visit("/settings/user/flags")
    |> within("#flags_list", fn session ->
      session
      |> assert_has(text: alice.profile.name)
      |> refute_has(text: content)
    end)
  end

  test "Unflag a post works", %{conn: conn, me: me, account: account, alice: alice} do
    # Alice creates a post
    content = "here is an epic html post"
    attrs = %{post_content: %{html_body: content}}
    assert {:ok, post} = Posts.publish(current_user: alice, post_attrs: attrs, boundary: "local")

    # Flag the post
    {:ok, flag} = Bonfire.Social.Flags.flag(me, post.id)

    # Unflag the post
    conn
    |> visit("/settings/user/flags")
    |> assert_has("article", text: content)
    |> click_button("button[data-role=unflag]")
    |> assert_has(text: "Unflagged!")
    |> refute_has("article", text: content)
  end

  test "Unflag a user works", %{conn: conn, me: me, account: account, alice: alice} do
    # Flag a user
    {:ok, flag} = Bonfire.Social.Flags.flag(me, alice.id)

    # Check and unflag
    conn
    |> visit("/settings/user/flags")
    |> assert_has("article", text: alice.profile.name)
    |> click_button("button[data-role=unflag]")
    |> assert_has(text: "Unflagged!")
    |> refute_has("article", text: alice.profile.name)
  end

  # can add once we implement custom roles
  # NOTE: we do have `Bonfire.Boundaries.can?(context, :mediate, :instance)`
  # test "If I have the right instance permission, as a user I want to see and act upon the flags feed in admin settings" do

  # end
end
