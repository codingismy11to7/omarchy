Name = "omarchyBackgroundSelector"
NamePretty = "Omarchy Background Selector"
Cache = false
HideFromProviderlist = true
SearchName = true

local function ShellEscape(s)
  return "'" .. s:gsub("'", "'\\''") .. "'"
end

function FormatName(filename)
  -- Remove leading number and dash
  local name = filename:gsub("^%d+", ""):gsub("^%-", "")
  -- Remove extension
  name = name:gsub("%.[^%.]+$", "")
  -- Replace dashes with spaces
  name = name:gsub("-", " ")
  -- Capitalize each word
  name = name:gsub("%S+", function(word)
    return word:sub(1, 1):upper() .. word:sub(2):lower()
  end)
  return name
end

function GetEntries()
  local entries = {}
  local home = os.getenv("HOME")

  -- Directories to search
  local dirs = {
    "@backgroundsDir@",
    home .. "/.config/omarchy/backgrounds/@theme@",
  }

  -- Track added files to avoid duplicates
  local seen = {}

  for _, wallpaper_dir in ipairs(dirs) do
    local handle = io.popen(
      "find " .. ShellEscape(wallpaper_dir)
        .. " -maxdepth 1 -type f \\( -name '*.jpg' -o -name '*.jpeg' -o -name '*.png' -o -name '*.gif' -o -name '*.bmp' -o -name '*.webp' \\) 2>/dev/null | sort"
    )
    if handle then
      for background in handle:lines() do
        local filename = background:match("([^/]+)$")
        if filename and not seen[filename] then
          seen[filename] = true
          table.insert(entries, {
            Text = FormatName(filename),
            Value = background,
            Actions = {
              activate = "omarchy-theme-bg-set " .. ShellEscape(background),
            },
            Preview = background,
            PreviewType = "file",
          })
        end
      end
      handle:close()
    end
  end

  return entries
end
