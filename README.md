amnesia - mnesia wrapper for Elixir
===================================
amnesia wraps everything exposed by mnesia, from fragments to fragment hash,
access and backup behaviors.

It provides a simplified table and database definition with some macros and
allows you to use the nice `Enum` functions on tables by implementing the
`Enum.Iterator` protocol.

Everything is documented and specced, even the unspecced and undocumented parts
of mnesia that have been wrapped.

The documentation often refers to mnesia functions, I strongly suggest you read
[mnesia's documentation](http://erlang.org/doc/man/mnesia.html) too, since it has a lot of valuable information.

Defining a database
-------------------
To use amnesia you have to define a database and the tables of that database.

You can have multiple databases in the same amnesia instance, a database is
actually just a way to group *mnesia* tables.

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
    @type t :: %Message{user_id: integer, content: String.t}

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
  deftable User, [{ :id, autoincrement }, :name, :email], type: :ordered_set, index: [:email] do
    # again not needed, but nice to have
    @type t :: %User{id: non_neg_integer, name: String.t, email: String.t}

    # this is a helper function to add a message to the user, using write
    # on the created records makes it write to the mnesia table
    def add_message(self, content) do
      %Message{user_id: self.id, content: content} |> Message.write
    end

    # like above, but again with dirty operations, the bang methods are used
    # thorough amnesia to be the dirty counterparts of the bang-less functions
    def add_message!(self, content) do
      %Message{user_id: self.id, content: content} |> Message.write!
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

Creating the database
---------------------
Before using a database you have to create it, and before it a schema.

To do so, you can use the built-in mix task `amnesia.create` passing your
database module via the `--database` or `-d` options.

```sh
mix amnesia.create -d Database --disk
```

The available options for creating the databases are:

- `--database` or `-d`: the database module to create
- `--no-schema`: to avoid creating the schema
- `--memory`: to create the tables with memory copying on the current node
- `--disk`: to create the tables with disc_copies on the current node
- `--disk!`: to create the tables with disc_only_copies on the current node

By default it creates the schema and uses disc_copies.

If you want to drop the tables there is also a drop task you should use with
__CAUTION__ as it will destroy all data. To use it just call:

```sh
mix amnesia.drop -d Database
```

The options accepted by this task are:

- `--database` or `-d`: same as with create. A database module to drop tables
- `--schema`: drops the schema too. Defaults to false

Writing to the database
-----------------------
Once the database has been defined and created, you can start using the various
tables.

```elixir
# You want to be in a transaction most of the time, this ensures the data
# doesn't get corrupted and you get meaningful values back.
#
# Most operation won't work outside a transaction and will raise an exception.
Amnesia.transaction do
  # Every table is a record, so you can do everything you can do with records.
  #
  # Once you want to save the record, you have to call `.write` on it, this
  # will write the record to the table.
  #
  # Since we defined the `User` table with an `autoincrement` id attribute it
  # will be incremented internally on write, unless the id attribute is set, in
  # that case it will be left as is.
  #
  # If you want to know the values of the autoincrement fields, `.write` always
  # returns the updated record.
  john = %User{name: "John", email: "john@example.com"} |> User.write

  # Let's create more users.
  richard = %User{name: "Richard", email: "richard@example.com"} |> User.write
  linus   = %User{name: "Linus", email: "linus@example.com"} |> User.write

  # Now let's add some messages.

  john |> User.add_message %S"""
  When we program a computer to make choices intelligently after determining
  its options, examining their consequences, and deciding which is most
  favorable or most moral or whatever, we must program it to take an attitude
  towards its freedom of choice essentially isomorphic to that which a human
  must take to his own.
  """

  john |> User.add_message %S"""
  He who refuses to do arithmetic is doomed to talk nonsense."
  """

  john |> User.add_message %S"""
  It's difficult to be rigorous about whether a machine really 'knows',
  'thinks', etc., because we're hard put to define these things. We understand
  human mental processes only slightly better than a fish understands swimming.
  """

  richard |> User.add_message %S"""
  For personal reasons, I do not browse the web from my computer. (I also have
  no net connection much of the time.) To look at page I send mail to a daemon
  which runs wget and mails the page back to me. It is very efficient use of my
  time, but it is slow in real time.
  """

  richard |> User.add_message %S"""
  I am skeptical of the claim that voluntarily pedophilia harms children. The
  arguments that it causes harm seem to be based on cases which aren't
  voluntary, which are then stretched by parents who are horrified by the idea
  that their little baby is maturing.
  """

  linus |> User.add_message %S"""
  Portability is for people who cannot write new programs.
  """

  linus |> User.add_message %S"""
  Really, I'm not out to destroy Microsoft. That will just be a completely
  unintentional side effect.
  """

  linus |> User.add_message %S"""
  Modern PCs are horrible. ACPI is a complete design disaster in every way. But
  we're kind of stuck with it. If any Intel people are listening to this and
  you had anything to do with ACPI, shoot yourself now, before you reproduce.
  """
end
```

Reading from the database
-------------------------
Once there's something written to the database you can start reading back
records from it.

```elixir
Amnesia.transaction do
  # The simplest way to read a record is using the key of the record (by
  # default the first attribute)
  #
  # Since we wrote the John, Richard and Linus in this order and the id is
  # defined as *autoincrement*, the first `User` will be John.
  john = User.read(1)

  # Now let's read his messages and print them all.
  john |> User.messages |> Enum.each &IO.puts(&1.content)

  # You can also use an Exquisite selector to fetch records.
  selection = Message.where user_id == 1 or user_id == 2,
    select: content

  # Get the values in the selector and print them.
  selection |> Amnesia.Selection.values |> Enum.each &IO.puts(&1.content)
end
```

Other documentation
-------------------
All the code has `@spec` and `@doc`, so you can either go around the source and
read the `@docs`, use the REPL and `h/1` or generate the documentation with
`ex_doc`.
