defmodule OcapRpcTest.TestUtils do
  @moduledoc false

  @user_account "0b078896a3D9166da5C37AE52a5809aCa48630d4"
  @contract_account "b98d4c97425d9908e66e53a6fdf673acca0be986"

  @sample_block %{
    "author" => "ea674fdde714fd979de3edf0f56aa9716b898ec8",
    "difficulty" => "cdc2c7fbcfa40",
    "extraData" => "65746865726d696e652d61736961312d34",
    "gasLimit" => "7a11f8",
    "gasUsed" => "55b14b",
    "hash" => "f1070c1252a9629c5f95728b44d5cb48869d33b69e05180c9eb74d551f6e8a28",
    "logsBloom" =>
      "00120000025050082011010002101002100001000801061000384209000c0168000102c0480048004000010001011009230001020820061210080805780420000004204a0329101188e04c0c00e024003208000084048020c021090310900020002000000640200401408048000228400050202000143004241300111480000400000e014000003400108482008c404a48420003000081460402648900012d000a0501004040020400400004c108c420100004000204802612000000181200000180080222246001042840410400284c00208024a2080800221c02000042640914006180a0c0002020060080d408e484410700b08013210d0004008080480880",
    "miner" => "ea674fdde714fd979de3edf0f56aa9716b898ec8",
    "mixHash" => "03f96602ab2e9f6f5dc476413723684a166a2740b4ef551c016457b3ef9d3196",
    "nonce" => "0196b9800479e0db",
    "number" => "5c5bd1",
    "parentHash" => "ec42f2e608f2491e1db0474e03073b2ebbe02a4672727cba309140c8394b448a",
    "receiptsRoot" => "206dddfaab2c3d7fd79b9df4e31ac6821f1593afa2dedc12a4424cf0e4905679",
    "sealFields" => [
      "a003f96602ab2e9f6f5dc476413723684a166a2740b4ef551c016457b3ef9d3196",
      "880196b9800479e0db"
    ],
    "sha3Uncles" => "1dcc4de8dec75d7aab85b567b6ccd41ad312451b948a7413f0a142fd40d49347",
    "size" => "5cca",
    "stateRoot" => "1f5fef327771b488d5991154f107cd94db5b5b89b09912aa077a94336859a847",
    "timestamp" => "5b5e0c67",
    "totalDifficulty" => "13334dadbed2cfbf5b5",
    "transactions" => [
      "735975a1b3d79624c81a1c2c97a4d3cead388b8b1a9bba4da07bb0032dd862e4"
    ],
    "transactionsRoot" => "c3a6a6eccbe86cf213678d2145197b46b7abe0ec131c0a21e6c8792f4129b643",
    "uncles" => []
  }

  @sample_tx %{
    "blockHash" => "f1070c1252a9629c5f95728b44d5cb48869d33b69e05180c9eb74d551f6e8a28",
    "blockNumber" => "5c5bd1",
    "chainId" => "1",
    "condition" => nil,
    "creates" => nil,
    "from" => "38871c5663bf192e32abd98ca558ac91ae101a72",
    "gas" => "5208",
    "gasPrice" => "12a05f2000",
    "hash" => "735975a1b3d79624c81a1c2c97a4d3cead388b8b1a9bba4da07bb0032dd862e4",
    "input" => "",
    "nonce" => "c",
    "publicKey" =>
      "bb0e15a02428bda78ad3dc4f926d4e87149e9f0c9c7a685b9a357a915e7066501899fb4dd6dd1bde6b2eb9cbdc14596da44b0f7df086e1ce44933033c07c37fe",
    "r" => "db2b10a37a6cdb812f2c021a25857a3a3f45acb1a638bbda1552c773b9d5e80f",
    "raw" =>
      "f86c0c8512a05f200082520894b9ee1e551f538a464e8f8c41e9904498505b49b088046ae65a7ce700008026a0db2b10a37a6cdb812f2c021a25857a3a3f45acb1a638bbda1552c773b9d5e80fa02f9b0a68907f0d98a940aa14802df423ee0fd2c70064ec57e59d7d739610e20b",
    "s" => "2f9b0a68907f0d98a940aa14802df423ee0fd2c70064ec57e59d7d739610e20b",
    "standardV" => "1",
    "to" => "b9ee1e551f538a464e8f8c41e9904498505b49b0",
    "transactionIndex" => "0",
    "v" => "26",
    "value" => "46ae65a7ce70000"
  }

  @sample_tx_receipt %{
    "blockHash" => "f1070c1252a9629c5f95728b44d5cb48869d33b69e05180c9eb74d551f6e8a28",
    "blockNumber" => "5c5bd1",
    "contractAddress" => nil,
    "cumulativeGasUsed" => "5208",
    "gasUsed" => "5208",
    "logs" => [],
    "logsBloom" =>
      "00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
    "root" => nil,
    "status" => "1",
    "transactionHash" => "735975a1b3d79624c81a1c2c97a4d3cead388b8b1a9bba4da07bb0032dd862e4",
    "transactionIndex" => "0"
  }
  @sample_tx_trace [
    %{
      "action" => %{
        "callType" => "call",
        "from" => "38871c5663bf192e32abd98ca558ac91ae101a72",
        "gas" => "0",
        "input" => "",
        "to" => "b9ee1e551f538a464e8f8c41e9904498505b49b0",
        "value" => "39aaed7b4b22400"
      },
      "blockHash" => "f1070c1252a9629c5f95728b44d5cb48869d33b69e05180c9eb74d551f6e8a28",
      "blockNumber" => "5c5bd1",
      "result" => %{"gasUsed" => "0", "output" => ""},
      "subtraces" => 0,
      "traceAddress" => [],
      "transactionHash" => "735975a1b3d79624c81a1c2c97a4d3cead388b8b1a9bba4da07bb0032dd862e4",
      "transactionPosition" => 64,
      "txGasLimit" => "5208",
      "type" => "call"
    }
  ]

  @sample_block_trace [
    %{
      "action" => %{
        "author" => "ea674fdde714fd979de3edf0f56aa9716b898ec8",
        "rewardType" => "block",
        "value" => "0x2aef353bcddd6000"
      },
      "blockHash" => "f1070c1252a9629c5f95728b44d5cb48869d33b69e05180c9eb74d551f6e8a28",
      "blockNumber" => "5c5bd1",
      "result" => nil,
      "subtraces" => 0,
      "traceAddress" => [],
      "transactionHash" => nil,
      "transactionPosition" => nil,
      "type" => "reward"
    },
    %{
      "action" => %{
        "author" => "441d463d69cb6eaa851eb6138c3efac95c86d17b",
        "rewardType" => "uncle",
        "value" => "0x246ddf9797668000"
      },
      "blockHash" => "f1070c1252a9629c5f95728b44d5cb48869d33b69e05180c9eb74d551f6e8a28",
      "blockNumber" => "5c5bd1",
      "result" => nil,
      "subtraces" => 0,
      "traceAddress" => [],
      "transactionHash" => nil,
      "transactionPosition" => nil,
      "type" => "reward"
    }
  ]

  @contract_tx %{
    "address" => "b98d4c97425d9908e66e53a6fdf673acca0be986",
    "blockHash" => "8259f329c890928af5f80841bcbe1b3f4f93726e2ced6bbfe7e8fb9b016799c3",
    "blockNumber" => "5c5dc3",
    "data" => "00000000000000000000000000000000000000000000000c0f415310c1754000",
    "logIndex" => "a",
    "topics" => [
      "ddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef",
      "000000000000000000000000adb2b42f6bd96f5c65920b9ac88619dce4166f94",
      "0000000000000000000000002cdf1c14e492595e0c392cd13110b8667ebf6363"
    ],
    "transactionHash" => "90bb15aebdaee782ff966ceab40dca78648b04f2bb3eccb711102f11b1ddbbb0",
    "transactionIndex" => "13",
    "transactionLogIndex" => "0",
    "type" => "mined"
  }

  def user_account, do: @user_account
  def user_balance, do: 10_491_876_721_330_364

  def contract_account, do: @contract_account
  def contract_code, do: "deadbeef"

  def block, do: @sample_block
  def block_hash, do: Map.get(@sample_block, "hash")
  def block_height, do: Map.get(@sample_block, "number")
  def block_trace, do: @sample_block_trace

  def tx, do: @sample_tx
  def tx_hash, do: Map.get(@sample_tx, "hash")

  def tx_receipt, do: @sample_tx_receipt
  def tx_trace, do: @sample_tx_trace

  def gas_price, do: Map.get(@sample_tx, "gasPrice")

  def contract_tx, do: @contract_tx

  def abt_supply, do: "00000000000000000000000000000000000000000099db083440e4a6fa000000"
end
