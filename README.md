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
# needed to get defdatabase and other macros
use Amnesia

# defines a database called Database, it's basically a defmodule with
# some additional magic
defdatabase Database do
  # this is just a forward declaration of the table, otherwise you'd have
  # to fully scope User.read in Message functions
  deftable User

  # this defines a table with an user_id key and a content attribute, and
  # makes the table a bag; tables are basically records with a bunch of helpers
  deftable Message, [:user_id, :content], type: :bag do
    # this isn't required, but it's always nice to spec things
    @type t :: Message[user_id: integer, content: String.t]

    # this defines a helper function to fetch the user from a Message record
    def user(self) do
      User.read(self.user_id)
    end

    # this does the same, but uses dirty operations
    def user!(self) do
      User.read!(self.user_id)
    end
  end

  # this defines a table with other attributes as ordered set, and defines an
  # additional index as email, this improves lookup operations
  deftable User, [:id, :name, :email], type: :ordered_set, index: [:email] do
    # again not needed, but nice to have
    @type t :: User[id: integer, name: String.t, email: String.t]

    # this is a helper function to add a message to the user, using write
    # on the created records makes it write to the mnesia table
    def add_message(content, self) do
      Message[user_id: self.id, content: content].write
    end

    # like above, but again with dirty operations, the bang methods are used
    # thorough amnesia to be the dirty counterparts of the bang-less functions
    def add_message!(content, self) do
      Message[user_id: self.id, content: content].write!
    end

    # this is a helper to fetch all messages for the user
    def messages(self) do
      Message.read(self.id)
    end

    # like above, but with dirty operations
    def messages!(self) do
      Message.read!(self.id)
    end
  end
end
```

Documentation
-------------
All the code has `@spec` and `@doc`, so you can either go around the source and
read the `@docs`, use the REPL and `h/1` or generate the documentation with
`ex_doc`.

There also some pages on the wiki from the gentleman @jschoch.
