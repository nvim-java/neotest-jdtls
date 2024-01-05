local nio = require("nio")
local Tree = require("neotest.types.tree").Tree
local helper = require("neotest-jdtls.helper")

local function jdtls()
  local clients = vim.lsp.get_active_clients({ name = "jdtls" })

  if #clients > 1 then
    error("Could not find any running jdtls clients")
  end

  return clients[1]
end

---Executes workspace command on jdtls
---@param cmd_info {command: string, arguments: any }
---@param timeout number?
---@param buffer number?
---@return { err: { code: number, message: string }, result: any }
local function execute_command(cmd_info, timeout, buffer)
  timeout = timeout and timeout or 5000
  buffer = buffer and buffer or 0

  return jdtls().request_sync("workspace/executeCommand", cmd_info, timeout, buffer)
end

local neotest = {}

---@type neotest.Adapter
neotest.Adapter = {
  name = "neotest-java",
}

---Find the project root directory given a current directory to work from.
---Should no root be found, the adapter can still be used in a non-project context if a test file matches.
---@async
---@param dir string @Directory to treat as cwd
---@return string | nil @Absolute root dir of test suite
---@diagnostic disable-next-line: unused-local
function neotest.Adapter.root(dir)
  vim.print("root" .. dir)
  return jdtls().config.root_dir
end

---Filter directories when searching for test files
---@async
---@param name string Name of directory
---@param rel_path string Path to directory, relative to root
---@param root string Root directory of project
---@return boolean
function neotest.Adapter.filter_dir(name, rel_path, root)
  -- local f = vim.tbl_contains({ "src/test", "src" }, rel_path)
  vim.print("filter_dir " .. rel_path .. "/" .. name)
  return true
end

local is_test = nio.wrap(helper.is_test, 2)

---@async
---@param file_path string
---@return boolean
function neotest.Adapter.is_test_file(file_path)
  vim.print("*** " .. file_path)
  local err, is_test_file = is_test(file_path)
  vim.print(err, is_test_file)
  return is_test_file
end

---Given a file path, parse all the tests within it.
---@async
---@param file_path string Absolute file path
---@return neotest.Tree | nil
function neotest.Adapter.discover_positions(file_path)
  vim.print("discover_position" .. file_path)

  local uri = vim.uri_from_fname(file_path)

  ---@type java-core.TestDetailsWithChildrenAndRange[]
  local test_info = execute_command({
    command = "vscode.java.test.findTestTypesAndMethods",
    arguments = { uri },
  })

  test_info = test_info[1]

  ---@type neotest.Tree
  local parent_node = Tree:new(test_info, nil, test_info.fullName, nil, nil)

  for _, test in ipairs(test_info.children) do
    Tree:new(test, nil, test.fullName, parent_node, nil)
  end

  vim.print(parent_node)
  return parent_node
end

---@param args neotest.RunArgs
---@return nil | neotest.RunSpec | neotest.RunSpec[]
function neotest.Adapter.build_spec(args)
  vim.print(args)
  return nil
end

---@async
---@param spec neotest.RunSpec
---@param result neotest.StrategyResult
---@param tree neotest.Tree
---@return table<string, neotest.Result>
function neotest.Adapter.results(spec, result, tree)
  vim.print("results")
end

return function(_, opts)
  return neotest.Adapter
end
