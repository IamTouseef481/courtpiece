defmodule CourtPiece.Utils.SimpleEctoQueries do
  @moduledoc """
  Query interface for Ecto Schemas.
  Example:

  > defmodule Statistics do
  >   use CourtPiece.Util.SimpleEctoQueries, ecto_schema: Statistics, ecto_repo: CourtPiece.Repo
  > end
  >
  > Statistics.get_by(id: id)
  >
  > Statistics.list(
  >   inserted_at: {:gt, yesterday},
  >   preload: :Users,
  >   order: [desc: :program_uuid, asc: :inserted_at],
  >   pagination: %{limit: 100, offset: 3}
  > )
  """
  alias CourtPiece.Utils.SimpleEctoQueries

  import Ecto.Query

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      @doc """
      Find your record by specific fields.
      """
      @spec unquote(Keyword.get(opts, :get_by_alias, :get_by))(Keyword.t() | map()) ::
              {:ok, unquote(opts[:ecto_schema]).t()} | {:error, String.t()}
      def unquote(Keyword.get(opts, :get_by_alias, :get_by))(params \\ %{}) do
        SimpleEctoQueries.get_by(
          params,
          unquote(opts[:ecto_schema]),
          unquote(opts[:ecto_repo])
        )
      end

      @doc """
      Search for your records by specific fields.
      """
      @spec unquote(Keyword.get(opts, :list_alias, :list))(Keyword.t() | map()) ::
              list(unquote(opts[:ecto_schema]).t())
      def unquote(Keyword.get(opts, :list_alias, :list))(params \\ %{}) do
        SimpleEctoQueries.list(
          params,
          unquote(opts[:ecto_schema]),
          unquote(opts[:ecto_repo])
        )
      end

      @doc """
      Obtain the Ecto Query for a search by specific fields.
      """
      @spec unquote(Keyword.get(opts, :ecto_query_alias, :ecto_query))(Keyword.t() | map()) :: Ecto.Query.t()
      def unquote(Keyword.get(opts, :ecto_query_alias, :ecto_query))(params \\ %{}) do
        SimpleEctoQueries.ecto_query(
          params,
          unquote(opts[:ecto_schema])
        )
      end

      defoverridable get_by: 1, list: 1, ecto_query: 1
    end
  end

  @spec get_by(Keyword.t() | map(), atom(), atom()) :: {:ok, struct()} | {:error, String.t()}
  def get_by(params, ecto_schema, repo) do
    params
    |> apply_filters(ecto_schema, allowed_keys(ecto_schema))
    |> preload_associations(params[:preload], allowed_ecto_associations(ecto_schema))
    |> repo.one()
    |> case do
      nil -> {:error, "Could not find #{inspect(ecto_schema)} with arguments #{inspect(params)}"}
      record -> {:ok, record}
    end
  end

  @spec list(Keyword.t() | map(), atom(), atom()) :: list(struct())
  def list(params, ecto_schema, repo) do
    params
    |> ecto_query(ecto_schema)
    |> repo.all()
  end

  @spec ecto_query(Keyword.t() | map(), atom()) :: Ecto.Query.t()
  def ecto_query(params, ecto_schema) do
    params
    |> apply_filters(ecto_schema, allowed_keys(ecto_schema))
    |> order_query(params[:order])
    |> paginate_query(params[:pagination])
    |> preload_associations(params[:preload], allowed_ecto_associations(ecto_schema))
  end

  # ----- PRIVATE FUNCTIONS ----------------------------------------------------

  # ----- allowed_ecto_associations --------------------------------------------
  defp allowed_ecto_associations(ecto_schema) do
    ecto_schema.__schema__(:associations)
  end

  # ----- allowed_keys ---------------------------------------------------------
  defp allowed_keys(ecto_schema) do
    ecto_schema
    |> Map.from_struct()
    |> Map.put(:search, :string)
    |> Map.keys()
  end

  # ----- apply_filters --------------------------------------------------------
  defp apply_filters(params, base_query, allowed_keys) do
    params
    |> Enum.into(%{})
    |> Map.take(allowed_keys)
    |> Enum.reduce(base_query, fn
      {:search, search_value}, query ->
        base_query.search_by(query, search_value)

      {key, {:between, value1, value2}}, query ->
        where(query, ^dynamic([f], field(f, ^key) >= ^value1 and field(f, ^key) <= ^value2))

      {key, {:gt, value}}, query ->
        where(query, ^dynamic([f], field(f, ^key) > ^value))

      {key, {:gte, value}}, query ->
        where(query, ^dynamic([f], field(f, ^key) >= ^value))

      {key, {:lt, value}}, query ->
        where(query, ^dynamic([f], field(f, ^key) < ^value))

      {key, {:lte, value}}, query ->
        where(query, ^dynamic([f], field(f, ^key) <= ^value))

      {key, {:ne, value}}, query ->
        where(query, ^dynamic([f], field(f, ^key) != ^value))

      {key, nil}, query ->
        where(query, ^dynamic([f], is_nil(field(f, ^key))))

      {key, values}, query when is_list(values) ->
        where(query, ^dynamic([f], field(f, ^key) in ^values))

      {key, value}, query ->
        where(query, ^dynamic([f], field(f, ^key) == ^value))
    end)
  end

  # ----- paginate_query ----------------------------------------------------------
  defp paginate_query(query, %{limit: limit, offset: offset}) do
    query
    |> limit(^limit)
    |> offset(^offset)
  end

  defp paginate_query(query, %{limit: limit}), do: paginate_query(query, %{limit: limit, offset: 0})
  defp paginate_query(query, nil), do: query

  # ----- preload_associations ----------------------------------------------------
  defp preload_associations(query, nil, _ecto_associations), do: query

  defp preload_associations(query, association, ecto_associations) when not is_list(association),
    do: preload_associations(query, [association], ecto_associations)

  defp preload_associations(query, associations, ecto_associations) do
    ecto_associations = associations -- associations -- ecto_associations
    preload(query, ^ecto_associations)
  end

  # ----- order_query ----------------------------------------------------------
  # When calling, use the following to change sort order to 'desc' :
  #    order_query(query, [desc: :inserted_at])
  defp order_query(query, nil), do: query

  defp order_query(query, order) when not is_list(order),
    do: order_query(query, [order])

  defp order_query(query, order) do
    order_by(query, ^order)
  end
end
