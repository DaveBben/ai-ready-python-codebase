# Test Data: Builders, Fixtures, Parametrize

A test shows only the values driving its assertion; everything else is a
visible-by-omission default.

## Builders: the default tool for domain objects

A builder is a typed function with valid defaults and keyword-only overrides:

```python
def build_order(*, total: Money = Money("20.00"), customer: Customer | None = None) -> Order:
    return Order(id=OrderId("ord_test"), total=total, customer=customer or build_customer())

def test_orders_over_100_ship_free() -> None:
    assert shipping_cost(build_order(total=Money("150.00"))) == Money("0.00")
```

- Defaults are *valid and boring*; a test needing an interesting value states
  it explicitly.
- Keyword-only arguments (`*,`), so call sites are self-labeling.
- Builders compose (`build_order(customer=build_customer(tier="vip"))`).
- Put them in `tests/builders.py`; plain functions, no pytest machinery.
- Skip `factory-boy` unless models are numerous and relational: plain functions
  stay typed and mypy-strict-friendly. Seed `faker` for bulk data; unseeded,
  it's a flake generator.

## Fixtures: for wiring and resources, not data

Reserve `@pytest.fixture` for things with a lifecycle or real cost: containers,
fake gateways, a configured app. Data objects come from builders inside the
test, visible to the reader.

- A fixture used by one module belongs in that module, not root `conftest.py`.
  Avoid chains more than two deep and fixtures that mutate other fixtures.
- Scope `function` by default; widen only for expensive read-only resources.
  Avoid `autouse=True` except for suite-wide guardrails (blocking sockets):
  it's setup the reader can't see.

## Parametrize

Parametrize when the *behavior* is one sentence and the cases form a table;
use `pytest.param(..., id="at_threshold")` so failures name themselves. Don't
parametrize different behaviors into one test: a case with its own setup or
assertion shape gets its own test. Twenty edge cases in one table often means
a Hypothesis property would cover the space better.

## Assertion hygiene

- Assert the field that matters, not the whole object, unless the shape *is*
  the contract; then assert it whole against a literal.
- Exceptions: pin the message, not just the type
  (`pytest.raises(ConfigurationError, match="missing STRIPE_KEY")`); a
  type-only check passes on the wrong error path.

## Snapshot tests: rarely, and only on contracts

Valuable in two cases only: a serialized payload that *is* a public contract,
or legacy code characterized before a refactor. Elsewhere it decays into
"approve whatever changed." If you snapshot, use `inline-snapshot` so the
expected value sits in the test; read the first one fully before approving it
(the code under test generated it), and scrutinize any update diff like a code
diff.
