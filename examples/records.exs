defmodule PreviewRecords do
  @moduledoc false

  def all do
    for number <- 1..200 do
      %{
        id: "R-#{number |> Integer.to_string() |> String.pad_leading(3, "0")}",
        name:
          "Example #{rem(number * 37, 200) |> Integer.to_string() |> String.pad_leading(3, "0")}",
        score: rem(number * 17, 101),
        group: "Group #{rem(number, 4) + 1}"
      }
    end
  end

  def page(options) do
    query = options.query |> String.downcase() |> String.trim()

    matches =
      Enum.filter(all(), fn row ->
        text = String.downcase(Enum.join([row.id, row.name, row.group], " "))
        String.contains?(text, query)
      end)

    key = if options.sort_by == "score", do: & &1.score, else: & &1.name
    direction = if options.sort_direction == "desc", do: :desc, else: :asc
    ordered = Enum.sort_by(matches, &{key.(&1), &1.id}, direction)
    total = length(ordered)
    pages = max(1, ceil(total / options.page_size))
    page = min(max(1, options.page), pages)

    %{
      rows: Enum.slice(ordered, (page - 1) * options.page_size, options.page_size),
      total: total,
      pages: pages,
      page: page,
      first: if(total == 0, do: 0, else: (page - 1) * options.page_size + 1),
      last: min(page * options.page_size, total)
    }
  end
end
