-- Java buffer options.
-- jdtls derives the formatter's tabulation.char/tabulation.size from these
-- buffer options (insertSpaces/tabSize in the LSP format request), so they
-- must agree with the Eclipse profile in formatting/eclipse-java-style.xml.
vim.bo.expandtab = true
vim.bo.shiftwidth = 2
vim.bo.softtabstop = 2
