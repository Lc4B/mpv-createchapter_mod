local utils = require("mp.utils")
local msg = require ("mp.msg")
local options = require ("mp.options")

local o = {
    -- Specifies the name of the chapters
	chapter_name = "Chapter_",
	-- Starting time of chapter 00
	time_start = "00:00:00.000",
	-- Specifies the language of the chapters
	chapter_language = "eng",
	-- Specifies IETF (standardized tag to identify languages)
	language_IETF = "en",
	-- MKV time format (nanosecond filling)
	matroska_format = false,
	-- Adds the suffix to the export file
	file_name = "_chapters",
	-- Specifies the path to MKVToolNix (if tools isn't in the same folder)
	mkvtoolnix = "",
	-- Sets keybinds for functions
	create_keybind = "C",
	remove_keybind = "X",
	write_keybind = "B",
	insert_keybind = "N",
}

options.read_options(o)

local function create_chapter()
    local time_pos = mp.get_property_number("time-pos")
    local time_pos_osd = mp.get_property_osd("time-pos/full")
    local curr_chapter = mp.get_property_number("chapter")
    local chapter_count = mp.get_property_number("chapter-list/count")
    local all_chapters = mp.get_property_native("chapter-list")
    mp.osd_message(time_pos_osd, 1)

    if chapter_count == 0 then
        all_chapters[1] = {
            title = o.chapter_name.."01",
            time = time_pos
        }
        -- We just set it to zero here so when we add 1 later it ends up as 1
        -- otherwise it's probably "nil"
        curr_chapter = 0
        -- note that mpv will treat the beginning of the file as all_chapters[0] when using pageup/pagedown
        -- so we don't actually have to worry if the file doesn't start with a chapter
    else
        -- to insert a chapter we have to increase the index on all subsequent chapters
        -- otherwise we'll end up with duplicate chapter IDs which will confuse mpv
        -- +2 looks weird, but remember mpv indexes at 0 and lua indexes at 1
        -- adding two will turn "current chapter" from mpv notation into "next chapter" from lua's notation
        -- count down because these areas of memory overlap
        for i = chapter_count, curr_chapter + 2, -1 do
            all_chapters[i + 1] = all_chapters[i]
        end
        all_chapters[curr_chapter+2] = {
            title = o.chapter_name..string.format("%02.f", curr_chapter+2),
            time = time_pos
        }
    end
    mp.set_property_native("chapter-list", all_chapters)
    mp.set_property_number("chapter", curr_chapter+1)
end

local function remove_chapter()
    local chapter_count = mp.get_property_number("chapter-list/count")

    if chapter_count < 1 then
        msg.verbose("No chapters to remove")
        return
    end

    local all_chapters = mp.get_property_native("chapter-list")
    -- +1 because mpv indexes from 0, lua from 1
    local curr_chapter = mp.get_property_number("chapter") + 1

    table.remove(all_chapters, curr_chapter)
    msg.debug("Removing chapter", curr_chapter)

    mp.set_property_native("chapter-list", all_chapters)
end

local function format_time(seconds)
    local result = ""
    if seconds <= 0 then
        return "00:00:00.000";
    else
        hours = string.format("%02.f", math.floor(seconds/3600))
        mins = string.format("%02.f", math.floor(seconds/60 - (hours*60)))
        secs = string.format("%02.f", math.floor(seconds - hours*60*60 - mins*60))
        msecs = string.format("%03.f", seconds*1000 - hours*60*60*1000 - mins*60*1000 - secs*1000)
        result = hours..":"..mins..":"..secs.."."..msecs
    end
    return result
end

local function write_chapters()
    local euid = mp.get_property_number("estimated-frame-count")
    local chapter_count = mp.get_property_number("chapter-list/count")
    local all_chapters = mp.get_property_native("chapter-list")
    local insert_chapters = ""
    local curr = nil
	local mkv_time = ""
	
    if chapter_count == 0 then
        msg.debug("No chapters to write")
        return
    end
	
	if o.matroska_format then
		mkv_time = "000000"
	end

    for i = 1, chapter_count, 1 do
        curr = all_chapters[i]
        local time_pos = format_time(curr.time)

        if i == 1 and curr.time ~= 0 then
            local first_chapter="    <ChapterAtom>\n      <ChapterUID>"..math.random(1000, 9000).."</ChapterUID>\n      <ChapterTimeStart>"..o.time_start..mkv_time.."</ChapterTimeStart>\n      <ChapterFlagHidden>0</ChapterFlagHidden>\n      <ChapterFlagEnabled>1</ChapterFlagEnabled>\n      <ChapterDisplay>\n        <ChapterString>"..o.chapter_name.."00</ChapterString>\n        <ChapterLanguage>"..o.chapter_language.."</ChapterLanguage>\n        <ChapLanguageIETF>"..o.language_IETF.."</ChapLanguageIETF>\n      </ChapterDisplay>\n    </ChapterAtom>\n"
            insert_chapters = insert_chapters..first_chapter
        end

        local next_chapter="    <ChapterAtom>\n      <ChapterUID>"..math.random(1000, 9000).."</ChapterUID>\n      <ChapterTimeStart>"..time_pos..mkv_time.."</ChapterTimeStart>\n      <ChapterFlagHidden>0</ChapterFlagHidden>\n      <ChapterFlagEnabled>1</ChapterFlagEnabled>\n      <ChapterDisplay>\n        <ChapterString>"..curr.title.."</ChapterString>\n        <ChapterLanguage>"..o.chapter_language.."</ChapterLanguage>\n        <ChapLanguageIETF>"..o.language_IETF.."</ChapLanguageIETF>\n      </ChapterDisplay>\n    </ChapterAtom>\n"
        insert_chapters = insert_chapters..next_chapter
    end

    local chapters="<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n\n<Chapters>\n  <EditionEntry>\n    <EditionUID>"..euid.."</EditionUID>\n    <EditionFlagHidden>0</EditionFlagHidden>\n    <EditionFlagDefault>0</EditionFlagDefault>\n"..insert_chapters.."  </EditionEntry>\n</Chapters>"

    local path = mp.get_property("path")
    dir, name_ext = utils.split_path(path)
    local name = string.sub(name_ext, 1, (string.len(name_ext)-4))
    local out_path = utils.join_path(dir, name..o.file_name..".xml")
    local file = io.open(out_path, "w")
    if file == nil then
        dir = utils.getcwd()
        out_path = utils.join_path(dir, "create_chapter.xml")
        file = io.open(out_path, "w")
    end
    if file == nil then
        mp.error("Could not open chapter file for writing")
        return
    end
    file:write(chapters)
    file:close()
    mp.osd_message("Export file to: "..out_path, 3)
	chapters_file = out_path
end

local function insert_matroska()
	local mkvpropedit = "mkvpropedit"
	
    if mp.get_property_number("chapter-list/count") == 0 then
        msg.verbose("No chapters present")
        return
    end

    if not chapters_file then
        msg.error("No chapters file")
        return
    end

    local filename = mp.get_property("filename")

    -- check file extension
    local reverse_dot_index = filename:reverse():find(".", 1, true)
    if reverse_dot_index == nil then
        msg.warning("File has no extension")
		return
    else
        local dot_index = #filename + 1 - reverse_dot_index
        local ext = filename:sub(dot_index + 1)
        msg.debug("ext:", ext)
        if ext ~= "mkv" then
            msg.error("File is not mkv")
			return
        end
    end

    local video_file = mp.get_property("path")
	if o.mkvtoolnix ~= "" then
		mkvpropedit = o.mkvtoolnix.."\\mkvpropedit"
	end

	local args = {mkvpropedit, "--chapters", chapters_file, video_file}

    msg.debug("args:", utils.to_string(args))

    local process = mp.command_native({
        name = 'subprocess',
        playback_only = false,
        capture_stdout = true,
        capture_stderr = true,
        args = args
    })

    if process.status == 0 then
        mp.osd_message("File written to " .. video_file, 3)
    else
        msg.error("Failed to write file:\n", process.stderr)
    end
end

local function glb_var(event)
	chapters_file = nil
end

mp.register_event("end-file", glb_var)

mp.add_key_binding(o.create_keybind, "create_chapter", create_chapter, {repeatable=true})
mp.add_key_binding(o.remove_keybind, "remove_chapter", remove_chapter, {repeatable=true})
mp.add_key_binding(o.write_keybind, "write_chapters", write_chapters, {repeatable=false})
mp.add_key_binding(o.insert_keybind, "insert_matroska", insert_matroska, {repeatable=false})
