# This is an experiment to create TODO lists using Elixir 

defmodule MultiMap do
  def new, do: Map.new

  def add(map, key, value) do
    Map.update(map, key, [value], &[value | &1])
  end

  def get(map, key, default_value \\ []) do
    Map.get(map, key, default_value)
  end
end


defmodule TodoList do
  defstruct auto_id: 1, entries: MultiMap.new

  def new, do: %TodoList{}
  
  def new(entries) do
    Enum.reduce(
      entries, 
      %TodoList{},
      fn(entry, list) -> 
        add_entry(list, entry)
      end
    )
  end

  def add_entry(%TodoList{entries: original_entries, auto_id: original_id} = todo_list, entry) do    
    entry       =            entry |> Map.put(:id, original_id)
    new_entries = original_entries |> Map.put(original_id, entry)
    
    %TodoList{todo_list | entries: new_entries, auto_id: original_id + 1} # update the struct itself
  end

  def update_entry(%TodoList{entries: entries} = todo_list, entry_id, updater_function) do
    case entries[entry_id] do
      nil -> todo_list
      entry -> 
        old_entry_id = entry.id
        new_entry = %{id: ^old_entry_id} = updater_function.(entry)
        new_entries = Map.put(entries, new_entry.id, new_entry)
        %TodoList{todo_list | entries: new_entries}
    end
  end

  def entries(%TodoList{entries: entries}, date) do
    entries 

    |> Stream.filter(
      fn({_, entry}) -> 
        entry.date == date  
      end)

    |> Enum.map(
      fn({_, entry}) -> 
        entry 
      end)
  end
end

defmodule TodoList.CSVImporter do
  
  def new, do: {:error, %{message: "Filename or path required"}}

  def new(filename) do
    filename 
      |> File.read 
      |> parse 
      |> to_todo
  end

  defp parse({:error, error}), do: {:error, error}
  
  defp parse({:ok, contents}) do
    result = 
      contents 
      |> split_by_lines("\n") 
      |> extract_date_and_title  
      |> parse_dates("/")

    {:ok, result}
  end

  defp to_todo({:ok, result}), do: TodoList.new(result)

  defp to_todo(error), do: error

  defp extract_date_and_title(list) do
    Stream.map(list, fn(line) -> 
      [date, title] = String.split(line, ",")
      %{date: date, title: title}
    end)
  end

  defp parse_dates(list, separator) do
    Stream.map(list, fn(map) -> 
      [year, month, day] = String.split(map.date, separator)
      
      {year,  _} = :string.to_integer(year)
      {month, _} = :string.to_integer(month)
      {day,   _} = :string.to_integer(day)

      %{date: {year, month, day}, title: map.title}
    end)
  end

  defp split_by_lines(contents, separator) do
    String.split(contents, separator) 
  end
end
