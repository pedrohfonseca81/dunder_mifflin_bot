defmodule DunderMifflinBot.Payments.AbacatePay do
  @base_url "https://api.abacatepay.com/v2"

  def create_pix(amount_cents, description, customer, metadata \\ %{}) do
    api_key = Application.get_env(:dunder_mifflin_bot, :abacatepay_api_key)

    body = %{
      method: "PIX",
      data: %{
        amount: amount_cents,
        description: description,
        expiresIn: 1800,
        customer: customer,
        metadata: metadata
      }
    }

    case Req.post("#{@base_url}/transparents/create",
           json: body,
           headers: [
             {"Authorization", "Bearer #{api_key}"},
             {"Content-Type", "application/json"}
           ]
         ) do
      {:ok, %{status: 200, body: %{"data" => data, "success" => true}}} ->
        {:ok, data}

      {:ok, %{status: status, body: body}} ->
        {:error, "AbacatePay #{status}: #{inspect(body)}"}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def get_charge(charge_id) do
    api_key = Application.get_env(:dunder_mifflin_bot, :abacatepay_api_key)

    case Req.get("#{@base_url}/transparents/#{charge_id}",
           headers: [{"Authorization", "Bearer #{api_key}"}]
         ) do
      {:ok, %{status: 200, body: %{"data" => data}}} -> {:ok, data}
      {:ok, %{status: status, body: body}} -> {:error, "AbacatePay #{status}: #{inspect(body)}"}
      {:error, reason} -> {:error, reason}
    end
  end
end
