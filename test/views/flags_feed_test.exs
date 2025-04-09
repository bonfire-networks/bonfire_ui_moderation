defmodule Bonfire.UI.Moderation.FlagsFeedTest do
  use Bonfire.UI.Moderation.ConnCase, async: true

  alias Bonfire.Social.Fake
  alias Bonfire.Posts
  alias Bonfire.Social.Graph.Follows
  alias Bonfire.Me.Accounts
  alias Bonfire.Me.Users
  alias Bonfire.Files.Test
  import Bonfire.Common.Enums

  setup do
    admin_account = fake_account!()
    admin = fake_admin!(admin_account)
    account = fake_account!()
    me = fake_user!(account)
    alice = fake_user!(account)
    bob = fake_user!(account)
    carl = fake_user!(account)

    conn = conn(user: me, account: account)

    {:ok,
     admin: admin,
     conn: conn,
     account: account,
     me: me,
     alice: alice,
     bob: bob,
     carl: carl,
     admin_account: admin_account}
  end

  test "My flags should not appear on local feed, and only on flagged feed or flags list", %{
    conn: conn,
    me: me,
    account: account,
    alice: alice,
    admin: admin,
    admin_account: admin_account
  } do
    # admin = fake_admin!(account)

    refute Accounts.is_admin?(account)
    assert Accounts.is_admin?(admin)

    # Alice creates a post
    content = "here is an epic html post"
    attrs = %{post_content: %{html_body: content}}
    assert {:ok, post} = Posts.publish(current_user: alice, post_attrs: attrs, boundary: "local")

    {:ok, _flag} = Bonfire.Social.Flags.flag(me, post.id)

    # Check views as myself (non-admin)
    conn
    |> visit("/feed/local")
    |> refute_has("div[data-role=flagged_by]")

    # Check my flags view as myself
    conn
    |> visit("/settings/user/flags")
    |> assert_has("div[data-role=flagged_by]")

    # Check views as Alice (non-admin & author of flagged post)
    conn(user: alice, account: account)
    |> visit("/feed/local")
    |> refute_has("div[data-role=flagged_by]")

    conn(user: alice, account: account)
    |> visit("/settings/user/flags")
    |> refute_has("div[data-role=flagged_by]")

    # Check views as admin
    conn(user: admin, account: account)
    |> visit("/feed/local")
    |> refute_has("div[data-role=flagged_by]")

    # Check admin flags view
    conn(user: admin, account: admin_account)
    |> visit("/settings/instance/flags")
    |> assert_has("div[data-role=flagged_by]")
  end

  test "Flags from other users should not appear", %{
    conn: conn,
    me: me,
    account: account,
    alice: alice,
    bob: bob
  } do
    # Alice creates a post
    content = "here is an epic html post"
    attrs = %{post_content: %{html_body: content}}
    assert {:ok, post} = Posts.publish(current_user: alice, post_attrs: attrs, boundary: "local")

    {:ok, _flag} = Bonfire.Social.Flags.flag(me, post.id)

    # Check as myself
    conn
    |> visit("/feed/local")
    |> refute_has("div[data-role=flagged_by]")

    conn
    |> visit("/settings/user/flags")
    |> assert_has("div[data-role=flagged_by]")

    # Check as Alice
    conn(user: alice, account: account)
    |> visit("/feed/local")
    |> refute_has("div[data-role=flagged_by]")

    conn(user: alice, account: account)
    |> visit("/settings/user/flags")
    |> refute_has("div[data-role=flagged_by]")

    # Check as Bob
    conn(user: bob, account: account)
    |> visit("/feed/local")
    |> refute_has("div[data-role=flagged_by]")

    conn(user: bob, account: account)
    |> visit("/settings/user/flags")
    |> refute_has("div[data-role=flagged_by]")
  end

  test "When I flag an activity, I want to see the flag in my flags feed in settings", %{
    conn: conn,
    me: me,
    account: account,
    alice: alice
  } do
    # Alice creates a post
    content = "here is an epic html post"
    attrs = %{post_content: %{html_body: content}}
    assert {:ok, post} = Posts.publish(current_user: alice, post_attrs: attrs, boundary: "local")

    # Flag the post
    {:ok, flag} = Bonfire.Social.Flags.flag(me, post.id)

    # Check my flags feed
    conn
    |> visit("/settings/user/flags")
    |> assert_has("article", text: content)
  end

  test "As an admin, When a user flags an activity I want to see the activity in flags feed in admin settings",
       %{conn: conn, me: me, account: account, alice: alice, bob: bob} do
    # Make myself an admin
    {:ok, me} = Bonfire.Me.Users.make_admin(me)

    # Alice creates a post
    content = "here is an epic html post"
    attrs = %{post_content: %{html_body: content}}
    assert {:ok, post} = Posts.publish(current_user: alice, post_attrs: attrs, boundary: "local")

    # Bob flags the post
    {:ok, flag} = Bonfire.Social.Flags.flag(bob, post.id)

    # Check admin flags view
    conn(user: me, account: account)
    |> visit("/settings/instance/flags")
    |> assert_has("article", text: content)
  end

  test "As an admin, When a user flags another user I want to see the user flagged in flags feed in admin settings",
       %{conn: conn, me: me, account: account, alice: alice, bob: bob} do
    # Make myself an admin
    {:ok, me} = Bonfire.Me.Users.make_admin(me)

    # Bob flags Alice
    {:ok, flag} = Bonfire.Social.Flags.flag(bob, alice.id)

    # Check admin flags view
    conn(user: me, account: account)
    |> visit("/settings/instance/flags")
    |> assert_has("article")
  end

  # can add once we implement custom roles
  # NOTE: we do have `Bonfire.Boundaries.can?(context, :mediate, :instance)`
  # test "If I have the right instance permission, as a user I want to see and act upon the flags feed in admin settings" do

  # end
end
