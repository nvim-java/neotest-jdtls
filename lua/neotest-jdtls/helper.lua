local async = require("java-core.utils.async").sync
local JdtlsClient = require("java-core.ls.clients.jdtls-client")

local M = {}

function M.get_lsp_client()
  local clients = vim.lsp.get_active_clients({ name = "jdtls" })

  if #clients < 1 then
    error("Jdtls client not found")
  end

  return clients[1]
end

function M.is_test(file_path, callback)
  async(function()
      vim.print("is test: " .. file_path)
      local uri = vim.uri_from_fname(file_path)
      local is_test_file = JdtlsClient(M.get_lsp_client()):java_project_is_test_file(uri)
      vim.print("res: ", is_test_file)
      callback(is_test_file)
    end)
    .run()
    .catch(function(err)
      vim.print("errorrrrrrr")
    end)
end

return M
