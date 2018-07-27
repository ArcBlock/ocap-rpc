# RPC data extraction DSL

this is a small DSL that extract data from the json rpc result. It currently applied to ethereum RPC but could be further applied to other blockchain RPC.

## Basic Notation

* ``.`` is xpath like notation. e.g. "transactions.0.blockHash" means to get blockHash from transaction 0.
* number or ``*`` or range (1-5): means to get specified data from list. e.g. "transactions.1-5.blockHash", result [hash1, hash2, ... hash5]
* ``_``: means same field (may require convert snake case to camelcase)
* ``$``: means variable from caller scope
* ``&``: means this is a function
* ``*`` in the field name means the function will pollute the current ctx with generated fields.
