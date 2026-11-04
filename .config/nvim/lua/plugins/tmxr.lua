return {
  "kryptic-sh/tmxr-navigator.nvim",
  cmd = {
    "TmxrNavigateLeft",
    "TmxrNavigateDown",
    "TmxrNavigateUp",
    "TmxrNavigateRight",
    "TmxrNavigatePrevious",
  },
  keys = {
    { "<c-h>", "<cmd>TmxrNavigateLeft<cr>" },
    { "<c-j>", "<cmd>TmxrNavigateDown<cr>" },
    { "<c-k>", "<cmd>TmxrNavigateUp<cr>" },
    { "<c-l>", "<cmd>TmxrNavigateRight<cr>" },
    { "<c-\\>", "<cmd>TmxrNavigatePrevious<cr>" },
  },
}
