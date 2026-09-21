# Durable tests

A durable test describes observable behavior through a public interface and survives internal restructuring.

```typescript
test("a valid cart can be checked out", async () => {
  const cart = createCart([{ price: 10 }, { price: 5 }]);

  const result = await checkout(cart, approvedPayment);

  expect(result.status).toBe("confirmed");
  expect(result.total).toBe(15);
});
```

Common failure modes:

- **Implementation coupling:** asserting private calls, call counts, or internal state when an outcome is available.
- **Tautology:** computing the expected value with the same algorithm as the code under test.
- **Side-channel verification:** bypassing the public interface to inspect storage when the capability can be observed through that interface.
- **Oversized setup:** one test creates a whole system to verify a narrow rule, hiding the actual behavior under fixtures.
- **Insensitive success:** the test remains green when the intended behavior is deliberately broken.

A test's value is demonstrated by its red state. Before trusting it, make the relevant implementation absent or wrong and observe the expected failure.
