# Mermaid test file

Put the cursor inside a fenced block below, then:

- `<leader>um` — live browser preview
- `<leader>uM` — inline terminal render (needs `mmdc` + chafa or Kitty)

## Flowchart

```mermaid
flowchart TD
    A[Open this file in Neovim] --> B{Cursor in block?}
    B -->|yes| C["Press leader um"]
    B -->|no| D[Move cursor into fence]
    D --> C
    C --> E[Browser preview]
    E --> F[Edit markdown — preview updates]
```

## Sequence

```mermaid
sequenceDiagram
    participant U as You
    participant N as Neovim
    participant B as Browser

    U->>N: leader um on mermaid block
    N->>B: localhost preview + mermaid.js
    B-->>U: rendered diagram
    U->>N: edit the block
    N->>B: SSE refresh
```

## State

```mermaid
stateDiagram-v2
    [*] --> Idle
    Idle --> Rendering: leader um
    Rendering --> Idle: leader mx / close tab
    Idle --> Inline: leader uM
    Inline --> Idle: scroll away
```
