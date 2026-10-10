Code.require_file("../examples/records.exs", __DIR__)

defmodule Armature.PreviewRecordsTest do
  use ExUnit.Case, async: true

  @options %{query: "", sort_by: "name", sort_direction: "asc", page: 1, page_size: 25}

  test "search covers the complete set before pagination and ignores case" do
    records = PreviewRecords.all()
    assert length(records) == 200
    assert length(Enum.uniq_by(records, & &1.id)) == 200
    result = PreviewRecords.page(%{@options | query: "r-200"})
    assert [%{id: "R-200"}] = result.rows
    assert result.total == 1
    result = PreviewRecords.page(%{@options | query: "gRoUp 2"})
    assert result.total == 50
    assert Enum.all?(result.rows, &(&1.group == "Group 2"))
  end

  test "text and numeric sorts order the complete set in both directions" do
    for {sort_by, key} <- [{"name", :name}, {"score", :score}], direction <- ~w(asc desc) do
      result = PreviewRecords.page(%{@options | sort_by: sort_by, sort_direction: direction})

      ordered =
        Enum.sort_by(
          PreviewRecords.all(),
          &{Map.fetch!(&1, key), &1.id},
          if(direction == "asc", do: :asc, else: :desc)
        )

      assert result.rows == Enum.take(ordered, 25)
    end
  end

  test "page sizes, boundary clamping and empty ranges remain consistent" do
    for size <- [10, 25, 50] do
      result = PreviewRecords.page(%{@options | page_size: size, page: 2})
      assert length(result.rows) == size
      assert result.first == size + 1
      assert result.last == 2 * size
      assert result.pages == div(200, size)
    end

    assert PreviewRecords.page(%{@options | page: -1}).page == 1
    assert PreviewRecords.page(%{@options | page: 100}).page == 8

    assert %{rows: [], total: 0, pages: 1, page: 1, first: 0, last: 0} =
             PreviewRecords.page(%{@options | query: "no match", page: 8})
  end
end
