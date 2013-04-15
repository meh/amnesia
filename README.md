amnesia - mnesia wrapper for Elixir
===================================
amnesia wraps everything exposed by mnesia, from fragments to fragment hash,
access and backup behaviors.

It provides a simplified table and database definition with some macros and
allows you to use the nice `Enum` functions on tables by implementing the
`Enum.Iterator` protocol.

Everything is documented and specced, even the unspecced and undocumented parts
of mnesia that have been wrapped.

Example
-------

```elixir
defdatabase Database do
  deftable User

  deftable Message, [:user_id, :content], type: :bag do
    @type t :: Message[user_id: integer, content: String.t]

    def user(self) do
      User.read(self.user_id)
    end

    def user!(self) do
      User.read!(self.user_id)
    end
  end

  deftable User, [:id, :name, :email], type: :ordered_set, index: [:email] do
    @type t :: User[id: integer, name: String.t, email: String.t]

    def add_message(content, self) do
      Message[user_id: self.id, content: content].write
    end

    def add_message!(content, self) do
      Message[user_id: self.id, content: content].write!
    end

    def messages(self) do
      Message.read(self.id)
    end

    def messages!(self) do
      Message.read!(self.id)
    end
  end
end
```
