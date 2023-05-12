"""
Multicall3 example using ape: https://github.com/ApeWorX/ape

Ape has native Multicall3 support which we leverage here. This example fetches the balances of 3
tokens for 3 users, along with token symbol and decimals. It then formats and prints the results.

To run the example:

1. Set an environment variable called `WEB3_INFURA_PROJECT_ID` that contains your Infura project ID.
2. Create a virtual environment with `python3 -m venv venv`
3. Activate the virtual environment with `source venv/bin/activate`
4. Install the dependencies with `pip install -r requirements.txt`
5. Run `python3 main.py`
"""
from ape import Contract, convert, networks
from ape_ethereum import multicall

# Requires an Infura API key to be set in an environment variable named `WEB3_INFURA_PROJECT_ID`
with networks.ethereum.mainnet.use_provider("infura"):
    # Define the users and tokens we want to query.
    tokens = [
        Contract("0x6B175474E89094C44Da98b954EedeAC495271d0F"),  # DAI.
        Contract("0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"),  # USDC.
        Contract("0xdAC17F958D2ee523a2206206994597C13D831ec7"),  # USDT.
    ]

    justin_sun = "0x3DdfA8eC3052539b6C9549F12cEA2C295cfF5296"
    users = ["vitalik.eth", "cz-🔶-binance.eth", justin_sun]

    # Create a multicall object.
    call = multicall.Call()

    # For each token we fetch the symbol and decimals, and then the balance for each user.
    for token in tokens:
        call.add(token.symbol)
        call.add(token.decimals)
        for user in users:
            call.add(token.balanceOf, user)

    # Execute the multicall, then format and print results.
    response = list(call())

    # Each token has 5 calls: symbol, decimals, and 3 balances. Therefore token symbols are at
    # indices 0, 5, 10, and token decimals are at indices 1, 6, 11.
    num_calls = 5
    for i, token in enumerate(tokens):
        # i = 0, 1, 2 therefore:
        #   - Token symbol indices are `i * num_calls`
        #   - Token decimals are at `i * num_calls + 1``
        symbol = response[i * num_calls]
        print(f"\033[1m{symbol} Balances:\033[0m")  # Print token symbol in bold.
        decimals = response[i * num_calls + 1]

        for j, user in enumerate(users):
            # The remaining 3 calls in a set of 5 are balances for each user, so we know that user
            # balances are at indices `i * num_calls + 2 + j`, where 2 is the number of calls prior
            # to the first balance call.
            num_prior_calls = 2
            balance = response[i * num_calls + num_prior_calls + j]
            user_name = user if j == 0 else "CZ" if j == 1 else "Justin Sun"
            formatted_balance = balance / 10**decimals
            print(f"  {user_name:<15} {formatted_balance}")
