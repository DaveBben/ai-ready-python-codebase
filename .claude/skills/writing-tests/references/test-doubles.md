# Test Doubles: Fakes, Mocks, and Contracts

The rule in one line: **double only what you don't control, prefer a fake over
a mock, and keep every fake honest with a contract test.**

- Double external APIs, time and randomness (see `determinism.md`), and the
  network. Never your own classes, the filesystem (`tmp_path`), or usually the
  database (a real engine via testcontainers catches bad queries a mock can't).
- Prefer a shared fake (a small working implementation with state you set up
  and observe, e.g. a `fail_next` attribute and a `charges` list) over per-test
  mock scripts. Reach for `unittest.mock` only for one-off stubs, and assert
  outcomes, not call signatures, unless the call itself *is* the observable
  behavior.
- Don't mock what you don't own: never patch `stripe.Client` or `httpx.get` in
  application tests. Wrap the SDK in a thin adapter you own: a `Protocol` with
  one named method per operation (`get_user`, `create_order`), not a generic
  `request(method, path, body)`. Fake the adapter.

## Contract tests keep the fake honest

The fake and the real adapter must agree, or the fake lies. Run the same
behavioral tests against both through a parametrized fixture, gating the real
one behind `-m integration`:

```python
@pytest.fixture(params=["fake", "real"])
def gateway(request: pytest.FixtureRequest) -> PaymentGateway:
    if request.param == "real":
        pytest.importorskip("stripe")
        return StripeGateway(sandbox_credentials())
    return FakePaymentGateway()
```

When a contract test catches a provider change, update the adapter, fake, and
contract together.

## Getting doubles in

Inject boundaries as `Protocol`-typed parameters. `monkeypatch` is the escape
hatch for code you can't restructure yet (patch where the name is *looked up*,
not where it's defined); monkeypatching your own internals means the code needs
a seam: add the parameter. When testing the adapter itself, stub at the
transport (`respx` for `httpx`, `responses` for `requests`) using the
provider's documented payloads, not what your code expects.
