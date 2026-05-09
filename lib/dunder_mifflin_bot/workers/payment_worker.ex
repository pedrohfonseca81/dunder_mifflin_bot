defmodule DunderMifflinBot.Workers.PaymentWorker do
  use Oban.Worker, queue: :payments, max_attempts: 5

  alias DunderMifflinBot.Payments.AbacatePay
  alias DunderMifflinBot.Economy.Store

  @impl true
  def perform(%Oban.Job{args: %{"billing_id" => billing_id}}) do
    with {:ok, charge} <- AbacatePay.get_charge(billing_id),
         "PAID" <- charge["status"],
         metadata when is_map(metadata) <- charge["metadata"] do
      Store.fulfill_purchase(billing_id, metadata)
    else
      "PENDING" -> {:snooze, 60}
      _ -> :ok
    end
  end
end
