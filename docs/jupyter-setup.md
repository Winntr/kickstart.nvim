# Jupyter Notebook Support Setup

This guide covers completing the setup for Jupyter notebook support in Neovim.

## Prerequisites

### 1. Install Python Dependencies

The Neovim Python venv is already configured at `~/.local/share/nvim/venv`. Install the required packages:

```powershell
# Activate the venv
& "$env:LOCALAPPDATA\nvim-data\venv\Scripts\Activate.ps1"

# Install dependencies
pip install pynvim jupyter_client nbformat jupytext ipykernel
```

### 2. Create a Jupyter Kernel

If you don't already have a kernel, create one from your project's venv or conda env:

```powershell
# From your project's environment
python -m ipykernel install --user --name myproject --display-name "Python (myproject)"

# Or use the nvim venv as a kernel
& "$env:LOCALAPPDATA\nvim-data\venv\Scripts\Activate.ps1"
python -m ipykernel install --user --name nvim --display-name "Python (nvim)"
```

List available kernels:
```powershell
jupyter kernelspec list
```

### 3. Update Remote Plugins

Molten is a "remote plugin" that requires registration. Run in Neovim:

```vim
:UpdateRemotePlugins
```

Then **restart Neovim**.

#### Windows Troubleshooting

If `:UpdateRemotePlugins` fails or molten commands don't work, you may need to manually create the rplugin manifest:

1. Find your python3 provider path:
   ```vim
   :echo g:python3_host_prog
   ```

2. Create/edit `~\AppData\Local\nvim-data\rplugin.vim` with:
   ```vim
   " python3 plugins
   call remote#host#RegisterPlugin('python3', 'C:/Users/trevor.winn/AppData/Local/nvim-data/lazy/molten-nvim/rplugin/python3/molten', [
         \ {'sync': v:false, 'name': 'MoltenInit', 'type': 'command', 'opts': {'nargs': '?'}},
         \ {'sync': v:false, 'name': 'MoltenInfo', 'type': 'command', 'opts': {}},
         \ {'sync': v:false, 'name': 'MoltenEvaluateLine', 'type': 'command', 'opts': {}},
         \ {'sync': v:false, 'name': 'MoltenEvaluateOperator', 'type': 'command', 'opts': {}},
         \ {'sync': v:false, 'name': 'MoltenEvaluateVisual', 'type': 'command', 'opts': {'range': ''}},
         \ {'sync': v:false, 'name': 'MoltenReevaluateCell', 'type': 'command', 'opts': {}},
         \ {'sync': v:false, 'name': 'MoltenDelete', 'type': 'command', 'opts': {}},
         \ {'sync': v:false, 'name': 'MoltenShowOutput', 'type': 'command', 'opts': {}},
         \ {'sync': v:false, 'name': 'MoltenHideOutput', 'type': 'command', 'opts': {}},
         \ {'sync': v:false, 'name': 'MoltenEnterOutput', 'type': 'command', 'opts': {}},
         \ {'sync': v:false, 'name': 'MoltenInterrupt', 'type': 'command', 'opts': {}},
         \ {'sync': v:false, 'name': 'MoltenRestart', 'type': 'command', 'opts': {'bang': v:true}},
         \ {'sync': v:false, 'name': 'MoltenImportOutput', 'type': 'command', 'opts': {}},
         \ {'sync': v:false, 'name': 'MoltenExportOutput', 'type': 'command', 'opts': {'bang': v:true}},
         \ {'sync': v:true, 'name': 'MoltenStatusLineInit', 'type': 'function', 'opts': {}},
         \ {'sync': v:true, 'name': 'MoltenStatusLineKernels', 'type': 'function', 'opts': {}},
        \ ])
   ```

3. Restart Neovim.

## Usage

### Opening Notebooks

Just open any `.ipynb` file. Jupytext automatically converts it to markdown for editing.

### Keymaps

All Jupyter keymaps use `<leader>j` prefix:

| Keymap | Description |
|--------|-------------|
| `<leader>ji` | Initialize/select kernel |
| `<leader>jI` | Show kernel info |
| `<leader>jc` | Run current cell |
| `<leader>jl` | Evaluate current line |
| `<leader>je` | Evaluate operator (motion) |
| `<leader>jv` | Evaluate visual selection |
| `<leader>jr` | Re-evaluate cell |
| `<leader>ja` | Run cell and all above |
| `<leader>jb` | Run cell and all below |
| `<leader>jA` | Run all cells |
| `<leader>jo` | Show/enter output window |
| `<leader>jh` | Hide output |
| `<leader>jd` | Delete cell output |
| `<leader>jx` | Interrupt kernel |
| `<leader>jR` | Restart kernel |
| `<leader>jsi` | Import outputs from .ipynb |
| `<leader>jse` | Export outputs to .ipynb |

### Code Cell Navigation

Use treesitter textobjects to navigate code blocks:

| Keymap | Description |
|--------|-------------|
| `]b` | Jump to next code block |
| `[b` | Jump to previous code block |
| `]B` | Jump to end of next code block |
| `[B` | Jump to end of previous code block |
| `ib` | Select inside code block (visual/operator) |
| `ab` | Select around code block (visual/operator) |
| `<leader>sbl` | Swap code block with next |
| `<leader>sbh` | Swap code block with previous |

### Workflow

1. Open a `.ipynb` file (auto-converted to markdown)
2. Run `:MoltenInit` or `<leader>ji` and select a kernel
3. Navigate to a code cell and run it with `<leader>jc`
4. Output appears as virtual text below the cell
5. Use `<leader>jo` to expand output or enter the output window
6. Save the file to auto-export outputs back to the `.ipynb`

### LSP Features

Quarto + Otter provide LSP features inside code blocks:
- Autocompletion
- Go to definition (`gd`)
- Hover documentation (`K`)
- Diagnostics

## Troubleshooting

### "No kernel found"
- Make sure you have a kernel installed: `jupyter kernelspec list`
- The kernel's Python must have `ipykernel` installed

### Molten commands not found
- Run `:UpdateRemotePlugins` and restart Neovim
- Check `:checkhealth provider` for Python issues

### Outputs not showing
- Check `:MoltenInfo` for kernel status
- Try `:MoltenShowOutput` or `<leader>jo`

### jupytext conversion issues
- Make sure `jupytext` is installed in the nvim venv
- Check if the `.md` file was created alongside the `.ipynb`
