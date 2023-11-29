ENTRY(_start)

PHDRS {
    text PT_LOAD FILEHDR AT (0x400000) FLAGS (7) ;
}

SECTIONS {
    . = 0x400000 + SIZEOF_HEADERS;
    .text :  { * (.text) } :text
    .data : { * (.data) } :text
}
