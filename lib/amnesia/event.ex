#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Amnesia.Event do
  @moduledoc """
  This module implements helpers to handle mnesia events.
  """

  @type system :: { :mnesia_up, node } |
                  { :mnesia_down, node } |
                  { :mnesia_checkpoint_activated, any } |
                  { :mnesia_overload, any } |
                  { :inconsistent_database, any } |
                  { :mnesia_fatal, char_list, [any], binary } |
                  { :mnesia_info, char_list, [any] } |
                  { :mnesia_user, any }

  @type activity :: { :complete, Amnesia.Access.id }

  @type table :: { :write, tuple, Amnesia.Access.id } |
                 { :delete_object, tuple, Amnesia.Access.id } |
                 { :delete, { atom, any }, Amnesia.Access.id } |
                 { :write, atom, tuple, [tuple], Amnesia.Access.id } |
                 { :delete, atom, any, [tuple], Amnesia.Access.id }

  @type category :: system | activity | table

  @doc false
  def handle([], fun) do
    receive do
      v -> fun.(v)
    end

    handle([], fun)
  end

  def handle(categories, fun) do
    Enum.each categories, &subscribe(&1)

    handle([], fun)
  end

  @doc """
  Observe the given events with the given function.
  """
  @spec observe(category | [category], (any -> none)) :: pid
  def observe(categories, fun) when is_list categories do
    spawn __MODULE__, :handle, [categories, fun]
  end

  def observe(category, fun) do
    observe([category], fun)
  end

  @doc """
  Subscribe to events of a given category, see `mnesia:subscribe`.
  """
  @spec subscribe(category) :: none
  def subscribe(category) do
    :mnesia.subscribe(category)
  end

  @doc """
  Unsubscribe from events of a given category, see `mnesia:unsubscribe`.
  """
  @spec unsubscribe(category) :: none
  def unsubscribe(category) do
    :mnesia.unsubscribe(category)
  end

  @doc """
  Report an event, see `mnesia:report_event`.
  """
  @spec report(any) :: :ok
  def report(event) do
    :mnesia.report_event(event)
  end
end
