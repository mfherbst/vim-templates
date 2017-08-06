" Project : vim-templates
" Author  : vikash
" Created : 27/11/2016
" License : MIT

if exists('g:vt_plugin_loaded')
    finish
endif

let g:vt_plugin_loaded = 1

if !exists('g:tmpl_auto_initialize')
    let g:tmpl_auto_initialize = 1
endif

" Templates
" TIMESTAMP:    DAY, DAY_FULL, DATE, MONTH, MONTH_SHORT, MONTH_FULL,
"               YEAR, TODAY, TIME, TIME_12, TIMESTAMP
" AUTHOR:       NAME, HOSTNAME, EMAIL
" FILE:         FILE, FILEE, FILEF, FILER
" PROJECT:      PROJECT
" COMPANY:      COMAPNY
" CURSOR:       CURSOR
" LICENSE:      LICENSE, LICENSE_FILE, COPYRIGHT
" LANGUAGES:    MACRO_GUARD, MACRO_GUARD_FULL, CLASS

function <SID>EscapeTemplate(tmpl)
    return escape(a:tmpl, '/')
endfunction

function <SID>ExpandTemplate(tmpl, value)
    silent! execute '%s/{{'. <SID>EscapeTemplate(a:tmpl) .'}}/'. <SID>EscapeTemplate(a:value) .'/gI'
endfunction

function <SID>PrepareMacro(str)
    return toupper(tr(a:str, '/.-', '___'))
endfunction

function <SID>ExpandTimestampTemplates()
    let l:day               = strftime('%a')
    let l:day_full          = strftime('%A')
    let l:date              = strftime('%d')
    let l:month             = strftime('%m')
    let l:month_short       = strftime('%b')
    let l:month_full        = strftime('%B')
    let l:year              = strftime('%Y')
    let l:today             = strftime('%d/%m/%Y')
    let l:time              = strftime('%T %Z')
    let l:time_12           = strftime('%r')
    let l:timestamp         = strftime('%A %b %d, %Y %T %Z')

    call <SID>ExpandTemplate('DAY', l:day)
    call <SID>ExpandTemplate('DAY_FULL', l:day_full)
    call <SID>ExpandTemplate('DATE', l:date)
    call <SID>ExpandTemplate('MONTH', l:month)
    call <SID>ExpandTemplate('MONTH_SHORT', l:month_short)
    call <SID>ExpandTemplate('MONTH_FULL', l:month_full)
    call <SID>ExpandTemplate('YEAR', l:year)
    call <SID>ExpandTemplate('TODAY', l:today)
    call <SID>ExpandTemplate('TIME', l:time)
    call <SID>ExpandTemplate('TIME_12', l:time_12)
    call <SID>ExpandTemplate('TIMESTAMP', l:timestamp)
endfunction

function <SID>ExpandAuthoringTemplates()

    let l:author_name = exists('g:tmpl_author_name') ? g:tmpl_author_name : expand('$USER')
    let l:author_hostname = exists('g:tmpl_author_hostname') ? g:tmpl_author_name : expand('$HOSTNAME')
    let l:author_email = exists('g:tmpl_author_email') ? g:tmpl_author_email :
                \ expand('$USER') .'@'. expand('$HOSTNAME')

    call <SID>ExpandTemplate('NAME', l:author_name)
    call <SID>ExpandTemplate('HOSTNAME', l:author_hostname)
    call <SID>ExpandTemplate('EMAIL', l:author_email)
endfunction

function <SID>ExpandFilePathTemplates()
    call <SID>ExpandTemplate('FILE', expand('%:t:r'))
    call <SID>ExpandTemplate('FILEE', expand('%:t'))
    call <SID>ExpandTemplate('FILEF', expand('%:p'))
    call <SID>ExpandTemplate('FILER', @%)
endfunction

function <SID>ExpandOtherTemplates()
    if (exists('g:tmpl_project'))
        call <SID>ExpandTemplate('PROJECT', g:tmpl_project)
    endif
    if (exists('g:tmpl_company'))
        call <SID>ExpandTemplate('COMPANY', g:tmpl_company)
    endif
endfunction

function <SID>ExpandLicenseFile()
    normal gg " go to first line
    " serach for LICENSE_FILE
    if !(search('{{LICENSE_FILE}}', 'W'))
        return
    endif

    let l:lineno = line('.')
    let l:colno = col('.')
    s/{{LICENSE_FILE}}// " remove license file
    call cursor(l:lineno, l:colno)

    " Expand lincense file
    " Read license file contents
    let l:license_files = [
                \ 'LICENSE',
                \ 'LICENSE.txt',
                \ 'LICENSE.md',
                \ 'license.txt',
                \ 'license.md']
    if (exists('g:tmpl_license_file'))
        let l:file_name = fnameescape(g:tmpl_license_file)
        if (filereadable(l:file_name))
            let l:license_file = expand(l:file_name)
        else
            echom 'file '.l:file_name.' does not exist or cannot be read'
        endif
    else
        for l:file in l:license_files
            let l:file_name = fnameescape(l:file)
            if (filereadable(l:file_name))
                let l:license_file = expand(l:file_name)
                break
            endif
        endfor
    endif

    if exists('l:license_file')
        " if license file is found then read it's content starting from next
        " line
        " expand path before reading it
        execute 'r '. expand(l:license_file)
    endif
endfunction

function <SID>ExpandLicenseTemplates()
    let l:license = exists('g:tmpl_license') ? g:tmpl_license : 'MIT'

    let l:company = exists('g:tmpl_company') ? g:tmpl_company : ''
    let l:copyright = exists('g:tmpl_copyright') ? g:tmpl_copyright : 'Copyright (c) '.l:company

    call <SID>ExpandTemplate('LICENSE', l:license)
    call <SID>ExpandTemplate('COPYRIGHT', l:copyright)

    call <SID>ExpandLicenseFile()


endfunction

function <SID>ExpandLanguageTemplates()
    let l:macro_guard = <SID>PrepareMacro(expand('%:t'))
    let l:macro_guard_full = <SID>PrepareMacro(@%)
    let l:filename = expand("%:t:r")

    call <SID>ExpandTemplate('MACRO_GUARD', l:macro_guard)
    call <SID>ExpandTemplate('MACRO_GUARD_FULL', l:macro_guard_full)
    call <SID>ExpandTemplate('CLASS', l:filename)

    if (exists('g:tmpl_namespace'))
        call <SID>ExpandTemplate('NAMESPACE', g:tmpl_namespace)
    endif
endfunction

function <SID>MoveCursor()
    normal gg " go to first line
    " serach for cursor if it is found then move cursor there
    if (search('{{CURSOR}}', 'W'))
        let l:lineno = line('.')
        let l:colno = col('.')
        s/{{CURSOR}}// " remove cursor
        call cursor(l:lineno, l:colno)
        return 1
    endif
    return 0
endfunction

" Expand all templates present in current file
function <SID>ExpandAllTemplates()
    normal mm " mark the current position so that we can return to it if cursor is not found

    call <SID>ExpandTimestampTemplates()
    call <SID>ExpandAuthoringTemplates()
    call <SID>ExpandFilePathTemplates()
    call <SID>ExpandOtherTemplates()
    call <SID>ExpandLicenseTemplates()
    call <SID>ExpandLanguageTemplates()

    let l:cursor_found = <SID>MoveCursor()

    if !l:cursor_found
        normal `m " return to old cursor position
    endif
endfunction

" If the settings file exits in the template directory, then
" it is read before expanding the templates. This can be used
" to populate the tmpl_ ... variables with values specific to
" a project or subtree
let s:settings_file = "tmpl_settings.vim"

" Try read a default varibles file if it exists
function <SID>TryReadSettings(template_path)
    let l:var_path = fnameescape(a:template_path.'/'.s:settings_file)
    if (filereadable(l:var_path))
        for line in readfile(l:var_path)
            " Ignore lines that do not actually set our
            " variables (for security reasons)
            if line =~ '^let g:tmpl_'
                execute l:line
            endif
        endfor
    endif
endfunction

" Initialize template from given template search path
function <SID>InitializeTemplateForExtension(extension, template_path)
    let l:template_path = fnameescape(a:template_path.'/'.a:extension.'.template')
    if (filereadable(l:template_path))
        call <SID>TryReadSettings(a:template_path)
        execute 'silent 0r '.l:template_path
        return 1
    endif
    return 0
endfunction


" get default template directory
let s:default_template_directory = expand('<sfile>:p:h:h') . '/templates'

" Insert content of template file for current file into the buffer and expand
" all templates
" @param a:ext extension of current file or empty, in which case extension
" will be automatically detected
function <SID>InitializeTemplate(...)
    " The directory containing the file we want to initialize
    let l:thisdir = expand('%:p:h')

    " Find all 'templates' directories from the directory containing
    " this file upwards.
    let l:tmpl_paths = finddir("templates", l:thisdir . ';',-1)

    " user defined search paths
    if (!exists('g:tmpl_search_paths'))
        let g:tmpl_search_paths = []
    endif
    for l:path in g:tmpl_search_paths
        let l:tmpl_paths = add(l:tmpl_paths, expand(l:path))
    endfor

    " default template path
    let l:tmpl_paths = add(l:tmpl_paths, s:default_template_directory)

    " get extension of file
    if (a:0 == 0)
        let l:extension = expand('%:e')
    else
        let l:extension = a:1
    endif

    for l:path in l:tmpl_paths
        let l:initialized = <SID>InitializeTemplateForExtension(l:extension, l:path)
        if (l:initialized)
            call <SID>ExpandAllTemplates()
            break
        endif
    endfor
endfunction

" Automatically initialze file from template when a new file is created
function <SID>AutoInitializeTemplate()
    if (exists('g:tmpl_auto_initialize') && g:tmpl_auto_initialize == 1)
        call <SID>InitializeTemplate()
    endif
endfunction


" Autogroup commands
au BufNewFile *.* TemplateAutoInit
" Define commands
command -nargs=0 TemplateExpand         :call <SID>ExpandAllTemplates()
command -nargs=? TemplateInit           :call <SID>InitializeTemplate(<f-args>)
command -nargs=0 TemplateAutoInit       :call <SID>AutoInitializeTemplate()
