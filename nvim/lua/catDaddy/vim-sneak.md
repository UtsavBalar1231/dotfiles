sneak.vim 👟
================

Jump to any location specified by two characters.

Usage
-----

<a href="http://imgur.com/Jke0mIJ" title="Click to see a short demo"><img src="https://raw.github.com/justinmk/vim-sneak/fluff/assets/readme_diagram.png"></a>

Sneak is invoked with `s` followed by exactly two characters:

    s{char}{char}

* Type `sab` to **move the cursor** immediately to the next instance of the text "ab".
    * Additional matches, if any, are highlighted until the cursor is moved.
* Type `;` to go to the next match (or `s` again, if `s_next` is enabled; see [`:help sneak`](doc/sneak.txt)).
* Type `3;` to skip to the third match from the current position.
* Type `ctrl-o` or ``` `` ``` to go back to the starting point.
    * This is a built-in Vim motion; Sneak adds to Vim's [jumplist](http://vimdoc.sourceforge.net/htmldoc/motion.html#jumplist)
      *only* on `s` invocation—not repeats—so you can
      abandon a trail of `;` or `,` by a single `ctrl-o` or ``` `` ```.
* Type `s<Enter>` at any time to repeat the last Sneak-search.
* Type `S` to search backwards.

Sneak can be limited to a **vertical scope** by prefixing `s` with a [count].

* Type `5sxy` to go immediately to the next instance of "xy" within 5 columns
  of the cursor.

Sneak is invoked with [**operators**](http://vimdoc.sourceforge.net/htmldoc/motion.html#operator)
via `z` (because `s` is taken by surround.vim).

* Type `3dzqt` to delete up to the *third* instance of "qt".
    * Type `.` to repeat the `3dzqt` operation.
    * Type `2.` to repeat twice.
    * Type `d;` to delete up to the next match.
    * Type `4d;` to delete up to the *fourth* next match.
* Type `yszxy]` to [surround] in brackets up to `xy`.
    * Type `.` to repeat the surround operation.
* Type `gUz\}` to upper-case the text from the cursor until the next instance
  of the literal text `\}`
    * Type `.` to repeat the `gUz\}` operation.

