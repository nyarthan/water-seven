# Design It Twice

Use this branch when the interface of a proposed module remains a consequential decision. Your first plausible interface is unlikely to be the best.

## Frame the design problem

State:

- behavior and invariants the module must own;
- facts callers should not need to know;
- dependencies and their categories from [DEEPENING.md](DEEPENING.md);
- performance, ordering, error, and lifecycle constraints; and
- the seam under consideration.

Ground the frame with representative caller examples, not a preferred solution.

## Produce alternatives

Develop at least three materially different interfaces. Vary the design pressure deliberately, for example:

- minimum surface and maximum leverage;
- easiest common-case caller experience;
- flexibility for known heterogeneous callers; or
- adapter placement for remote or external dependencies.

Use independent agents when configured and independence materially improves exploration. Otherwise produce alternatives sequentially and say that they were generated in one context.

For each alternative show:

1. The complete caller-visible interface, including invariants and errors.
2. A representative usage example.
3. Complexity hidden behind the seam.
4. Dependency and adapter strategy.
5. Trade-offs in depth, locality, and migration cost.

## Compare

Compare alternatives using the same constraints. Recommend one, or a deliberate hybrid, and explain what evidence would change the recommendation. Do not implement until the user chooses a direction or the surrounding request already authorizes that phase.
