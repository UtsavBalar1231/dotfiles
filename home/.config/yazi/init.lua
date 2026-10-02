require("smart-enter"):setup {
	open_multi = true,
}

require("full-border"):setup()

require("git"):setup {
	order = 1500,
}

require("what-size"):setup {
	priority = 400,
	LEFT = "",
	RIGHT = " ",
}

require("copy-file-contents"):setup {
	append_char = "\n",
	notification = true,
}

require("mime-ext.local"):setup {
	fallback_file1 = true,
}
