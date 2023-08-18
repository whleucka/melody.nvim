local actions = require "telescope.actions"
local finders = require "telescope.finders"
local pickers = require "telescope.pickers"
local conf = require("telescope.config").values
local action_state = require "telescope.actions.state"
local settings = require("settings")

local M = {}

-- Is empty?
local function is_empty(s)
  return s == nil or s == ''
end

-- Setup opts
function M.setup(opts)
	opts = opts or {}
	local options = vim.tbl_deep_extend("force", settings.options, opts)
	settings.options = options
end

-- Music searching
function M.music_search()
	if is_empty(settings.options.music_dir) then
		error("music_dir is not set")
	end

	local pattern = "*.mp3"
	local cmd = string.format("find %s -name '%s'", settings.options.music_dir, pattern)

	-- execute the find command and capture the output
	local output = io.popen(cmd):read("*a")

	-- process the output into a Lua table
	local tracks = {}
	for file_name in output:gmatch("[^\n]+") do
    table.insert(tracks, file_name)
	end

	-- print the table contents
	-- for i, fileName in ipairs(tracks) do
 --    print(i, fileName)
	-- end

  -- create the telescope picker and display the results
  pickers
    .new({}, {
      prompt_title = "select a track",
      finder = finders.new_table {
        results = tracks,
        entry_maker = function(track)
          return {
            display = track,
            ordinal = track,
            value = track,
          }
        end,
      },
      sorter = conf.generic_sorter {},
      attach_mappings = function(prompt_bufnr, map)
        local play_track = function()
          if vim.fn.executable('mpv') ~= 1 then
		        error("mpv is not installed.")
	        end
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          if selection then
      			vim.notify("now playing: " .. selection.display)
      			local mpv_command = string.format("mpv --no-config --vo=tct --really-quiet --profile=sw-fast %q", selection.value)
      			require("toggleterm").exec(mpv_command, nil, nil, "", "vertical")
					end
        end

        -- map a key to play the selected track
        map("i", "<cr>", play_track)
        map("n", "<cr>", play_track)

        return true
      end,
    })
    :find()
end

return M
