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
mnesia's documentation too, since it has a lot of valuable information.

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
  deftable User, [{ :id, autoincrement }, :name, :email], type: :ordered_set, index: [:email] do
    # again not needed, but nice to have
    @type t :: User[id: non_neg_integer, name: String.t, email: String.t]

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

Creating the database
---------------------
Before using a database you have to create it, and before it a schema.

A good way to do this is having two mix tasks, one to install and one to
uninstall the database.

```elixir
defmodule Mix.Tasks.Install do
  use Mix.Task
  use Database

  def run(_) do
    # This creates the mnesia schema, this has to be done on every node before
    # starting mnesia itself, the schema gets stored on disk based on the
    # `-mnesia` config, so you don't really need to create it every time.
    Amnesia.Schema.create

    # Once the schema has been created, you can start mnesia.
    Amnesia.start

    # When you call create/1 on the database, it creates a metadata table about
    # the database for various things, then iterates over the tables and creates
    # each one of them with the passed copying behaviour
    #
    # In this case it will keep a ram and disk copy on the current node.
    Database.create(disk: [node])

    # This waits for the database to be fully created.
    Database.wait

    Amnesia.transaction do
      # ... initial data creation
    end

    # Stop mnesia so it can flush everything and keep the data sane.
    Amnesia.stop
  end
end
```

```elixir
defmodule Mix.Tasks.Uninstall do
  use Mix.Task
  use Database

  def run(_) do
    # Start mnesia, or we can't do much.
    Amnesia.start

    # Destroy the database.
    Database.destroy

    # Stop mnesia, so it flushes everything.
    Amnesia.stop

    # Destroy the schema for the node.
    Amnesia.Schema.destroy
  end
end
```

To know more about the possible attributes for database creation check out the
`@doc`.

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
  john = User[name: "John", email: "john@example.com"].write

  # Let's create more users.
  richard = User[name: "Richard", email: "richard@example.com"].write
  linus   = User[name: "Linus", email: "linus@example.com"].write

  # Now let's add some messages.

  john.add_message %S"""
  When we program a computer to make choices intelligently after determining
  its options, examining their consequences, and deciding which is most
  favorable or most moral or whatever, we must program it to take an attitude
  towards its freedom of choice essentially isomorphic to that which a human
  must take to his own.
  """

  john.add_message %S"""
  He who refuses to do arithmetic is doomed to talk nonsense."
  """

  john.add_message %S"""
  It's difficult to be rigorous about whether a machine really 'knows',
  'thinks', etc., because we're hard put to define these things. We understand
  human mental processes only slightly better than a fish understands swimming.
  """

  richard.add_message %S"""
  For personal reasons, I do not browse the web from my computer. (I also have
  no net connection much of the time.) To look at page I send mail to a daemon
  which runs wget and mails the page back to me. It is very efficient use of my
  time, but it is slow in real time.
  """

  richard.add_message %S"""
  I am skeptical of the claim that voluntarily pedophilia harms children. The
  arguments that it causes harm seem to be based on cases which aren't
  voluntary, which are then stretched by parents who are horrified by the idea
  that their little baby is maturing.
  """

  linus.add_message %S"""
  Portability is for people who cannot write new programs.
  """

  linus.add_message %S"""
  Really, I'm not out to destroy Microsoft. That will just be a completely
  unintentional side effect.
  """

  linus.add_message %S"""
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
  john.messages |> Enum.each &IO.puts(&1.content)

  # You can also use an Exquisite selector to fetch records.
  selector = Message.where user_id == 1 or user_id == 2,
    select: content

  # Get the values in the selector and print them.
  selector.values |> Enum.each &IO.puts(&1.content)
  
  # Just for fun, let's read *all* Users
  users = User.where(true).values
end
```

Other documentation
-------------------
All the code has `@spec` and `@doc`, so you can either go around the source and
read the `@docs`, use the REPL and `h/1` or generate the documentation with
`ex_doc`.
