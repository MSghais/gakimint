defmodule Cashubrew.Cashu.ProofValidator do
  @moduledoc """
  Handles the serialization and deserialization of Cashu tokens.
  """
  alias Cashubrew.Cashu.Proof
  alias CBOR

  def handle_proofs(%{"proofs" => proofs_input}) do
    # Step 1: Check if input is already a list (array)
    proofs =
      cond do
        is_list(proofs_input) ->
          proofs_input  # Input is already an array, so use it directly

        is_binary(proofs_input) ->
          # Step 2: Input is a string, try to parse it as JSON
          case parse_proofs(proofs_input) do
            {:ok, parsed_proofs} -> parsed_proofs
            {:error, reason} -> return_error("Invalid JSON: #{reason}")
          end

        true ->
          # return_error(conn, "Invalid input type, must be array or JSON string.")
      end

    # Step 3: Process the proofs (e.g., validate or further processing)
    if ProofValidator.validate_proofs(proofs) do
      # Handle valid proofs
      {:reply, proofs}
    else
      return_error("Invalid proofs.")
    end
  end

  defp return_error(message) do
    {:error, message}
  end


  defp convert_to_proof_struct(proof_map) do
    # Assuming your proof structure matches the ProofValidator struct

    # %Proof{
    #   amount: proof_map["amount"],
    #   id: proof_map["id"],
    #   secret: proof_map["secret"],
    #   C: proof_map["C"]
    # }

    %Proof{
      amount: Map.fetch!(proof_map, "amount"),
      id:  Map.fetch!(proof_map, "id"),
      secret:  Map.fetch!(proof_map, "secret"),
      C:  Map.fetch!(proof_map, "C")
    }

  end

    # Parsing function: checks if it's a string or list and tries to parse it as JSON
  defp parse_proofs(proofs_input) when is_binary(proofs_input) do
      # Try to decode the JSON string
      case Jason.decode(proofs_input) do
        {:ok, proof_list} when is_list(proof_list) ->
          {:ok, proof_list}

        {:ok, _other} ->
          {:error, "Expected an array of proofs but received something else."}

        {:error, %Jason.DecodeError{}} ->
          {:error, "Invalid JSON format in proofs."}
      end
  end

  # If input is already a list, return it
  defp parse_proofs(proofs_input) when is_list(proofs_input), do: {:ok, proofs_input}

  # If input is neither string nor list, return an error
  defp parse_proofs(_), do: {:error, "Invalid input type for proofs."}

  # def parse_proofs(json_string) do
  #   IO.puts("json_string: #{json_string}")

  #   case Jason.decode(json_string) do
  #     {:ok, proof_list} ->
  #       IO.puts("proof_list: #{proof_list}")

  #       # Convert to Proof structs if necessary or keep as map
  #       {:ok, proof_list |> Enum.map(&convert_to_proof_struct/1)}

  #     {:error, reason} ->
  #       {:error, "Failed to parse JSON: #{reason}"}
  #   end
  # end

  def validate_proofs(proofs) when is_list(proofs) do
    Enum.all?(proofs, &valid_proof?/1)
  end

  defp valid_proof?(proof) when is_map(proof) do
    has_required_keys?(proof) and valid_values?(proof)
  end

  defp has_required_keys?(%{
         "C" => _,
         "amount" => _,
         "secret" => _,
         "id" => _
       }), do: true

  defp has_required_keys?(_), do: false

  defp valid_values?(%{
         "C" => c,
         "amount" => amount,
         "secret" => secret,
         "id" => id
       }) do
    is_binary(c) and
      is_integer(amount) and
      is_binary(secret) and
      is_binary(id)
  end
end
