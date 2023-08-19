local actions = require("telescope.actions")
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local conf = require("telescope.config").values
local action_state = require("telescope.actions.state")
local settings = require("settings")

local M = {}

-- Is empty?
local function is_empty(s)
	return s == nil or s == ""
end

-- Good old path exists function
local function path_exists(path)
	local ok, err, code = os.rename(path, path)
	if not ok then
		if code == 13 then
			-- Permission denied, but it exists
			return true
		end
	end
	return ok, err
end

-- ID3 tag reader adapted from:
--- https://gist.github.com/mkottman/1162235/481e3cba04d74460102d5c1f8f82aaa9fad9223d
local function unpad(str)
	return (str:gsub("[%s%z]+$", ""))
end
--- Read ID3 tags from MP3 file.
-- @param file Either string (filename) or file opened by io.open()
-- @return Table containing the following info:
local function readtags(file)
	if type(file) == "string" then
		file = assert(io.open(file, "rb"))
	elseif type(file) ~= "userdata" then
		error("Expecting file or filename as #1, not " .. type(file), 2)
	end

	local position = file:seek()

	local function readStr(len)
		local str = assert(file:read(len), "Could not read " .. len .. "-byte string.")
		return unpad(str)
	end

	local function readByte()
		local byte = assert(file:read(1), "Could not read byte.")
		return string.byte(byte)
	end

	-- TODO: try ID3v2 first

	-- try ID3v1
	file:seek("end", -128)
	local header = file:read(3)
	if header == "TAG" then
		local info = {}
		info.title = readStr(30)
		info.artist = readStr(30)
		info.album = readStr(30)
		info.year = readStr(4)
		info.comment = readStr(28)
		local zero = readByte()
		local track = readByte()
		local genre = readByte()
		if zero == 0 then
			info.track = track
			info.genre = genre
		else
			info.comment = unpad(info.comment .. string.char(zero, track, genre))
		end
		-- TODO: extended ID3v1 header

		file:seek("set", position)
		return info
	end
end

-- Setup opts
function M.setup(opts)
	opts = opts or {}
	local options = vim.tbl_deep_extend("force", settings.options, opts)
	settings.options = options
end

-- Music searching
function M.music_search()
	local music_dir = settings.options.music_dir
	if is_empty(music_dir) or not path_exists(music_dir) then
		error("music_dir is not set, check config")
	end

	local pattern = "*.mp3"
	local cmd = string.format("find %s -name '%s'", music_dir, pattern)

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
				finder = finders.new_table({
					results = tracks,
					entry_maker = function(track)
						local tag = readtags(track) or {}
						local display = string.format("%s - %s; %s [%s]", tag.artist, tag.title, tag.album, tag.year)
						if tag.artist == nil then
							display = track
						end
						return {
							display = display,
							ordinal = track,
							value = track,
						}
					end,
				}),
				sorter = conf.generic_sorter({}),
				attach_mappings = function(prompt_bufnr, map)
					local play_track = function()
						if vim.fn.executable("mpv") ~= 1 then
							error("mpv is not installed.")
						end
						local selection = action_state.get_selected_entry()
						actions.close(prompt_bufnr)
						if selection then
							vim.notify("now playing: " .. selection.display)
							local mpv_command = string.format(
								"mpv --no-config --vo=tct --really-quiet --profile=sw-fast %q",
								selection.value
							)
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
