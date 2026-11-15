defmodule Bonfire.UI.Moderation.FlagUnreadableTest do
  @moduledoc "Flagging is for what I can see. The delegated `flag` event is sent by the browser with just an object id, so the server has to check that I can read it."
  use Bonfire.UI.Moderation.ConnCase, async: false

  alias Bonfire.Social.Flags

  setup do
    Process.put(:federating, false)

    author = fake_user!(fake_account!())
    account = fake_account!()
    me = fake_user!(account)
    reader = fake_user!(fake_account!())

    {:ok, private_post} =
      Bonfire.Posts.publish(
        current_user: author,
        post_attrs: %{post_content: %{html_body: "<p>only for the author</p>"}},
        boundary: "mentions"
      )

    {:ok, public_post} =
      Bonfire.Posts.publish(
        current_user: author,
        post_attrs: %{post_content: %{html_body: "<p>for everyone</p>"}},
        boundary: "public"
      )

    {:ok, view, _html} = live(conn(user: me, account: account), "/@" <> author.character.username)

    %{
      me: me,
      reader: reader,
      private_post: private_post,
      public_post: public_post,
      view: view
    }
  end

  test "I cannot flag a post I cannot read", %{
    me: me,
    reader: reader,
    private_post: private_post,
    public_post: public_post,
    view: view
  } do
    refute Bonfire.Boundaries.can?(reader, :read, private_post),
           "control: a user like me cannot read it"

    render_hook(view, "Bonfire.Social.Flags:flag", %{
      "object_id" => public_post.id,
      "comment" => "control"
    })

    assert {:ok, _} = Flags.get(me, public_post, skip_boundary_check: true),
           "control: flagging a readable post works"

    render_hook(view, "Bonfire.Social.Flags:flag", %{
      "object_id" => private_post.id,
      "comment" => "spam"
    })

    refute match?({:ok, _}, Flags.get(me, private_post, skip_boundary_check: true))
  end
end
