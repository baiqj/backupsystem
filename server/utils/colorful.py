#!/usr/bin/env python

havecolor = True

_esc_seq = '\x1b['
_codes = {
	'reset': _esc_seq + '39;49;00m',
	'bold': _esc_seq + '01m',
	'faint': _esc_seq + '02m',
	'standout': _esc_seq + '03m',
	'underline': _esc_seq + '04m',
	'blink': _esc_seq + '05m',
	'overline': _esc_seq + '06m',
	'reverse': _esc_seq + '07m',
}

_ansi_color_codes = []
for x in xrange(30, 38):
	_ansi_color_codes.append('%im' % x)
	_ansi_color_codes.append('%i;01m' % x)

_rgb_ansi_colors = ['0x000000', '0x555555', '0xAA0000', '0xFF5555', '0x00AA00',
	'0x55FF55', '0xAA5500', '0xFFFF55', '0x0000AA', '0x5555FF', '0xAA00AA',
	'0xFF55FF', '0x00AAAA', '0x55FFFF', '0xAAAAAA', '0xFFFFFF']

for x in xrange(len(_rgb_ansi_colors)):
	_codes[_rgb_ansi_colors[x]] = _esc_seq + _ansi_color_codes[x]

del x

_codes['black']     = _codes['0x000000']
_codes['darkgray']  = _codes['0x555555']

_codes['red']       = _codes['0xFF5555']
_codes['darkred']   = _codes['0xAA0000']

_codes['green']     = _codes['0x55FF55']
_codes['darkgreen'] = _codes['0x00AA00']

_codes['yellow']    = _codes['0xFFFF55']
_codes['brown']     = _codes['0xAA5500']

_codes['blue']      = _codes['0x5555FF']
_codes['darkblue']  = _codes['0x0000AA']

_codes['fuchsia']   = _codes['0xFF55FF']
_codes['purple']    = _codes['0xAA00AA']

_codes['turquoise'] = _codes['0x55FFFF']
_codes['teal']      = _codes['0x00AAAA']

_codes['white']     = _codes['0xFFFFFF']
_codes['lightgray'] = _codes['0xAAAAAA']

_codes['darkteal']   = _codes['turquoise']
# Some terminals have darkyellow instead of brown.
_codes['0xAAAA00']   = _codes['brown']
_codes['darkyellow'] = _codes['0xAAAA00']

_codes['bg_black']      = _esc_seq + '40m'
_codes['bg_darkred']    = _esc_seq + '41m'
_codes['bg_darkgreen']  = _esc_seq + '42m'
_codes['bg_brown']      = _esc_seq + '43m'
_codes['bg_darkblue']   = _esc_seq + '44m'
_codes['bg_purple']     = _esc_seq + '45m'
_codes['bg_teal']       = _esc_seq + '46m'
_codes['bg_lightgray']  = _esc_seq + '47m'

_codes['bg_darkyellow'] = _codes['bg_brown']

# Colors from /etc/init.d/functions.sh
_codes['NORMAL']     = _esc_seq + '0m'
_codes['GOOD']       = _codes['green']
_codes['WARN']       = _codes['yellow']
_codes['BAD']        = _codes['red']
_codes['HILITE']     = _codes['teal']
_codes['BRACKET']    = _codes['blue']

# Portage functions
_codes['INFORM']                  = _codes['darkgreen']
_codes['UNMERGE_WARN']            = _codes['red']
_codes['SECURITY_WARN']           = _codes['red']
_codes['MERGE_LIST_PROGRESS']     = _codes['yellow']
_codes['PKG_BLOCKER']             = _codes['red']
_codes['PKG_BLOCKER_SATISFIED']   = _codes['darkblue']
_codes['PKG_MERGE']               = _codes['darkgreen']
_codes['PKG_MERGE_SYSTEM']        = _codes['darkgreen']
_codes['PKG_MERGE_WORLD']         = _codes['green']
_codes['PKG_UNINSTALL']           = _codes['red']
_codes['PKG_NOMERGE']             = _codes['darkblue']
_codes['PKG_NOMERGE_SYSTEM']      = _codes['darkblue']
_codes['PKG_NOMERGE_WORLD']       = _codes['blue']
_codes['PROMPT_CHOICE_DEFAULT']   = _codes['green']
_codes['PROMPT_CHOICE_OTHER']     = _codes['red']


def colorize(color_key, text):
	global havecolor
	if havecolor:
		return _codes[color_key] + text + _codes['reset']
	else:
		return text

