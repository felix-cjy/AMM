## Foundry

```bash
$ forge test --gas-report
[⠢] Compiling...
No files changed, compilation skipped

Ran 10 tests for test/AMM.t.sol:AMMTest
[PASS] testAddLiquidity() (gas: 297323)
[PASS] testAddLiquidityTwice() (gas: 394002)
[PASS] testFailInsufficientLiquidity() (gas: 59035)
[PASS] testFailInvalidToken() (gas: 667397)
[PASS] testGetAmount() (gas: 8878)
[PASS] testInitialState() (gas: 25110)
[PASS] testRemoveLiquidity() (gas: 396911)
[PASS] testRemoveLiquidityPartially() (gas: 431443)
[PASS] testSwapTokenForWETH() (gas: 417586)
[PASS] testSwapWETHForToken() (gas: 417436)
Suite result: ok. 10 passed; 0 failed; 0 skipped; finished in 11.51ms (49.66ms CPU time)
| src/AMM.sol:AMM contract |                 |        |        |        |         |
|--------------------------|-----------------|--------|--------|--------|---------|
| Deployment Cost          | Deployment Size |        |        |        |         |
| 1458821                  | 6747            |        |        |        |         |
| Function Name            | min             | avg    | median | max    | # calls |
| addLiquidity             | 86141           | 176579 | 190053 | 199653 | 7       |
| approve                  | 46388           | 46388  | 46388  | 46388  | 2       |
| getAmount                | 667             | 667    | 667    | 667    | 1       |
| removeLiquidity          | 68852           | 77458  | 77458  | 86065  | 2       |
| reserveToken             | 383             | 783    | 383    | 2383   | 5       |
| reserveWeth              | 339             | 739    | 339    | 2339   | 5       |
| swap                     | 76260           | 76324  | 76324  | 76388  | 2       |
| token                    | 2447            | 2447   | 2447   | 2447   | 1       |
| weth                     | 2404            | 2404   | 2404   | 2404   | 1       |


| src/SimpleToken.sol:SimpleToken contract |                 |       |        |       |         |
|------------------------------------------|-----------------|-------|--------|-------|---------|
| Deployment Cost                          | Deployment Size |       |        |       |         |
| 580219                                   | 3121            |       |        |       |         |
| Function Name                            | min             | avg   | median | max   | # calls |
| approve                                  | 46371           | 46380 | 46383  | 46383 | 8       |
| balanceOf                                | 562             | 1095  | 562    | 2562  | 15      |
| transfer                                 | 51404           | 51404 | 51404  | 51404 | 20      |


| src/WETH.sol:WETH contract |                 |       |        |       |         |
|----------------------------|-----------------|-------|--------|-------|---------|
| Deployment Cost            | Deployment Size |       |        |       |         |
| 621203                     | 2854            |       |        |       |         |
| Function Name              | min             | avg   | median | max   | # calls |
| approve                    | 46371           | 46371 | 46371  | 46371 | 8       |
| balanceOf                  | 562             | 1095  | 562    | 2562  | 15      |
| deposit                    | 52062           | 60612 | 60612  | 69162 | 20      |




Ran 1 test suite in 36.42ms (11.51ms CPU time): 10 tests passed, 0 failed, 0 skipped
(10 total tests)
```

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Anvil

```shell
$ anvil
```
